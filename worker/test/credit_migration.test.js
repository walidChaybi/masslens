import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import {DatabaseSync} from "node:sqlite";
import test from "node:test";

import {
  accessPayload,
  completeScan,
  enforceDailyAiCostLimit,
  MonetizationError,
  refundScan,
  reserveScan,
} from "../src/monetization.js";

const initialMigration = readFileSync(
  new URL("../migrations/0001_monetization.sql", import.meta.url),
  "utf8",
);
const creditsMigration = readFileSync(
  new URL("../migrations/0002_consumable_credits.sql", import.meta.url),
  "utf8",
);
const adsOnlyMigration = readFileSync(
  new URL("../migrations/0003_ads_only_access.sql", import.meta.url),
  "utf8",
);

function insertPurchase(db, {token, productId, credits, now}) {
  db.prepare(
    `INSERT OR IGNORE INTO consumable_purchases (
       purchase_token, client_id_hash, product_id, credits, order_id,
       purchase_time_ms, state, verified_at_ms, updated_at_ms
     ) VALUES (?, 'client-hash', ?, ?, NULL, ?, 'granted', ?, ?)`,
  ).run(token, productId, credits, now, now, now);
}

test("credit migration grants each token once and adds repeated packs", () => {
  const db = new DatabaseSync(":memory:");
  db.exec(creditsMigration);

  insertPurchase(db, {
    token: "token-basic",
    productId: "masslens_100_scans",
    credits: 100,
    now: 1,
  });
  insertPurchase(db, {
    token: "token-basic",
    productId: "masslens_100_scans",
    credits: 100,
    now: 2,
  });
  insertPurchase(db, {
    token: "token-max",
    productId: "masslens_500_scans",
    credits: 500,
    now: 3,
  });

  const wallet = db.prepare(
    "SELECT balance, lifetime_granted FROM credit_wallets",
  ).get();
  assert.equal(wallet.balance, 600);
  assert.equal(wallet.lifetime_granted, 600);
  assert.equal(
    db.prepare("SELECT COUNT(*) AS count FROM consumable_purchases").get()
      .count,
    2,
  );
  db.close();
});

test("voided purchases are removed once and can create refund debt", () => {
  const db = new DatabaseSync(":memory:");
  db.exec(creditsMigration);
  insertPurchase(db, {
    token: "token-max",
    productId: "masslens_500_scans",
    credits: 500,
    now: 1,
  });
  db.prepare(
    "UPDATE credit_wallets SET balance = 20 WHERE client_id_hash = ?",
  ).run("client-hash");

  db.prepare(
    `UPDATE consumable_purchases
        SET state = 'voided', voided_at_ms = 2, updated_at_ms = 2
      WHERE purchase_token = ?`,
  ).run("token-max");
  db.prepare(
    `UPDATE consumable_purchases
        SET state = 'voided', voided_at_ms = 3, updated_at_ms = 3
      WHERE purchase_token = ?`,
  ).run("token-max");

  assert.equal(
    db.prepare("SELECT balance FROM credit_wallets").get().balance,
    -480,
  );
  db.close();
});

test("ads-only migration carries bonus scans and preserves legacy credits", () => {
  const db = new DatabaseSync(":memory:");
  db.exec(initialMigration);
  db.exec(creditsMigration);
  db.prepare(
    `INSERT INTO free_usage (
       client_id_hash, period_key, included_used, bonus_credits, updated_at_ms
     ) VALUES ('client-hash', '2026-08', 2, 2, 100)`,
  ).run();
  db.prepare(
    `INSERT INTO credit_wallets (
       client_id_hash, balance, lifetime_granted, updated_at_ms
     ) VALUES ('client-hash', 7, 7, 100)`,
  ).run();

  db.exec(adsOnlyMigration);
  const wallet = db.prepare(
    "SELECT starter_used, rewarded_balance FROM ad_scan_wallets",
  ).get();
  assert.equal(wallet.starter_used, 1);
  assert.equal(wallet.rewarded_balance, 2);

  db.prepare(
    `INSERT OR IGNORE INTO ad_rewards (
       transaction_id, client_id_hash, period_key, reward_amount, created_at_ms
     ) VALUES ('transaction-1', 'client-hash', 'lifetime', 1, 200)`,
  ).run();
  db.prepare(
    `INSERT OR IGNORE INTO ad_rewards (
       transaction_id, client_id_hash, period_key, reward_amount, created_at_ms
     ) VALUES ('transaction-1', 'client-hash', 'lifetime', 1, 201)`,
  ).run();
  assert.equal(
    db.prepare(
      "SELECT rewarded_balance FROM ad_scan_wallets WHERE client_id_hash = 'client-hash'",
    ).get().rewarded_balance,
    3,
  );
  assert.equal(
    db.prepare("SELECT balance FROM credit_wallets").get().balance,
    7,
  );
  db.close();
});

test("starter reservation refunds failures and replays completed JSON", async () => {
  const sqlite = new DatabaseSync(":memory:");
  sqlite.exec(initialMigration);
  sqlite.exec(creditsMigration);
  sqlite.exec(adsOnlyMigration);
  const DB = d1Adapter(sqlite);
  const env = {DB, SCAN_ACCESS_ENFORCED: "true"};
  const clientHash = "a".repeat(64);

  const first = await reserveScan(env, clientHash, "request_identifier_refund");
  assert.equal(first.kind, "starter");
  await refundScan(env, clientHash, first);
  assert.equal(
    sqlite.prepare(
      "SELECT starter_used FROM ad_scan_wallets WHERE client_id_hash = ?",
    ).get(clientHash).starter_used,
    0,
  );

  const second = await reserveScan(env, clientHash, "request_identifier_replay");
  const estimate = {object_label: "Mug", estimate_grams: 300};
  await completeScan(env, clientHash, second, estimate);
  const replay = await reserveScan(
    env,
    clientHash,
    "request_identifier_replay",
  );
  assert.equal(replay.kind, "replay");
  assert.deepEqual(JSON.parse(replay.resultJson), estimate);
  const cached = sqlite.prepare(
    "SELECT updated_at_ms, expires_at_ms FROM scan_requests WHERE request_id = ?",
  ).get("request_identifier_replay");
  assert.ok(cached.expires_at_ms - cached.updated_at_ms >= 86_399_000);
  assert.equal(
    sqlite.prepare(
      "SELECT starter_used FROM ad_scan_wallets WHERE client_id_hash = ?",
    ).get(clientHash).starter_used,
    1,
  );

  const payload = accessPayload({starterUsed: 1, scanAccessEnforced: true});
  assert.equal(payload.remainingScans, 0);
  sqlite.close();
});

test("daily AI cost ceiling blocks before another provider call", async () => {
  const sqlite = new DatabaseSync(":memory:");
  sqlite.exec(initialMigration);
  sqlite.exec(creditsMigration);
  sqlite.exec(adsOnlyMigration);
  const today = new Date().toISOString().slice(0, 10);
  sqlite.prepare(
    `INSERT INTO daily_metrics (
       day, metric, dimension, event_count, value_micros, updated_at_ms
     ) VALUES (?, 'ai_cost', 'gpt-5-nano', 10, 5000, 1)`,
  ).run(today);

  await assert.rejects(
    enforceDailyAiCostLimit({
      DB: d1Adapter(sqlite),
      MAX_DAILY_AI_COST_MICROS: "5000",
    }),
    (error) => error instanceof MonetizationError &&
      error.code === "daily_cost_limit_reached",
  );
  sqlite.close();
});

function d1Adapter(sqlite) {
  return {
    prepare(sql) {
      let bindings = [];
      return {
        bind(...values) {
          bindings = values;
          return this;
        },
        run() {
          const result = sqlite.prepare(sql).run(...bindings);
          return {meta: {changes: Number(result.changes)}};
        },
        first() {
          return sqlite.prepare(sql).get(...bindings);
        },
      };
    },
  };
}

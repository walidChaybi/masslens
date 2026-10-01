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
  getAccess,
  isDebugUnlimited,
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
const lifetimeMigration = readFileSync(
  new URL("../migrations/0006_lifetime_entitlements.sql", import.meta.url),
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
  assert.equal(wallet.starter_used, 2);
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
  db.prepare(
    `INSERT OR IGNORE INTO ad_rewards (
       transaction_id, client_id_hash, period_key, reward_amount, created_at_ms
     ) VALUES ('transaction-2', 'client-hash', 'lifetime', 1, 202)`,
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
  sqlite.exec(lifetimeMigration);
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
  assert.equal(payload.remainingScans, 1);
  sqlite.close();
});

test("exactly two lifetime starter scans are available", async () => {
  const sqlite = new DatabaseSync(":memory:");
  sqlite.exec(initialMigration);
  sqlite.exec(creditsMigration);
  sqlite.exec(adsOnlyMigration);
  sqlite.exec(lifetimeMigration);
  const env = {DB: d1Adapter(sqlite), SCAN_ACCESS_ENFORCED: "true"};
  const clientHash = "b".repeat(64);

  for (let index = 1; index <= 2; index += 1) {
    const reservation = await reserveScan(
      env,
      clientHash,
      `starter_request_identifier_${index}`,
    );
    assert.equal(reservation.kind, "starter");
  }

  await assert.rejects(
    reserveScan(env, clientHash, "starter_request_identifier_3"),
    (error) => error instanceof MonetizationError &&
      error.status === 402 &&
      error.code === "scan_limit_reached",
  );
  assert.equal(
    sqlite.prepare(
      "SELECT starter_used FROM ad_scan_wallets WHERE client_id_hash = ?",
    ).get(clientHash).starter_used,
    2,
  );
  assert.equal(
    accessPayload({starterUsed: 2, scanAccessEnforced: true}).remainingScans,
    0,
  );
  sqlite.close();
});

test("debug unlimited is scoped to one installation and preserves normal quotas", async () => {
  const sqlite = new DatabaseSync(":memory:");
  sqlite.exec(initialMigration);
  sqlite.exec(creditsMigration);
  sqlite.exec(adsOnlyMigration);
  sqlite.exec(lifetimeMigration);
  const debugHash = "d".repeat(64);
  const env = {DB: d1Adapter(sqlite), SCAN_ACCESS_ENFORCED: "true", DEBUG_UNLIMITED_CLIENT_HASH: debugHash};
  assert.equal(isDebugUnlimited({}, debugHash, true), false);
  assert.equal(isDebugUnlimited(env, "e".repeat(64), true), false);
  for (let i = 0; i < 5; i++) {
    const reservation = await reserveScan(env, debugHash, `debug_unlimited_request_${i}`, true);
    assert.equal(reservation.kind, "lifetime");
    await completeScan(env, debugHash, reservation, {estimate_grams: 100});
  }
  const access = await getAccess(env, debugHash, true);
  assert.equal(access.debugUnlimited, true);
  assert.equal(access.hasLifetime, false);
  assert.equal(access.adsEnabled, true);
  assert.equal(access.starterScansRemaining, 2);
  // The same approved installation in a release build still has normal limits.
  assert.equal(isDebugUnlimited(env, debugHash), false);
  assert.equal((await getAccess(env, debugHash)).debugUnlimited, false);
  assert.equal((await getAccess(env, debugHash)).adsEnabled, true);
  await reserveScan(env, debugHash, "release_request_identifier_1");
  await reserveScan(env, debugHash, "release_request_identifier_2");
  await assert.rejects(reserveScan(env, debugHash, "release_request_identifier_3"), error => error.status === 402);
  const other = "e".repeat(64);
  await reserveScan(env, other, "normal_request_identifier_1");
  await reserveScan(env, other, "normal_request_identifier_2");
  await assert.rejects(reserveScan(env, other, "normal_request_identifier_3"), error => error.status === 402);
  assert.equal((await getAccess(env, other)).debugUnlimited, false);
  sqlite.close();
});

test("daily AI cost ceiling blocks before another provider call", async () => {
  const sqlite = new DatabaseSync(":memory:");
  sqlite.exec(initialMigration);
  sqlite.exec(creditsMigration);
  sqlite.exec(adsOnlyMigration);
  sqlite.exec(lifetimeMigration);
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


test("a user who used one free scan gets a second, then spends rewarded credit", async () => {
  const sqlite = new DatabaseSync(":memory:");
  for (const migration of [initialMigration, creditsMigration, adsOnlyMigration, lifetimeMigration]) {
    sqlite.exec(migration);
  }
  const env = {DB: d1Adapter(sqlite), SCAN_ACCESS_ENFORCED: "true"};
  const clientHash = "existing-one-scan-user";
  const first = await reserveScan(env, clientHash, "existing_first_scan_request");
  assert.equal(first.kind, "starter");
  await refundScan(env, clientHash, first);
  const retry = await reserveScan(env, clientHash, "existing_retry_scan_request");
  await completeScan(env, clientHash, retry, {estimate_grams: 10});
  assert.equal(accessPayload({starterUsed: 1, env}).starterScansRemaining, 1);

  const second = await reserveScan(env, clientHash, "existing_second_scan_request");
  assert.equal(second.kind, "starter");
  await completeScan(env, clientHash, second, {estimate_grams: 10});
  await assert.rejects(
    reserveScan(env, clientHash, "existing_third_scan_request"),
    error => error.status === 402 && error.code === "scan_limit_reached",
  );

  sqlite.prepare("UPDATE ad_scan_wallets SET rewarded_balance = 1 WHERE client_id_hash = ?")
    .run(clientHash);
  const rewarded = await reserveScan(env, clientHash, "existing_rewarded_scan_request");
  assert.equal(rewarded.kind, "rewarded");
  await completeScan(env, clientHash, rewarded, {estimate_grams: 10});
  assert.equal(accessPayload({starterUsed: 2, rewardedScans: 0, env}).remainingScans, 0);
  sqlite.close();
});

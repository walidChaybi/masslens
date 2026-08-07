import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import {DatabaseSync} from "node:sqlite";
import test from "node:test";

const migration = readFileSync(
  new URL("../migrations/0002_consumable_credits.sql", import.meta.url),
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
  db.exec(migration);

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
  db.exec(migration);
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

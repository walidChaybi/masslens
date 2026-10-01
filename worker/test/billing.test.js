import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import {DatabaseSync} from "node:sqlite";
import test from "node:test";

import {
  handleBillingRoute,
  hasActiveLifetimeEntitlement,
  resetPlayAuthCacheForTests,
  verifyLifetimePurchase,
  voidLifetimePurchase,
} from "../src/billing.js";
import {
  accessPayload,
  handleMonetizationRoute,
  reserveScan,
} from "../src/monetization.js";

const migrations = [
  readFileSync(new URL("../migrations/0001_monetization.sql", import.meta.url), "utf8"),
  readFileSync(new URL("../migrations/0002_consumable_credits.sql", import.meta.url), "utf8"),
  readFileSync(new URL("../migrations/0003_ads_only_access.sql", import.meta.url), "utf8"),
  readFileSync(new URL("../migrations/0006_lifetime_entitlements.sql", import.meta.url), "utf8"),
];

const clientId = "abcdefghijklmnopqrstuvwx";
const productId = "masslens_lifetime_unlimited";
const purchaseToken = "purchase-token-abcdefghijklmnopqrstuvwxyz";

function createContext() {
  const sqlite = new DatabaseSync(":memory:");
  for (const migration of migrations) sqlite.exec(migration);
  const env = {
    DB: d1Adapter(sqlite),
    SCAN_ACCESS_ENFORCED: "true",
    PLAY_PACKAGE_NAME: "com.lilai.aivirtual",
    PLAY_LIFETIME_PRODUCT_ID: productId,
    PLAY_SERVICE_ACCOUNT_JSON: JSON.stringify({
      client_email: "billing@example.iam.gserviceaccount.com",
      private_key: "-----BEGIN PRIVATE KEY-----\nMIIB\n-----END PRIVATE KEY-----\n",
    }),
  };
  return {
    sqlite,
    env,
    close: () => sqlite.close(),
  };
}

function d1Adapter(sqlite) {
  return {
    prepare(sql) {
      return {
        bind(...bindings) {
          return {
            run: async () => {
              const result = sqlite.prepare(sql).run(...bindings);
              return {meta: {changes: result.changes}};
            },
            first: async () => sqlite.prepare(sql).get(...bindings),
            all: async () => sqlite.prepare(sql).all(...bindings),
          };
        },
      };
    },
    batch: async (statements) => {
      sqlite.exec("BEGIN");
      try {
        const results = [];
        for (const statement of statements) results.push(await statement.run());
        sqlite.exec("COMMIT");
        return results;
      } catch (error) {
        sqlite.exec("ROLLBACK");
        throw error;
      }
    },
  };
}

async function hashClientId(value) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest), (byte) =>
    byte.toString(16).padStart(2, "0"),
  ).join("");
}

function mockPlayPurchase(overrides = {}) {
  return {
    purchaseState: 0,
    acknowledgementState: 1,
    purchaseTimeMillis: 1_700_000_000_000,
    orderId: "GPA.1234-5678-9012-34567",
    ...overrides,
  };
}

test("access payload disables ads for lifetime buyers", () => {
  const payload = accessPayload({
    starterUsed: 3,
    scanAccessEnforced: true,
    hasLifetime: true,
  });
  assert.equal(payload.hasLifetime, true);
  assert.equal(payload.adsEnabled, false);
});

test("verify grants lifetime entitlement and is idempotent", async () => {
  const context = createContext();
  const clientIdHash = await hashClientId(clientId);
  const dependencies = {
    verifyPurchaseWithPlay: async () => mockPlayPurchase(),
    acknowledgePurchaseWithPlay: async () => {},
    now: () => 1000,
  };

  const first = await verifyLifetimePurchase(
    context.env,
    clientIdHash,
    {productId, purchaseToken},
    dependencies,
  );
  assert.deepEqual(first, {hasLifetime: true, status: "verified"});
  assert.equal(await hasActiveLifetimeEntitlement(context.env.DB, clientIdHash), true);

  const second = await verifyLifetimePurchase(
    context.env,
    clientIdHash,
    {productId, purchaseToken},
    dependencies,
  );
  assert.deepEqual(second, {hasLifetime: true, status: "restored"});
  assert.equal(
    context.sqlite.prepare("SELECT COUNT(*) AS count FROM lifetime_entitlements").get()
      .count,
    1,
  );
  context.close();
});

test("verify accepts discounted lifetime SKUs from the wheel", async () => {
  const context = createContext();
  const clientIdHash = await hashClientId(clientId);
  const discountedId = "masslens_lifetime_off_50";
  const first = await verifyLifetimePurchase(
    context.env,
    clientIdHash,
    {productId: discountedId, purchaseToken},
    {
      verifyPurchaseWithPlay: async (_env, args) => {
        assert.equal(args.productId, discountedId);
        return mockPlayPurchase();
      },
      acknowledgePurchaseWithPlay: async () => {},
      now: () => 1000,
    },
  );
  assert.deepEqual(first, {hasLifetime: true, status: "verified"});
  assert.equal(await hasActiveLifetimeEntitlement(context.env.DB, clientIdHash), true);
  const row = context.sqlite.prepare(
    "SELECT product_id FROM lifetime_entitlements WHERE purchase_token = ?",
  ).get(purchaseToken);
  assert.equal(row.product_id, discountedId);
  context.close();
});

test("rtdn void accepts a discounted lifetime SKU", async () => {
  resetPlayAuthCacheForTests();
  const context = createContext();
  const clientIdHash = await hashClientId(clientId);
  const discountedId = "masslens_lifetime_off_70";
  context.sqlite.prepare(
    `INSERT INTO lifetime_entitlements (
       purchase_token, client_id_hash, product_id, order_id,
       purchase_time_ms, state, verified_at_ms, voided_at_ms, updated_at_ms
     ) VALUES (?, ?, ?, NULL, 1, 'active', 1, NULL, 1)`,
  ).run(purchaseToken, clientIdHash, discountedId);

  const payload = {
    message: {
      data: btoa(JSON.stringify({
        oneTimeProductNotification: {
          notificationType: 2,
          purchaseToken,
          sku: discountedId,
        },
      })),
    },
  };
  const response = await handleBillingRoute(
    new Request("https://masslens.example/billing/rtdn", {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify(payload),
    }),
    context.env,
    new URL("https://masslens.example/billing/rtdn"),
    {now: () => 2000},
  );
  assert.equal(response.status, 204);
  assert.equal(await hasActiveLifetimeEntitlement(context.env.DB, clientIdHash), false);
  context.close();
});

test("verify rejects unsupported products and voided purchases", async () => {
  const context = createContext();
  const clientIdHash = await hashClientId(clientId);
  context.sqlite.prepare(
    `INSERT INTO lifetime_entitlements (
       purchase_token, client_id_hash, product_id, order_id,
       purchase_time_ms, state, verified_at_ms, voided_at_ms, updated_at_ms
     ) VALUES (?, ?, ?, NULL, 1, 'voided', 1, 2, 2)`,
  ).run(purchaseToken, clientIdHash, productId);

  await assert.rejects(
    () => verifyLifetimePurchase(
      context.env,
      clientIdHash,
      {productId: "wrong_product", purchaseToken},
      {verifyPurchaseWithPlay: async () => mockPlayPurchase()},
    ),
    (error) => error.code === "invalid_product_id",
  );

  await assert.rejects(
    () => verifyLifetimePurchase(
      context.env,
      clientIdHash,
      {productId, purchaseToken},
      {verifyPurchaseWithPlay: async () => mockPlayPurchase()},
    ),
    (error) => error.code === "purchase_voided",
  );
  context.close();
});

test("restore rebinds an active purchase token to the current installation", async () => {
  const context = createContext();
  const oldHash = "old-client-hash";
  const newHash = await hashClientId(clientId);
  context.sqlite.prepare(
    `INSERT INTO lifetime_entitlements (
       purchase_token, client_id_hash, product_id, order_id,
       purchase_time_ms, state, verified_at_ms, voided_at_ms, updated_at_ms
     ) VALUES (?, ?, ?, NULL, 1, 'active', 1, NULL, 1)`,
  ).run(purchaseToken, oldHash, productId);

  const result = await verifyLifetimePurchase(
    context.env,
    newHash,
    {productId, purchaseToken},
    {verifyPurchaseWithPlay: async () => mockPlayPurchase()},
  );
  assert.equal(result.status, "restored");
  const row = context.sqlite.prepare(
    "SELECT client_id_hash FROM lifetime_entitlements WHERE purchase_token = ?",
  ).get(purchaseToken);
  assert.equal(row.client_id_hash, newHash);
  context.close();
});

test("lifetime users reserve scans without touching the wallet", async () => {
  const context = createContext();
  const clientIdHash = await hashClientId(clientId);
  context.sqlite.prepare(
    `INSERT INTO lifetime_entitlements (
       purchase_token, client_id_hash, product_id, order_id,
       purchase_time_ms, state, verified_at_ms, voided_at_ms, updated_at_ms
     ) VALUES (?, ?, ?, NULL, 1, 'active', 1, NULL, 1)`,
  ).run(purchaseToken, clientIdHash, productId);

  const reservation = await reserveScan(
    context.env,
    clientIdHash,
    "request_identifier_lifetime",
  );
  assert.equal(reservation.kind, "lifetime");
  assert.equal(
    context.sqlite.prepare("SELECT starter_used FROM ad_scan_wallets").get()
      ?.starter_used ?? 0,
    0,
  );
  context.close();
});

test("lifetime access permits more than 40 scans per day", async () => {
  const context = createContext();
  const clientIdHash = await hashClientId(clientId);
  context.sqlite.prepare(
    `INSERT INTO lifetime_entitlements (
       purchase_token, client_id_hash, product_id, order_id,
       purchase_time_ms, state, verified_at_ms, voided_at_ms, updated_at_ms
     ) VALUES (?, ?, ?, NULL, 1, 'active', 1, NULL, 1)`,
  ).run(purchaseToken, clientIdHash, productId);

  for (let index = 0; index < 40; index += 1) {
    await reserveScan(
      context.env,
      clientIdHash,
      `request_identifier_lifetime_${index}`,
    );
  }

  const next = await reserveScan(
    context.env,
    clientIdHash,
    "request_identifier_lifetime_overflow",
  );
  assert.equal(next.kind, "lifetime");
  context.close();
});

test("rtdn void revokes lifetime access", async () => {
  resetPlayAuthCacheForTests();
  const context = createContext();
  const clientIdHash = await hashClientId(clientId);
  context.sqlite.prepare(
    `INSERT INTO lifetime_entitlements (
       purchase_token, client_id_hash, product_id, order_id,
       purchase_time_ms, state, verified_at_ms, voided_at_ms, updated_at_ms
     ) VALUES (?, ?, ?, NULL, 1, 'active', 1, NULL, 1)`,
  ).run(purchaseToken, clientIdHash, productId);

  const payload = {
    message: {
      data: btoa(JSON.stringify({
        oneTimeProductNotification: {
          notificationType: 2,
          purchaseToken,
          sku: productId,
        },
      })),
    },
  };
  const response = await handleBillingRoute(
    new Request("https://masslens.example/billing/rtdn", {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify(payload),
    }),
    context.env,
    new URL("https://masslens.example/billing/rtdn"),
    {now: () => 2000},
  );
  assert.equal(response.status, 204);
  assert.equal(await hasActiveLifetimeEntitlement(context.env.DB, clientIdHash), false);
  assert.equal(await voidLifetimePurchase(context.env, purchaseToken, 2000), false);
  context.close();
});

test("billing verify route returns access payload fields through monetization router", async () => {
  const context = createContext();
  const response = await handleMonetizationRoute(
    new Request("https://masslens.example/billing/verify", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-MassLens-Client-ID": clientId,
      },
      body: JSON.stringify({productId, purchaseToken}),
    }),
    context.env,
    new URL("https://masslens.example/billing/verify"),
    {
      verifyPurchaseWithPlay: async () => mockPlayPurchase({acknowledgementState: 0}),
      acknowledgePurchaseWithPlay: async () => {},
      now: () => 1000,
    },
  );
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {hasLifetime: true, status: "verified"});
  context.close();
});


test("new app purchases and restores verify the explicit package with Google Play", async () => {
  const context = createContext();
  const packageName = "com.lilai.masslens.photoestimates";
  context.env.PLAY_ADDITIONAL_PACKAGE_NAMES = packageName;
  const verifiedPackages = [];
  const dependencies = {
    verifyPurchaseWithPlay: async (_, request) => {
      verifiedPackages.push(request.packageName);
      return mockPlayPurchase();
    },
    now: () => 1000,
  };
  try {
    const hash = await hashClientId(clientId);
    await verifyLifetimePurchase(context.env, hash, {productId, purchaseToken}, dependencies);
    await verifyLifetimePurchase(context.env, hash, {productId, purchaseToken, packageName}, dependencies);
    assert.deepEqual(verifiedPackages, ["com.lilai.aivirtual", packageName]);
    await assert.rejects(
      verifyLifetimePurchase(context.env, hash, {productId, purchaseToken, packageName: "com.unknown.app"}, dependencies),
      (error) => error.code === "invalid_package_name",
    );
    assert.equal(verifiedPackages.length, 2);
  } finally {
    context.close();
  }
});

test("new app rejects wheel products even when legacy products are supported", async () => {
  const context = createContext();
  const packageName = "com.lilai.masslens.photoestimates";
  context.env.PLAY_ADDITIONAL_PACKAGE_NAMES = packageName;
  try {
    for (const percent of [30, 40, 50, 60, 70, 80, 90]) {
      await assert.rejects(
        verifyLifetimePurchase(context.env, await hashClientId(clientId), {
          productId: `masslens_lifetime_off_${percent}`, purchaseToken, packageName,
        }, {verifyPurchaseWithPlay: async () => { throw new Error("Must not reach Play"); }}),
        (error) => error.code === "invalid_product_id",
      );
    }
  } finally { context.close(); }
});

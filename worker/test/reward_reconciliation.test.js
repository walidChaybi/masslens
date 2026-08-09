import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import {DatabaseSync} from "node:sqlite";
import test from "node:test";

import worker from "../src/index.js";
import {
  handleMonetizationRoute,
  MonetizationError,
} from "../src/monetization.js";

const migrationUrls = [
  "../migrations/0001_monetization.sql",
  "../migrations/0002_consumable_credits.sql",
  "../migrations/0003_ads_only_access.sql",
  "../migrations/0004_reward_reconciliation.sql",
  "../migrations/0005_client_reward_grants.sql",
];
const migrations = migrationUrls.map((url) =>
  readFileSync(new URL(url, import.meta.url), "utf8"),
);
const initialNow = 1_786_200_000_000;
const cooldownMs = 2 * 60 * 1000;
const clientId = "reward_client_identifier_01";
const otherClientId = "reward_client_identifier_02";

test("client-earned atomically verifies and credits one scan", async () => {
  const context = createContext();
  const attemptId = "reward_attempt_identifier_01";

  const started = await postAttempt(context, clientId, attemptId, "started");
  assert.equal(started.status, 201);
  assert.equal((await started.json()).state, "pending");

  const earned = await postAttempt(
    context,
    clientId,
    attemptId,
    "client_earned",
  );
  assert.equal(earned.status, 200);
  assert.equal((await earned.json()).state, "verified");
  assert.equal(rewardedBalance(context.sqlite, clientId), 1);
  assert.equal(tableCount(context.sqlite, "client_reward_grants"), 1);
  assert.equal(tableCount(context.sqlite, "ad_rewards"), 0);

  const status = await getAttempt(context, clientId, attemptId);
  assert.equal(status.status, 200);
  assert.equal((await status.json()).state, "verified");
  assert.equal(metricCount(context.sqlite, "reward_granted"), 1);
  context.close();
});

test("lost acknowledgements and concurrent retries never double-credit", async () => {
  const context = createContext();
  const attemptId = "reward_attempt_identifier_02";
  await postAttempt(context, clientId, attemptId, "started");

  const responses = await Promise.all([
    postAttempt(context, clientId, attemptId, "client_earned"),
    postAttempt(context, clientId, attemptId, "client_earned"),
  ]);
  assert.deepEqual(responses.map((response) => response.status), [200, 200]);
  assert.ok(
    (await Promise.all(responses.map((response) => response.json())))
      .every((payload) => payload.state === "verified"),
  );
  assert.equal(rewardedBalance(context.sqlite, clientId), 1);
  assert.equal(tableCount(context.sqlite, "client_reward_grants"), 1);

  const laterRetry = await postAttempt(
    context,
    clientId,
    attemptId,
    "client_earned",
  );
  assert.equal((await laterRetry.json()).state, "verified");
  assert.equal(rewardedBalance(context.sqlite, clientId), 1);
  assert.equal(tableCount(context.sqlite, "client_reward_grants"), 1);
  context.close();
});

test("server cooldown blocks a new ad but never its immediate earned event", async () => {
  const context = createContext();
  const firstAttempt = "reward_attempt_identifier_03";
  const secondAttempt = "reward_attempt_identifier_04";
  await postAttempt(context, clientId, firstAttempt, "started");

  const immediateGrant = await postAttempt(
    context,
    clientId,
    firstAttempt,
    "client_earned",
  );
  assert.equal((await immediateGrant.json()).state, "verified");
  await assert.rejects(
    postAttempt(context, clientId, secondAttempt, "started"),
    isMonetizationError(429, "reward_cooldown"),
  );

  context.clock.now += cooldownMs;
  const afterCooldown = await postAttempt(
    context,
    clientId,
    secondAttempt,
    "started",
  );
  assert.equal(afterCooldown.status, 201);
  assert.equal((await afterCooldown.json()).state, "pending");
  context.close();
});

test("grant cooldown keeps a migrated earned attempt pending for retry", async () => {
  const context = createContext();
  const firstAttempt = "reward_attempt_identifier_11";
  const migratedAttempt = "reward_attempt_identifier_12";
  await postAttempt(context, clientId, firstAttempt, "started");
  await postAttempt(context, clientId, firstAttempt, "client_earned");
  const clientIdHash = context.sqlite.prepare(
    "SELECT client_id_hash FROM ad_scan_wallets LIMIT 1",
  ).get().client_id_hash;
  context.sqlite.prepare(
    `INSERT INTO reward_attempts (
       attempt_id, client_id_hash, state, created_at_ms, updated_at_ms,
       expires_at_ms
     ) VALUES (?, ?, 'pending', ?, ?, ?)`,
  ).run(
    migratedAttempt,
    clientIdHash,
    context.clock.now,
    context.clock.now,
    context.clock.now + 24 * 60 * 60 * 1000,
  );

  await assert.rejects(
    postAttempt(context, clientId, migratedAttempt, "client_earned"),
    isMonetizationError(429, "reward_cooldown"),
  );
  assert.equal(
    (await (await getAttempt(context, clientId, migratedAttempt)).json()).state,
    "pending",
  );
  context.clock.now += cooldownMs;
  const retried = await postAttempt(
    context,
    clientId,
    migratedAttempt,
    "client_earned",
  );
  assert.equal((await retried.json()).state, "verified");
  assert.equal(rewardedBalance(context.sqlite, clientId), 2);
  context.close();
});

test("concurrent starts create only one cooldown lease", async () => {
  const context = createContext();
  const attempts = [
    "concurrent_reward_attempt_01",
    "concurrent_reward_attempt_02",
  ];
  const outcomes = await Promise.allSettled(
    attempts.map((attemptId) =>
      postAttempt(context, clientId, attemptId, "started"),
    ),
  );

  assert.equal(
    outcomes.filter((outcome) => outcome.status === "fulfilled").length,
    1,
  );
  const rejection = outcomes.find((outcome) => outcome.status === "rejected");
  assert.ok(rejection.reason instanceof MonetizationError);
  assert.equal(rejection.reason.code, "reward_cooldown");
  assert.equal(tableCount(context.sqlite, "reward_attempts"), 1);
  context.close();
});

test("balance cap prevents an ad from starting", async () => {
  const context = createContext();
  await setRewardedBalance(context, clientId, 3);

  await assert.rejects(
    postAttempt(
      context,
      clientId,
      "reward_attempt_identifier_05",
      "started",
    ),
    isMonetizationError(409, "reward_balance_cap_reached"),
  );
  assert.equal(tableCount(context.sqlite, "reward_attempts"), 0);
  assert.equal(tableCount(context.sqlite, "client_reward_grants"), 0);
  assert.equal(rewardedBalance(context.sqlite, clientId), 3);
  context.close();
});

test("a cap race leaves an earned attempt durable until capacity exists", async () => {
  const context = createContext();
  const attemptId = "reward_attempt_identifier_06";
  await setRewardedBalance(context, clientId, 2);
  await postAttempt(context, clientId, attemptId, "started");
  await setRewardedBalance(context, clientId, 3);

  await assert.rejects(
    postAttempt(context, clientId, attemptId, "client_earned"),
    isMonetizationError(409, "reward_balance_cap_reached"),
  );
  const pending = await getAttempt(context, clientId, attemptId);
  const pendingPayload = await pending.json();
  assert.equal(pendingPayload.state, "pending");
  assert.equal(pendingPayload.clientEarnedAtMs, context.clock.now);
  assert.equal(tableCount(context.sqlite, "client_reward_grants"), 0);

  await setRewardedBalance(context, clientId, 2);
  const retried = await postAttempt(
    context,
    clientId,
    attemptId,
    "client_earned",
  );
  assert.equal((await retried.json()).state, "verified");
  assert.equal(rewardedBalance(context.sqlite, clientId), 3);
  assert.equal(tableCount(context.sqlite, "client_reward_grants"), 1);
  context.close();
});

test("attempt ownership is required for client-earned grants", async () => {
  const context = createContext();
  const attemptId = "reward_attempt_identifier_07";
  await postAttempt(context, clientId, attemptId, "started");

  await assert.rejects(
    postAttempt(context, otherClientId, attemptId, "client_earned"),
    isMonetizationError(404, "reward_attempt_not_found"),
  );
  assert.equal(tableCount(context.sqlite, "client_reward_grants"), 0);
  assert.equal(rewardedBalance(context.sqlite, clientId), 0);
  context.close();
});

test("an abandoned attempt can be superseded only after cooldown", async () => {
  const context = createContext();
  const abandoned = "reward_attempt_identifier_08";
  const current = "reward_attempt_identifier_09";
  await postAttempt(context, clientId, abandoned, "started");
  context.clock.now += cooldownMs;
  await postAttempt(context, clientId, current, "started");

  const oldEarned = await postAttempt(
    context,
    clientId,
    abandoned,
    "client_earned",
  );
  const oldPayload = await oldEarned.json();
  assert.equal(oldPayload.state, "rejected");
  assert.equal(oldPayload.rejectionCode, "attempt_superseded");
  assert.equal(tableCount(context.sqlite, "client_reward_grants"), 0);

  const currentEarned = await postAttempt(
    context,
    clientId,
    current,
    "client_earned",
  );
  assert.equal((await currentEarned.json()).state, "verified");
  assert.equal(rewardedBalance(context.sqlite, clientId), 1);
  context.close();
});

test("pending attempts created before migration 0005 remain grantable", async () => {
  const context = createContext();
  const attemptId = "reward_attempt_identifier_10";
  await postAttempt(context, clientId, attemptId, "started");
  context.sqlite.prepare("DELETE FROM reward_client_cooldowns").run();

  const earned = await postAttempt(
    context,
    clientId,
    attemptId,
    "client_earned",
  );
  assert.equal((await earned.json()).state, "verified");
  assert.equal(rewardedBalance(context.sqlite, clientId), 1);
  assert.equal(tableCount(context.sqlite, "client_reward_grants"), 1);
  context.close();
});

test("the former AdMob SSV callback route is inert", async () => {
  const response = await worker.fetch(
    new Request("https://masslens.example/admob/reward?anything=1"),
    {},
  );
  assert.equal(response.status, 404);
  assert.equal((await response.json()).error.code, "not_found");
});

test("audited support adjustments remain separate and idempotent", () => {
  const context = createContext();
  const sql = `INSERT OR IGNORE INTO scan_credit_adjustments (
      adjustment_id, client_id_hash, credit_amount, reason, actor,
      created_at_ms
    ) VALUES ('support-case-001', 'client-hash', 1,
              'reward_reconciliation', 'support', 1)`;
  context.sqlite.prepare(sql).run();
  context.sqlite.prepare(sql).run();

  const wallet = context.sqlite.prepare(
    `SELECT balance, lifetime_granted FROM credit_wallets
      WHERE client_id_hash = 'client-hash'`,
  ).get();
  assert.equal(wallet.balance, 1);
  assert.equal(wallet.lifetime_granted, 1);
  assert.equal(tableCount(context.sqlite, "scan_credit_adjustments"), 1);
  assert.equal(tableCount(context.sqlite, "client_reward_grants"), 0);
  context.close();
});

function createContext() {
  const sqlite = new DatabaseSync(":memory:");
  for (const migration of migrations) sqlite.exec(migration);
  const clock = {now: initialNow};
  return {
    sqlite,
    clock,
    env: {DB: d1Adapter(sqlite)},
    close: () => sqlite.close(),
  };
}

async function postAttempt(context, client, attemptId, event) {
  return route(context, "/reward-attempts", {
    method: "POST",
    client,
    body: {attemptId, event},
  });
}

async function getAttempt(context, client, attemptId) {
  return route(context, `/reward-attempts/${attemptId}`, {client});
}

async function route(
  context,
  path,
  {method = "GET", client, body} = {},
) {
  const headers = {};
  if (client) headers["X-MassLens-Client-ID"] = client;
  if (body) headers["Content-Type"] = "application/json";
  const request = new Request(`https://masslens.example${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  return handleMonetizationRoute(
    request,
    context.env,
    new URL(request.url),
    {now: () => context.clock.now},
  );
}

async function setRewardedBalance(context, client, balance) {
  const attemptId = "wallet_seed_attempt_identifier";
  if (tableCount(context.sqlite, "ad_scan_wallets") === 0) {
    await postAttempt(context, client, attemptId, "started").catch(() => {});
    context.sqlite.prepare(
      "DELETE FROM reward_attempts WHERE attempt_id = ?",
    ).run(attemptId);
    context.sqlite.prepare(
      "DELETE FROM reward_client_cooldowns WHERE client_id_hash IN (SELECT client_id_hash FROM ad_scan_wallets)",
    ).run();
  }
  context.sqlite.prepare(
    "UPDATE ad_scan_wallets SET rewarded_balance = ?",
  ).run(balance);
}

function rewardedBalance(sqlite, client) {
  assert.ok(client);
  return Number(sqlite.prepare(
    "SELECT rewarded_balance FROM ad_scan_wallets LIMIT 1",
  ).get()?.rewarded_balance || 0);
}

function tableCount(sqlite, table) {
  return Number(sqlite.prepare(`SELECT COUNT(*) AS count FROM ${table}`).get().count);
}

function metricCount(sqlite, metric) {
  return Number(sqlite.prepare(
    "SELECT COALESCE(SUM(event_count), 0) AS count FROM daily_metrics WHERE metric = ?",
  ).get(metric).count);
}

function isMonetizationError(status, code) {
  return (error) => error instanceof MonetizationError &&
    error.status === status && error.code === code;
}

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
    async batch(statements) {
      sqlite.exec("BEGIN");
      try {
        const results = [];
        for (const statement of statements) results.push(statement.run());
        sqlite.exec("COMMIT");
        return results;
      } catch (error) {
        sqlite.exec("ROLLBACK");
        throw error;
      }
    },
  };
}

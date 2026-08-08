const clientIdPattern = /^[A-Za-z0-9_-]{20,80}$/;
const requestIdPattern = /^[A-Za-z0-9_-]{20,80}$/;
const lifetimeStarterScans = 3;
const rewardBalanceCap = 3;
const resultTtlMs = 24 * 60 * 60 * 1000;
const pendingTtlMs = 2 * 60 * 1000;

let cachedAdMobKeys;

export async function handleMonetizationRoute(request, env, url) {
  if (request.method === "GET" && url.pathname === "/access") {
    const clientIdHash = await readHashedClientId(request);
    return jsonResponse(await getAccess(env, clientIdHash));
  }

  if (request.method === "GET" && url.pathname === "/admob/reward") {
    await handleAdMobReward(request, env);
    return new Response("OK", {
      status: 200,
      headers: {"Cache-Control": "no-store", "Content-Type": "text/plain"},
    });
  }

  if (request.method === "POST" && url.pathname === "/metrics/ad-revenue") {
    const clientIdHash = await readHashedClientId(request);
    await recordAdRevenue(request, env, clientIdHash);
    return new Response(null, {status: 204});
  }

  return null;
}

export function isScanAccessEnforced(env) {
  return env.SCAN_ACCESS_ENFORCED === "true";
}

export function readRequestId(request) {
  const requestId = request.headers.get("x-masslens-request-id") || "";
  if (!requestIdPattern.test(requestId)) {
    throw new MonetizationError(
      400,
      "invalid_request_id",
      "A valid scan request identifier is required.",
    );
  }
  return requestId;
}

export async function reserveScan(env, clientIdHash, requestId) {
  if (!isScanAccessEnforced(env)) return {kind: "disabled", requestId};
  const db = requireDatabase(env);
  const now = Date.now();
  await ensureWallet(db, clientIdHash, now);
  await cleanupExpiredRequests(db, now);

  const existing = await db.prepare(
    `SELECT client_id_hash, state, reservation_kind, result_json, created_at_ms
       FROM scan_requests WHERE request_id = ?`,
  ).bind(requestId).first();
  if (existing) {
    if (existing.client_id_hash !== clientIdHash) {
      throw new MonetizationError(
        409,
        "request_owner_mismatch",
        "This scan request belongs to another installation.",
      );
    }
    if (existing.state === "completed" && existing.result_json) {
      return {kind: "replay", requestId, resultJson: existing.result_json};
    }
    if (
      (existing.state === "pending" || existing.state === "reserved") &&
      now - Number(existing.created_at_ms) < pendingTtlMs
    ) {
      throw new MonetizationError(
        409,
        "scan_in_progress",
        "This scan is still processing.",
      );
    }
    if (existing.state === "reserved") {
      await refundScan(env, clientIdHash, {
        kind: existing.reservation_kind,
        requestId,
      });
    }
    await db.prepare("DELETE FROM scan_requests WHERE request_id = ?")
      .bind(requestId).run();
  }

  await db.prepare(
    `INSERT INTO scan_requests (
       request_id, client_id_hash, state, created_at_ms, updated_at_ms,
       expires_at_ms
     ) VALUES (?, ?, 'pending', ?, ?, ?)`,
  ).bind(requestId, clientIdHash, now, now, now + resultTtlMs).run();

  let kind;
  const starter = await db.prepare(
    `UPDATE ad_scan_wallets
        SET starter_used = starter_used + 1, updated_at_ms = ?
      WHERE client_id_hash = ? AND starter_used < ?`,
  ).bind(now, clientIdHash, lifetimeStarterScans).run();
  if (changedRows(starter) === 1) {
    kind = "starter";
  } else {
    // Historical purchased credits stay ad-free and are deliberately spent
    // before rewarded credits so ads resume only after legacy value is gone.
    const legacy = await db.prepare(
      `UPDATE credit_wallets
          SET balance = balance - 1, updated_at_ms = ?
        WHERE client_id_hash = ? AND balance > 0`,
    ).bind(now, clientIdHash).run();
    if (changedRows(legacy) === 1) {
      kind = "legacy";
    } else {
      const rewarded = await db.prepare(
        `UPDATE ad_scan_wallets
            SET rewarded_balance = rewarded_balance - 1, updated_at_ms = ?
          WHERE client_id_hash = ? AND rewarded_balance > 0`,
      ).bind(now, clientIdHash).run();
      if (changedRows(rewarded) === 1) kind = "rewarded";
    }
  }

  if (!kind) {
    await db.prepare("DELETE FROM scan_requests WHERE request_id = ?")
      .bind(requestId).run();
    throw new MonetizationError(
      402,
      "scan_limit_reached",
      "No scans remain. Watch a rewarded ad to add one scan.",
    );
  }

  await db.prepare(
    `UPDATE scan_requests
        SET state = 'reserved', reservation_kind = ?, updated_at_ms = ?
      WHERE request_id = ?`,
  ).bind(kind, now, requestId).run();
  await safeMetric(env, "scan_reserved", kind, 1, 0);
  return {kind, requestId};
}

export async function completeScan(env, clientIdHash, reservation, estimate) {
  if (!reservation || reservation.kind === "disabled") return;
  const db = requireDatabase(env);
  const now = Date.now();
  await db.prepare(
    `UPDATE scan_requests
        SET state = 'completed', result_json = ?, updated_at_ms = ?,
            expires_at_ms = ?
      WHERE request_id = ? AND client_id_hash = ? AND state = 'reserved'`,
  ).bind(
    JSON.stringify(estimate),
    now,
    now + resultTtlMs,
    reservation.requestId,
    clientIdHash,
  ).run();
  await safeMetric(env, "scan_completed", reservation.kind, 1, 0);
}

export async function refundScan(env, clientIdHash, reservation) {
  if (
    !reservation ||
    reservation.kind === "disabled" ||
    reservation.kind === "replay" ||
    !env.DB
  ) {
    return;
  }
  const now = Date.now();
  const marked = await env.DB.prepare(
    `UPDATE scan_requests
        SET state = 'refunded', updated_at_ms = ?
      WHERE request_id = ? AND client_id_hash = ? AND state = 'reserved'`,
  ).bind(now, reservation.requestId, clientIdHash).run();
  if (changedRows(marked) !== 1) return;

  if (reservation.kind === "starter") {
    await env.DB.prepare(
      `UPDATE ad_scan_wallets
          SET starter_used = MAX(0, starter_used - 1), updated_at_ms = ?
        WHERE client_id_hash = ?`,
    ).bind(now, clientIdHash).run();
  } else if (reservation.kind === "rewarded") {
    await env.DB.prepare(
      `UPDATE ad_scan_wallets
          SET rewarded_balance = rewarded_balance + 1, updated_at_ms = ?
        WHERE client_id_hash = ?`,
    ).bind(now, clientIdHash).run();
  } else if (reservation.kind === "legacy") {
    await env.DB.prepare(
      `UPDATE credit_wallets
          SET balance = balance + 1, updated_at_ms = ?
        WHERE client_id_hash = ?`,
    ).bind(now, clientIdHash).run();
  }
  await safeMetric(env, "scan_refunded", reservation.kind, 1, 0);
}

export async function enforceDailyAiCostLimit(env) {
  const limit = readPositiveNumber(env.MAX_DAILY_AI_COST_MICROS, 0);
  if (!env.DB || limit <= 0) return;
  const row = await env.DB.prepare(
    `SELECT COALESCE(SUM(value_micros), 0) AS value_micros
       FROM daily_metrics WHERE day = ? AND metric = 'ai_cost'`,
  ).bind(currentDay()).first();
  if (Number(row?.value_micros || 0) >= limit) {
    throw new MonetizationError(
      503,
      "daily_cost_limit_reached",
      "AI scans are temporarily paused. Please try again tomorrow.",
    );
  }
}

export async function recordAiUsage(
  env,
  {model, inputTokens = 0, outputTokens = 0},
) {
  if (!env.DB) return;
  const inputRate = readPositiveNumber(
    env.OPENAI_INPUT_USD_PER_MTOK,
    model === "gpt-5-nano" ? 0.05 : 0.20,
  );
  const outputRate = readPositiveNumber(
    env.OPENAI_OUTPUT_USD_PER_MTOK,
    model === "gpt-5-nano" ? 0.40 : 1.20,
  );
  const estimatedCostMicros = Math.ceil(
    Number(inputTokens) * inputRate + Number(outputTokens) * outputRate,
  );
  await Promise.all([
    recordDailyMetric(env, "ai_input_tokens", model, Number(inputTokens), 0),
    recordDailyMetric(env, "ai_output_tokens", model, Number(outputTokens), 0),
    recordDailyMetric(env, "ai_cost", model, 1, estimatedCostMicros),
  ]);
}

export async function readHashedClientId(request) {
  const clientId = request.headers.get("x-masslens-client-id") || "";
  if (!clientIdPattern.test(clientId)) {
    throw new MonetizationError(
      400,
      "invalid_client_id",
      "A valid client identifier is required.",
    );
  }
  return hashIdentifier(clientId);
}

async function getAccess(env, clientIdHash) {
  const enforced = isScanAccessEnforced(env);
  if (!env.DB) {
    if (enforced) {
      throw new MonetizationError(
        503,
        "access_not_configured",
        "Scan access storage is not configured.",
      );
    }
    return accessPayload({scanAccessEnforced: false});
  }

  const now = Date.now();
  await ensureWallet(env.DB, clientIdHash, now);
  const wallet = await env.DB.prepare(
    `SELECT starter_used, rewarded_balance
       FROM ad_scan_wallets WHERE client_id_hash = ?`,
  ).bind(clientIdHash).first();
  const legacy = await env.DB.prepare(
    "SELECT balance FROM credit_wallets WHERE client_id_hash = ?",
  ).bind(clientIdHash).first();
  return accessPayload({
    starterUsed: Number(wallet?.starter_used || 0),
    rewardedScans: Number(wallet?.rewarded_balance || 0),
    legacyScans: Math.max(0, Number(legacy?.balance || 0)),
    scanAccessEnforced: enforced,
    env,
  });
}

export function accessPayload({
  starterUsed = 0,
  rewardedScans = 0,
  legacyScans = 0,
  scanAccessEnforced = false,
  env = {},
} = {}) {
  const starterScansRemaining = Math.max(
    0,
    lifetimeStarterScans - Math.max(0, Number(starterUsed || 0)),
  );
  const remainingScans =
    starterScansRemaining + rewardedScans + legacyScans;
  return {
    starterScansRemaining,
    rewardedScans,
    legacyScans,
    remainingScans,
    rewardBalanceCap,
    scanAccessEnforced,
    adsEnabled: scanAccessEnforced && legacyScans === 0,
    analysisModel: env.OPENAI_MODEL || "gpt-5-nano",
    adPolicy: {
      interstitialEvery: readPositiveInteger(env.INTERSTITIAL_EVERY, 2),
      interstitialCooldownSeconds: readPositiveInteger(
        env.INTERSTITIAL_COOLDOWN_SECONDS,
        180,
      ),
      appOpenCooldownSeconds: readPositiveInteger(
        env.APP_OPEN_COOLDOWN_SECONDS,
        14400,
      ),
    },
  };
}

async function ensureWallet(db, clientIdHash, now) {
  await db.prepare(
    `INSERT OR IGNORE INTO ad_scan_wallets (
       client_id_hash, starter_used, rewarded_balance, updated_at_ms
     ) VALUES (?, 0, 0, ?)`,
  ).bind(clientIdHash, now).run();
}

async function cleanupExpiredRequests(db, now) {
  await db.prepare(
    `DELETE FROM scan_requests
      WHERE expires_at_ms < ? OR
            (state IN ('pending', 'refunded') AND updated_at_ms < ?)`,
  ).bind(now, now - resultTtlMs).run();
}

async function handleAdMobReward(request, env) {
  const db = requireDatabase(env);
  const requestUrl = request.url;
  const query = requestUrl.includes("?") ? requestUrl.split("?")[1] : "";
  const signatureMarker = "&signature=";
  const signatureIndex = query.indexOf(signatureMarker);
  if (signatureIndex < 1) {
    throw new MonetizationError(400, "invalid_reward", "Missing signature.");
  }
  const content = query.slice(0, signatureIndex);
  const signedParameters = new URLSearchParams(
    query.slice(signatureIndex + 1),
  );
  const signature = signedParameters.get("signature");
  const keyId = signedParameters.get("key_id");
  if (!signature || !keyId) {
    throw new MonetizationError(400, "invalid_reward", "Invalid signature.");
  }
  await verifyAdMobSignature(content, signature, keyId);

  const parameters = new URLSearchParams(content);
  const clientId = parameters.get("user_id") || "";
  const transactionId = parameters.get("transaction_id") || "";
  const timestamp = Number(parameters.get("timestamp"));
  const rewardAmount = Number(parameters.get("reward_amount"));
  const rewardItem = parameters.get("reward_item") || "";
  const receivedAdUnit = parameters.get("ad_unit") || "";
  const expectedAdUnit = (env.ADMOB_REWARDED_AD_UNIT_ID || "").split("/").pop();
  if (!expectedAdUnit) {
    throw new MonetizationError(
      503,
      "reward_not_configured",
      "Reward verification is not configured.",
    );
  }
  if (
    !clientIdPattern.test(clientId) ||
    !/^[A-Fa-f0-9]{16,128}$/.test(transactionId) ||
    !Number.isFinite(timestamp) ||
    Math.abs(Date.now() - timestamp) > 24 * 60 * 60 * 1000 ||
    rewardAmount !== 1 ||
    rewardItem !== "scan" ||
    receivedAdUnit !== expectedAdUnit
  ) {
    throw new MonetizationError(
      400,
      "invalid_reward",
      "Reward callback data is invalid.",
    );
  }

  const clientIdHash = await hashIdentifier(clientId);
  const now = Date.now();
  await ensureWallet(db, clientIdHash, now);
  const inserted = await db.prepare(
    `INSERT OR IGNORE INTO ad_rewards (
       transaction_id, client_id_hash, period_key, reward_amount, created_at_ms
     ) VALUES (?, ?, 'lifetime', 1, ?)`,
  ).bind(transactionId, clientIdHash, now).run();
  if (changedRows(inserted) === 1) {
    await safeMetric(env, "reward_granted", "rewarded", 1, 0);
  }
}

async function verifyAdMobSignature(content, signature, keyId) {
  const keys = await getAdMobKeys();
  const matching = keys.find((key) => String(key.keyId) === String(keyId));
  if (!matching) {
    cachedAdMobKeys = null;
    throw new MonetizationError(
      400,
      "invalid_reward_signature",
      "The reward signature key is unknown.",
    );
  }
  const key = await crypto.subtle.importKey(
    "spki",
    base64ToBytes(matching.base64),
    {name: "ECDSA", namedCurve: "P-256"},
    false,
    ["verify"],
  );
  const valid = await crypto.subtle.verify(
    {name: "ECDSA", hash: "SHA-256"},
    key,
    derSignatureToRaw(base64UrlToBytes(signature), 32),
    new TextEncoder().encode(content),
  );
  if (!valid) {
    throw new MonetizationError(
      400,
      "invalid_reward_signature",
      "The reward signature is invalid.",
    );
  }
}

async function getAdMobKeys() {
  if (cachedAdMobKeys?.expiresAt > Date.now()) return cachedAdMobKeys.keys;
  const response = await fetch(
    "https://www.gstatic.com/admob/reward/verifier-keys.json",
  );
  const payload = await response.json().catch(() => ({}));
  if (!response.ok || !Array.isArray(payload.keys)) {
    throw new MonetizationError(
      502,
      "reward_verification_unavailable",
      "Reward verification is temporarily unavailable.",
    );
  }
  cachedAdMobKeys = {
    keys: payload.keys,
    expiresAt: Date.now() + 23 * 60 * 60 * 1000,
  };
  return payload.keys;
}

async function recordAdRevenue(request, env, clientIdHash) {
  if (!env.DB) return;
  const data = await readSmallJson(request);
  const placement = String(data.placement || "");
  const currencyCode = String(data.currencyCode || "").toUpperCase();
  const precision = String(data.precision || "unknown");
  const valueMicros = Number(data.valueMicros);
  if (
    ![
      "scale_first_screen",
      "ai_home",
      "history_after_second",
      "rewarded",
      "interstitial",
      "app_open",
    ].includes(placement) ||
    !/^[A-Z]{3}$/.test(currencyCode) ||
    !["unknown", "estimated", "publisherProvided", "precise"].includes(
      precision,
    ) ||
    !Number.isFinite(valueMicros) ||
    valueMicros < 0 ||
    valueMicros > 100000000
  ) {
    throw new MonetizationError(
      400,
      "invalid_metric",
      "Ad revenue data is invalid.",
    );
  }
  // This client-sourced signal is diagnostic only and never grants access.
  const dimension = `${placement}:${currencyCode}:${precision}`;
  await recordDailyMetric(env, "ad_revenue", dimension, 1, valueMicros);
  await recordDailyMetric(env, "ad_reporter", clientIdHash.slice(0, 12), 1, 0);
}

async function recordDailyMetric(env, metric, dimension, count, valueMicros) {
  if (!env.DB) return;
  await env.DB.prepare(
    `INSERT INTO daily_metrics (
       day, metric, dimension, event_count, value_micros, updated_at_ms
     ) VALUES (?, ?, ?, ?, ?, ?)
     ON CONFLICT(day, metric, dimension) DO UPDATE SET
       event_count = daily_metrics.event_count + excluded.event_count,
       value_micros = daily_metrics.value_micros + excluded.value_micros,
       updated_at_ms = excluded.updated_at_ms`,
  ).bind(
    currentDay(),
    metric,
    String(dimension).slice(0, 100),
    Math.max(0, Math.round(count)),
    Math.max(0, Math.round(valueMicros)),
    Date.now(),
  ).run();
}

async function safeMetric(env, metric, dimension, count, valueMicros) {
  try {
    await recordDailyMetric(env, metric, dimension, count, valueMicros);
  } catch (error) {
    console.error("Daily metric write failed", {
      metric,
      name: error instanceof Error ? error.name : "UnknownError",
    });
  }
}

async function readSmallJson(request) {
  const contentType = request.headers.get("content-type") || "";
  if (!contentType.toLowerCase().startsWith("application/json")) {
    throw new MonetizationError(
      415,
      "unsupported_media_type",
      "Content-Type must be application/json.",
    );
  }
  const text = await request.text();
  if (text.length > 8192) {
    throw new MonetizationError(413, "request_too_large", "Request is too large.");
  }
  try {
    const data = JSON.parse(text);
    if (!data || typeof data !== "object" || Array.isArray(data)) throw new Error();
    return data;
  } catch {
    throw new MonetizationError(400, "invalid_json", "Request JSON is invalid.");
  }
}

function derSignatureToRaw(der, componentSize) {
  let offset = 0;
  if (der[offset++] !== 0x30) throw new Error("Invalid ECDSA signature.");
  const sequenceLength = readDerLength(der, offset);
  offset = sequenceLength.offset;
  if (der[offset++] !== 0x02) throw new Error("Invalid ECDSA signature.");
  const rLength = readDerLength(der, offset);
  offset = rLength.offset;
  const r = der.slice(offset, offset + rLength.length);
  offset += rLength.length;
  if (der[offset++] !== 0x02) throw new Error("Invalid ECDSA signature.");
  const sLength = readDerLength(der, offset);
  offset = sLength.offset;
  const s = der.slice(offset, offset + sLength.length);
  const raw = new Uint8Array(componentSize * 2);
  copyDerInteger(r, raw, 0, componentSize);
  copyDerInteger(s, raw, componentSize, componentSize);
  return raw;
}

function readDerLength(bytes, offset) {
  const first = bytes[offset++];
  if ((first & 0x80) === 0) return {length: first, offset};
  const count = first & 0x7f;
  let length = 0;
  for (let index = 0; index < count; index++) {
    length = (length << 8) | bytes[offset++];
  }
  return {length, offset};
}

function copyDerInteger(integer, output, outputOffset, size) {
  const withoutPadding = integer[0] === 0 ? integer.slice(1) : integer;
  if (withoutPadding.length > size) throw new Error("Invalid ECDSA integer.");
  output.set(withoutPadding, outputOffset + size - withoutPadding.length);
}

function readPositiveInteger(value, fallback) {
  const number = Number(value);
  return Number.isInteger(number) && number > 0 ? number : fallback;
}

function readPositiveNumber(value, fallback) {
  const number = Number(value);
  return Number.isFinite(number) && number >= 0 ? number : fallback;
}

function currentDay(now = new Date()) {
  return now.toISOString().slice(0, 10);
}

function changedRows(result) {
  return Number(result?.meta?.changes ?? result?.changes ?? 0);
}

function requireDatabase(env) {
  if (!env.DB) {
    throw new MonetizationError(
      503,
      "access_not_configured",
      "Scan access storage is not configured.",
    );
  }
  return env.DB;
}

async function hashIdentifier(value) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest), (byte) =>
    byte.toString(16).padStart(2, "0"),
  ).join("");
}

function base64ToBytes(value) {
  const binary = atob(value);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function base64UrlToBytes(value) {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  return base64ToBytes(normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "="));
}

function jsonResponse(payload, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "Cache-Control": "no-store",
      "Content-Type": "application/json; charset=utf-8",
      "X-Content-Type-Options": "nosniff",
    },
  });
}

export class MonetizationError extends Error {
  constructor(status, code, message) {
    super(message);
    this.name = "MonetizationError";
    this.status = status;
    this.code = code;
  }
}

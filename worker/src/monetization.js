const clientIdPattern = /^[A-Za-z0-9_-]{20,80}$/;
const purchaseTokenPattern = /^[A-Za-z0-9._~+/=-]{20,4096}$/;
const freeScanLimit = 3;
const subscriptionStates = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
]);

const plans = new Map([
  ["masslens_50_monthly", {name: "Basic", scanLimit: 50}],
  ["masslens_100_monthly", {name: "Plus", scanLimit: 100}],
  ["masslens_max_monthly", {name: "Max", scanLimit: 300}],
]);

let cachedGoogleAccessToken;
let cachedAdMobKeys;

export async function handleMonetizationRoute(request, env, url) {
  if (request.method === "GET" && url.pathname === "/access") {
    const clientIdHash = await readHashedClientId(request);
    return jsonResponse(await getAccess(env, clientIdHash));
  }

  if (request.method === "POST" && url.pathname === "/billing/verify") {
    const clientIdHash = await readHashedClientId(request);
    const data = await readSmallJson(request);
    const productId = readProductId(data.productId);
    const purchaseToken = readPurchaseToken(data.purchaseToken);
    await verifyAndStoreSubscription(env, {
      clientIdHash,
      productId,
      purchaseToken,
    });
    return jsonResponse(await getAccess(env, clientIdHash));
  }

  if (request.method === "GET" && url.pathname === "/admob/reward") {
    await handleAdMobReward(request, env);
    return new Response("OK", {
      status: 200,
      headers: {"Cache-Control": "no-store", "Content-Type": "text/plain"},
    });
  }

  return null;
}

export function isBillingEnforced(env) {
  return env.BILLING_ENFORCED === "true";
}

export async function reserveScan(env, clientIdHash) {
  if (!isBillingEnforced(env)) return {kind: "disabled"};
  const db = requireDatabase(env);
  const now = Date.now();

  const paid = await db.prepare(
    `UPDATE entitlements
       SET scans_used = scans_used + 1, updated_at_ms = ?
     WHERE client_id_hash = ?
       AND state IN ('active', 'grace')
       AND period_end_ms > ?
       AND scans_used < scan_limit`,
  ).bind(now, clientIdHash, now).run();
  if (changedRows(paid) === 1) return {kind: "paid"};

  const periodKey = currentPeriodKey();
  await resetOrCreateFreeUsage(db, clientIdHash, periodKey, now);
  const before = await getFreeUsage(db, clientIdHash);
  const free = await db.prepare(
    `UPDATE free_usage
       SET included_used = included_used +
             CASE WHEN included_used < ? THEN 1 ELSE 0 END,
           bonus_credits = bonus_credits -
             CASE WHEN included_used >= ? AND bonus_credits > 0 THEN 1 ELSE 0 END,
           updated_at_ms = ?
     WHERE client_id_hash = ?
       AND period_key = ?
       AND (included_used < ? OR bonus_credits > 0)`,
  ).bind(
    freeScanLimit,
    freeScanLimit,
    now,
    clientIdHash,
    periodKey,
    freeScanLimit,
  ).run();
  if (changedRows(free) !== 1) {
    throw new MonetizationError(
      402,
      "scan_limit_reached",
      "No scans remain. Watch a rewarded ad or choose a plan.",
    );
  }
  return {
    kind: before.included_used < freeScanLimit ? "free" : "bonus",
    periodKey,
  };
}

export async function refundScan(env, clientIdHash, reservation) {
  if (!reservation || reservation.kind === "disabled" || !env.DB) return;
  const now = Date.now();
  if (reservation.kind === "paid") {
    await env.DB.prepare(
      `UPDATE entitlements
          SET scans_used = MAX(0, scans_used - 1), updated_at_ms = ?
        WHERE client_id_hash = ?`,
    ).bind(now, clientIdHash).run();
    return;
  }
  if (reservation.kind === "free") {
    await env.DB.prepare(
      `UPDATE free_usage
          SET included_used = MAX(0, included_used - 1), updated_at_ms = ?
        WHERE client_id_hash = ? AND period_key = ?`,
    ).bind(now, clientIdHash, reservation.periodKey).run();
    return;
  }
  if (reservation.kind === "bonus") {
    await env.DB.prepare(
      `UPDATE free_usage
          SET bonus_credits = bonus_credits + 1, updated_at_ms = ?
        WHERE client_id_hash = ? AND period_key = ?`,
    ).bind(now, clientIdHash, reservation.periodKey).run();
  }
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
  const billingEnforced = isBillingEnforced(env);
  if (!env.DB) {
    if (billingEnforced) {
      throw new MonetizationError(
        503,
        "billing_not_configured",
        "Billing storage is not configured.",
      );
    }
    return accessPayload({billingEnforced});
  }

  const now = Date.now();
  if (billingEnforced) {
    await refreshStoredEntitlementIfStale(env, clientIdHash, now);
  }
  const entitlement = await env.DB.prepare(
    `SELECT product_id, state, scan_limit, scans_used, period_end_ms
       FROM entitlements
      WHERE client_id_hash = ?
        AND state IN ('active', 'grace')
        AND period_end_ms > ?`,
  ).bind(clientIdHash, now).first();

  if (entitlement && plans.has(entitlement.product_id)) {
    const plan = plans.get(entitlement.product_id);
    return accessPayload({
      planId: entitlement.product_id,
      planName: plan.name,
      scanLimit: Number(entitlement.scan_limit),
      scansUsed: Number(entitlement.scans_used),
      periodEndMs: Number(entitlement.period_end_ms),
      isPaid: true,
      billingEnforced,
    });
  }

  const periodKey = currentPeriodKey();
  await resetOrCreateFreeUsage(env.DB, clientIdHash, periodKey, now);
  const usage = await getFreeUsage(env.DB, clientIdHash);
  return accessPayload({
    scansUsed: Number(usage.included_used),
    bonusCredits: Number(usage.bonus_credits),
    billingEnforced,
  });
}

function accessPayload({
  planId = "free",
  planName = "Free",
  scanLimit = freeScanLimit,
  scansUsed = 0,
  bonusCredits = 0,
  periodEndMs,
  isPaid = false,
  billingEnforced = false,
} = {}) {
  return {
    planId,
    planName,
    scanLimit,
    scansUsed,
    bonusCredits,
    remainingScans: Math.max(0, scanLimit - scansUsed + bonusCredits),
    periodEndsAt: periodEndMs
      ? new Date(periodEndMs).toISOString()
      : endOfCurrentMonth().toISOString(),
    isPaid,
    adsEnabled: billingEnforced && !isPaid,
    billingEnforced,
  };
}

async function refreshStoredEntitlementIfStale(env, clientIdHash, now) {
  const stored = await env.DB.prepare(
    `SELECT product_id, purchase_token, state, verified_at_ms
       FROM entitlements WHERE client_id_hash = ?`,
  ).bind(clientIdHash).first();
  if (
    !stored ||
    stored.state === "inactive" ||
    Number(stored.verified_at_ms) > now - 6 * 60 * 60 * 1000
  ) {
    return;
  }
  try {
    await verifyAndStoreSubscription(env, {
      clientIdHash,
      productId: stored.product_id,
      purchaseToken: stored.purchase_token,
    });
  } catch (error) {
    const isDefinitivelyInactive =
      error instanceof MonetizationError &&
      [
        "subscription_inactive",
        "subscription_expired",
        "product_mismatch",
      ].includes(error.code);
    if (isDefinitivelyInactive) {
      await env.DB.prepare(
        `UPDATE entitlements
            SET state = 'inactive', verified_at_ms = ?, updated_at_ms = ?
          WHERE client_id_hash = ?`,
      ).bind(now, now, clientIdHash).run();
      return;
    }
    // A temporary Google outage should not revoke an already-paid period.
    console.error("Deferred subscription refresh", {
      code: error instanceof MonetizationError ? error.code : "unknown",
    });
  }
}

async function verifyAndStoreSubscription(
  env,
  {clientIdHash, productId, purchaseToken},
) {
  const db = requireDatabase(env);
  const existingOwner = await db.prepare(
    "SELECT client_id_hash FROM entitlements WHERE purchase_token = ?",
  ).bind(purchaseToken).first();
  if (existingOwner && existingOwner.client_id_hash !== clientIdHash) {
    throw new MonetizationError(
      409,
      "purchase_already_linked",
      "This Google Play purchase is already linked to another installation.",
    );
  }

  const purchase = await getGoogleSubscription(env, purchaseToken);
  if (!subscriptionStates.has(purchase.subscriptionState)) {
    throw new MonetizationError(
      402,
      "subscription_inactive",
      "Google Play reports that this subscription is not active.",
    );
  }
  const matchingItems = (purchase.lineItems || []).filter(
    (item) => item.productId === productId,
  );
  if (matchingItems.length === 0) {
    throw new MonetizationError(
      400,
      "product_mismatch",
      "The purchase does not match the selected MassLens plan.",
    );
  }
  const periodEndMs = Math.max(
    ...matchingItems.map((item) => Date.parse(item.expiryTime || "")),
  );
  if (!Number.isFinite(periodEndMs) || periodEndMs <= Date.now()) {
    throw new MonetizationError(
      402,
      "subscription_expired",
      "This subscription period has expired.",
    );
  }

  const now = Date.now();
  const plan = plans.get(productId);
  const state = purchase.subscriptionState ===
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD" ? "grace" : "active";
  await db.prepare(
    `INSERT INTO entitlements (
       client_id_hash, product_id, purchase_token, state, scan_limit,
       scans_used, period_end_ms, verified_at_ms, updated_at_ms
     ) VALUES (?, ?, ?, ?, ?, 0, ?, ?, ?)
     ON CONFLICT(client_id_hash) DO UPDATE SET
       product_id = excluded.product_id,
       purchase_token = excluded.purchase_token,
       state = excluded.state,
       scan_limit = excluded.scan_limit,
       scans_used = CASE
         WHEN excluded.period_end_ms > entitlements.period_end_ms
         THEN 0 ELSE entitlements.scans_used END,
       period_end_ms = excluded.period_end_ms,
       verified_at_ms = excluded.verified_at_ms,
       updated_at_ms = excluded.updated_at_ms`,
  ).bind(
    clientIdHash,
    productId,
    purchaseToken,
    state,
    plan.scanLimit,
    periodEndMs,
    now,
    now,
  ).run();

  if (purchase.acknowledgementState === "ACKNOWLEDGEMENT_STATE_PENDING") {
    await acknowledgeGoogleSubscription(env, productId, purchaseToken);
  }
}

async function getGoogleSubscription(env, purchaseToken) {
  const packageName = env.GOOGLE_PLAY_PACKAGE_NAME || "com.lilai.aivirtual";
  const token = await getGoogleAccessToken(env);
  const response = await fetch(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/` +
      `applications/${encodeURIComponent(packageName)}/purchases/` +
      `subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`,
    {headers: {Authorization: `Bearer ${token}`}},
  );
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    console.error("Google Play verification failed", {status: response.status});
    throw new MonetizationError(
      response.status === 404 ? 400 : 502,
      "play_verification_failed",
      "Google Play could not verify this purchase.",
    );
  }
  return payload;
}

async function acknowledgeGoogleSubscription(env, productId, purchaseToken) {
  const packageName = env.GOOGLE_PLAY_PACKAGE_NAME || "com.lilai.aivirtual";
  const token = await getGoogleAccessToken(env);
  const response = await fetch(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/` +
      `applications/${encodeURIComponent(packageName)}/purchases/` +
      `subscriptions/${encodeURIComponent(productId)}/tokens/` +
      `${encodeURIComponent(purchaseToken)}:acknowledge`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: "{}",
    },
  );
  if (!response.ok) {
    console.error("Google Play acknowledgement failed", {
      status: response.status,
    });
    throw new MonetizationError(
      502,
      "play_acknowledgement_failed",
      "The purchase was verified but could not be acknowledged.",
    );
  }
}

async function getGoogleAccessToken(env) {
  if (cachedGoogleAccessToken?.expiresAt > Date.now() + 60_000) {
    return cachedGoogleAccessToken.value;
  }
  let credentials;
  try {
    credentials = JSON.parse(env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON || "");
  } catch {
    throw new MonetizationError(
      503,
      "play_not_configured",
      "Google Play verification is not configured.",
    );
  }
  if (!credentials.client_email || !credentials.private_key) {
    throw new MonetizationError(
      503,
      "play_not_configured",
      "Google Play verification is not configured.",
    );
  }

  const nowSeconds = Math.floor(Date.now() / 1000);
  const assertion = await signServiceAccountJwt(credentials, nowSeconds);
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok || typeof payload.access_token !== "string") {
    console.error("Google OAuth failed", {status: response.status});
    throw new MonetizationError(
      502,
      "play_authentication_failed",
      "Could not authenticate with Google Play.",
    );
  }
  cachedGoogleAccessToken = {
    value: payload.access_token,
    expiresAt: Date.now() + Number(payload.expires_in || 3600) * 1000,
  };
  return cachedGoogleAccessToken.value;
}

async function signServiceAccountJwt(credentials, nowSeconds) {
  const header = base64UrlJson({alg: "RS256", typ: "JWT"});
  const payload = base64UrlJson({
    iss: credentials.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: credentials.token_uri || "https://oauth2.googleapis.com/token",
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  });
  const input = `${header}.${payload}`;
  const keyBytes = pemToBytes(credentials.private_key);
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    {name: "RSASSA-PKCS1-v1_5", hash: "SHA-256"},
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(input),
  );
  return `${input}.${base64UrlBytes(new Uint8Array(signature))}`;
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

  const contentParameters = new URLSearchParams(content);
  const clientId = contentParameters.get("user_id") || "";
  const transactionId = contentParameters.get("transaction_id") || "";
  const timestamp = Number(contentParameters.get("timestamp"));
  const rewardAmount = Number(contentParameters.get("reward_amount"));
  const receivedAdUnit = contentParameters.get("ad_unit") || "";
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
    rewardAmount < 1 ||
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
  // The migration's AFTER INSERT trigger adds exactly one bonus scan. Duplicate
  // transaction IDs are ignored, making callback retries safe.
  await db.prepare(
    `INSERT OR IGNORE INTO ad_rewards (
       transaction_id, client_id_hash, period_key, reward_amount, created_at_ms
     ) VALUES (?, ?, ?, 1, ?)`,
  ).bind(transactionId, clientIdHash, currentPeriodKey(), now).run();
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

function readProductId(value) {
  if (typeof value !== "string" || !plans.has(value)) {
    throw new MonetizationError(400, "invalid_product", "Unknown plan.");
  }
  return value;
}

function readPurchaseToken(value) {
  if (typeof value !== "string" || !purchaseTokenPattern.test(value)) {
    throw new MonetizationError(
      400,
      "invalid_purchase_token",
      "Google Play purchase token is invalid.",
    );
  }
  return value;
}

async function resetOrCreateFreeUsage(db, clientIdHash, periodKey, now) {
  await db.prepare(
    `INSERT INTO free_usage (
       client_id_hash, period_key, included_used, bonus_credits, updated_at_ms
     ) VALUES (?, ?, 0, 0, ?)
     ON CONFLICT(client_id_hash) DO UPDATE SET
       period_key = excluded.period_key,
       included_used = CASE
         WHEN free_usage.period_key = excluded.period_key
         THEN free_usage.included_used ELSE 0 END,
       bonus_credits = CASE
         WHEN free_usage.period_key = excluded.period_key
         THEN free_usage.bonus_credits ELSE 0 END,
       updated_at_ms = excluded.updated_at_ms`,
  ).bind(clientIdHash, periodKey, now).run();
}

async function getFreeUsage(db, clientIdHash) {
  return db.prepare(
    `SELECT included_used, bonus_credits
       FROM free_usage WHERE client_id_hash = ?`,
  ).bind(clientIdHash).first();
}

function currentPeriodKey(now = new Date()) {
  return `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, "0")}`;
}

function endOfCurrentMonth(now = new Date()) {
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1));
}

function changedRows(result) {
  return Number(result?.meta?.changes ?? result?.changes ?? 0);
}

function requireDatabase(env) {
  if (!env.DB) {
    throw new MonetizationError(
      503,
      "billing_not_configured",
      "Billing storage is not configured.",
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

function pemToBytes(pem) {
  return base64ToBytes(
    pem.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, ""),
  );
}

function base64UrlJson(value) {
  return base64UrlBytes(new TextEncoder().encode(JSON.stringify(value)));
}

function base64UrlBytes(bytes) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
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

const clientIdPattern = /^[A-Za-z0-9_-]{20,80}$/;
const purchaseTokenPattern = /^[A-Za-z0-9._~+/=-]{20,4096}$/;
const freeScanLimit = 3;

export const scanPackCredits = Object.freeze({
  masslens_100_scans: 100,
  masslens_500_scans: 500,
});
const scanPacks = new Map(
  Object.entries(scanPackCredits).map(([productId, credits]) => [
    productId,
    {credits},
  ]),
);

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
    await verifyAndGrantConsumable(env, {
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

  const periodKey = currentPeriodKey();
  await resetOrCreateFreeUsage(db, clientIdHash, periodKey, now);
  const included = await db.prepare(
    `UPDATE free_usage
       SET included_used = included_used + 1, updated_at_ms = ?
     WHERE client_id_hash = ?
       AND period_key = ?
       AND included_used < ?`,
  ).bind(now, clientIdHash, periodKey, freeScanLimit).run();
  if (changedRows(included) === 1) return {kind: "free", periodKey};

  const bonus = await db.prepare(
    `UPDATE free_usage
       SET bonus_credits = bonus_credits - 1, updated_at_ms = ?
     WHERE client_id_hash = ?
       AND period_key = ?
       AND bonus_credits > 0`,
  ).bind(now, clientIdHash, periodKey).run();
  if (changedRows(bonus) === 1) return {kind: "bonus", periodKey};

  const purchased = await db.prepare(
    `UPDATE credit_wallets
       SET balance = balance - 1, updated_at_ms = ?
     WHERE client_id_hash = ? AND balance > 0`,
  ).bind(now, clientIdHash).run();
  if (changedRows(purchased) === 1) return {kind: "purchased"};

  throw new MonetizationError(
    402,
    "scan_limit_reached",
    "No scans remain. Watch a rewarded ad or buy a scan pack.",
  );
}

export async function refundScan(env, clientIdHash, reservation) {
  if (!reservation || reservation.kind === "disabled" || !env.DB) return;
  const now = Date.now();
  if (reservation.kind === "purchased") {
    await env.DB.prepare(
      `UPDATE credit_wallets
          SET balance = balance + 1, updated_at_ms = ?
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
  const periodKey = currentPeriodKey();
  await resetOrCreateFreeUsage(env.DB, clientIdHash, periodKey, now);
  const usage = await getFreeUsage(env.DB, clientIdHash);
  const wallet = await env.DB.prepare(
    `SELECT balance FROM credit_wallets WHERE client_id_hash = ?`,
  ).bind(clientIdHash).first();
  return accessPayload({
    scansUsed: Number(usage.included_used),
    bonusCredits: Number(usage.bonus_credits),
    walletBalance: Number(wallet?.balance || 0),
    billingEnforced,
  });
}

function accessPayload({
  scansUsed = 0,
  bonusCredits = 0,
  walletBalance = 0,
  billingEnforced = false,
} = {}) {
  const purchasedCredits = Math.max(0, walletBalance);
  const creditDebt = Math.max(0, -walletBalance);
  const includedRemaining = Math.max(0, freeScanLimit - scansUsed);
  const hasPaidCredits = purchasedCredits > 0;
  return {
    planId: hasPaidCredits ? "credits" : "free",
    planName: hasPaidCredits ? "Scan credits" : "Free",
    scanLimit: freeScanLimit,
    scansUsed,
    bonusCredits,
    purchasedCredits,
    creditDebt,
    remainingScans: includedRemaining + bonusCredits + purchasedCredits,
    periodEndsAt: endOfCurrentMonth().toISOString(),
    isPaid: hasPaidCredits,
    adsEnabled: billingEnforced && !hasPaidCredits,
    billingEnforced,
  };
}

async function verifyAndGrantConsumable(
  env,
  {clientIdHash, productId, purchaseToken},
) {
  const db = requireDatabase(env);
  let existing = await db.prepare(
    `SELECT client_id_hash, product_id, state
       FROM consumable_purchases WHERE purchase_token = ?`,
  ).bind(purchaseToken).first();
  validateExistingPurchaseOwner(existing, {clientIdHash, productId});
  if (existing?.state === "consumed") return;
  if (existing?.state === "voided") {
    throw new MonetizationError(
      402,
      "purchase_voided",
      "Google Play has voided this purchase.",
    );
  }

  const purchase = await getGoogleProductPurchase(env, purchaseToken);
  let verified;
  try {
    verified = validateGoogleProductPurchase(purchase, productId);
  } catch (error) {
    if (
      existing &&
      error instanceof MonetizationError &&
      error.code === "purchase_canceled"
    ) {
      const now = Date.now();
      await db.prepare(
        `UPDATE consumable_purchases
            SET state = 'voided', voided_at_ms = ?, updated_at_ms = ?
          WHERE purchase_token = ? AND state <> 'voided'`,
      ).bind(now, now, purchaseToken).run();
    }
    throw error;
  }

  const externalAccountId = verified.externalAccountId;
  if (
    !externalAccountId ||
    await hashIdentifier(externalAccountId) !== clientIdHash
  ) {
    throw new MonetizationError(
      409,
      "purchase_owner_mismatch",
      "This purchase does not belong to this MassLens installation.",
    );
  }
  if (!existing && verified.consumptionState === "CONSUMPTION_STATE_CONSUMED") {
    throw new MonetizationError(
      409,
      "purchase_already_consumed",
      "This purchase was already consumed before MassLens could grant it.",
    );
  }

  const now = Date.now();
  if (!existing) {
    const pack = scanPacks.get(productId);
    await db.prepare(
      `INSERT OR IGNORE INTO consumable_purchases (
         purchase_token, client_id_hash, product_id, credits, order_id,
         purchase_time_ms, state, verified_at_ms, updated_at_ms
       ) VALUES (?, ?, ?, ?, ?, ?, 'granted', ?, ?)`,
    ).bind(
      purchaseToken,
      clientIdHash,
      productId,
      pack.credits,
      verified.orderId,
      verified.purchaseTimeMs,
      now,
      now,
    ).run();
    existing = await db.prepare(
      `SELECT client_id_hash, product_id, state
         FROM consumable_purchases WHERE purchase_token = ?`,
    ).bind(purchaseToken).first();
    validateExistingPurchaseOwner(existing, {clientIdHash, productId});
  }

  if (existing?.state === "consumed") return;
  if (verified.consumptionState !== "CONSUMPTION_STATE_CONSUMED") {
    await consumeGoogleProduct(env, productId, purchaseToken);
  }
  await db.prepare(
    `UPDATE consumable_purchases
        SET state = 'consumed', consumed_at_ms = ?, verified_at_ms = ?,
            updated_at_ms = ?
      WHERE purchase_token = ? AND state = 'granted'`,
  ).bind(
    now,
    now,
    now,
    purchaseToken,
  ).run();
}

function validateExistingPurchaseOwner(existing, {clientIdHash, productId}) {
  if (!existing) return;
  if (existing.client_id_hash !== clientIdHash) {
    throw new MonetizationError(
      409,
      "purchase_already_linked",
      "This Google Play purchase is already linked to another installation.",
    );
  }
  if (existing.product_id !== productId) {
    throw new MonetizationError(
      400,
      "product_mismatch",
      "The purchase does not match the selected MassLens scan pack.",
    );
  }
}

export function validateGoogleProductPurchase(purchase, productId) {
  const state = purchase?.purchaseStateContext?.purchaseState;
  if (state === "PENDING") {
    throw new MonetizationError(
      409,
      "purchase_pending",
      "Google Play reports that this purchase is still pending.",
    );
  }
  if (state !== "PURCHASED") {
    throw new MonetizationError(
      402,
      "purchase_canceled",
      "Google Play reports that this purchase is not active.",
    );
  }
  const items = Array.isArray(purchase.productLineItem)
    ? purchase.productLineItem
    : [];
  if (items.length !== 1 || items[0].productId !== productId) {
    throw new MonetizationError(
      400,
      "product_mismatch",
      "The purchase does not match the selected MassLens scan pack.",
    );
  }
  const details = items[0].productOfferDetails || {};
  const quantity = details.quantity ?? 1;
  if (!Number.isInteger(quantity) || quantity !== 1) {
    throw new MonetizationError(
      400,
      "unsupported_quantity",
      "MassLens scan packs must be purchased one at a time.",
    );
  }
  const consumptionState = details.consumptionState;
  if (![
    "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
    "CONSUMPTION_STATE_CONSUMED",
  ].includes(consumptionState)) {
    throw new MonetizationError(
      400,
      "invalid_consumption_state",
      "Google Play returned an invalid purchase state.",
    );
  }
  const purchaseTimeMs = Date.parse(purchase.purchaseCompletionTime || "");
  if (!Number.isFinite(purchaseTimeMs)) {
    throw new MonetizationError(
      400,
      "invalid_purchase_time",
      "Google Play did not return a valid purchase time.",
    );
  }
  return {
    consumptionState,
    externalAccountId: purchase.obfuscatedExternalAccountId || "",
    orderId: typeof purchase.orderId === "string" ? purchase.orderId : null,
    purchaseTimeMs,
  };
}

async function getGoogleProductPurchase(env, purchaseToken) {
  const packageName = env.GOOGLE_PLAY_PACKAGE_NAME || "com.lilai.aivirtual";
  const token = await getGoogleAccessToken(env);
  const response = await fetch(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/` +
      `applications/${encodeURIComponent(packageName)}/purchases/` +
      `productsv2/tokens/${encodeURIComponent(purchaseToken)}`,
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

async function consumeGoogleProduct(env, productId, purchaseToken) {
  const packageName = env.GOOGLE_PLAY_PACKAGE_NAME || "com.lilai.aivirtual";
  const token = await getGoogleAccessToken(env);
  const response = await fetch(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/` +
      `applications/${encodeURIComponent(packageName)}/purchases/` +
      `products/${encodeURIComponent(productId)}/tokens/` +
      `${encodeURIComponent(purchaseToken)}:consume`,
    {
      method: "POST",
      headers: {Authorization: `Bearer ${token}`},
    },
  );
  if (response.ok) return;

  // A retry can race a previous request that consumed successfully but died
  // before updating D1. Confirm that state before treating it as a failure.
  const refreshed = await getGoogleProductPurchase(env, purchaseToken);
  const item = (refreshed.productLineItem || []).find(
    (candidate) => candidate.productId === productId,
  );
  if (
    item?.productOfferDetails?.consumptionState ===
    "CONSUMPTION_STATE_CONSUMED"
  ) return;

  console.error("Google Play consumption failed", {status: response.status});
  throw new MonetizationError(
    502,
    "play_consumption_failed",
    "The purchase was verified but could not be finalized.",
  );
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
  if (typeof value !== "string" || !scanPacks.has(value)) {
    throw new MonetizationError(400, "invalid_product", "Unknown scan pack.");
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

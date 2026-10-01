import {MonetizationError} from "./monetization.js";

const purchaseTokenPattern = /^[A-Za-z0-9._-]{10,500}$/;
const defaultLifetimeProductId = "masslens_lifetime_unlimited";
const defaultLifetimeProductIds = [
  "masslens_lifetime_unlimited",
  "masslens_lifetime_off_30",
  "masslens_lifetime_off_40",
  "masslens_lifetime_off_50",
  "masslens_lifetime_off_60",
  "masslens_lifetime_off_70",
  "masslens_lifetime_off_80",
  "masslens_lifetime_off_90",
];
const defaultPackageName = "com.lilai.aivirtual";
const playScope = "https://www.googleapis.com/auth/androidpublisher";

let cachedAccessToken = null;
let cachedAccessTokenExpiresAt = 0;

export function readLifetimeProductId(env) {
  return String(env.PLAY_LIFETIME_PRODUCT_ID || defaultLifetimeProductId);
}

export function readLifetimeProductIds(env) {
  const ids = new Set(defaultLifetimeProductIds);
  ids.add(readLifetimeProductId(env));
  for (const id of String(env.PLAY_LIFETIME_PRODUCT_IDS || "").split(",")) {
    const trimmed = id.trim();
    if (trimmed) ids.add(trimmed);
  }
  return ids;
}

export function isLifetimeProductId(env, productId) {
  return Boolean(productId) && readLifetimeProductIds(env).has(productId);
}

export function readPackageName(env) {
  return String(env.PLAY_PACKAGE_NAME || defaultPackageName);
}

export async function handleBillingRoute(request, env, url, dependencies = {}) {
  if (request.method === "POST" && url.pathname === "/billing/verify") {
    return handleBillingVerify(request, env, dependencies);
  }

  if (request.method === "POST" && url.pathname === "/billing/rtdn") {
    return handleBillingRtdn(request, env, dependencies);
  }

  return null;
}

export async function hasActiveLifetimeEntitlement(db, clientIdHash) {
  try {
    const row = await db.prepare(
      `SELECT purchase_token
         FROM lifetime_entitlements
        WHERE client_id_hash = ? AND state = 'active'
        LIMIT 1`,
    ).bind(clientIdHash).first();
    return Boolean(row);
  } catch {
    // Missing table must never take down /access (ads stay on for free users).
    return false;
  }
}

export async function verifyLifetimePurchase(
  env,
  clientIdHash,
  {productId, purchaseToken, packageName: requestedPackageName},
  dependencies = {},
) {
  const db = requireDatabase(env);
  const packageName = requestedPackageName ?? readPackageName(env);
  const allowedPackages = new Set([
    readPackageName(env),
    ...String(env.PLAY_ADDITIONAL_PACKAGE_NAMES || "").split(",").map((name) => name.trim()).filter(Boolean),
  ]);
  if (!allowedPackages.has(packageName)) {
    throw new MonetizationError(400, "invalid_package_name", "This app package is not supported.");
  }
  if (!isLifetimeProductId(env, productId) ||
      (packageName !== readPackageName(env) && productId !== readLifetimeProductId(env))) {
    throw new MonetizationError(
      400,
      "invalid_product_id",
      "This purchase product is not supported.",
    );
  }
  if (!purchaseTokenPattern.test(purchaseToken)) {
    throw new MonetizationError(
      400,
      "invalid_purchase_token",
      "A valid purchase token is required.",
    );
  }

  const existing = await db.prepare(
    `SELECT purchase_token, client_id_hash, state
       FROM lifetime_entitlements
      WHERE purchase_token = ?`,
  ).bind(purchaseToken).first();

  if (existing?.state === "voided") {
    throw new MonetizationError(
      409,
      "purchase_voided",
      "This purchase was refunded and no longer grants access.",
    );
  }

  // Explicit package requests are reverified with Play, including restores.
  // This prevents an entitlement cached for another app from bypassing package checks.
  if (existing?.state === "active" && requestedPackageName == null) {
    if (existing.client_id_hash !== clientIdHash) {
      await db.prepare(
        `UPDATE lifetime_entitlements
            SET client_id_hash = ?, updated_at_ms = ?
          WHERE purchase_token = ? AND state = 'active'`,
      ).bind(clientIdHash, Date.now(), purchaseToken).run();
    }
    return buildVerifyResponse(true, "restored");
  }

  const verifyPurchase = dependencies.verifyPurchaseWithPlay
    ?? verifyPurchaseWithPlay;
  const purchase = await verifyPurchase(env, {
    packageName,
    productId,
    purchaseToken,
  });

  if (purchase.purchaseState !== 0) {
    throw new MonetizationError(
      409,
      "purchase_not_paid",
      "This purchase is not active.",
    );
  }

  const now = dependencyNow(dependencies);
  await db.prepare(
    `INSERT INTO lifetime_entitlements (
       purchase_token, client_id_hash, product_id, order_id,
       purchase_time_ms, state, verified_at_ms, voided_at_ms, updated_at_ms
     ) VALUES (?, ?, ?, ?, ?, 'active', ?, NULL, ?)
     ON CONFLICT(purchase_token) DO UPDATE SET
       client_id_hash = excluded.client_id_hash,
       product_id = excluded.product_id,
       order_id = excluded.order_id,
       purchase_time_ms = excluded.purchase_time_ms,
       state = 'active',
       verified_at_ms = excluded.verified_at_ms,
       voided_at_ms = NULL,
       updated_at_ms = excluded.updated_at_ms`,
  ).bind(
    purchaseToken,
    clientIdHash,
    productId,
    purchase.orderId || null,
    Number(purchase.purchaseTimeMillis || now),
    now,
    now,
  ).run();

  if (purchase.acknowledgementState === 0) {
    const acknowledge = dependencies.acknowledgePurchaseWithPlay
      ?? acknowledgePurchaseWithPlay;
    await acknowledge(env, {packageName, productId, purchaseToken});
  }

  return buildVerifyResponse(true, "verified");
}

async function handleBillingVerify(request, env, dependencies) {
  const db = requireDatabase(env);
  const clientIdHash = await readHashedClientId(request, dependencies);
  const data = await readSmallJson(request);
  const productId = String(data.productId || "");
  const purchaseToken = String(data.purchaseToken || "");
  const result = await verifyLifetimePurchase(
    env,
    clientIdHash,
    {productId, purchaseToken, packageName: data.packageName},
    dependencies,
  );
  return jsonResponse(result);
}

async function handleBillingRtdn(request, env, dependencies) {
  requireDatabase(env);
  const data = await readSmallJson(request);
  const message = data.message;
  if (!message || typeof message !== "object") {
    throw new MonetizationError(
      400,
      "invalid_rtdn",
      "The billing notification payload is invalid.",
    );
  }
  const encoded = String(message.data || "");
  if (!encoded) {
    return new Response(null, {status: 204});
  }
  let payload;
  try {
    payload = JSON.parse(atob(encoded));
  } catch {
    throw new MonetizationError(
      400,
      "invalid_rtdn",
      "The billing notification payload is invalid.",
    );
  }

  const notification = payload.oneTimeProductNotification;
  if (!notification) {
    return new Response(null, {status: 204});
  }

  const purchaseToken = String(notification.purchaseToken || "");
  const productId = String(notification.sku || "");
  const notificationType = Number(notification.notificationType);
  if (
    !purchaseTokenPattern.test(purchaseToken) ||
    !isLifetimeProductId(env, productId)
  ) {
    return new Response(null, {status: 204});
  }

  if (notificationType === 2) {
    await voidLifetimePurchase(env, purchaseToken, dependencyNow(dependencies));
  }

  return new Response(null, {status: 204});
}

export async function voidLifetimePurchase(env, purchaseToken, now = Date.now()) {
  if (!env.DB) return false;
  const result = await env.DB.prepare(
    `UPDATE lifetime_entitlements
        SET state = 'voided', voided_at_ms = ?, updated_at_ms = ?
      WHERE purchase_token = ? AND state = 'active'`,
  ).bind(now, now, purchaseToken).run();
  return Number(result?.meta?.changes ?? result?.changes ?? 0) === 1;
}

async function verifyPurchaseWithPlay(env, {packageName, productId, purchaseToken}) {
  const accessToken = await getPlayAccessToken(env);
  const url = new URL(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`,
  );
  const response = await fetch(url, {
    headers: {Authorization: `Bearer ${accessToken}`},
  });
  if (response.status === 404) {
    throw new MonetizationError(
      404,
      "purchase_not_found",
      "Google Play could not find this purchase.",
    );
  }
  if (!response.ok) {
    throw new MonetizationError(
      503,
      "purchase_verification_failed",
      "Purchase verification is temporarily unavailable.",
    );
  }
  return response.json();
}

async function acknowledgePurchaseWithPlay(
  env,
  {packageName, productId, purchaseToken},
) {
  const accessToken = await getPlayAccessToken(env);
  const url = new URL(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`,
  );
  const response = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Length": "0",
    },
  });
  if (!response.ok) {
    throw new MonetizationError(
      503,
      "purchase_ack_failed",
      "Purchase acknowledgement failed.",
    );
  }
}

async function getPlayAccessToken(env) {
  const now = Date.now();
  if (cachedAccessToken && cachedAccessTokenExpiresAt > now + 60_000) {
    return cachedAccessToken;
  }

  const serviceAccount = readServiceAccount(env);
  const assertion = await createServiceAccountJwt(serviceAccount);
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!response.ok) {
    throw new MonetizationError(
      503,
      "play_auth_failed",
      "Google Play authentication failed.",
    );
  }
  const payload = await response.json();
  cachedAccessToken = String(payload.access_token || "");
  cachedAccessTokenExpiresAt = now + Number(payload.expires_in || 3600) * 1000;
  if (!cachedAccessToken) {
    throw new MonetizationError(
      503,
      "play_auth_failed",
      "Google Play authentication failed.",
    );
  }
  return cachedAccessToken;
}

function readServiceAccount(env) {
  const raw = env.PLAY_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    throw new MonetizationError(
      503,
      "billing_not_configured",
      "Google Play billing is not configured.",
    );
  }
  try {
    const parsed = JSON.parse(raw);
    if (
      !parsed ||
      typeof parsed.client_email !== "string" ||
      typeof parsed.private_key !== "string"
    ) {
      throw new Error("invalid service account");
    }
    return parsed;
  } catch {
    throw new MonetizationError(
      503,
      "billing_not_configured",
      "Google Play billing is not configured.",
    );
  }
}

async function createServiceAccountJwt(serviceAccount) {
  const header = base64UrlEncode(JSON.stringify({alg: "RS256", typ: "JWT"}));
  const now = Math.floor(Date.now() / 1000);
  const claim = base64UrlEncode(
    JSON.stringify({
      iss: serviceAccount.client_email,
      scope: playScope,
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );
  const unsigned = `${header}.${claim}`;
  const key = await importPkcs8PrivateKey(serviceAccount.private_key);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  return `${unsigned}.${base64UrlEncode(signature)}`;
}

async function importPkcs8PrivateKey(pem) {
  const normalized = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const binary = Uint8Array.from(atob(normalized), (char) => char.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    binary,
    {name: "RSASSA-PKCS1-v1_5", hash: "SHA-256"},
    false,
    ["sign"],
  );
}

function base64UrlEncode(value) {
  const bytes = value instanceof ArrayBuffer
    ? new Uint8Array(value)
    : new TextEncoder().encode(String(value));
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function buildVerifyResponse(hasLifetime, status) {
  return {hasLifetime, status};
}

async function readHashedClientId(request, dependencies = {}) {
  const hashIdentifier = dependencies.hashIdentifier
    ?? (async (value) => {
      const digest = await crypto.subtle.digest(
        "SHA-256",
        new TextEncoder().encode(value),
      );
      return Array.from(new Uint8Array(digest), (byte) =>
        byte.toString(16).padStart(2, "0"),
      ).join("");
    });
  const clientIdPattern = /^[A-Za-z0-9_-]{20,80}$/;
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

function dependencyNow(dependencies = {}) {
  const now = dependencies.now ? Number(dependencies.now()) : Date.now();
  return Number.isFinite(now) ? now : Date.now();
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

export function resetPlayAuthCacheForTests() {
  cachedAccessToken = null;
  cachedAccessTokenExpiresAt = 0;
}

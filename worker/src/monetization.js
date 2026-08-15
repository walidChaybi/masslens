const clientIdPattern = /^[A-Za-z0-9_-]{20,80}$/;
const requestIdPattern = /^[A-Za-z0-9_-]{20,80}$/;
const rewardAttemptIdPattern = /^[A-Za-z0-9_-]{20,80}$/;
const lifetimeStarterScans = 3;
const rewardBalanceCap = 3;
const resultTtlMs = 24 * 60 * 60 * 1000;
const pendingTtlMs = 2 * 60 * 1000;
const rewardAttemptTtlMs = 24 * 60 * 60 * 1000;
const rewardCooldownMs = 2 * 60 * 1000;

export async function handleMonetizationRoute(
  request,
  env,
  url,
  dependencies = {},
) {
  if (request.method === "GET" && url.pathname === "/access") {
    const clientIdHash = await readHashedClientId(request);
    return jsonResponse(await getAccess(env, clientIdHash));
  }

  if (request.method === "POST" && url.pathname === "/reward-attempts") {
    return handleRewardAttemptPost(request, env, dependencies);
  }

  if (request.method === "GET" && url.pathname.startsWith("/reward-attempts/")) {
    return handleRewardAttemptGet(request, env, url, dependencies);
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

export async function completeScan(
  env,
  clientIdHash,
  reservation,
  estimate,
  scanMode = "object",
) {
  if (!reservation) return;
  const metricMode = scanMode === "food_plate" ? "food_plate" : "object";
  if (reservation.kind === "disabled") {
    await safeMetric(env, "scan_completed_mode", metricMode, 1, 0);
    return;
  }
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
  await Promise.all([
    safeMetric(env, "scan_completed", reservation.kind, 1, 0),
    safeMetric(env, "scan_completed_mode", metricMode, 1, 0),
  ]);
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
    // Billing was removed before launch. Migrated and support credits still
    // preserve scan access, but they must not silently disable the ads-only
    // experience or hide the rewarded path.
    adsEnabled: scanAccessEnforced,
    analysisModel: env.OPENAI_MODEL || "gpt-5-nano",
    adPolicy: {
      interstitialEvery: readPositiveInteger(env.INTERSTITIAL_EVERY, 2),
      historyInterstitialEvery: readPositiveInteger(
        env.HISTORY_INTERSTITIAL_EVERY,
        2,
      ),
      interstitialCooldownSeconds: readPositiveInteger(
        env.INTERSTITIAL_COOLDOWN_SECONDS,
        180,
      ),
      appOpenCooldownSeconds: readPositiveInteger(
        env.APP_OPEN_COOLDOWN_SECONDS,
        900,
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

async function readRewardWallet(db, clientIdHash) {
  return db.prepare(
    `SELECT starter_used, rewarded_balance
       FROM ad_scan_wallets WHERE client_id_hash = ?`,
  ).bind(clientIdHash).first();
}

async function cleanupExpiredRequests(db, now) {
  await db.prepare(
    `DELETE FROM scan_requests
      WHERE expires_at_ms < ? OR
            (state IN ('pending', 'refunded') AND updated_at_ms < ?)`,
  ).bind(now, now - resultTtlMs).run();
}

async function handleRewardAttemptPost(request, env, dependencies) {
  const db = requireDatabase(env);
  const clientIdHash = await readHashedClientId(request);
  const data = await readSmallJson(request);
  const attemptId = String(data.attemptId || "");
  const event = String(data.event || "started");
  if (!rewardAttemptIdPattern.test(attemptId)) {
    throw new MonetizationError(
      400,
      "invalid_reward_attempt_id",
      "A valid reward attempt identifier is required.",
    );
  }
  if (event !== "started" && event !== "client_earned") {
    throw new MonetizationError(
      400,
      "invalid_reward_attempt_event",
      "The reward attempt event is invalid.",
    );
  }

  const now = dependencyNow(dependencies);
  if (event === "started") {
    let attempt = await readRewardAttempt(db, attemptId);
    if (attempt) {
      if (attempt.client_id_hash !== clientIdHash) {
        throw new MonetizationError(
          409,
          "reward_attempt_conflict",
          "This reward attempt identifier is already in use.",
        );
      }
      attempt = await expireRewardAttemptIfNeeded(
        db,
        attempt,
        clientIdHash,
        now,
      );
      return jsonResponse(rewardAttemptPayload(attempt));
    }

    await ensureWallet(db, clientIdHash, now);
    const ensureCooldown = db.prepare(
      `INSERT OR IGNORE INTO reward_client_cooldowns (
         client_id_hash, active_attempt_id, last_started_at_ms,
         last_granted_at_ms, updated_at_ms
       ) VALUES (?, NULL, NULL, NULL, ?)`,
    ).bind(clientIdHash, now);
    const claimCooldown = db.prepare(
      `UPDATE reward_client_cooldowns
          SET active_attempt_id = ?, last_started_at_ms = ?, updated_at_ms = ?
        WHERE client_id_hash = ?
          AND (last_started_at_ms IS NULL OR last_started_at_ms <= ?)
          AND (last_granted_at_ms IS NULL OR last_granted_at_ms <= ?)
          AND EXISTS (
            SELECT 1 FROM ad_scan_wallets
             WHERE client_id_hash = ? AND rewarded_balance < ?
          )
          AND (
            active_attempt_id IS NULL OR NOT EXISTS (
              SELECT 1 FROM reward_attempts
               WHERE attempt_id = reward_client_cooldowns.active_attempt_id
                 AND state = 'pending' AND client_earned_at_ms IS NOT NULL
                 AND expires_at_ms >= ?
            )
          )`,
    ).bind(
      attemptId,
      now,
      now,
      clientIdHash,
      now - rewardCooldownMs,
      now - rewardCooldownMs,
      clientIdHash,
      rewardBalanceCap,
      now,
    );
    const insertAttempt = db.prepare(
      `INSERT OR IGNORE INTO reward_attempts (
         attempt_id, client_id_hash, state, created_at_ms, updated_at_ms,
         expires_at_ms
       )
       SELECT ?, ?, 'pending', ?, ?, ?
         FROM reward_client_cooldowns
        WHERE client_id_hash = ? AND active_attempt_id = ?
          AND last_started_at_ms = ?`,
    ).bind(
      attemptId,
      clientIdHash,
      now,
      now,
      now + rewardAttemptTtlMs,
      clientIdHash,
      attemptId,
      now,
    );
    const results = await runDatabaseBatch(
      db,
      [ensureCooldown, claimCooldown, insertAttempt],
    );
    attempt = await readRewardAttempt(db, attemptId);
    if (attempt?.client_id_hash !== clientIdHash && attempt) {
      throw new MonetizationError(
        409,
        "reward_attempt_conflict",
        "This reward attempt identifier is already in use.",
      );
    }
    if (!attempt) {
      const wallet = await readRewardWallet(db, clientIdHash);
      if (Number(wallet?.rewarded_balance || 0) >= rewardBalanceCap) {
        await safeMetric(env, "reward_rejected", "balance_cap", 1, 0);
        throw new MonetizationError(
          409,
          "reward_balance_cap_reached",
          "Use an earned scan before watching another ad.",
        );
      }
      await safeMetric(env, "reward_rejected", "cooldown", 1, 0);
      throw new MonetizationError(
        429,
        "reward_cooldown",
        "Please wait before watching another rewarded ad.",
      );
    }
    if (changedRows(results[2]) === 1) {
      await safeMetric(env, "reward_attempt_started", "client", 1, 0);
    }
    return jsonResponse(
      rewardAttemptPayload(attempt),
      changedRows(results[2]) === 1 ? 201 : 200,
    );
  }

  let attempt = await readRewardAttempt(db, attemptId);
  if (!attempt || attempt.client_id_hash !== clientIdHash) {
    throw new MonetizationError(
      404,
      "reward_attempt_not_found",
      "Reward attempt not found.",
    );
  }
  attempt = await expireRewardAttemptIfNeeded(
    db,
    attempt,
    clientIdHash,
    now,
  );
  if (attempt.state !== "pending") {
    return jsonResponse(rewardAttemptPayload(attempt));
  }

  await ensureWallet(db, clientIdHash, now);
  const ensureCooldown = db.prepare(
    `INSERT OR IGNORE INTO reward_client_cooldowns (
       client_id_hash, active_attempt_id, last_started_at_ms,
       last_granted_at_ms, updated_at_ms
     ) VALUES (?, ?, NULL, NULL, ?)`,
  ).bind(clientIdHash, attemptId, now);
  const claimUnleasedAttempt = db.prepare(
    `UPDATE reward_client_cooldowns
        SET active_attempt_id = ?, updated_at_ms = ?
      WHERE client_id_hash = ? AND active_attempt_id IS NULL
        AND (last_granted_at_ms IS NULL OR last_granted_at_ms <= ?)`,
  ).bind(
    attemptId,
    now,
    clientIdHash,
    now - rewardCooldownMs,
  );
  const recordClientEarned = db.prepare(
    `UPDATE reward_attempts
        SET client_earned_at_ms = COALESCE(client_earned_at_ms, ?),
            updated_at_ms = MAX(updated_at_ms, ?)
      WHERE attempt_id = ? AND client_id_hash = ? AND state = 'pending'
        AND expires_at_ms >= ?`,
  ).bind(now, now, attemptId, clientIdHash, now);
  const insertGrant = db.prepare(
    `INSERT OR IGNORE INTO client_reward_grants (
       attempt_id, client_id_hash, reward_amount, source, created_at_ms
     )
     SELECT ?, ?, 1, 'mobile_sdk', ?
      WHERE EXISTS (
        SELECT 1
          FROM reward_attempts AS attempt
          JOIN ad_scan_wallets AS wallet
            ON wallet.client_id_hash = attempt.client_id_hash
          JOIN reward_client_cooldowns AS cooldown
            ON cooldown.client_id_hash = attempt.client_id_hash
         WHERE attempt.attempt_id = ? AND attempt.client_id_hash = ?
           AND attempt.state = 'pending' AND attempt.client_earned_at_ms IS NOT NULL
           AND attempt.expires_at_ms >= ?
           AND wallet.rewarded_balance < ?
           AND cooldown.active_attempt_id = attempt.attempt_id
           AND (
             cooldown.last_granted_at_ms IS NULL OR
             cooldown.last_granted_at_ms <= ?
           )
      )`,
  ).bind(
    attemptId,
    clientIdHash,
    now,
    attemptId,
    clientIdHash,
    now,
    rewardBalanceCap,
    now - rewardCooldownMs,
  );
  const verifyAttempt = db.prepare(
    `UPDATE reward_attempts
        SET state = 'verified', rejection_code = NULL,
            verified_at_ms = COALESCE(verified_at_ms, ?), updated_at_ms = ?
      WHERE attempt_id = ? AND client_id_hash = ? AND state = 'pending'
        AND EXISTS (
          SELECT 1 FROM client_reward_grants WHERE attempt_id = ?
        )`,
  ).bind(now, now, attemptId, clientIdHash, attemptId);
  const finishCooldown = db.prepare(
    `UPDATE reward_client_cooldowns
        SET active_attempt_id = NULL, last_granted_at_ms = ?, updated_at_ms = ?
      WHERE client_id_hash = ? AND active_attempt_id = ?
        AND EXISTS (
          SELECT 1 FROM client_reward_grants
           WHERE attempt_id = ? AND created_at_ms = ?
        )`,
  ).bind(now, now, clientIdHash, attemptId, attemptId, now);
  const results = await runDatabaseBatch(db, [
    ensureCooldown,
    claimUnleasedAttempt,
    recordClientEarned,
    insertGrant,
    verifyAttempt,
    finishCooldown,
  ]);
  attempt = await readRewardAttempt(db, attemptId);
  if (attempt.state === "verified") {
    const granted = changedRows(results[3]) === 1;
    await safeMetric(
      env,
      granted ? "reward_granted" : "reward_duplicate",
      granted ? "client_earned" : "client_attempt",
      1,
      0,
    );
    return jsonResponse(rewardAttemptPayload(attempt));
  }

  const wallet = await readRewardWallet(db, clientIdHash);
  if (Number(wallet?.rewarded_balance || 0) >= rewardBalanceCap) {
    await safeMetric(env, "reward_rejected", "balance_cap", 1, 0);
    throw new MonetizationError(
      409,
      "reward_balance_cap_reached",
      "Use an earned scan before retrying this reward.",
    );
  }
  const cooldown = await db.prepare(
    `SELECT active_attempt_id, last_granted_at_ms
       FROM reward_client_cooldowns WHERE client_id_hash = ?`,
  ).bind(clientIdHash).first();
  if (Number(cooldown?.last_granted_at_ms || 0) > now - rewardCooldownMs) {
    await safeMetric(env, "reward_rejected", "cooldown", 1, 0);
    throw new MonetizationError(
      429,
      "reward_cooldown",
      "Please wait before retrying this reward.",
    );
  }
  if (cooldown?.active_attempt_id !== attemptId) {
    await rejectRewardAttempt(
      db,
      attemptId,
      clientIdHash,
      "attempt_superseded",
      now,
    );
    attempt = await readRewardAttempt(db, attemptId);
    await safeMetric(env, "reward_rejected", "attempt_superseded", 1, 0);
    return jsonResponse(rewardAttemptPayload(attempt));
  }
  throw new MonetizationError(
    503,
    "reward_persistence_failed",
    "Reward credit storage is temporarily unavailable.",
  );
}

async function handleRewardAttemptGet(request, env, url, dependencies) {
  const db = requireDatabase(env);
  const clientIdHash = await readHashedClientId(request);
  const attemptId = url.pathname.slice("/reward-attempts/".length);
  if (!rewardAttemptIdPattern.test(attemptId)) {
    throw new MonetizationError(
      400,
      "invalid_reward_attempt_id",
      "A valid reward attempt identifier is required.",
    );
  }
  let attempt = await readRewardAttempt(db, attemptId);
  if (!attempt || attempt.client_id_hash !== clientIdHash) {
    throw new MonetizationError(
      404,
      "reward_attempt_not_found",
      "Reward attempt not found.",
    );
  }
  attempt = await expireRewardAttemptIfNeeded(
    db,
    attempt,
    clientIdHash,
    dependencyNow(dependencies),
  );
  return jsonResponse(rewardAttemptPayload(attempt));
}

async function readRewardAttempt(db, attemptId) {
  return db.prepare(
    `SELECT attempt_id, client_id_hash, state, client_earned_at_ms,
            transaction_id, rejection_code, callback_count,
            last_callback_at_ms, verified_at_ms, created_at_ms,
            updated_at_ms, expires_at_ms
       FROM reward_attempts WHERE attempt_id = ?`,
  ).bind(attemptId).first();
}

async function expireRewardAttemptIfNeeded(db, attempt, clientIdHash, now) {
  if (
    attempt.state !== "pending" ||
    Number(attempt.expires_at_ms) >= now
  ) {
    return attempt;
  }
  await db.prepare(
    `UPDATE reward_attempts
        SET state = 'expired', rejection_code = 'attempt_expired',
            updated_at_ms = ?
      WHERE attempt_id = ? AND client_id_hash = ? AND state = 'pending'
        AND expires_at_ms < ?`,
  ).bind(now, attempt.attempt_id, clientIdHash, now).run();
  return readRewardAttempt(db, attempt.attempt_id);
}

function rewardAttemptPayload(attempt) {
  const payload = {
    attemptId: attempt.attempt_id,
    state: attempt.state,
    createdAtMs: Number(attempt.created_at_ms),
    updatedAtMs: Number(attempt.updated_at_ms),
    expiresAtMs: Number(attempt.expires_at_ms),
  };
  if (attempt.client_earned_at_ms != null) {
    payload.clientEarnedAtMs = Number(attempt.client_earned_at_ms);
  }
  if (attempt.verified_at_ms != null) {
    payload.verifiedAtMs = Number(attempt.verified_at_ms);
  }
  if (attempt.rejection_code) payload.rejectionCode = attempt.rejection_code;
  return payload;
}

async function rejectRewardAttempt(db, attemptId, clientIdHash, code, now) {
  await db.prepare(
    `UPDATE reward_attempts
        SET state = 'rejected', rejection_code = ?, updated_at_ms = ?
      WHERE attempt_id = ? AND client_id_hash = ? AND state = 'pending'`,
  ).bind(code, now, attemptId, clientIdHash).run();
}

async function runDatabaseBatch(db, statements) {
  if (typeof db.batch === "function") return db.batch(statements);
  const results = [];
  for (const statement of statements) results.push(await statement.run());
  return results;
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
      "onboarding_interstitial",
      "onboarding_intro",
      "onboarding_framing",
      "onboarding_light",
      "onboarding_ready",
      "drawer_ai_scan_interstitial",
      "drawer_digital_scale_interstitial",
      "drawer_history_interstitial",
      "history_detail_interstitial",
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

function readPositiveInteger(value, fallback) {
  const number = Number(value);
  return Number.isInteger(number) && number > 0 ? number : fallback;
}

function readPositiveNumber(value, fallback) {
  const number = Number(value);
  return Number.isFinite(number) && number >= 0 ? number : fallback;
}

function dependencyNow(dependencies = {}) {
  const now = dependencies.now ? Number(dependencies.now()) : Date.now();
  return Number.isFinite(now) ? now : Date.now();
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

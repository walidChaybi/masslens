-- Link a verified AdMob transaction to at most one client-created attempt.
-- NULL keeps callbacks from app versions that predate reward attempts working.
ALTER TABLE ad_rewards ADD COLUMN attempt_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS ad_rewards_attempt
  ON ad_rewards(attempt_id)
  WHERE attempt_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS reward_attempts (
  attempt_id TEXT PRIMARY KEY,
  client_id_hash TEXT NOT NULL,
  state TEXT NOT NULL DEFAULT 'pending' CHECK (
    state IN ('pending', 'verified', 'rejected', 'expired')
  ),
  client_earned_at_ms INTEGER,
  transaction_id TEXT UNIQUE,
  rejection_code TEXT CHECK (
    rejection_code IS NULL OR length(rejection_code) BETWEEN 1 AND 80
  ),
  callback_count INTEGER NOT NULL DEFAULT 0 CHECK (callback_count >= 0),
  last_callback_at_ms INTEGER,
  verified_at_ms INTEGER,
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL,
  expires_at_ms INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS reward_attempts_client
  ON reward_attempts(client_id_hash, created_at_ms);

CREATE INDEX IF NOT EXISTS reward_attempts_pending_expiry
  ON reward_attempts(state, expires_at_ms);

-- Support and migration credits must be auditable and idempotent. They enter
-- the legacy wallet so a reconciliation never pretends that an ad transaction
-- was cryptographically verified.
CREATE TABLE IF NOT EXISTS scan_credit_adjustments (
  adjustment_id TEXT PRIMARY KEY,
  client_id_hash TEXT NOT NULL,
  credit_amount INTEGER NOT NULL CHECK (
    credit_amount BETWEEN 1 AND 100
  ),
  reason TEXT NOT NULL CHECK (length(reason) BETWEEN 1 AND 80),
  actor TEXT NOT NULL CHECK (length(actor) BETWEEN 1 AND 80),
  created_at_ms INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS scan_credit_adjustments_client
  ON scan_credit_adjustments(client_id_hash, created_at_ms);

CREATE TRIGGER IF NOT EXISTS grant_scan_credit_adjustment
AFTER INSERT ON scan_credit_adjustments
BEGIN
  INSERT INTO credit_wallets (
    client_id_hash, balance, lifetime_granted, updated_at_ms
  ) VALUES (
    NEW.client_id_hash,
    NEW.credit_amount,
    NEW.credit_amount,
    NEW.created_at_ms
  )
  ON CONFLICT(client_id_hash) DO UPDATE SET
    balance = credit_wallets.balance + NEW.credit_amount,
    lifetime_granted = credit_wallets.lifetime_granted + NEW.credit_amount,
    updated_at_ms = NEW.created_at_ms;
END;

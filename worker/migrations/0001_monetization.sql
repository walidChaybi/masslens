CREATE TABLE IF NOT EXISTS entitlements (
  client_id_hash TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  purchase_token TEXT NOT NULL UNIQUE,
  state TEXT NOT NULL CHECK (state IN ('active', 'grace', 'inactive')),
  scan_limit INTEGER NOT NULL CHECK (scan_limit > 0),
  scans_used INTEGER NOT NULL DEFAULT 0 CHECK (scans_used >= 0),
  period_end_ms INTEGER NOT NULL,
  verified_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS entitlements_period_end
  ON entitlements(period_end_ms);

CREATE TABLE IF NOT EXISTS free_usage (
  client_id_hash TEXT PRIMARY KEY,
  period_key TEXT NOT NULL,
  included_used INTEGER NOT NULL DEFAULT 0 CHECK (included_used >= 0),
  bonus_credits INTEGER NOT NULL DEFAULT 0 CHECK (bonus_credits >= 0),
  updated_at_ms INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS ad_rewards (
  transaction_id TEXT PRIMARY KEY,
  client_id_hash TEXT NOT NULL,
  period_key TEXT NOT NULL,
  reward_amount INTEGER NOT NULL CHECK (reward_amount = 1),
  created_at_ms INTEGER NOT NULL
);

CREATE TRIGGER IF NOT EXISTS grant_verified_ad_reward
AFTER INSERT ON ad_rewards
BEGIN
  INSERT INTO free_usage (
    client_id_hash, period_key, included_used, bonus_credits, updated_at_ms
  ) VALUES (
    NEW.client_id_hash, NEW.period_key, 0, NEW.reward_amount, NEW.created_at_ms
  )
  ON CONFLICT(client_id_hash) DO UPDATE SET
    period_key = excluded.period_key,
    included_used = CASE
      WHEN free_usage.period_key = excluded.period_key
      THEN free_usage.included_used ELSE 0 END,
    bonus_credits = CASE
      WHEN free_usage.period_key = excluded.period_key
      THEN free_usage.bonus_credits + NEW.reward_amount
      ELSE NEW.reward_amount END,
    updated_at_ms = NEW.created_at_ms;
END;

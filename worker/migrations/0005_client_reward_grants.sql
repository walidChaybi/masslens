-- The mobile ads SDK's onUserEarnedReward event is the app credit authority.
-- Keep it separate from ad_rewards so client-authoritative grants can never be
-- mistaken for cryptographically verified AdMob SSV transactions.
CREATE TABLE IF NOT EXISTS client_reward_grants (
  attempt_id TEXT PRIMARY KEY,
  client_id_hash TEXT NOT NULL,
  reward_amount INTEGER NOT NULL DEFAULT 1 CHECK (reward_amount = 1),
  source TEXT NOT NULL DEFAULT 'mobile_sdk' CHECK (source = 'mobile_sdk'),
  created_at_ms INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS client_reward_grants_client
  ON client_reward_grants(client_id_hash, created_at_ms);

-- A per-installation lease makes the two-minute start/grant guard atomic under
-- concurrent requests. An earned-but-not-yet-credited attempt keeps its lease
-- so a cap-limited grant can be retried after a scan is spent.
CREATE TABLE IF NOT EXISTS reward_client_cooldowns (
  client_id_hash TEXT PRIMARY KEY,
  active_attempt_id TEXT,
  last_started_at_ms INTEGER,
  last_granted_at_ms INTEGER,
  updated_at_ms INTEGER NOT NULL
);

CREATE TRIGGER IF NOT EXISTS grant_client_reward
AFTER INSERT ON client_reward_grants
BEGIN
  INSERT INTO ad_scan_wallets (
    client_id_hash, starter_used, rewarded_balance, updated_at_ms
  ) VALUES (
    NEW.client_id_hash, 0, NEW.reward_amount, NEW.created_at_ms
  )
  ON CONFLICT(client_id_hash) DO UPDATE SET
    rewarded_balance = MIN(
      3,
      ad_scan_wallets.rewarded_balance + NEW.reward_amount
    ),
    updated_at_ms = NEW.created_at_ms;
END;

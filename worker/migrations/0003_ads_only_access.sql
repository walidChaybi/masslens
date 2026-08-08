CREATE TABLE IF NOT EXISTS ad_scan_wallets (
  client_id_hash TEXT PRIMARY KEY,
  starter_used INTEGER NOT NULL DEFAULT 0 CHECK (
    starter_used BETWEEN 0 AND 3
  ),
  rewarded_balance INTEGER NOT NULL DEFAULT 0 CHECK (rewarded_balance >= 0),
  updated_at_ms INTEGER NOT NULL
);

-- Carry forward beta usage without restoring the old monthly reset. Previously
-- consumed beta scans count against the three lifetime starter scans, while
-- every verified bonus remains available.
INSERT OR IGNORE INTO ad_scan_wallets (
  client_id_hash, starter_used, rewarded_balance, updated_at_ms
)
SELECT
  client_id_hash,
  MIN(3, MAX(0, included_used)),
  bonus_credits,
  updated_at_ms
FROM free_usage;

DROP TRIGGER IF EXISTS grant_verified_ad_reward;

CREATE TRIGGER grant_verified_ad_reward
AFTER INSERT ON ad_rewards
BEGIN
  INSERT INTO ad_scan_wallets (
    client_id_hash, starter_used, rewarded_balance, updated_at_ms
  ) VALUES (
    NEW.client_id_hash, 0, NEW.reward_amount, NEW.created_at_ms
  )
  ON CONFLICT(client_id_hash) DO UPDATE SET
    rewarded_balance = CASE
      WHEN ad_scan_wallets.rewarded_balance < 3
      THEN MIN(3, ad_scan_wallets.rewarded_balance + NEW.reward_amount)
      ELSE ad_scan_wallets.rewarded_balance
    END,
    updated_at_ms = NEW.created_at_ms;
END;

CREATE TABLE IF NOT EXISTS scan_requests (
  request_id TEXT PRIMARY KEY,
  client_id_hash TEXT NOT NULL,
  state TEXT NOT NULL CHECK (
    state IN ('pending', 'reserved', 'completed', 'refunded')
  ),
  reservation_kind TEXT CHECK (
    reservation_kind IS NULL OR
    reservation_kind IN ('starter', 'rewarded', 'legacy')
  ),
  result_json TEXT,
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL,
  expires_at_ms INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS scan_requests_expiry
  ON scan_requests(expires_at_ms);

CREATE INDEX IF NOT EXISTS scan_requests_client
  ON scan_requests(client_id_hash, created_at_ms);

CREATE TABLE IF NOT EXISTS daily_metrics (
  day TEXT NOT NULL,
  metric TEXT NOT NULL,
  dimension TEXT NOT NULL,
  event_count INTEGER NOT NULL DEFAULT 0 CHECK (event_count >= 0),
  value_micros INTEGER NOT NULL DEFAULT 0 CHECK (value_micros >= 0),
  updated_at_ms INTEGER NOT NULL,
  PRIMARY KEY (day, metric, dimension)
);

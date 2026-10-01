CREATE TABLE IF NOT EXISTS lifetime_entitlements (
  purchase_token TEXT PRIMARY KEY,
  client_id_hash TEXT NOT NULL,
  product_id TEXT NOT NULL,
  order_id TEXT,
  purchase_time_ms INTEGER NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('active', 'voided')),
  verified_at_ms INTEGER NOT NULL,
  voided_at_ms INTEGER,
  updated_at_ms INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS lifetime_entitlements_client
  ON lifetime_entitlements(client_id_hash, state);

CREATE INDEX IF NOT EXISTS lifetime_entitlements_order
  ON lifetime_entitlements(order_id);

CREATE TABLE IF NOT EXISTS scan_requests_v2 (
  request_id TEXT PRIMARY KEY,
  client_id_hash TEXT NOT NULL,
  state TEXT NOT NULL CHECK (
    state IN ('pending', 'reserved', 'completed', 'refunded')
  ),
  reservation_kind TEXT CHECK (
    reservation_kind IS NULL OR
    reservation_kind IN ('starter', 'rewarded', 'legacy', 'lifetime')
  ),
  result_json TEXT,
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL,
  expires_at_ms INTEGER NOT NULL
);

INSERT INTO scan_requests_v2
SELECT * FROM scan_requests;

DROP TABLE scan_requests;

ALTER TABLE scan_requests_v2 RENAME TO scan_requests;

CREATE INDEX IF NOT EXISTS scan_requests_expiry
  ON scan_requests(expires_at_ms);

CREATE INDEX IF NOT EXISTS scan_requests_client
  ON scan_requests(client_id_hash, created_at_ms);

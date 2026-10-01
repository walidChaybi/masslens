-- Additive only. Do not rebuild scan_requests.
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

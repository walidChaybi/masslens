CREATE TABLE IF NOT EXISTS credit_wallets (
  client_id_hash TEXT PRIMARY KEY,
  balance INTEGER NOT NULL DEFAULT 0,
  lifetime_granted INTEGER NOT NULL DEFAULT 0 CHECK (lifetime_granted >= 0),
  updated_at_ms INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS consumable_purchases (
  purchase_token TEXT PRIMARY KEY,
  client_id_hash TEXT NOT NULL,
  product_id TEXT NOT NULL,
  credits INTEGER NOT NULL CHECK (credits > 0),
  order_id TEXT,
  purchase_time_ms INTEGER NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('granted', 'consumed', 'voided')),
  verified_at_ms INTEGER NOT NULL,
  consumed_at_ms INTEGER,
  voided_at_ms INTEGER,
  updated_at_ms INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS consumable_purchases_client
  ON consumable_purchases(client_id_hash, purchase_time_ms);

CREATE INDEX IF NOT EXISTS consumable_purchases_order
  ON consumable_purchases(order_id);

CREATE TRIGGER IF NOT EXISTS grant_consumable_purchase
AFTER INSERT ON consumable_purchases
BEGIN
  INSERT INTO credit_wallets (
    client_id_hash, balance, lifetime_granted, updated_at_ms
  ) VALUES (
    NEW.client_id_hash, NEW.credits, NEW.credits, NEW.updated_at_ms
  )
  ON CONFLICT(client_id_hash) DO UPDATE SET
    balance = credit_wallets.balance + NEW.credits,
    lifetime_granted = credit_wallets.lifetime_granted + NEW.credits,
    updated_at_ms = NEW.updated_at_ms;
END;

-- A void can take an account below zero when some refunded credits were
-- already used. Later purchases first settle that debt, preventing refund
-- abuse without deleting the purchase history.
CREATE TRIGGER IF NOT EXISTS revoke_consumable_purchase
AFTER UPDATE OF state ON consumable_purchases
WHEN NEW.state = 'voided' AND OLD.state <> 'voided'
BEGIN
  UPDATE credit_wallets
     SET balance = balance - OLD.credits,
         updated_at_ms = NEW.updated_at_ms
   WHERE client_id_hash = OLD.client_id_hash;
END;

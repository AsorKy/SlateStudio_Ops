-- ============================================================
-- TimeTracker Schema · Clients (dimension)
-- ============================================================

CREATE TABLE clients (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_name       TEXT NOT NULL,
  client_type       client_type      NOT NULL DEFAULT 'per_project',
  client_program    client_program   NOT NULL DEFAULT 'standard',
  billing_type      billing_type     NOT NULL DEFAULT 'monthly',
  status            client_status    NOT NULL DEFAULT 'active',
  client_start_date DATE             NOT NULL DEFAULT CURRENT_DATE,
  client_churn_date DATE,                                          -- NULL while relationship is active
  notes             TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Business rules
  CONSTRAINT chk_churn_after_start
    CHECK (client_churn_date IS NULL OR client_churn_date >= client_start_date)
);

CREATE INDEX idx_clients_status ON clients (status);
CREATE INDEX idx_clients_name   ON clients (client_name);

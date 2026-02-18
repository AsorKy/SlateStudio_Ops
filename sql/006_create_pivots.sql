-- ============================================================
-- TimeTracker Schema · Junction / Pivot Tables
-- ============================================================

-- ---- Employee ↔ Client (many-to-many) ----------------------
CREATE TABLE employee_clients (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id  UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  client_id    UUID NOT NULL REFERENCES clients(id)   ON DELETE CASCADE,
  assigned_at  DATE NOT NULL DEFAULT CURRENT_DATE,
  removed_at   DATE,

  CONSTRAINT uq_employee_client UNIQUE (employee_id, client_id)
);

CREATE INDEX idx_ec_employee ON employee_clients (employee_id);
CREATE INDEX idx_ec_client   ON employee_clients (client_id);

-- ---- Client ↔ Project (many-to-many) -----------------------
CREATE TABLE client_projects (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id    UUID NOT NULL REFERENCES clients(id)   ON DELETE CASCADE,
  project_id   UUID NOT NULL REFERENCES projects(id)  ON DELETE CASCADE,
  assigned_at  DATE NOT NULL DEFAULT CURRENT_DATE,
  removed_at   DATE,

  CONSTRAINT uq_client_project UNIQUE (client_id, project_id)
);

CREATE INDEX idx_cp_client  ON client_projects (client_id);
CREATE INDEX idx_cp_project ON client_projects (project_id);

-- ---- Employee ↔ Project (many-to-many) ---------------------
-- Added: knowing which employees work on which projects
-- makes time-entry validation and reporting easier.
CREATE TABLE employee_projects (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id  UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  project_id   UUID NOT NULL REFERENCES projects(id)  ON DELETE CASCADE,
  role         TEXT,                                    -- optional: "lead", "contributor", etc.
  assigned_at  DATE NOT NULL DEFAULT CURRENT_DATE,
  removed_at   DATE,

  CONSTRAINT uq_employee_project UNIQUE (employee_id, project_id)
);

CREATE INDEX idx_ep_employee ON employee_projects (employee_id);
CREATE INDEX idx_ep_project  ON employee_projects (project_id);

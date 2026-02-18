-- ============================================================
-- TimeTracker Schema · Employees (dimension)
-- ============================================================

CREATE TABLE employees (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name       TEXT            NOT NULL,
  email           TEXT            UNIQUE,                         -- useful for N8N form auth / lookup
  country_code    CHAR(2),                                       -- ISO 3166-1 alpha-2 (e.g. "CO", "US")
  country         TEXT,                                          -- human-readable country name
  employment_type employment_type NOT NULL DEFAULT 'full_time',
  department_id   UUID            NOT NULL REFERENCES departments(id),
  hire_date       DATE            NOT NULL DEFAULT CURRENT_DATE,
  termination_date DATE,
  is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

  CONSTRAINT chk_termination_after_hire
    CHECK (termination_date IS NULL OR termination_date >= hire_date)
);

CREATE INDEX idx_employees_department ON employees (department_id);
CREATE INDEX idx_employees_active     ON employees (is_active);
CREATE INDEX idx_employees_name       ON employees (full_name);

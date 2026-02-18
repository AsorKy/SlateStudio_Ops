-- ============================================================
-- TimeTracker Schema · Projects (dimension)
-- ============================================================

CREATE TABLE projects (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_name            TEXT             NOT NULL,
  category                service_category NOT NULL DEFAULT 'other',
  status                  project_status   NOT NULL DEFAULT 'active',

  -- Hour estimates (for budgeting & variance analysis)
  estimated_hours         NUMERIC(7,2),     -- expected monthly hours
  minimum_hours           NUMERIC(7,2),     -- lower bound
  maximum_hours           NUMERIC(7,2),     -- upper bound

  project_start_date      DATE             NOT NULL DEFAULT CURRENT_DATE,
  project_end_date        DATE,
  main_instructions       TEXT,             -- key operation highlights

  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Sanity checks
  CONSTRAINT chk_hours_range
    CHECK (
      (minimum_hours IS NULL AND maximum_hours IS NULL)
      OR minimum_hours <= maximum_hours
    ),
  CONSTRAINT chk_estimated_within_range
    CHECK (
      estimated_hours IS NULL
      OR (
        (minimum_hours IS NULL OR estimated_hours >= minimum_hours)
        AND (maximum_hours IS NULL OR estimated_hours <= maximum_hours)
      )
    ),
  CONSTRAINT chk_end_after_start
    CHECK (project_end_date IS NULL OR project_end_date >= project_start_date)
);

CREATE INDEX idx_projects_status   ON projects (status);
CREATE INDEX idx_projects_category ON projects (category);

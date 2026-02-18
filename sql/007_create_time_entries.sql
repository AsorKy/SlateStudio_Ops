-- ============================================================
-- TimeTracker Schema · Time Entries (fact table)
-- ============================================================
-- This is the core table populated by the N8N form.
-- Each row = one activity report from an employee.
-- ============================================================

CREATE TABLE time_entries (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign keys (the "who / what / for whom" of every entry)
  employee_id       UUID            NOT NULL REFERENCES employees(id),
  project_id        UUID            NOT NULL REFERENCES projects(id),
  client_id         UUID            NOT NULL REFERENCES clients(id),

  -- Hours
  hours             NUMERIC(5,2)    NOT NULL CHECK (hours > 0),

  -- Time context
  time_frame        time_frame_type NOT NULL DEFAULT 'daily',
  report_date       DATE            NOT NULL DEFAULT CURRENT_DATE,  -- when the entry was submitted
  activity_date     DATE            NOT NULL,                       -- the actual day the work happened
  activity_start    TIMESTAMPTZ,                                    -- optional: precise start
  activity_end      TIMESTAMPTZ,                                    -- optional: precise end

  -- Derived calendar helpers (populated by trigger, used by reporting views)
  iso_year          INT GENERATED ALWAYS AS (EXTRACT(ISOYEAR FROM activity_date)::INT) STORED,
  iso_week          INT GENERATED ALWAYS AS (EXTRACT(WEEK    FROM activity_date)::INT) STORED,
  month             INT GENERATED ALWAYS AS (EXTRACT(MONTH   FROM activity_date)::INT) STORED,
  year              INT GENERATED ALWAYS AS (EXTRACT(YEAR    FROM activity_date)::INT) STORED,

  -- Descriptive
  activity_description TEXT,                                        -- what was done
  activity_comments    TEXT,                                        -- highlights / blockers

  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Guard: end must be after start
  CONSTRAINT chk_activity_window
    CHECK (activity_start IS NULL OR activity_end IS NULL OR activity_end > activity_start)
);

-- ---- Indexes optimised for the reporting queries ------------
CREATE INDEX idx_te_employee      ON time_entries (employee_id);
CREATE INDEX idx_te_project       ON time_entries (project_id);
CREATE INDEX idx_te_client        ON time_entries (client_id);
CREATE INDEX idx_te_activity_date ON time_entries (activity_date);
CREATE INDEX idx_te_year_week     ON time_entries (iso_year, iso_week);
CREATE INDEX idx_te_year_month    ON time_entries (year, month);

-- Composite index for the most common dashboard query:
-- "hours per employee per project in a date range"
CREATE INDEX idx_te_emp_proj_date ON time_entries (employee_id, project_id, activity_date);

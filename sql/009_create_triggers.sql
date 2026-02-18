-- ============================================================
-- TimeTracker Schema · Triggers & Utility Functions
-- ============================================================

-- ---- Auto-update `updated_at` on any row change -------------
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to every table that has an updated_at column
CREATE TRIGGER trg_departments_updated   BEFORE UPDATE ON departments      FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_clients_updated       BEFORE UPDATE ON clients          FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_employees_updated     BEFORE UPDATE ON employees        FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_projects_updated      BEFORE UPDATE ON projects         FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
CREATE TRIGGER trg_time_entries_updated  BEFORE UPDATE ON time_entries     FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

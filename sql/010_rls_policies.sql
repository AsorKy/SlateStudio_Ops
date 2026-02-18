-- ============================================================
-- TimeTracker Schema · Row Level Security (RLS)
-- ============================================================
-- Enable RLS on all tables. Policies below are a starting
-- point — adjust once you wire up Supabase Auth or an API key
-- strategy for N8N.
--
-- NOTE: Run this AFTER all tables are created.
--       The service_role key bypasses RLS, so N8N can use
--       that key for inserts and your dashboard can use the
--       anon key with these policies.
-- ============================================================

ALTER TABLE departments      ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients          ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees        ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects         ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_projects  ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_entries     ENABLE ROW LEVEL SECURITY;

-- ---- Public read access for all dimension tables ------------
-- (adjust if you need stricter access)
CREATE POLICY "Allow public read on departments"
  ON departments FOR SELECT USING (true);

CREATE POLICY "Allow public read on clients"
  ON clients FOR SELECT USING (true);

CREATE POLICY "Allow public read on employees"
  ON employees FOR SELECT USING (true);

CREATE POLICY "Allow public read on projects"
  ON projects FOR SELECT USING (true);

-- ---- Time entries: read all, insert via authenticated/service role
CREATE POLICY "Allow read on time_entries"
  ON time_entries FOR SELECT USING (true);

CREATE POLICY "Allow insert on time_entries for authenticated"
  ON time_entries FOR INSERT
  WITH CHECK (true);  -- tighten to auth.uid() = employee's auth_id if needed

-- ---- Junction tables: read all
CREATE POLICY "Allow read on employee_clients"
  ON employee_clients FOR SELECT USING (true);

CREATE POLICY "Allow read on client_projects"
  ON client_projects FOR SELECT USING (true);

CREATE POLICY "Allow read on employee_projects"
  ON employee_projects FOR SELECT USING (true);

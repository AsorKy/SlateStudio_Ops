-- ============================================================
-- TimeTracker Schema · Reporting Views
-- ============================================================
-- Pre-built views that power your end-of-month dashboards.
-- All views join the fact table with dimensions so you can
-- query plain names instead of UUIDs.
-- ============================================================

-- ============================================================
-- 1. Base enriched view (all entries with dimension labels)
-- ============================================================
CREATE OR REPLACE VIEW v_time_entries AS
SELECT
  te.id                AS entry_id,
  te.activity_date,
  te.report_date,
  te.hours,
  te.time_frame,

  -- Employee
  te.employee_id,
  e.full_name          AS employee_name,
  e.employment_type,
  e.country,

  -- Department
  d.id                 AS department_id,
  d.name               AS department_name,

  -- Client
  te.client_id,
  c.client_name,
  c.client_type,
  c.billing_type,

  -- Project
  te.project_id,
  p.project_name,
  p.category           AS project_category,
  p.estimated_hours    AS project_estimated_hours,

  -- Calendar helpers
  te.iso_year,
  te.iso_week,
  te.month,
  te.year,

  te.activity_description,
  te.activity_comments
FROM time_entries te
JOIN employees   e ON e.id = te.employee_id
JOIN departments d ON d.id = e.department_id
JOIN clients     c ON c.id = te.client_id
JOIN projects    p ON p.id = te.project_id;


-- ============================================================
-- 2. Total hours per EMPLOYEE (monthly)
-- ============================================================
CREATE OR REPLACE VIEW v_hours_by_employee_monthly AS
SELECT
  employee_id,
  employee_name,
  department_name,
  year,
  month,
  SUM(hours) AS total_hours
FROM v_time_entries
GROUP BY employee_id, employee_name, department_name, year, month
ORDER BY year DESC, month DESC, total_hours DESC;


-- ============================================================
-- 3. Total hours per EMPLOYEE (weekly)
-- ============================================================
CREATE OR REPLACE VIEW v_hours_by_employee_weekly AS
SELECT
  employee_id,
  employee_name,
  department_name,
  iso_year,
  iso_week,
  SUM(hours) AS total_hours
FROM v_time_entries
GROUP BY employee_id, employee_name, department_name, iso_year, iso_week
ORDER BY iso_year DESC, iso_week DESC, total_hours DESC;


-- ============================================================
-- 4. Total hours per PROJECT (monthly)
-- ============================================================
CREATE OR REPLACE VIEW v_hours_by_project_monthly AS
SELECT
  project_id,
  project_name,
  project_category,
  project_estimated_hours,
  client_name,
  year,
  month,
  SUM(hours)                                          AS total_hours,
  SUM(hours) - COALESCE(project_estimated_hours, 0)  AS variance_hours
FROM v_time_entries
GROUP BY project_id, project_name, project_category, project_estimated_hours,
         client_name, year, month
ORDER BY year DESC, month DESC, total_hours DESC;


-- ============================================================
-- 5. Total hours per PROJECT (weekly)
-- ============================================================
CREATE OR REPLACE VIEW v_hours_by_project_weekly AS
SELECT
  project_id,
  project_name,
  project_category,
  client_name,
  iso_year,
  iso_week,
  SUM(hours) AS total_hours
FROM v_time_entries
GROUP BY project_id, project_name, project_category, client_name,
         iso_year, iso_week
ORDER BY iso_year DESC, iso_week DESC, total_hours DESC;


-- ============================================================
-- 6. Total hours per CLIENT (monthly)
-- ============================================================
CREATE OR REPLACE VIEW v_hours_by_client_monthly AS
SELECT
  client_id,
  client_name,
  client_type,
  billing_type,
  year,
  month,
  SUM(hours) AS total_hours
FROM v_time_entries
GROUP BY client_id, client_name, client_type, billing_type, year, month
ORDER BY year DESC, month DESC, total_hours DESC;


-- ============================================================
-- 7. Total hours per CLIENT (weekly)
-- ============================================================
CREATE OR REPLACE VIEW v_hours_by_client_weekly AS
SELECT
  client_id,
  client_name,
  client_type,
  billing_type,
  iso_year,
  iso_week,
  SUM(hours) AS total_hours
FROM v_time_entries
GROUP BY client_id, client_name, client_type, billing_type, iso_year, iso_week
ORDER BY iso_year DESC, iso_week DESC, total_hours DESC;


-- ============================================================
-- 8. Total hours per DEPARTMENT (monthly)
-- ============================================================
CREATE OR REPLACE VIEW v_hours_by_department_monthly AS
SELECT
  department_id,
  department_name,
  year,
  month,
  SUM(hours)       AS total_hours,
  COUNT(DISTINCT employee_id) AS active_employees
FROM v_time_entries
GROUP BY department_id, department_name, year, month
ORDER BY year DESC, month DESC, total_hours DESC;


-- ============================================================
-- 9. Total hours per DEPARTMENT (weekly)
-- ============================================================
CREATE OR REPLACE VIEW v_hours_by_department_weekly AS
SELECT
  department_id,
  department_name,
  iso_year,
  iso_week,
  SUM(hours)       AS total_hours,
  COUNT(DISTINCT employee_id) AS active_employees
FROM v_time_entries
GROUP BY department_id, department_name, iso_year, iso_week
ORDER BY iso_year DESC, iso_week DESC, total_hours DESC;

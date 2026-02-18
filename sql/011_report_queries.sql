-- ============================================================
-- TimeTracker · Standalone Report Queries
-- ============================================================
-- These are the exact queries used by the N8N weekly report
-- workflow. You can also run them manually in the Supabase
-- SQL Editor or any PostgreSQL client.
--
-- All queries accept a date range via the WHERE clause.
-- Swap the interval for monthly reports.
-- ============================================================


-- ============================================================
-- 1. HOURS BY DEPARTMENT (last 7 days)
-- ============================================================
SELECT
  d.name                          AS department,
  SUM(te.hours)                   AS total_hours,
  COUNT(DISTINCT te.employee_id)  AS employees_reporting,
  COUNT(te.id)                    AS entries
FROM time_entries te
JOIN employees   e  ON e.id = te.employee_id
JOIN departments d  ON d.id = e.department_id
WHERE te.activity_date >= date_trunc('week', CURRENT_DATE) - INTERVAL '7 days'
  AND te.activity_date <  date_trunc('week', CURRENT_DATE)
GROUP BY d.name
ORDER BY total_hours DESC;


-- ============================================================
-- 2. HOURS BY CLIENT (last 7 days)
-- ============================================================
SELECT
  c.client_name                   AS client,
  c.client_type::TEXT             AS type,
  SUM(te.hours)                   AS total_hours,
  COUNT(DISTINCT te.project_id)   AS projects,
  COUNT(DISTINCT te.employee_id)  AS employees
FROM time_entries te
JOIN clients c ON c.id = te.client_id
WHERE te.activity_date >= date_trunc('week', CURRENT_DATE) - INTERVAL '7 days'
  AND te.activity_date <  date_trunc('week', CURRENT_DATE)
GROUP BY c.client_name, c.client_type
ORDER BY total_hours DESC;


-- ============================================================
-- 3. HOURS BY EMPLOYEE (last 7 days)
-- ============================================================
SELECT
  e.full_name                     AS employee,
  d.name                          AS department,
  e.employment_type::TEXT         AS type,
  SUM(te.hours)                   AS total_hours,
  COUNT(DISTINCT te.project_id)   AS projects_worked,
  COUNT(te.id)                    AS entries
FROM time_entries te
JOIN employees   e  ON e.id = te.employee_id
JOIN departments d  ON d.id = e.department_id
WHERE te.activity_date >= date_trunc('week', CURRENT_DATE) - INTERVAL '7 days'
  AND te.activity_date <  date_trunc('week', CURRENT_DATE)
GROUP BY e.full_name, d.name, e.employment_type
ORDER BY total_hours DESC;


-- ============================================================
-- 4. HOURS BY PROJECT (last 7 days)
-- ============================================================
SELECT
  p.project_name                  AS project,
  c.client_name                   AS client,
  p.category::TEXT                AS category,
  p.estimated_hours               AS estimated,
  SUM(te.hours)                   AS actual_hours,
  SUM(te.hours) - COALESCE(p.estimated_hours, 0) AS variance,
  COUNT(DISTINCT te.employee_id)  AS employees
FROM time_entries te
JOIN projects p ON p.id = te.project_id
JOIN clients  c ON c.id = te.client_id
WHERE te.activity_date >= date_trunc('week', CURRENT_DATE) - INTERVAL '7 days'
  AND te.activity_date <  date_trunc('week', CURRENT_DATE)
GROUP BY p.project_name, c.client_name, p.category, p.estimated_hours
ORDER BY actual_hours DESC;


-- ============================================================
-- 5. MONTHLY SUMMARY (current month)
-- Replace CURRENT_DATE with a specific date for historical.
-- ============================================================
SELECT
  'Department' AS dimension,
  d.name       AS name,
  SUM(te.hours) AS total_hours
FROM time_entries te
JOIN employees   e ON e.id = te.employee_id
JOIN departments d ON d.id = e.department_id
WHERE te.year  = EXTRACT(YEAR  FROM CURRENT_DATE)::INT
  AND te.month = EXTRACT(MONTH FROM CURRENT_DATE)::INT
GROUP BY d.name

UNION ALL

SELECT
  'Client'     AS dimension,
  c.client_name AS name,
  SUM(te.hours) AS total_hours
FROM time_entries te
JOIN clients c ON c.id = te.client_id
WHERE te.year  = EXTRACT(YEAR  FROM CURRENT_DATE)::INT
  AND te.month = EXTRACT(MONTH FROM CURRENT_DATE)::INT
GROUP BY c.client_name

UNION ALL

SELECT
  'Employee'   AS dimension,
  e.full_name  AS name,
  SUM(te.hours) AS total_hours
FROM time_entries te
JOIN employees e ON e.id = te.employee_id
WHERE te.year  = EXTRACT(YEAR  FROM CURRENT_DATE)::INT
  AND te.month = EXTRACT(MONTH FROM CURRENT_DATE)::INT
GROUP BY e.full_name

ORDER BY dimension, total_hours DESC;

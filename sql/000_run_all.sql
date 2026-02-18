-- ============================================================
-- TimeTracker · Master Migration Script
-- ============================================================
-- Run this file in Supabase SQL Editor to set up the full
-- schema from scratch.  Files are executed in order.
--
-- Usage in Supabase SQL Editor:
--   Copy-paste each file in sequence, or concatenate them
--   and run as a single transaction.
-- ============================================================

-- To run as a single atomic migration, wrap in a transaction:
BEGIN;

-- 1. Enum types
\i 001_create_enums.sql

-- 2. Dimension tables
\i 002_create_departments.sql
\i 003_create_clients.sql
\i 004_create_employees.sql
\i 005_create_projects.sql

-- 3. Junction tables
\i 006_create_pivots.sql

-- 4. Fact table
\i 007_create_time_entries.sql

-- 5. Reporting views
\i 008_create_views.sql

-- 6. Triggers
\i 009_create_triggers.sql

-- 7. Row Level Security (optional — comment out if not needed yet)
\i 010_rls_policies.sql

COMMIT;

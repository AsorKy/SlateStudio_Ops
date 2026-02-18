-- ============================================================
-- TimeTracker Schema · Enums
-- Supabase-compatible (PostgreSQL 15+)
-- ============================================================

-- Client billing / relationship types
CREATE TYPE client_type        AS ENUM ('per_project', 'retainer', 'one_time');
CREATE TYPE client_program     AS ENUM ('basic', 'standard', 'premium', 'enterprise', 'custom');
CREATE TYPE billing_type       AS ENUM ('per_project', 'retainer', 'monthly', 'yearly');
CREATE TYPE client_status      AS ENUM ('active', 'inactive', 'churned');

-- Employee types
CREATE TYPE employment_type    AS ENUM ('contractor', 'part_time', 'full_time');

-- Project / department service categories
CREATE TYPE service_category   AS ENUM (
  'design',
  'video',
  'social_media',
  'blogs_written_dev',
  'web_dev',
  'strategy',
  'other'
);

-- Project lifecycle
CREATE TYPE project_status     AS ENUM ('active', 'paused', 'completed', 'cancelled');

-- Time-entry granularity reported by the user
CREATE TYPE time_frame_type    AS ENUM ('daily', 'weekly', 'monthly');

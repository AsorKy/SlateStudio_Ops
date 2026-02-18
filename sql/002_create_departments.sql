-- ============================================================
-- TimeTracker Schema · Departments (dimension)
-- ============================================================
-- Extracted into its own table so you can add departments
-- without touching enum definitions or code.
-- ============================================================

CREATE TABLE departments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL UNIQUE,                       -- e.g. "Design", "Video"
  category        service_category NOT NULL DEFAULT 'other',  -- maps to the broad category
  description     TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed the initial departments that match your org structure
INSERT INTO departments (name, category) VALUES
  ('Design',              'design'),
  ('Video',               'video'),
  ('Social Media',        'social_media'),
  ('Blogs & Written Dev', 'blogs_written_dev'),
  ('Web Development',     'web_dev'),
  ('Strategy',            'strategy');

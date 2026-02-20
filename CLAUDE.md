# CLAUDE.md — TimeTracker Context Bank

> This file is the authoritative context source for all AI-assisted work on this project.
> Update it whenever the schema, workflows, or business rules change.

---

## Project Identity

- **Name:** TimeTracker
- **Owner:** SlateStudio
- **Goal:** Track employee operation hours and report weekly/monthly by project, client, department, and employee.
- **Stack:** Supabase (PostgreSQL) · N8N (automation/forms/reports) · Slack · Email (SMTP)

---

## Repository Structure

```
TimeTracker/
├── CLAUDE.md                          ← this file
├── README.md
├── ProjectCredentials.txt             ← secrets (never commit)
├── .gitignore
├── data/                              ← placeholder, unused
├── sql/
│   ├── 000_run_all.sql                ← master migration runner
│   ├── 001_create_enums.sql
│   ├── 002_create_departments.sql
│   ├── 003_create_clients.sql
│   ├── 004_create_employees.sql
│   ├── 005_create_projects.sql
│   ├── 006_create_pivots.sql          ← junction tables
│   ├── 007_create_time_entries.sql    ← fact table
│   ├── 008_create_views.sql           ← pre-built reporting views
│   ├── 009_create_triggers.sql        ← auto updated_at
│   ├── 010_rls_policies.sql           ← Row Level Security
│   ├── 011_report_queries.sql         ← standalone ad-hoc reports
│   └── 012_seed_dummy_data.sql        ← 4 weeks of demo data
└── app/n8n/
    ├── SETUP.md
    └── workflows/
        ├── 01_hour_reporting_form.json
        ├── 02_new_employee_form.json
        ├── 03_new_project_form.json
        ├── 04_new_client_form.json
        ├── 05_weekly_report.json
        └── TimeTracker — Weekly Report (Slack + Email).json
```

---

## Database: Supabase (PostgreSQL)

**Project URL:** `https://imbzyvngcptnqaiiijfs.supabase.co`
**DB name:** `postgres`
**Credentials file:** `ProjectCredentials.txt` (not in git)

### Enum Types (001_create_enums.sql)

| Enum | Values |
|------|--------|
| `client_type` | `per_project`, `retainer`, `one_time` |
| `client_program` | `basic`, `standard`, `premium`, `enterprise`, `custom` |
| `billing_type` | `per_project`, `retainer`, `monthly`, `yearly` |
| `client_status` | `active`, `inactive`, `churned` |
| `employment_type` | `contractor`, `part_time`, `full_time` |
| `service_category` | `design`, `video`, `social_media`, `blogs_written_dev`, `web_dev`, `strategy`, `other` |
| `project_status` | `active`, `paused`, `completed`, `cancelled` |
| `time_frame_type` | `daily`, `weekly`, `monthly` |

---

### Dimension Tables

#### `departments`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | auto |
| name | TEXT UNIQUE | e.g. "Design", "Video" |
| category | service_category | |
| description | TEXT | |
| created_at / updated_at | TIMESTAMPTZ | trigger-managed |

Seeded: Design, Video, Social Media, Blogs & Written Dev, Web Development, Strategy

#### `clients`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| client_name | TEXT NOT NULL | |
| client_type | client_type | |
| client_program | client_program | |
| billing_type | billing_type | |
| status | client_status | |
| client_start_date | DATE | |
| client_churn_date | DATE | NULL while active |
| notes | TEXT | |

Indexes: `idx_clients_status`, `idx_clients_name`

#### `employees`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| full_name | TEXT NOT NULL | |
| email | TEXT UNIQUE | used by N8N form lookup |
| country_code | CHAR(2) | ISO 3166-1 alpha-2 |
| country | TEXT | |
| employment_type | employment_type | |
| department_id | UUID FK → departments | |
| hire_date | DATE | |
| termination_date | DATE | NULL if active |
| is_active | BOOLEAN | soft-delete flag |

Indexes: `idx_employees_department`, `idx_employees_active`, `idx_employees_name`

#### `projects`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| project_name | TEXT NOT NULL | |
| category | service_category | |
| status | project_status | |
| estimated_hours | NUMERIC(7,2) | for variance analysis |
| minimum_hours | NUMERIC(7,2) | |
| maximum_hours | NUMERIC(7,2) | |
| project_start_date | DATE | |
| project_end_date | DATE | NULL if ongoing |
| main_instructions | TEXT | |

Indexes: `idx_projects_status`, `idx_projects_category`

---

### Junction (Pivot) Tables (006_create_pivots.sql)

| Table | Purpose | Unique Constraint |
|-------|---------|-------------------|
| `employee_clients` | Employee ↔ Client assignments | (employee_id, client_id) |
| `client_projects` | Client ↔ Project links | (client_id, project_id) |
| `employee_projects` | Employee ↔ Project assignments (with `role`) | (employee_id, project_id) |

All have `assigned_at` (DATE) and `removed_at` (DATE, NULL = active).

---

### Fact Table: `time_entries` (007_create_time_entries.sql)

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| employee_id | UUID FK → employees | |
| project_id | UUID FK → projects | |
| client_id | UUID FK → clients | |
| hours | NUMERIC(5,2) | CHECK > 0 |
| time_frame | time_frame_type | daily / weekly / monthly |
| report_date | DATE | when submitted |
| activity_date | DATE NOT NULL | actual day worked |
| activity_start | TIMESTAMPTZ | optional |
| activity_end | TIMESTAMPTZ | optional, must be > start |
| iso_year | INT GENERATED | EXTRACT(ISOYEAR) |
| iso_week | INT GENERATED | EXTRACT(WEEK) |
| month | INT GENERATED | EXTRACT(MONTH) |
| year | INT GENERATED | EXTRACT(YEAR) |
| activity_description | TEXT | what was done |
| activity_comments | TEXT | blockers / highlights |

**Key Indexes:**
- `idx_te_year_week` ON (iso_year, iso_week) — weekly report performance
- `idx_te_year_month` ON (year, month) — monthly report performance
- `idx_te_emp_proj_date` ON (employee_id, project_id, activity_date) — composite

---

### Reporting Views (008_create_views.sql)

| View | Dimensions | Granularity |
|------|-----------|-------------|
| `v_time_entries` | All (base enriched view) | row-level |
| `v_hours_by_employee_monthly` | employee, department | year + month |
| `v_hours_by_employee_weekly` | employee, department | iso_year + iso_week |
| `v_hours_by_project_monthly` | project, client, variance | year + month |
| `v_hours_by_project_weekly` | project, client | iso_year + iso_week |
| `v_hours_by_client_monthly` | client, billing_type | year + month |
| `v_hours_by_client_weekly` | client, billing_type | iso_year + iso_week |
| `v_hours_by_department_monthly` | department, active_employees count | year + month |
| `v_hours_by_department_weekly` | department, active_employees count | iso_year + iso_week |

`variance_hours` in project views = `total_hours - project_estimated_hours`

---

### Triggers (009_create_triggers.sql)

`fn_set_updated_at()` — BEFORE UPDATE on: `departments`, `clients`, `employees`, `projects`, `time_entries`

---

### Row Level Security (010_rls_policies.sql)

- Dimension tables: Public SELECT
- `time_entries`: Public SELECT, Authenticated/Service role INSERT
- Junction tables: Public SELECT
- N8N uses the **service role key** which bypasses RLS

---

## N8N Workflows

**Credential placeholder in all workflows:** `REPLACE_WITH_CREDENTIAL_ID`

### Data Entry Workflows (triggered by form submission)

| File | Purpose | Target Table |
|------|---------|-------------|
| `01_hour_reporting_form.json` | Employees log hours | `time_entries` |
| `02_new_employee_form.json` | Register new employee | `employees` |
| `03_new_project_form.json` | Create project + link to client | `projects` + `client_projects` |
| `04_new_client_form.json` | Register new client | `clients` |

**Hour Reporting Logic (01) — 2-page multi-step form:**

*Page 1 (Form Trigger, static):* Hours, Activity Date, Time Frame, Description, Comments
→ `responseMode: "responseNode"` holds the session open for page 2

*Between pages (workflow executes):*
- `Fetch Dropdown Options` (Postgres): single `json_agg` query returns active employees, clients, projects in one shot
- `Format Dropdown Options` (Code): converts arrays to `[{ option: name }]` format

*Page 2 (Form node, dynamic dropdowns):*
- Employee Name — `={{ $json.employeeOptions }}`
- Client Name — `={{ $json.clientOptions }}`
- Project Name — `={{ $json.projectOptions }}`

*After page 2 submission:*
- INSERT resolves IDs by `full_name` / `project_name` / `client_name` (not by email)
- Page 1 data referenced as: `$('Hour Reporting Form').first().json['Hours']` etc.
- IF node checks RETURNING id — success or error Set node

**Important:** Employee lookup is now by `full_name`, not by email.

### Weekly Report Workflow (scheduled)

**File:** `05_weekly_report.json` / `TimeTracker — Weekly Report (Slack + Email).json`
**Schedule:** Every Monday at 09:00 AM (cron: `0 9 * * 1`)

**Pipeline:**
1. Three parallel SQL queries (last 7 days): hours by department, by client, by employee
2. JavaScript code node merges results → formats Slack markdown + HTML email
3. Sends to Slack channel and email recipients

**Placeholders to replace:**
- `REPLACE_WITH_CREDENTIAL_ID` — Supabase Postgres credential ID
- `REPLACE_WITH_CHANNEL_ID` — Slack channel ID
- `REPLACE_WITH_RECIPIENT@slatestudio.com` — email recipient(s)
- `timetracker@slatestudio.com` — sender address

---

## Business Rules & Constraints

- `hours > 0` (enforced by DB CHECK)
- `activity_end > activity_start` if both provided
- `client_churn_date >= client_start_date` if not NULL
- `termination_date >= hire_date` if not NULL
- `minimum_hours <= maximum_hours`
- `estimated_hours BETWEEN minimum_hours AND maximum_hours` if provided
- `project_end_date >= project_start_date` if not NULL
- Employee lookup in `01_hour_reporting_form` is done **by full_name** (dynamic dropdown, selected by user — changed from email after multi-page redesign)
- Client/Project lookup in forms is done **by name** (display values from dropdowns)

---

## Seed Data Summary (012_seed_dummy_data.sql)

- 6 clients, 10 employees (across 6 departments), 8 projects
- 4 weeks of time entries: Jan 27 – Feb 21, 2025
- Realistic mix of projects, hours (0.5–4h per entry), and descriptions
- Pivot table assignments link employees to clients and projects

---

## Key Decisions & Notes

1. **Generated columns** (`iso_year`, `iso_week`, `month`, `year`) are computed at INSERT time from `activity_date` — never manually set.
2. **Report date vs activity date:** `report_date` is when the form was submitted; `activity_date` is the actual day worked. Reports should filter on `activity_date`.
3. **time_frame_type** is informational (describes whether hours cover a day/week/month block) — reporting aggregation uses `activity_date` ranges, not this field.
4. The weekly report queries the last 7 days using `CURRENT_DATE - INTERVAL '7 days'` — it does NOT use `iso_week` filtering.
5. `ProjectCredentials.txt` must **never be committed** to git (already in `.gitignore`).
6. All N8N SQL inserts use the **service role key** (bypasses RLS). The anon key is for read-only client apps.
7. `v_hours_by_project_monthly` includes `variance_hours` — always check this view when comparing budget vs actuals.

---

## Future Enhancements (Backlog Ideas)

- Dynamic dropdown loading in N8N forms (query DB for active clients/projects)
- Monthly report workflow (parallel to weekly, triggered on 1st of month)
- Dashboard in Supabase Studio or external BI tool (Metabase, Retool)
- Slack slash command for on-demand reports
- Employee self-service view of own hours
- Approval workflow for time entries

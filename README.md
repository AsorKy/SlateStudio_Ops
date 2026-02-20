# TimeTracker

Employee time tracking and reporting system for SlateStudio. Track hours per employee, project, client, and department — with automated weekly and monthly reports delivered to Slack and email.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [1. Database Setup (Supabase)](#1-database-setup-supabase)
  - [2. N8N Setup](#2-n8n-setup)
  - [3. Configure Credentials in N8N](#3-configure-credentials-in-n8n)
  - [4. Import Workflows](#4-import-workflows)
  - [5. Update Workflow Placeholders](#5-update-workflow-placeholders)
  - [6. Activate Workflows](#6-activate-workflows)
  - [7. Deploy the Custom HTML Form (Vercel)](#7-deploy-the-custom-html-form-vercel)
- [How It Works](#how-it-works)
  - [Logging Hours — Custom HTML Form](#logging-hours--custom-html-form)
  - [Adding Employees, Clients, and Projects](#adding-employees-clients-and-projects)
  - [Weekly Report](#weekly-report)
- [Database Schema](#database-schema)
- [Reporting Views](#reporting-views)
- [Project Structure](#project-structure)
- [Security Notes](#security-notes)

---

## Overview

TimeTracker answers these operational questions on a **weekly and monthly** basis:

| Question | Powered by |
|----------|-----------|
| Total hours per employee | `v_hours_by_employee_weekly/monthly` |
| Total hours per project | `v_hours_by_project_weekly/monthly` |
| Total hours per client | `v_hours_by_client_weekly/monthly` |
| Total hours per department | `v_hours_by_department_weekly/monthly` |
| Hours vs estimated (variance) | `v_hours_by_project_monthly` |

Reports are delivered automatically every Monday morning via **Slack** and **Email**.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│           Vercel (Static Hosting)                                │
│   app/form/hour-reporting.html                                   │
│                                                                  │
│   On load:  GET  /webhook/custom-form-options ──┐                │
│   On submit: POST /webhook/custom-form ─────────┤                │
└─────────────────────────────────────────────────┼────────────────┘
                                                  │
┌─────────────────────────────────────────────────▼────────────────┐
│                   N8N Cloud (slatestudio.app.n8n.cloud)          │
│                                                                  │
│  Webhook Workflows                  Report Workflow              │
│  ┌────────────────────────┐         ┌──────────────────────┐    │
│  │ 06: GET options        │         │ Schedule: Mon 9 AM   │    │
│  │ 07: POST submit        │         │ Query → Slack/Email  │    │
│  │ 01: N8N form (internal)│         └──────────────────────┘    │
│  │ 02: New Employee       │                                      │
│  │ 03: New Project        │                                      │
│  │ 04: New Client         │                                      │
│  └────────────┬───────────┘                                      │
└───────────────┼──────────────────────────────────────────────────┘
                │ INSERT / SELECT
                ▼
┌───────────────────────────────┐
│    Supabase (PostgreSQL)      │
│                               │
│  Dimensions: departments,     │
│  clients, employees,          │
│  projects                     │
│                               │
│  Fact: time_entries           │
│                               │
│  Views: 9 reporting views     │
└───────────────────────────────┘
```

---

## Prerequisites

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| [Supabase](https://supabase.com) account | — | PostgreSQL database |
| [N8N](https://n8n.io) instance | v1.0+ | Workflow automation — cloud recommended |
| [Vercel](https://vercel.com) account | — | Static hosting for the HTML form |
| GitHub repository | — | Source for Vercel auto-deploy |
| Slack workspace | — | Report delivery |
| SMTP account | — | Email report delivery (Gmail, SendGrid, SES, etc.) |

---

## Installation

### 1. Database Setup (Supabase)

1. Create a new Supabase project at [supabase.com](https://supabase.com).

2. Open the **SQL Editor** in your Supabase dashboard.

3. Run the migration scripts **in order**. You can run them all at once using the master script:

   ```sql
   -- Option A: Run all at once (paste contents of sql/000_run_all.sql)
   ```

   Or run each file individually in this order:

   | # | File | Description |
   |---|------|-------------|
   | 001 | `001_create_enums.sql` | PostgreSQL enum types |
   | 002 | `002_create_departments.sql` | Departments table + seed data |
   | 003 | `003_create_clients.sql` | Clients table |
   | 004 | `004_create_employees.sql` | Employees table |
   | 005 | `005_create_projects.sql` | Projects table |
   | 006 | `006_create_pivots.sql` | Junction tables |
   | 007 | `007_create_time_entries.sql` | Fact table |
   | 008 | `008_create_views.sql` | Reporting views |
   | 009 | `009_create_triggers.sql` | Auto-update timestamps |
   | 010 | `010_rls_policies.sql` | Row Level Security |

4. (Optional) Load demo data to verify everything works:

   ```sql
   -- Paste contents of sql/012_seed_dummy_data.sql
   ```

5. Collect your Supabase credentials from **Settings → API**:
   - **Project URL**
   - **anon key** (public, read-only)
   - **service_role key** (server-side writes — keep secret)
   - **Database password** (from Settings → Database)

---

### 2. N8N Setup

**Self-hosted (Docker — recommended):**

```bash
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

Then open `http://localhost:5678` and complete the initial setup.

**Cloud:** Sign up at [n8n.io](https://n8n.io) and use the cloud dashboard.

---

### 3. Configure Credentials in N8N

You need three credential types in N8N. Navigate to **Settings → Credentials → New**.

#### Supabase (PostgreSQL Direct Connection)

1. Create credential type: **PostgreSQL**
2. Fill in:

   | Field | Value |
   |-------|-------|
   | Host | `db.<your-project-ref>.supabase.co` |
   | Database | `postgres` |
   | Port | `5432` |
   | User | `postgres` |
   | Password | Your database password |
   | SSL | `true` |

3. Save and note the **Credential ID** (visible in the URL when editing).

#### Slack

1. Create a Slack App at [api.slack.com/apps](https://api.slack.com/apps)
2. Add Bot Token Scopes: `chat:write`, `chat:write.public`
3. Install to your workspace and copy the **Bot OAuth Token**
4. In N8N, create credential type: **Slack**
5. Paste the bot token

#### Email (SMTP)

1. In N8N, create credential type: **SMTP**
2. Configure with your email provider:

   | Provider | Host | Port |
   |----------|------|------|
   | Gmail | `smtp.gmail.com` | 587 |
   | SendGrid | `smtp.sendgrid.net` | 587 |
   | AWS SES | `email-smtp.<region>.amazonaws.com` | 587 |

---

### 4. Import Workflows

1. In N8N, go to **Workflows → Import from File**
2. Import each JSON file from `app/n8n/workflows/`:

   | File | Function | Type |
   |------|---------|------|
   | `01_hour_reporting_form.json` | N8N multi-page hour logging form (internal) | N8N Form Trigger |
   | `02_new_employee_form.json` | New employee registration | N8N Form Trigger |
   | `03_new_project_form.json` | New project creation | N8N Form Trigger |
   | `04_new_client_form.json` | New client registration | N8N Form Trigger |
   | `05_weekly_report.json` | Automated weekly report | Scheduled |
   | `06_custom_form_options.json` | GET endpoint — returns dropdown data for the HTML form | Webhook (GET) |
   | `07_custom_form_submit.json` | POST endpoint — receives and inserts HTML form submissions | Webhook (POST) |

---

### 5. Update Workflow Placeholders

Every imported workflow contains placeholder values that must be replaced. Open each workflow and update:

#### All Workflows — Database Credential

In every Postgres node, replace the credential with the one you created in Step 3:
- Look for `"REPLACE_WITH_CREDENTIAL_ID"` in node settings
- Select your Supabase PostgreSQL credential from the dropdown

#### Weekly Report Workflow Only

| Node | Field | Replace With |
|------|-------|-------------|
| Send Slack Report | Channel | Your Slack channel ID |
| Send Slack Report | Credential | Your Slack credential |
| Send Email Report | To | Recipient email(s) |
| Send Email Report | From | `timetracker@yourdomain.com` |
| Send Email Report | Credential | Your SMTP credential |

**Finding your Slack Channel ID:** Right-click the channel in Slack → View channel details → scroll to the bottom.

#### Hour Reporting Form — Dropdown Values

The client and project dropdowns in `01_hour_reporting_form.json` are currently static placeholders. Update them with your actual client and project names, or configure a DB-query node to load them dynamically.

---

### 6. Activate Workflows

1. Open each workflow in N8N
2. Toggle the **Active** switch in the top-right corner
3. Workflows `06` and `07` must be active before the HTML form can load data or submit entries

---

### 7. Deploy the Custom HTML Form (Vercel)

The HTML form lives at `app/form/hour-reporting.html` and is deployed as a static site on Vercel.

#### First-time setup

1. Push the repository to GitHub (if not already done)
2. Go to [vercel.com](https://vercel.com) → **Add New Project** → Import your GitHub repo
3. In **Build & Development Settings**, set:
   - **Framework Preset:** Other
   - **Build Command:** *(leave blank)*
   - **Output Directory:** *(leave blank)*
   - **Install Command:** *(leave blank)*
4. Click **Deploy**

The `vercel.json` at the project root handles everything automatically:

```json
{
  "framework": null,
  "buildCommand": "",
  "installCommand": "",
  "outputDirectory": "app/form",
  "routes": [
    { "src": "/", "dest": "/hour-reporting.html" },
    { "src": "/hour-reporting", "dest": "/hour-reporting.html" }
  ]
}
```

#### Re-deploys

Every `git push` to `main` triggers an automatic re-deploy. No manual steps needed.

#### Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `ng: command not found` | Vercel detected Angular (wrong preset) | Set Framework to **Other** in dashboard settings |
| Dropdowns show "Loading…" forever | Workflow 06 is not active | Activate `06_custom_form_options.json` in N8N |
| Submit returns network error | Workflow 07 is not active | Activate `07_custom_form_submit.json` in N8N |

---

## How It Works

### Logging Hours — Custom HTML Form

Employees open the Vercel URL (e.g. `https://your-project.vercel.app`) and:

1. The page loads and immediately calls the **GET options webhook**, populating three dropdowns from the live database:
   - **Your Name** — all active employees
   - **Client** — all active clients
   - **Project** — all active projects

2. The employee fills in the remaining fields:
   - Activity Date (defaults to today)
   - Hours Worked
   - Time Frame (daily / weekly / monthly)
   - Activity Description (required)
   - Comments / Notes (optional)

3. On submit, the form POSTs JSON to the **POST submit webhook**, which resolves the employee/client/project IDs and inserts a row into `time_entries`.

4. A success or error message appears inline — no page reload.

> **N8N internal form (`01_hour_reporting_form.json`)** is also available as a secondary entry point via the N8N-hosted form URL. It uses the same 2-page multi-step approach with dynamic dropdowns.

### Adding Employees, Clients, and Projects

Use the corresponding form workflows:

- **02_new_employee_form** — registers a new team member
- **03_new_project_form** — creates a project and links it to a client
- **04_new_client_form** — registers a new client

### Weekly Report

Every **Monday at 9:00 AM**, N8N automatically:

1. Queries the last 7 days of `time_entries`
2. Aggregates hours by department, client, and employee
3. Formats a Slack message and an HTML email
4. Delivers both simultaneously

To trigger the report manually, open the workflow in N8N and click **Execute Workflow**.

---

## Database Schema

```
departments ──┐
              │ (department_id FK)
employees ────┤
              │
              ├──── employee_clients ──── clients
              │                              │
              └──── employee_projects ──┐   │
                                        │   │
projects ───── client_projects ─────────┘───┘
    │
    └──────────────────────────────────────────────┐
                                                   │
time_entries (fact table)                          │
  employee_id → employees                          │
  project_id  → projects ──────────────────────────┘
  client_id   → clients
```

### Key Columns in `time_entries`

| Column | Description |
|--------|-------------|
| `activity_date` | The actual day work was performed — use this for filtering |
| `report_date` | When the entry was submitted (may differ from activity_date) |
| `hours` | Hours worked (must be > 0) |
| `time_frame` | Whether hours cover a day, week, or month block |
| `iso_year` / `iso_week` | Auto-generated for fast weekly grouping |
| `month` / `year` | Auto-generated for fast monthly grouping |

---

## Reporting Views

Query these views directly in Supabase Studio or any SQL client:

```sql
-- Total hours per employee this month
SELECT * FROM v_hours_by_employee_monthly
WHERE year = 2025 AND month = 2;

-- Weekly summary for all clients
SELECT * FROM v_hours_by_client_weekly
WHERE iso_year = 2025 AND iso_week = 7;

-- Project variance (actual vs estimated)
SELECT project_name, estimated_hours, total_hours, variance_hours
FROM v_hours_by_project_monthly
WHERE year = 2025 AND month = 2
ORDER BY variance_hours DESC;

-- Department productivity this week
SELECT * FROM v_hours_by_department_weekly
WHERE iso_year = 2025 AND iso_week = 7;
```

---

## Project Structure

```
TimeTracker/
├── vercel.json             Vercel static deployment config (no build step)
├── CLAUDE.md               AI assistant context bank
├── README.md               This file
├── ProjectCredentials.txt  API keys and secrets (NEVER commit)
├── sql/                    Database migration scripts (run in order 001–010)
├── data/                   Reserved for future data exports
└── app/
    ├── form/
    │   └── hour-reporting.html   Custom HTML form → deployed to Vercel
    └── n8n/
        ├── SETUP.md
        └── workflows/
            ├── 01_hour_reporting_form.json   N8N multi-page form (internal)
            ├── 02_new_employee_form.json
            ├── 03_new_project_form.json
            ├── 04_new_client_form.json
            ├── 05_weekly_report.json         Scheduled Monday 9 AM
            ├── 06_custom_form_options.json   GET webhook → dropdown data
            └── 07_custom_form_submit.json    POST webhook → insert time entry
```

---

## Security Notes

- `ProjectCredentials.txt` is listed in `.gitignore` — **never commit it**.
- The **service role key** (used by N8N) bypasses Row Level Security. Treat it like a database root password.
- The **anon key** is safe for client-side use — it only allows public reads as defined by RLS policies.
- Time entry inserts require authentication (service role) — employees cannot insert directly without going through N8N.
- Consider rotating Supabase credentials periodically under **Settings → API**.

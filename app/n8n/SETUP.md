# N8N Workflows — Setup Guide

## Prerequisites

1. **Supabase project** with the SQL schema deployed (run files in `sql/` in order)
2. **N8N instance** (self-hosted or cloud)
3. **Slack workspace** with a bot token (for report notifications)
4. **SMTP credentials** (for email notifications)

---

## Step 1 — Configure N8N Credentials

Create the following credentials in N8N (Settings → Credentials):

### Postgres (Supabase)
- **Name**: `Supabase Postgres`
- **Host**: `db.<your-project-ref>.supabase.co`
- **Port**: `5432`
- **Database**: `postgres`
- **User**: `postgres`
- **Password**: your Supabase DB password
- **SSL**: enable (required by Supabase)

### Slack
- **Name**: `Slack`
- Create a Slack app at https://api.slack.com/apps
- Required scopes: `chat:write`, `chat:write.public`
- Install to your workspace and copy the Bot User OAuth Token

### SMTP (Email)
- **Name**: `SMTP`
- Configure with your email provider (Gmail, SendGrid, AWS SES, etc.)

---

## Step 2 — Import Workflows

Import each JSON file from `n8n/workflows/` into N8N:

| File | Purpose | Trigger |
|------|---------|---------|
| `01_hour_reporting_form.json` | Employees report worked hours | Form (URL) |
| `02_new_employee_form.json` | Register new team members | Form (URL) |
| `03_new_project_form.json` | Create projects + link to client | Form (URL) |
| `04_new_client_form.json` | Register new clients | Form (URL) |
| `05_weekly_report.json` | Weekly metrics → Slack + Email | Schedule (Mon 9AM) |

**How to import**: N8N → Workflows → Import from File → select the JSON.

---

## Step 3 — Replace Placeholders

After importing, update these placeholders in each workflow:

1. **`REPLACE_WITH_CREDENTIAL_ID`** — select your `Supabase Postgres` credential in each Postgres node
2. **`REPLACE_WITH_CHANNEL_ID`** — your Slack channel ID (in the weekly report workflow)
3. **`REPLACE_WITH_RECIPIENT@slatestudio.com`** — email recipient(s) for the weekly report
4. **`timetracker@slatestudio.com`** — sender email address

---

## Step 4 — Customize Form Dropdowns

The **Hour Reporting Form** has placeholder dropdown values for Client and Project.
To load them dynamically:

**Option A — Static list**: Manually update the dropdown options in the form trigger node whenever you add a new client/project.

**Option B — Dynamic (recommended)**: Replace the Form Trigger with a Webhook + custom HTML form that fetches dropdown options from Supabase via API on page load.

---

## Step 5 — Activate & Test

1. Activate all 5 workflows
2. Open each form URL (shown in the Form Trigger node) and submit test data
3. Verify inserts in Supabase (Table Editor or SQL Editor)
4. Manually trigger the weekly report workflow to test Slack + Email delivery

---

## Workflow Architecture

```
┌─────────────────────────────────────────────────────────┐
│  DATA ENTRY (4 Form Workflows)                          │
│                                                          │
│  [Hour Form] ──→ [Insert time_entries]                  │
│  [Employee Form] ──→ [Insert employees]                 │
│  [Project Form] ──→ [Insert projects] ──→ [Link pivot]  │
│  [Client Form] ──→ [Insert clients]                     │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼  (data accumulates in Supabase)
┌─────────────────────────────────────────────────────────┐
│  WEEKLY REPORT                                           │
│                                                          │
│  [Schedule Mon 9AM]                                      │
│       │                                                  │
│       ├──→ [SQL: Hours by Department] ──┐                │
│       ├──→ [SQL: Hours by Client]    ───┤                │
│       └──→ [SQL: Hours by Employee]  ───┘                │
│                                          │               │
│                                    [Merge + Format]      │
│                                          │               │
│                                    ┌─────┴─────┐        │
│                                    ▼           ▼        │
│                              [Slack]     [Email]        │
└─────────────────────────────────────────────────────────┘
```

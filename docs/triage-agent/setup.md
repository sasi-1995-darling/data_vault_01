# DV Failure Triage Agent — Local Setup

**Audience**: Engineer joining the triage-agent project for the first time.
**Acceptance criterion**: After following this doc you should be able to make a successful `list_jobs_runs` call against dbt Cloud within 30 minutes.
**Owner**: DataOps team.

---

## 1. Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Python | 3.13 | Used by `uvx` to spin up the dbt-mcp server |
| `uv` / `uvx` | latest | `brew install uv` on macOS |
| VS Code | latest | with GitHub Copilot Chat enabled |
| Snowflake CLI access | role `DATA_ENGINEER` minimum | needed for observability table writes (Phase 1 Day 2+) |
| Secret Server access | yes | for retrieving the dbt Cloud service token |

---

## 2. dbt Cloud Service Token

1. Open Secret Server, search for **"dbt job admin service token"**.
2. Copy the token value. **Never paste it into a terminal command** (it lands in shell history). Paste only into the env file (step 4) or VS Code's secret prompt.
3. If you cannot see this secret, ask the DataOps team for access — do not create a new token.

Reference IDs you will need:

| Variable | Value |
|----------|-------|
| `DBT_HOST` | `us1.dbt.com` (BARE cell host — composed with the prefix below into `kl673.us1.dbt.com`; not `cloud.getdbt.com`) |
| `MULTICELL_ACCOUNT_PREFIX` | `kl673` (multi-cell prefix — **REQUIRED**; dbt-mcp composes `<prefix>.<DBT_HOST>`. Omit it and every account-scoped call 404s) |
| `DBT_ACCOUNT_ID` | `173296` |
| `DBT_PROD_ENV_ID` | `296881` |
| `DBT_DEV_ENV_ID` | `287190` (PR runs) |
| `DBT_QA_ENV_ID` | `296453` (PR runs) |
| `DBT_PROD_JOB_ID` | `786800` |
| `DBT_DEV_JOB_ID` | `786806` |
| `DBT_QA_JOB_ID` | `786808` |

---

## 3. Install dbt-mcp

`dbt-mcp` is the MCP server that wraps the dbt Cloud API. It is invoked through `uvx` so you do not pollute a local venv.

```bash
# Smoke test only (will exit after printing schema)
uvx --python 3.13 --from dbt-mcp==1.19.2 dbt-mcp --help
```

You should see usage text. If `uvx` is missing, `brew install uv` then retry.

---

## 4. Configure `.vscode/mcp.json`

> **This file is gitignored** (see `.gitignore` line 162: `.vscode/*`). Every engineer creates it locally — it is **not** checked in and never should be.

Create `/path/to/dbt-datavault/.vscode/mcp.json`:

```jsonc
{
  "servers": {
    "dbt-mcp": {
      "command": "uvx",
      "args": [
        "--python", "3.13",
        "--from", "dbt-mcp==1.19.2",
        "dbt-mcp"
      ],
      "env": {
        "DBT_HOST": "us1.dbt.com",
        "MULTICELL_ACCOUNT_PREFIX": "kl673",
        "DBT_TOKEN": "${input:dbt_cloud_token}",
        "DBT_ACCOUNT_ID": "173296",
        "DBT_PROD_ENV_ID": "296881",
        "DBT_DEV_ENV_ID": "287190",
        "DBT_QA_ENV_ID": "296453",
        "DBT_MCP_ENABLE_ADMIN_API": "true"
      }
    }
  },
  "inputs": [
    {
      "id": "dbt_cloud_token",
      "type": "promptString",
      "description": "dbt Cloud service token (job admin)",
      "password": true
    }
  ]
}
```

> **Env keys** (these mirror what the triage cron composes — see `scripts/automation/src/triage/dbt_cloud_client.py` Decision 2):
> - `DBT_ACCOUNT_ID` is **required** — dbt-mcp's account-scoped Admin API builds `/accounts/{id}/…` URLs. (The cron injects it under this name from `DBT_CLOUD_ACCOUNT_ID`.)
> - `DBT_MCP_ENABLE_ADMIN_API: "true"` scopes the server to the Admin API toolset (`list_jobs_runs`, `get_job_run_error`, …).
> - `DBT_HOST` is the **cell host** `us1.dbt.com` (full subdomain), per the dbt-mcp env-vars reference.
> - `DBT_USER_ID` is **omitted** — it is only needed for the `execute_sql` tool, which the triage cron never calls. Add it locally only if you want to run `execute_sql` from your own VS Code session.

VS Code will prompt for the token on first use and cache it in the OS keychain. **Do not** hard-code the token in this file.

---

## 5. Validation — the 30-minute acceptance test

1. Reload the VS Code window (`Cmd+Shift+P` → "Developer: Reload Window").
2. Open Copilot Chat in **Agent** mode.
3. Verify dbt-mcp tools are loaded — type `#` and look for `mcp_dbt-mcp_*` entries (especially `list_jobs_runs`, `get_job_run_details`, `get_job_run_error`).
4. Run this exact call (paste in chat):

   > Use `mcp_dbt-mcp_list_jobs_runs` with `job_definition_id=786800`, `limit=3`, and order by `id desc`.

5. Expected: JSON listing the 3 most recent PROD runs (run ID, status, duration, finished timestamp).
6. If it fails:
   - **401 / unauthorized** → service token wrong or expired; re-fetch from Secret Server.
   - **404 / job not found** → wrong account/env IDs; re-check section 2.
   - **`mcp_dbt-mcp_*` tools not visible** → mcp.json not loaded; check JSON validity, reload window again.

If step 5 succeeded within 30 minutes from a clean machine, this doc met its acceptance criterion. If it took longer, file a PR against this doc with what slowed you down.

---

## 6. Snowflake side (Phase 1 Day 2+)

The triage agent writes RCA records to **`OPS_PROD.LOGS.*`** (table names TBD in Phase 1, e.g. `DBT_FAILURE_RCA`, `DBT_FAILURE_RCA_REVIEWS`).

**Why `OPS_PROD.LOGS`** (verified 2026-06-03):
- Database owned by `DATA_OPS` — no cross-team governance gating.
- `LOGS` schema already used for append-only event logs (`CERTIFIED_GRANT_LOG`, `DD_CERTIFIED_VIEW_CREATION_LOG`). Exact semantic match for append-only failure-event records.
- Owner: `DATA_OPS` (`OWNERSHIP` privilege confirmed via `INFORMATION_SCHEMA.OBJECT_PRIVILEGES`).
- Rejected alternative: `DATA_GOVERNANCE.OBSERVABILITY` — does not exist; would require Joe's approval to create in a shared governed namespace.

**Required runtime role**: `DATA_OPS`. The agent's Snowflake service account (or service-token-mapped user) must have `DATA_OPS` granted. Engineers querying RCA results interactively should `USE ROLE DATA_OPS;` first.

**Day 2 task**: create the tables under `OPS_PROD.LOGS` via a dbt model or migration script (table DDL ships with Phase 1 — see v2-plan §2). No schema-creation request needed.

---

## 7. Where to go next

- Architecture & PII decisions: `docs/triage-agent/gate-d-findings.md`
- Phase 1 build plan: `docs/triage-agent/v2-plan.md`
- Working branch: `feature/dv-failure-triage-agent`

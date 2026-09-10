---
name: DV Pipeline Handoff
description: "Compact the current pipeline session into a continuation document so a fresh agent can pick up where this one left off."
allowed-tools: "Bash(.venv/bin/python3 *) Read Grep Glob"
paths:
  - "scripts/automation/**"
  - "models/int_staging_views/**"
  - "models/raw_vault/**"
version: 1.0.0
---

# DV Pipeline Handoff

> **Python:** Always use `.venv/bin/python3` — system python3 lacks required packages.

You produce a **handoff document** that captures the current pipeline session state so a fresh agent (or a new conversation) can continue seamlessly. This is different from the orchestrator state file (`.pipeline_state/*.json`) — that captures WHAT was decided. This captures WHY.

**Input**: Current pipeline session (model name, or auto-detected from active state)
**Output**: Markdown handoff document at `scripts/automation/configs/<config_name>/handoff.md`
  (where `<config_name>` is the model name with the leading `v_psa_stg_` prefix stripped —
  matches what `_persist_profile_markdown` writes alongside `profile.md`)

## When to Use

- Context window is filling up (conversation > 80 messages)
- User explicitly requests a handoff (`/handoff`, "save progress", "continue later")
- Session is about to end with incomplete pipeline work
- Switching from one agent to another mid-pipeline

## Workflow

### Step 1: Identify Active Pipeline

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py status
```

If no active state, check for the most recently modified state file:
```bash
ls -lt scripts/automation/.pipeline_state/*.json | head -5
```

If `$ARGUMENTS` is provided, treat as the model name to hand off.

### Step 2: Gather Context

Collect the following from the current session:

1. **Pipeline state** — current phase, steps completed, steps remaining
2. **Decisions made** — design choices (STG-only vs add-raw-vault, domain, grain columns, BK selection)
3. **Decision reasoning** — WHY each choice was made (user preference, data pattern, naming convention)
4. **Blockers encountered** — errors, retries, workarounds applied
5. **Approval status** — which gates have been passed (profile, XLSX, code)
6. **Key file paths** — generated files, config locations, state file
7. **Branch** — current git branch and commit status

### Step 3: Generate Handoff Document

Run the handoff generator:
```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py generate-handoff
```

If the command is not available (older orchestrator version), generate manually using the template below.

### Step 4: Validate and Save

- Verify handoff contains NO secrets (API keys, passwords, tokens, connection strings)
- Verify handoff references files by path, NOT by duplicating content
- Save to `scripts/automation/configs/<model>/handoff.md`

## Handoff Document Template

```markdown
# Pipeline Handoff: <model_name>

**Generated**: <ISO timestamp>
**Branch**: <current branch>
**Agent**: <which agent was running>
**Phase**: <current phase number and name>

## Pipeline Progress

| Step | Status | Completed At |
|------|--------|-------------|
| init | ✅/⏳/❌ | <timestamp> |
| profile | ✅/⏳/❌ | <timestamp> |
| approve-profile | ✅/⏳/❌ | <timestamp> |
| generate-yaml | ✅/⏳/❌ | <timestamp> |
| generate-xlsx | ✅/⏳/❌ | <timestamp> |
| approve-xlsx | ✅/⏳/❌ | <timestamp> |
| generate-code | ✅/⏳/❌ | <timestamp> |
| approve-code | ✅/⏳/❌ | <timestamp> |
| implement | ✅/⏳/❌ | <timestamp> |

## Decisions & Reasoning

| Decision | Choice | Reasoning |
|----------|--------|-----------|
| Raw Vault design | Option A / Option B | <why> |
| Domain | <domain> | <why> |
| Grain columns | <columns> | <why> |
| BK naming | <name> | <why> |
| Volume tier | Normal / Caution / Large | <why> |

## Blockers & Workarounds

<List any errors encountered, retries performed, or workarounds applied>

## Next Steps

1. <Immediate next action for the continuing agent>
2. <Subsequent steps>

## Key Files

| Purpose | Path |
|---------|------|
| State file | `scripts/automation/.pipeline_state/<model>.json` |
| Config YAML | `scripts/automation/configs/<config_name>.yml` (flat file — `generate-yaml` does NOT nest under a per-model directory) |
| Tech spec | `scripts/automation/mappings/v_psa_stg_<config_name>.xlsx` (XLSX lives under `mappings/`, NOT `configs/`) |
| Profile | `scripts/automation/configs/<config_name>/profile.md` (per-model directory — same place handoff.md is written) |
| Generated SQL | `models/int_staging_views/<domain>/<model>.sql` |
| Generated YAML | `models/int_staging_views/<domain>/<model>.yml` |

## Resumption Command

To continue this pipeline, the next agent should run:
\```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py <next_command> [args]
\```
```

## Security Rules

- **NEVER** include credentials, tokens, connection strings, or PII
- **NEVER** duplicate file content — reference by path
- **NEVER** include Snowflake query results (they may contain business data)
- **DO** include column names, counts, and metadata (non-sensitive)
- **DO** redact BKCC values if they appear (use `<BKCC_REDACTED>`)

## STOP Rules

- STOP if handoff contains any credential-like strings (regex: `[A-Za-z0-9+/=]{20,}`)
- STOP if handoff exceeds 500 lines (it should be compact — 50-150 lines typical)
- STOP if no active pipeline state exists and user hasn't specified a model

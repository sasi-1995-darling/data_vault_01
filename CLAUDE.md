## Critical: Python Environment

**ALL automation commands MUST use `.venv/bin/python3`.**
**NEVER** use `python3` or system python — it does NOT have `snowflake-connector-python`.

```bash
# Correct:
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py profile

# Wrong:
python3 scripts/automation/pipeline_orchestrator.py profile
```

# dbt-datavault Project Standards

## Navigation Guide

| Topic | Location |
|-------|----------|
| Architecture, CTE structure, PSA source, env config | `.claude/rules/01-architecture.md` |
| Hash keys, BKCC, ghost records, testing by layer, guardrails | `.claude/rules/02-data-vault-standards.md` |
| Pipeline orchestrator, 3-stage workflow, YAML config | `.claude/rules/03-pipeline-automation.md` |
| Security (credentials, mcp.json, .env) | `.claude/rules/04-security.md` |
| Code review, SQL formatting, CI/CD pipeline | `.claude/rules/05-code-review-standards.md` |
| v_psa_stg SQL patterns | `.github/instructions/v-psa-stg-standards.instructions.md` |
| YAML schema standards | `.github/instructions/yaml-schema-standards.instructions.md` |

> Rules files are auto-loaded by Claude Code based on `paths:` frontmatter.
> This file is the canonical master reference — rules files are focused extracts.

## Project Overview
FBIN Data Vault 2.x on dbt + Snowflake. 2,141+ SQL models across staging, raw vault, business vault, and info mart layers. PSA is the source — all raw data lands in PSA first. dbt 1.5+ with Fusion/static parser.

## Directory Structure
```
models/
  staging/base/          # base_<entity>__<source> — LEGACY (AutomateDV)
  staging/stage/         # stage tables — LEGACY (AutomateDV)
  int_staging_views/     # v_psa_stg_* views (448 models)
  raw_vault/hub/         # hub_* incremental (151 models)
  raw_vault/sat/         # sat_*, lsat_*, msat_*, esat_* (388 models)
  raw_vault/link/        # lnk_*, tlink_* incremental (115 models)
  bus_vault/             # pit_*, pb_*, dim_*, fact_*, ref_*, flat_logic
  info_mart/<domain>/    # rpt_*, rep_*, fact_*, im_*
tests/                   # Singular tests: pk_, de_, dt_, c_, u_, v_, t_, re_
macros/                  # 9 DQ macros + utilities
seeds/                   # Reference data seeds
```

## Table Naming — see `01-architecture.md` for full table

| Layer | Prefix | Materialization |
|-------|--------|----------------|
| Int staging | `v_psa_stg_` | view |
| Hub | `hub_` | incremental |
| Satellite | `sat_`, `lsat_`, `msat_`, `esat_` | incremental |
| Link | `lnk_`, `tlink_` | incremental |
| PIT / PB | `pit_`, `pb_` | table |
| Dim / Fact | `dim_`, `fact_` | view |
| Reference | `ref_` | table |

## Column Naming — see `02-data-vault-standards.md` for hash formulas
- UPPERCASE columns in SQL: `_HK` (hash key), `_BK` (business key), `LNK_` (link HK prefix)
- Standard columns: `BKCC`, `LOAD_DTS`, `REC_SRC`, `HASHDIFF`

## Volume Tier Configuration
| Volume Tier | Row Count | Actions |
|-------------|-----------|---------|
| **Normal** | < 50M | Standard v_psa_stg view |
| **Caution** | 50M–300M | `cluster_by: [<BK>]`, SQL header comment |
| **Large** | > 300M | `large_volume: true`, `cluster_by`, `full_refresh = false`, INCR_WATERMARK pattern |

## CI/CD Summary
GitHub Actions + dbt Cloud API. PR flow: DEV (job 786806) → QA (job 786808, PR-isolated schema) → PROD (job 786800, auto-merge). See `05-code-review-standards.md` for details.

## Security — see `04-security.md`
**NEVER** read/display credentials from mcp.json, .env, or config files. **NEVER** paste tokens into terminal commands.

## Design Decision Delegation — MANDATORY

You MUST NEVER make design decisions on behalf of the user. Specifically:

1. **Raw Vault Design Decision**: When the orchestrator prints the Raw Vault
   Design Decision prompt (Option A: STG-only, Option B: add-raw-vault),
   you MUST show the FULL prompt to the user and ask which option they want.
   Do NOT assume "STG-only" because the user "only asked for a v_psa_stg."
   The user may want to add Raw Vault objects — that is THEIR decision.

2. **Approval Gates**: When running approve-profile, approve-xlsx, or
   approve-code, you MUST show the relevant output (profile summary,
   XLSX validation results, generated SQL) to the user FIRST, then ask
   for explicit approval before running the approve command.

3. **Domain Selection**: When running implement --domain, ask the user
   which domain folder to use. Do NOT guess from the schema or table name.

4. **Model Naming**: When the user provides a table name, confirm the
   model name (v_psa_stg_<entity>__<source>) before running init.
   Do NOT auto-derive without confirmation.

**The rule is simple: if the orchestrator presents a choice, YOU present
that choice to the user. You are a facilitator, not a decision-maker.**

**Maintenance**: This block is duplicated across all agent files intentionally (lesson #107). Do not remove "duplicates."

## Guardrails — see `02-data-vault-standards.md`
No direct raw vault edits. No hardcoded BKCC. No `SELECT DISTINCT` (use QUALIFY). `CONVERT_TIMEZONE('UTC', ...)` for timestamps. `'1900-01-01'::TIMESTAMP` for NULL dates.

## Lessons Learned
- Add lessons to `scripts/automation/lessons.md` in the `## Proposed` section
- DataOps lead reviews and moves Proposed → Approved
- Agent ONLY follows lessons from `## Approved` section
- Review lessons at the start of every generation session

## Skills

| Skill | Location |
|-------|----------|
| v_psa_stg generator | `.github/skills/v-psa-stg-generator/` |
| Raw Vault generator | `.github/skills/dv-raw-vault-generator/` |
| Tech Design Creator | `.github/skills/dv-tech-design-creator/` |
| Code Implementer | `.github/skills/dv-code-implementer/` |
| Conventional Commit | `.github/skills/conventional-commit/` |
| Code Reviewer | `.github/skills/dv-code-reviewer/` |
| Modeling Advisor (conceptual design) | `.github/skills/dv-modeling-advisor/` |
| DV 2.x Knowledge Base | `.github/knowledge/data-vault/` |
| dbt-labs skills (7) | `.agents/skills/` |

All FBIN skills support: `$ARGUMENTS`, `context: fork`, `paths`, `allowed-tools`.

**Skill precedence**: CLAUDE.md/rules standards override generic dbt-labs skill advice.

### Skill & Agent Sync
- `.github/skills/` is **canonical** — never edit `.claude/skills/` directly
- After editing: `bash scripts/sync_skills.sh && git add .claude/skills/`
- CI blocks PRs if skills diverge (`.github/workflows/skill-sync-check.yaml`)

### Agents

Agent files live ONLY in `.github/agents/` (canonical). `.claude/agents/` was
removed — VS Code Copilot discovers agent frontmatter in all `.md` files and
would show duplicates if copies existed there.

| Agent | Purpose | Location |
|-------|---------|----------|
| Pipeline Coordinator | 3-stage orchestration | `.github/agents/dv-pipeline-coordinator.agent.md` |
| Source Analyzer | Stage 1: Profile + YAML | `.github/agents/dv-source-analyzer.agent.md` |
| Model Generator | Stage 2: Code gen | `.github/agents/dv-model-generator.agent.md` |
| Validator | Stage 3: Compile/test | `.github/agents/dv-validator.agent.md` |
| Knowledge Advisor | Conceptual modeling: explain/advise/review (read-only) | `.github/agents/dv-knowledge-advisor.agent.md` |

### Hooks

| Hook Type | Script | Purpose |
|-----------|--------|---------|
| `PreToolUse` | `scripts/automation/hooks/pre_tool_guard.py` | Blocks direct model writes |
| `PostToolUse` | `scripts/automation/hooks/post_write_compile_check.sh` | Auto-compiles .sql |
| `SessionStart` | `scripts/automation/hooks/session_start_digest.sh` | Loads lessons + state |
| `Stop` | `scripts/automation/hooks/session_stop_summary.sh` | Session summary |

## Pipeline Enforcement — see `03-pipeline-automation.md`

All v_psa_stg generation **MUST** use the pipeline orchestrator:
```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py <command>
```
Direct SQL/YAML/XLSX generation is **prohibited**. See `03-pipeline-automation.md` for the 3-stage workflow and key files.

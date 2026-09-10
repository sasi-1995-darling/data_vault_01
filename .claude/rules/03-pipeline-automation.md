---
paths:
  - "scripts/automation/**"
  - ".github/skills/**"
  - ".claude/skills/**"
---

# Pipeline Automation Rules

## Pipeline Enforcement
All v_psa_stg model generation **MUST** go through the pipeline orchestrator:

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py <command>
```

Direct SQL/YAML/XLSX generation is **prohibited**. The orchestrator enforces step
ordering, automatic validation (21 XLSX checks), and user approval gates.

## 3-Stage Workflow with Approval Gates

```
Stage 1: Tech Design Creator (dv-source-analyzer agent)
  → Profile source, validate BK, detect flags, produce YAML config
  → Output: scripts/automation/configs/<entity>__<source>.yml
  → STOP: User reviews

Stage 2: Code Generator (dv-model-generator agent)
  → Read YAML config, run deterministic Python pipeline
  → python src/main.py --yaml-config <config.yml>
  → Output: SQL + YAML + source entry

Stage 3: Code Implementer (dv-validator agent)
  → Place files, register source, compile, build, test, commit
  → Output: Files on feature branch, ready for PR
```

## Key Pipeline Files
- **Pipeline orchestrator**: `scripts/automation/pipeline_orchestrator.py` (state machine)
- Pipeline coordinator: `.github/agents/dv-pipeline-coordinator.agent.md`
- YAML→dict bridge: `scripts/automation/src/yaml_reader.py`
- SQL code generator: `scripts/automation/src/build.py`
- YAML schema generator: `scripts/automation/src/make_yml.py`
- YAML config schema: `.github/skills/v-psa-stg-generator/input-schema.yml`

## XLSX as Source of Truth
The XLSX tech spec is the authoritative design document. The orchestrator:
1. Generates YAML config from profiled data
2. Generates XLSX from YAML config
3. Validates XLSX against 21+ automated checks
4. User reviews and approves XLSX before code generation
5. Code generator reads XLSX (via `sheets.py` dict-based lookup) to produce SQL

## Volume Tier Configuration
v_psa_stg models are VIEWs — volume config is stored in YAML `_pipeline_metadata`.

| Volume Tier | Row Count | Config Actions |
|-------------|-----------|----------------|
| **Normal** | < 50M | No special config. Standard v_psa_stg view. |
| **Caution** | 50M–300M | `cluster_by: [<BK_COLUMN>]`. SQL header comment. Downstream: `tags = ['materialization_override', 'large_volume', '<object_type>']` |
| **Large** | > 300M | `large_volume: true`, `cluster_by: [<BK_COLUMN>]`. Downstream: `full_refresh = false`, `on_schema_change = 'append_new_columns'`. Hub gets INCR_WATERMARK pattern. |

## NEVER Generate SQL Directly
If a user asks to create a v_psa_stg model, hub, link, or satellite, your first action is ALWAYS:
```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py init \
  --schema <SCHEMA> --table <TABLE> \
  --bk "<BK>" --bk-name "<ENTITY_BK>" \
  --rec-src "<REC_SRC>" --model-name "<MODEL_NAME>"
```

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
   for explicit approval before running the approve command with --reviewed.

3. **Domain Selection**: When running implement --domain, ask the user
   which domain folder to use. Do NOT guess from the schema or table name.

4. **Model Naming**: When the user provides a table name, confirm the
   model name (v_psa_stg_<entity>__<source>) before running init.
   Do NOT auto-derive without confirmation.

**The rule is simple: if the orchestrator presents a choice, YOU present
that choice to the user. You are a facilitator, not a decision-maker.**

## Lessons Learned Governance
- Lessons file: `scripts/automation/lessons.md`
- After ANY bug fix or pattern correction, add to `## Proposed` section
- Only `## Approved` lessons are active — agent ignores Proposed
- Governance: Proposed → Approved requires DataOps lead approval via PR

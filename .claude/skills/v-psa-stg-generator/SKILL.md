---
name: v-psa-stg-generator
description: >
  Generates v_psa_stg (PSA staging view) SQL and YAML files for Data Vault 2.x
  using the pipeline orchestrator. Use when user says "generate v_psa_stg",
  "create staging view", "new PSA staging model", "model this source table",
  or provides a source table name for modeling.
  Do NOT use for raw vault (hub/sat/link), business vault, or info mart models.
disable-model-invocation: true
context: fork
paths:
  - "models/int_staging_views/**"
  - "scripts/automation/**"
arguments: "$ARGUMENTS contains SCHEMA.TABLE if provided (e.g., SHOPIFY_MOEN.FULFILLMENT)"
metadata:
  author: FBIN Data Engineering
  version: 3.2.0
  category: data-vault
---

# v_psa_stg Generator

> **Lessons:** Read `scripts/automation/lessons.md` before starting.
> **Python:** Always use `.venv/bin/python3` — system python3 lacks required packages.
> These are validated patterns from 50+ integration tests and 29 bug fixes.

## CRITICAL: Always Use the Pipeline Orchestrator

**NEVER** generate SQL, YAML configs, or XLSX tech specs directly.
**ALWAYS** use the pipeline orchestrator:

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py <command>
```

The orchestrator enforces step ordering and prevents skipping STOP gates.
It refuses to run a step if prerequisites are not met — this is by design.

## ⛔ NEVER make design decisions for the user
When the orchestrator presents a choice (Raw Vault design decision,
domain selection, model naming), show the choice to the user and wait
for their response. Do NOT auto-choose.

## Workflow

```
init → profile → approve-profile → generate-yaml → generate-xlsx
     → approve-xlsx → generate-code → approve-code → implement → done
```

### 1. Initialize

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py init \
  --schema <SCHEMA> --table <TABLE> \
  --bk "<BK_COLUMN>" --bk-name "<ENTITY_BK>" \
  --hk "ENTITY_HK:BK_COL,BKCC" \
  --hk "PARENT_HK:FK_COL,BKCC" \
  --hk "LNK_ENTITY_PARENT_HK:@ENTITY_HK,@PARENT_HK" \
  --rec-src "<Location.System.Application.Table>" \
  --model-name "v_psa_stg_<entity>__<source>"
```

### Hash Key Definitions (--hk)

When the user specifies hash keys in their prompt, map each to a `--hk` flag on init.

**User prompt format:**
```
SUBSCRIPTION_HK : ID, BKCC
SUBSCRIBER_HK : SUBSCRIBER_ID, BKCC
LNK_SUBSCRIBER_SUBSCRIPTION_HK: SUBSCRIBER_ID, ID, BKCC
```

**Mapped to init flags:**
```bash
--hk "SUBSCRIPTION_HK:ID,BKCC" \
--hk "SUBSCRIBER_HK:SUBSCRIBER_ID,BKCC" \
--hk "LNK_SUBSCRIBER_SUBSCRIPTION_HK:@SUBSCRIBER_HK,@SUBSCRIPTION_HK"
```

The link HK maps to the participating **hub HKs** via the `@`-sigil, not the raw keys
the user listed: `SUBSCRIBER_ID → @SUBSCRIBER_HK`, `ID → @SUBSCRIPTION_HK` (#1907).

**Format:** `--hk "HK_NAME:COL1,COL2,..."` (repeatable)

**Rules:**
- HK name before colon, input columns after (comma-separated)
- BKCC should be included for hub HKs (names NOT starting with LNK_)
- **Link HKs** (names starting with `LNK_`) compose from the participating **hub HK
  columns** via the `@`-sigil (`@HUB1_HK,@HUB2_HK`), NOT raw columns, and carry **no
  BKCC** — each hub HK already embeds its own (DV 2.1, #1907). Map each raw key the user
  lists to the hub HK that hashes it. A raw-column `LNK_` declaration (no `@`) is the
  legacy form and yields a non-DV-2.1 link HK that does not unify across sources.
- Column order matters — it defines the hash value
- The `--hk` flag is repeatable: one per hash key definition

**Recognition patterns — map these user inputs to --hk:**
- `SUBSCRIPTION_HK : ID, BKCC` → `--hk "SUBSCRIPTION_HK:ID,BKCC"`
- `Hash : ID, BKCC as SUBSCRIPTION_HK` → `--hk "SUBSCRIPTION_HK:ID,BKCC"`
- `HK: SUBSCRIPTION_HK = MD5(ID, BKCC)` → `--hk "SUBSCRIPTION_HK:ID,BKCC"`
- Any line with `_HK` and a colon/equals with column names → `--hk`

**CRITICAL:** If the user's prompt contains ANY hash key definitions (lines with
`_HK` and column lists), you MUST include `--hk` flags on init. Dropping them
silently causes downstream failures in YAML/XLSX/code generation.

### Adding Hash Keys After Init

If hash keys were missed during init, add them at profile time:
```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py profile \
  --hk "SUBSCRIPTION_HK:ID,BKCC" \
  --hk "SUBSCRIBER_HK:SUBSCRIBER_ID,BKCC"
```
This updates the pipeline state without re-running init.

### 2. Profile Source

Snowflake connection priority:
1. **MCP tools** — if snow-mcp is available in agent tool set, use it for queries
2. **Orchestrator built-in** — reads .vscode/mcp.json creds automatically
3. **`--profile-json`** — offline fallback with pre-computed results

```bash
# With Snowflake access (orchestrator reads mcp.json automatically):
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py profile

# Without Snowflake (terminal-only):
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py profile \
  --profile-json path/to/profile.json
```

### 3. Review Profile

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py show-profile
```

Present results to user. Wait for confirmation of BK, entity name, domain.

### 4. Approve Profile

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py approve-profile
```

### 5. Generate YAML Config

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py generate-yaml
```

### 6. Generate XLSX + Auto-Validate

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py generate-xlsx
```

This automatically runs `validate_tech_spec.py` (21 DV 2.x compliance checks).
If any check fails, the step exits non-zero and is NOT recorded as complete.

Tell user to review the XLSX. Wait for approval.

### 7. Approve XLSX

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py approve-xlsx
```

### 8. Generate Code (Stage 2)

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py generate-code
```

Show generated SQL/YAML to user. Wait for approval.

### 9. Approve Code

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py approve-code
```

### 10. Implement (Stage 3)

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py implement --domain <folder>
```

Runs: place files → dbt compile → dbt run → dbt test → report.

### 11. Check Status (anytime)

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py status
```

## Quick Reference

### Re-run a Failed Step
Just run the same command again after fixing the issue. The orchestrator is idempotent.

### Start Over
Delete the state file:
```bash
rm scripts/automation/.pipeline_state/<model_name>.json
```

### Reset to a Specific Step
```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py reset <step_name>
```

### File Placement
| File | Directory |
|------|-----------|
| `v_psa_stg_*.sql` | `models/int_staging_views/<domain>/` |
| `v_psa_stg_*.yml` | `models/int_staging_views/<domain>/` |
| Source entry | `models/sources/_sources_staging_psa.yml` |

### Common Domains
procurement, item, order, invoice, supplier, customer, pricing, shipments,
consumer_feedback, connected_device, pos, competitive_pricing, direct_spend

## STOP Conditions (enforced by orchestrator)

The orchestrator **will not proceed** past these gates without the prerequisite steps:

| Gate | Requires |
|------|----------|
| `generate-yaml` | `approve-profile` (BK/entity confirmed) |
| `generate-code` | `approve-xlsx` (XLSX reviewed by user) |
| `implement` | `approve-code` (generated SQL/YAML reviewed) |


## ⛔ ADD-SOURCE Approval Gate

When the orchestrator detects ADD-SOURCE for an existing hub or link during
Raw Vault design (after `approve-xlsx`), you MUST stop and present the user
with a choice:

```
The parent hub `hub_<entity>` already exists. Adding this source requires
modifying the existing hub model (ADD-SOURCE injection).

Options:
  A) Include hub ADD-SOURCE in this pipeline (modifies existing hub model)
  B) Build SAT/MSAT only — defer hub ADD-SOURCE to a separate run

Which approach?
```

Do NOT auto-select either option. Wait for the user's explicit response.

If the user selects (B), pass `--skip-hub` to the implement step —
this excludes the hub from the build selector.

### Anti-pattern: Auto-injecting ADD-SOURCE

NEVER automatically inject ADD-SOURCE into an existing hub or link model without
explicit user approval. Even if the detection says "safe surgical path", the user
must approve scope changes that modify existing production models.

This applies to:
- Hub ADD-SOURCE (adding a new source to an existing hub)
- Link ADD-SOURCE (adding a new source to an existing link)
- Any modification to an existing Raw Vault model

## Common Mistakes (from 38 lessons learned)

| Mistake | Correct Approach |
|---------|-----------------|
| **Generating SQL/YAML/XLSX directly** | **Use the pipeline orchestrator** — it enforces all gates |
| Using BK alias in HK formula | Use raw source column names |
| Auto-selecting BK without user confirmation | Propose candidates, user must confirm |
| Excluding PSA_DELETE_IND from HASHDIFF | PSA_DELETE_IND is data, not metadata |
| Excluding _FIVETRAN_DELETED from HASHDIFF | _FIVETRAN_DELETED is data |
| Missing BKCC in hash key | BKCC must be last component in ANY HK |
| Adding QUALIFY in FINAL layer | **PROHIBITED** — fix upstream in SRC CTE |
| Filtering on `_FIVETRAN_DELETED` or `PSA_DELETE_IND` | **NEVER** filter deletes at staging |
| Adding standalone `unique` test on BK | PSA is append-only; BK is not unique |
| **Dropping --hk flags from init** | **If user specifies _HK definitions, map ALL to --hk flags** |

## Reference Files

```
references/
  cte-patterns.md           — 4-layer CTE template with examples
  hash-key-formulas.md      — HK, HASHDIFF, LNK_HK formulas
  hashdiff-rules.md         — Definitive inclusion/exclusion rules
  bkcc-reference.md         — OpCo mappings, registration workflow
  lookup-join-patterns.md   — LEFT/INNER join patterns
  qualify-dedup-patterns.md — Pattern A/B/C examples
```

## Self-Improvement

Review `scripts/automation/lessons.md` before each generation. **Only follow lessons from the
`## Approved` section** — the `## Proposed` section contains unverified findings
pending DataOps lead review.

## STOP if you're about to:
- Write SQL directly without running the pipeline orchestrator
- Skip the XLSX review step
- Modify generated code instead of fixing the generator
- Use `{{ source() }}` instead of `{{ ref() }}` for cross-staging references
- Remove columns from the payload (100% data rule)
- Set LOAD_DTS from a business date instead of system timestamp

## Python Environment

**ALWAYS** use `.venv/bin/python3` for ALL automation commands.
**NEVER** use system `python3` — it does NOT have `snowflake-connector-python`.

```bash
# Correct:
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py profile

# Wrong:
python3 scripts/automation/pipeline_orchestrator.py profile
```

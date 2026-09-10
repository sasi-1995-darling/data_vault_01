---
applyTo: "**/*"
---

## Python Environment

**Always use `.venv/bin/python3`** for ALL `scripts/automation/` commands.
System `python3` does NOT have `snowflake-connector-python`.

## Pipeline Enforcement

**NEVER** generate v_psa_stg SQL, YAML config, or XLSX tech spec files directly.
Always use the pipeline orchestrator:

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py <command>
```

## Design Decision Delegation — MANDATORY

You MUST NEVER make design decisions on behalf of the user. Specifically:

1. **Raw Vault Design Decision**: Show the FULL prompt (Option A/B) and ask.
2. **Approval Gates**: Show output FIRST, then ask for explicit approval.
3. **Domain Selection**: Ask the user — do NOT guess.
4. **Model Naming**: Confirm `v_psa_stg_<entity>__<source>` before running init.

**If the orchestrator presents a choice, YOU present that choice to the user.**

## Session Hygiene

- One pipeline run = one session. Start fresh for each new model.
- Break complex tasks into focused requests (15-25 messages max per session).
- If an approach fails after 3 attempts, stop and rephrase — do not loop.
- Use `/commands` (check-status, compile-model, etc.) instead of verbose prompts.

---

## Quick Reference (full detail in scoped instruction files)

### Naming
- Columns: UPPERCASE (`CUSTOMER_BK`, `INVOICE_HK`, `LNK_PO_ITEM_HK`)
- Tables: lowercase (`hub_customer`, `sat_po_header__winn_sap`)
- Prefixes: `v_psa_stg_` | `hub_` | `sat_`/`lsat_`/`msat_`/`esat_` | `lnk_`/`tlink_` | `pit_`/`pb_` | `dim_`/`fact_` | `ref_` | `rpt_`/`rep_`/`im_`

### CTE Pattern
- New models: `SRC → LOGIC → JOIN → FINAL` (4-layer)
- Legacy models: 6-layer (do NOT convert)

### Hash Keys
- HK: `MD5_BINARY(UPPER(CONCAT_WS('||', COALESCE(NULLIF(TRIM(CAST(raw_col AS VARCHAR)),''),'^^'), ..., BKCC_last)))`
- HASHDIFF: `MD5_BINARY(UPPER(NULLIF(CONCAT(IFNULL(TRIM(col::text),'^^'),'||',...), '^^||^^')))`
- HK uses raw column names (not aliases); BKCC always last component
- HASHDIFF includes: `PSA_DELETE_IND`, `_FIVETRAN_DELETED`, `GLDELFLAG`
- HASHDIFF excludes: HK, BK, BKCC, REC_SRC, LOAD_DTS, `_FIVETRAN_ID`, `_FIVETRAN_SYNCED`, `PSA_LOAD_DTS`, grain cols, `GLREQUEST`, `GLSOURCESYSTEM`, `GLCHANGETIME`

### BKCC
- 1:1 with business concept; join via `INNER JOIN SRC_BKCC ON '1' = '1'`
- Register BKCC + REC_SRC in DEV via Streamlit before `dbt build`
- REC_SRC format: `Location.System.Application.Table` (e.g., `USOHNO.SAP.ECCPRD.Z_EKPO`)

### LOAD_DTS Derivation
- Fivetran: `CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)`
- SNP GLUE: `IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ(SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16), 'YYYYMMDDHH24MISS.FF9')))`
- Other: `CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)`

### Dates
- NULL dates → `'1900-01-01'::TIMESTAMP`; always `CONVERT_TIMEZONE('UTC', ...)`

### Testing (by layer)
- v_psa_stg: `not_null` on BK + `unique_combination_of_columns` on BK + LOAD_DTS. Use `data_tests:`
- Raw vault: `dbt_constraints.primary_key` + `foreign_key` + `expect_table_row_count_to_be_between` (min: 4)
- Business vault tables: PK constraints + metrics tests
- DIM/FACT views: QA team owns singular tests — do not duplicate
- `rep_` models: No tests needed

### Guardrails
- No `SELECT DISTINCT` — use QUALIFY with ROW_NUMBER()
- No business logic in DIM/FACT — logic belongs in PIT/PB
- No direct raw vault edits — use pipeline orchestrator
- No hardcoded BKCC — use REF_BUSINESS_KEY_COLLISION

---

## Scoped Instruction Files (loaded on file match)

| Scope | File |
|-------|------|
| v_psa_stg models | `.github/instructions/v-psa-stg-standards.instructions.md` |
| YAML schemas | `.github/instructions/yaml-schema-standards.instructions.md` |
| Hub models | `.github/instructions/raw-vault-hub.instructions.md` |
| Satellite models | `.github/instructions/raw-vault-sat.instructions.md` |
| Link models | `.github/instructions/raw-vault-link.instructions.md` |
| Business vault | `.github/instructions/bus-vault.instructions.md` |
| Info mart | `.github/instructions/info-mart.instructions.md` |

## Skills & Automation

| Purpose | Location |
|---------|----------|
| v_psa_stg generation | `.github/skills/v-psa-stg-generator/` |
| Raw Vault generation | `.github/skills/dv-raw-vault-generator/` |
| Source profiling | `.github/skills/dv-tech-design-creator/` |
| Compile + test | `.github/skills/dv-code-implementer/` |
| Code review | `.github/skills/dv-code-reviewer/` |
| Commit messages | `.github/skills/conventional-commit/` |
| Conceptual modeling guidance | `.github/skills/dv-modeling-advisor/` |
| DV 2.x modeling knowledge base | `.github/knowledge/data-vault/` |

Skills: `.github/skills/` is canonical — never edit `.claude/skills/` directly.
Sync after edits: `bash scripts/sync_skills.sh`

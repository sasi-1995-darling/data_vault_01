# Structured Prompt Guide — Data Vault Automation

> **Agent**: Select **"DV Pipeline Coordinator"** from the Copilot Chat agent
> dropdown before pasting these prompts. The Coordinator parses your request,
> confirms parameters, and orchestrates the full pipeline.

> Copy-paste these templates into Copilot Chat / Claude Code to drive the pipeline.
> All commands use `.venv/bin/python3 scripts/automation/pipeline_orchestrator.py`.

---

## Table of Contents

1. [v_psa_stg Pipeline (Single Table)](#v_psa_stg-pipeline-single-table)
2. [v_psa_stg Pipeline (Multi-Table / Lookup Join)](#v_psa_stg-pipeline-multi-table--lookup-join)
3. [v_psa_stg + Raw Vault (Hub / Link / SAT)](#v_psa_stg--raw-vault-hub--link--sat)
4. [Adding Raw Vault to an Existing STG Pipeline](#adding-raw-vault-to-an-existing-stg-pipeline)
5. [Full DV Pipeline (Hub/Sat/Link/PB/Fact)](#full-dv-pipeline-hubsatlinkpbfact)
6. [Pipeline Commands Reference](#pipeline-commands-reference)
7. [Common Patterns & Gotchas](#common-patterns--gotchas)

---

## v_psa_stg Pipeline (Single Table)

For single-source v_psa_stg staging views:

```
Source table: PSA_PROD.<SCHEMA>.<TABLE>
Entity name: <entity_name>  (e.g., po_item, customer, supplier)
Source system: <source_system>  (e.g., sap_ecc, emtk_ebs, tt_gp)
Business key columns: <col1>, <col2>  (raw source column names)
REC_SRC: <Location.System.Application.Table>  (e.g., USOHNO.SAP.ECCPRD.Z_EKPO)
Domain: <domain>  (e.g., procurement, item, supplier — or "auto" to infer)
```

### CLI Equivalent

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py init \
  --schema <SCHEMA> --table <TABLE> \
  --bk "<BK_COLUMNS>" --bk-name "<ENTITY_BK>" \
  --rec-src "<REC_SRC>" --model-name "v_psa_stg_<entity>__<source>"
```

### Single-Table Examples

**Simple (single BK, no lookups)**:
```
Source table: PSA_PROD.SAP_ECC_PRD.Z_T001
Entity name: company_code
Source system: winn_sap
Business key columns: BUKRS
REC_SRC: USOHNO.SAP.ECCPRD.Z_T001
Domain: legal_entity
```

**Quick one-liner**:
```
Generate v_psa_stg for PSA_PROD.SAP_ECC_PRD.Z_EKPO with BK=EBELN+EBELP, REC_SRC=USOHNO.SAP.ECCPRD.Z_EKPO
```

---

## v_psa_stg Pipeline (Multi-Table / Lookup Join)

When a staging view needs columns from a **secondary (lookup) table**, use these
additional parameters. The pipeline handles column collision detection, auto-renaming,
BK validation, and QUALIFY dedup on the secondary source.

```
Source table: PSA_PROD.<SCHEMA>.<TABLE>
Entity name: <entity_name>
Source system: <source_system>
Business key columns: <col1>  (driver table BK)
REC_SRC: <Location.System.Application.Table>
Domain: <domain>

Secondary table: <SECONDARY_TABLE>
Secondary schema: <SCHEMA>  (optional — defaults to driver schema)
Join type: LEFT JOIN | INNER JOIN  (default: LEFT JOIN)
Join predicate: <DRIVER_COL> = <ALIAS>.<CHILD_COL>  (e.g., ORDER_ID = ORD.ID)
Secondary columns: <COL1> <COL2> ...  (columns to pull from lookup)
Secondary BK: <expression>  (e.g., COALESCE(ORD_NAME, '-1'))
Secondary BK name: <BK_NAME>  (e.g., ORDER_HEADER_BK)
```

### CLI Equivalent

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py init \
  --schema <SCHEMA> --table <TABLE> \
  --bk "<BK>" --bk-name "<ENTITY_BK>" \
  --rec-src "<REC_SRC>" --model-name "v_psa_stg_<entity>__<source>" \
  --secondary-table <SECONDARY_TABLE> \
  --secondary-schema <SCHEMA> \
  --join-type "LEFT JOIN" \
  --join-on "<DRIVER_COL> = <ALIAS>.<CHILD_COL>" \
  --secondary-columns <COL1> <COL2> \
  --secondary-bk "<BK_EXPRESSION>" \
  --secondary-bk-name "<BK_NAME>"
```

### Multi-Table Examples

**Fulfillment + Order lookup (Shopify)**:
```
Source table: PSA_PROD.SHOPIFY_MOEN.FULFILLMENT
Entity name: dtc_fulfillment
Source system: winn_shopify
Business key columns: ID
REC_SRC: US.SHOPIFY_MOEN.FULFILLMENT
Domain: shipments

Secondary table: ORDER
Secondary schema: SHOPIFY_MOEN
Join type: LEFT JOIN
Join predicate: ORDER_ID = ORD.ID
Secondary columns: ID NAME
Secondary BK: COALESCE(ORD_NAME, '-1')
Secondary BK name: ORDER_HEADER_BK
```

**PO Item + Vendor lookup (SAP)**:
```
Source table: PSA_PROD.SAP_ECC_PRD.Z_EKPO
Entity name: po_item
Source system: winn_sap
Business key columns: EBELN, EBELP
REC_SRC: USOHNO.SAP.ECCPRD.Z_EKPO
Domain: procurement

Secondary table: Z_LFA1
Join type: LEFT JOIN
Join predicate: LIFNR = LFA.LIFNR
Secondary columns: LIFNR NAME1 LAND1
Secondary BK name: SUPPLIER_BK
Secondary BK: TO_CHAR(LFA_LIFNR)
```

### How Multi-Table Works Behind the Scenes

1. **Profile** profiles both driver AND secondary tables in Snowflake
2. **Column collision detection**: If both tables share column names (e.g., `ID`, `NAME`),
   the secondary columns are auto-prefixed with the alias (e.g., `ID` → `ORD_ID`, `NAME` → `ORD_NAME`)
3. **BK validation** (lesson #92): The `--secondary-bk` expression is validated against the
   **post-rename** column set — you must reference renamed columns, not originals
4. **QUALIFY dedup**: Secondary source automatically gets `QUALIFY ROW_NUMBER() OVER(PARTITION BY <join_col> ORDER BY <timestamp> DESC) = 1`
5. **Source name resolution**: Reserved-word table names (e.g., `ORDER`) are resolved from
   `_sources_staging_psa.yml` to preserve exact case for `source()` calls

### Multi-Table Gotchas

| Issue | Cause | Fix |
|-------|-------|-----|
| `Secondary BK references 'NAME'` error | Column was renamed to `ORD_NAME` due to collision | Use `ORD_NAME` in `--secondary-bk` |
| `source('schema', 'order')` compile error | Table name is `ORDER` (uppercase) in source YAML | Pipeline auto-resolves from `_sources_staging_psa.yml` |
| Missing columns in secondary | `--secondary-columns` not specified | Omit to get interactive column picker prompt |
| Wrong QUALIFY partition | Join predicate format wrong | Use `DRIVER_COL = ALIAS.CHILD_COL` format |

---

## v_psa_stg + Raw Vault (Hub / Link / SAT)

Generate all objects in a single pipeline run:

```
Source table: PSA_PROD.<SCHEMA>.<TABLE>
Entity name: <entity_name>
Source system: <source_system>
Business key columns: <BK_COLUMNS>
REC_SRC: <Location.System.Application.Table>
Domain: <domain>
Objects: stg, hub, lnk, sat

Link name: <link_name>  (e.g., order_fulfillment)
Parent HKs: <HK1>,<HK2>  (e.g., FULFILLMENT_HK,ORDER_HEADER_HK)
SAT type: sat | lsat | msat  (lsat if parent is a link)
SAT parent HK: <PARENT_HK>  (e.g., LNK_ORDER_FULFILLMENT_HK)
SAT parent model: <parent_model>  (e.g., lnk_order_fulfillment)
```

### CLI Equivalent

```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py init \
  --schema <SCHEMA> --table <TABLE> \
  --bk "<BK>" --bk-name "<ENTITY_BK>" \
  --rec-src "<REC_SRC>" --model-name "v_psa_stg_<entity>__<source>" \
  --objects "stg,hub,lnk,sat" \
  --lnk-name "<link_name>" \
  --parent-hks "<HK1>,<HK2>" \
  --sat-type lsat \
  --sat-parent-hk "<PARENT_HK>" \
  --sat-parent-model "<parent_model>"
```

### Full Pipeline Example (Multi-Table + Raw Vault)

```bash
# Fulfillment pipeline: v_psa_stg + hub + lnk + lsat (with ORDER lookup)
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py init \
  --schema SHOPIFY_MOEN --table FULFILLMENT \
  --bk "ID" --bk-name "FULFILLMENT_BK" \
  --rec-src "US.SHOPIFY_MOEN.FULFILLMENT" \
  --model-name "v_psa_stg_dtc_fulfillment__winn_shopify" \
  --objects "stg,hub,lnk,sat" \
  --lnk-name "order_fulfillment" \
  --parent-hks "FULFILLMENT_HK,ORDER_HEADER_HK" \
  --sat-type lsat \
  --sat-parent-hk "LNK_ORDER_FULFILLMENT_HK" \
  --sat-parent-model "lnk_order_fulfillment" \
  --secondary-table ORDER \
  --secondary-schema SHOPIFY_MOEN \
  --join-type "LEFT JOIN" \
  --join-on "ORDER_ID = ORD.ID" \
  --secondary-columns ID NAME \
  --secondary-bk "COALESCE(ORD_NAME, '-1')" \
  --secondary-bk-name "ORDER_HEADER_BK"
```

Then step through:
```bash
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py profile --profile-json <profile.json>
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py approve-profile
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py generate-yaml
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py generate-xlsx
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py approve-xlsx
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py generate-code
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py approve-code
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py implement --domain <DOMAIN> --skip-build
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py build-all
```

---

## Adding Raw Vault to an Existing STG Pipeline

If you already completed a STG-only pipeline and want to add hub/lnk/sat later:

```bash
# Add Raw Vault objects (resets from generate-yaml onward)
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py add-raw-vault \
  --objects "hub,lnk,sat" \
  --lnk-name "<link_name>" \
  --parent-hks "<HK1>,<HK2>" \
  --sat-type lsat \
  --sat-parent-hk "<PARENT_HK>" \
  --sat-parent-model "<parent_model>"

# Then re-run from generate-yaml
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py generate-yaml
# ... continue through approve-code → implement
```

**Note**: `add-raw-vault` surgically resets the pipeline from `generate-yaml` onward
because YAML config and XLSX tech specs need hub/lnk/sat tabs added. Earlier steps
(init, profile, approve-profile) are preserved.

### SAT Variants

| Type | Prefix | When to Use | Extra Params |
|------|--------|-------------|-------------|
| `sat` | `sat_` | Standard satellite (parent is a hub) | — |
| `lsat` | `lsat_` | Link satellite (parent is a link) | — |
| `msat` | `msat_` | Multi-active satellite | `--multi-active-key <COL>` |
| `lmsat` | `lmsat_` | Multi-active link satellite | `--multi-active-key <COL>` |

---

## Full DV Pipeline (Hub/Sat/Link/PB/Fact)

Use this guide in the **process-mapping** repo (open it in VS Code, open Copilot Chat)
to auto-generate XLSX tech specs and dbt SQL for **any** Data Vault objects.

### The Structured Prompt Template

```
I need to generate a Data Vault tech spec for the following objects, then
run it through the process-mapping tool to produce uniform dbt SQL + YAML.

**Source System:** <<SOURCE_SYSTEM>>
**PSA Source Tables:** <<TABLE_1>> (description), <<TABLE_2>> (description)
**PSA Source Schema:** <<SCHEMA>>

**Objects to build (RAW_VAULT → BUS_VAULT):**

1. **HUB_<<NAME>>**
   - Business Keys: <<BK_COLUMNS>>
   - Source: <<STG_VIEW_NAME>>

2. **SAT_<<NAME>>__<<SOURCE>>**
   - Parent Hub: HUB_<<NAME>>
   - Payload columns: all columns from <<TABLE>> (or list specific columns)
   - Source: <<STG_VIEW_NAME>>

3. **PB_<<NAME>>**
   - Joins HUB + SAT(s)
   - Filters: <<FILTER_CONDITIONS>>

4. **FACT_<<NAME>>**
   - Source: PB_<<NAME>>
   - Dimension joins: <<DIM_TABLE>> on <<JOIN_COL>>

Please:
1. Create a YAML config at scripts/configs/<<name>>.yml
2. Run: python scripts/generate_tech_spec.py --config scripts/configs/<<name>>.yml --outdir output/mappings
3. Run: python src/main.py --rootdir output --loglevel INFO
4. Show me the generated SQL files
```

### Examples

**Full Pipeline (multiple tables)**:
```
Source System: moen_sap
PSA Tables: Z_KEKO (cost estimate header), Z_KEPH (cost estimate components)
PSA Schema: SAP_ECC_PRD

Objects to build:
1. HUB_PRODUCT_COST_ESTIMATE — BKs: MATNR, WERKS, POPER+BDATJ, KLVAR
2. SAT_PRODUCT_COST_ESTIMATE__MOEN_SAP — all columns from Z_KEKO
3. PB_PRODUCT_COST_ESTIMATE — join HUB + SAT, derived PER_UNIT_COST
4. FACT_PRODUCT_COST_ESTIMATE — join DIM_ITEM_FBIN, DIM_DATE_FISCAL_445
```

**Minimal one-liner**:
```
Generate a tech spec for HUB_PLANT from v_psa_stg_plant_master__moen_sap with BK WERKS.
```

---

## Pipeline Commands Reference

| Command | Purpose | Prerequisites |
|---------|---------|---------------|
| `init` | Initialize pipeline state | None |
| `profile` | Profile source table(s) in Snowflake | `init` |
| `show-profile` | Display profile results | `profile` |
| `approve-profile` | User gate: approve BK + profile | `profile` |
| `generate-yaml` | Generate YAML config | `approve-profile` |
| `generate-xlsx` | Generate XLSX + auto-validate (21 checks) | `generate-yaml` |
| `approve-xlsx` | User gate: approve XLSX tech spec | `generate-xlsx` |
| `generate-code` | Run Stage 2 code generation | `approve-xlsx` |
| `show-code` | Display generated SQL/YAML | `generate-code` |
| `approve-code` | User gate: approve generated code | `generate-code` |
| `implement` | Place files, register source, build, test | `approve-code` |
| `build-all` | Run dbt build for all models in one pass | `implement` |
| `add-raw-vault` | Add hub/lnk/sat to existing STG pipeline | `approve-xlsx` |
| `status` | Show pipeline status | Any |
| `reset` | Reset pipeline to re-run from a step | Any |

### Useful Flags

| Flag | Command(s) | Purpose |
|------|-----------|---------|
| `--profile-json <file>` | `profile` | Load pre-computed profile (skip Snowflake) |
| `--skip-build` | `implement` | Place files only, build later with `build-all` |
| `--force` | `init` | Overwrite existing pipeline state |
| `--domain <folder>` | `implement` | Target domain folder under `models/int_staging_views/` |
| `--objects "stg,hub,lnk,sat"` | `init`, `add-raw-vault` | Object types to generate |

---

## Common Patterns & Gotchas

### Reserved-Word Table Names

Tables like `ORDER`, `GROUP`, `TABLE` are SQL reserved words. The pipeline preserves
the exact case from `_sources_staging_psa.yml`. If your source YAML entry uses
`name: ORDER`, the generated SQL will produce `source('shopify_moen', 'ORDER')`.

**Action**: Ensure the source YAML entry uses `quoting: { identifier: true }` for
reserved-word table names.

### Column Collision Detection

When two tables share column names (e.g., both `FULFILLMENT` and `ORDER` have `ID` and `NAME`):
- Secondary columns are auto-prefixed with the alias: `ID` → `ORD_ID`, `NAME` → `ORD_NAME`
- **All downstream references must use the renamed name** in BK expressions, HASHDIFF, etc.

### BK Expression Validation (Lesson #92)

The pipeline validates that `--secondary-bk` references only columns that exist in the
post-rename column set. If `NAME` was renamed to `ORD_NAME`, using `COALESCE(NAME, '-1')`
will fail with a suggestion to use `COALESCE(ORD_NAME, '-1')`.

### LOAD_DTS Derivation

The pipeline auto-detects ingestion type and generates the correct LOAD_DTS:

| Ingestion | Detection | LOAD_DTS Pattern |
|-----------|-----------|-----------------|
| Fivetran | `_FIVETRAN_SYNCED` present | `CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, _FIVETRAN_SYNCED))` |
| SNP GLUE | `GLCHANGETIME` present | `IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ(...)))` |
| Custom | Neither | `CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)` |

### Pipeline Flow Diagram

```
init → profile → approve-profile → generate-yaml → generate-xlsx
  → approve-xlsx ──┬── generate-code → approve-code → implement → build-all
                   │
                   └── add-raw-vault → generate-yaml → ... (re-run from YAML)
```

### What Gets Generated (per object)

| Object | SQL File Location | YAML File Location |
|--------|------------------|-------------------|
| `v_psa_stg_*` | `models/int_staging_views/<domain>/` | Same directory |
| `hub_*` | `models/raw_vault/hub/` | Same directory |
| `lnk_*` | `models/raw_vault/link/` | Same directory |
| `sat_*` / `lsat_*` / `msat_*` | `models/raw_vault/sat/` | Same directory |

---

## Reference

| Resource | Path |
|----------|------|
| Pipeline orchestrator | `scripts/automation/pipeline_orchestrator.py` |
| Multi-table module | `scripts/automation/multi_table.py` |
| YAML config schema | `.github/skills/v-psa-stg-generator/input-schema.yml` |
| Example configs | `scripts/automation/configs/integration_test/` |
| Lessons learned | `scripts/automation/lessons.md` |
| Setup guide | `SETUP_GUIDE.md` |
| Project standards | `CLAUDE.md` |
| XLSX validator | `scripts/automation/validate_tech_spec.py` |
| Code generator | `scripts/automation/src/build.py` |
| YAML schema generator | `scripts/automation/src/make_yml.py` |

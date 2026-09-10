# PROMPT: v_psa_stg Automation Pipeline

You are generating a v_psa_stg staging view using the dbt-datavault automation pipeline.

## CRITICAL INSTRUCTION
You MUST execute each step below IN ORDER. Do NOT skip ahead. Do NOT combine steps.
Do NOT proceed past any STOP gate without my explicit approval.
After completing each step, SHOW ME the result and WAIT for my response.

---

## STAGE 1: Tech Design Creator

Read these files first:
- `.github/skills/dv-tech-design-creator/SKILL.md`
- `CLAUDE.md`
- `scripts/automation/src/yaml_reader.py`

Then execute these steps ONE AT A TIME:

### Step 1.1 — Collision Check
Search the repo for any existing model that uses this driver table:
```bash
grep -r "source('<schema>', '<table>')" models/
find models/int_staging_views/ -name "v_psa_stg_*<entity>*"
```
If a model already exists -> STOP and report. Do not continue.
If no collision -> say "Collision check passed" and proceed to Step 1.2.

### Step 1.2 — DESCRIBE Source Table
Run via snow-mcp:
```sql
SELECT column_name, data_type, comment
FROM PSA_PROD.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = '<SCHEMA>' AND table_name = '<TABLE>'
ORDER BY ordinal_position;
```
Show me the full column list. Count total columns.

### Step 1.3 — Sample Data
```sql
SELECT * FROM PSA_PROD.<schema>.<table> LIMIT 5;
```
Show me the sample.

### Step 1.4 — Row Count + Volume Assessment
```sql
SELECT COUNT(*) FROM PSA_PROD.<schema>.<table>;
```
Report the row count and apply the volume tier with CONCRETE actions:

| Volume Tier | Row Count | Actions for v_psa_stg YAML Config |
|-------------|-----------|-----------------------------------|
| **Normal** | < 50M | No special config. Standard v_psa_stg view. |
| **Caution** | 50M-300M | Set `cluster_by: [<BK_COLUMN>]` in YAML config. Add SQL header comment: `-- CAUTION: 50-300M rows. cluster_by applied for downstream hub/sat performance.` Flag in XLSX for reviewer. |
| **Large** | > 300M | Set `large_volume: true` in `_pipeline_metadata`. Set `cluster_by: [<BK_COLUMN>]`. Note for downstream: hub/sat models sourcing from this table should use INCR_WATERMARK pattern (per-REC_SRC watermark with `DATEADD(DAY, -3, MAX(LOAD_DTS))`). |

**Important:** v_psa_stg models are VIEWs, so `full_refresh: false` and `on_schema_change` do NOT apply to the staging view itself. The volume config is recorded in the YAML so that **future downstream hub/sat generation** applies the correct dbt config:

**Downstream hub/sat config for 50M-300M (Caution) sources:**
```jinja-sql
{{
  config(
    cluster_by = ['<BK_COLUMN>'],
    tags = ['materialization_override', 'large_volume', 'hub']  -- or 'sat'
  )
}}
```

**Downstream hub/sat config for >300M (Large) sources:**
```jinja-sql
{{
  config(
    full_refresh = false,
    on_schema_change = 'append_new_columns',
    cluster_by = ['<BK_COLUMN>'],
    tags = ['materialization_override', 'large_volume', 'hub']  -- or 'sat'
  )
}}
```
Note: Replace `'hub'` with `'sat'`, `'lsat'`, etc. based on the actual object type.

These configs are NOT applied to the v_psa_stg view itself — they are stored in the YAML `_pipeline_metadata` section so that when Raw Vault generation runs later, it reads the volume tier and applies the correct config block automatically.

### Step 1.5 — BK Grain Validation
```sql
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT <BK> || '~' || TO_VARCHAR(PSA_LOAD_DTS)) AS distinct_grain
FROM PSA_PROD.<schema>.<table>;
```
Both numbers must match. If they don't -> grain problem, STOP.

### Step 1.6 — NULL BK Check
```sql
SELECT COUNT(*) AS null_count
FROM PSA_PROD.<schema>.<table>
WHERE <BK> IS NULL;
```
Report count. If nulls > 0, note that COALESCE will be needed.

### Step 1.7 — Detect Metadata & System Columns + Identify Ingestion Source

From the column list in Step 1.2, scan for ALL of the following metadata/system columns.
Different source systems use different ingestion tools — the column presence tells you which tool loaded this table.

**Step 1.7a — Identify the ingestion source by column fingerprint:**

| Ingestion Tool | Fingerprint Columns | Common Source Systems |
|----------------|---------------------|----------------------|
| **Fivetran** | `_FIVETRAN_DELETED`, `_FIVETRAN_SYNCED`, `_FIVETRAN_ID` | Oracle EBS (ml_ebs, outd_ocf, emtk_ebs), Salesforce, AppBot, Smartsheet |
| **SNP GLUE** | `MANDT`, `GLREQUEST`, `GLSOURCESYSTEM`, `GLDELFLAG`, `GLCHANGETIME` | SAP ECC/S4 (winn_sap, moen_sap, sap_ecc_prd) |
| **Custom / Python** | None of the above — only PSA standard columns | Ad-hoc loads, SimpleLab, Delta Direct |

Report which ingestion source was detected.

**Step 1.7b — Check each column and report YES/NO:**

**PSA Standard Columns (present in ALL sources):**
- `PSA_LOAD_DTS` -> always present (passthrough; used for LOAD_DTS only in non-Fivetran sources)
- `PSA_RECORD_SOURCE` -> always present (excluded from HASHDIFF)
- `PSA_DELETE_IND` -> set `has_psa_delete_ind: true/false`. If present, include in HASHDIFF.

**Fivetran Columns (if Fivetran-ingested):**
- `_FIVETRAN_DELETED` -> set `has_fivetran_deleted: true/false`. If present, include in HASHDIFF.
- `_FIVETRAN_SYNCED` -> present YES/NO. Keeps original name. **Excluded from HASHDIFF. Used for LOAD_DTS derivation in Fivetran sources.**
- `_FIVETRAN_ID` -> present YES/NO. **Excluded from HASHDIFF.**

**SAP System Columns (if SNP GLUE-ingested):**
- `MANDT` -> present YES/NO. **Excluded from HASHDIFF** (SAP client ID, system metadata).
- `GLREQUEST` -> present YES/NO. **Excluded from HASHDIFF** (SNP GLUE request ID).
- `GLSOURCESYSTEM` -> present YES/NO. **Excluded from HASHDIFF** (SNP GLUE source system ID).
- `GLDELFLAG` -> present YES/NO. **Excluded from HASHDIFF** (SNP GLUE deletion flag).
- `GLCHANGETIME` -> present YES/NO. **Excluded from HASHDIFF** (SNP GLUE change timestamp).

**LOAD_DTS derivation pattern (important — varies by ingestion source):**

| Ingestion Source | LOAD_DTS Derivation |
|------------------|---------------------|
| **Fivetran** | `CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)` — provides true per-record change timestamp |
| **SNP GLUE** | `IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ(SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16), 'YYYYMMDDHH24MISS.FF9')))` — GLCHANGETIME is NUMBER; fractional seconds beyond pos 14 require SUBSTR+FF9 |
| **Custom** | `CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)` |

Record the detected LOAD_DTS derivation pattern in the YAML config.

**Summary — columns ALWAYS excluded from HASHDIFF (across all sources):**
PSA_LOAD_DTS, PSA_RECORD_SOURCE, _FIVETRAN_SYNCED, _FIVETRAN_ID, MANDT, GLREQUEST, GLSOURCESYSTEM, GLDELFLAG, GLCHANGETIME

**Summary — columns INCLUDED in HASHDIFF (flag-driven):**
PSA_DELETE_IND (if present), _FIVETRAN_DELETED (if present)

### Step 1.8 — BKCC Validation
```sql
-- Uses DATAVAULT_{DBT_ENVIRON} (defaults to DATAVAULT_DEV for local dev)
SELECT BKCC FROM DATAVAULT_DEV.RAW_VAULT.REF_BUSINESS_KEY_COLLISION
WHERE REC_SRC = '<REC_SRC>';
```
Note: The orchestrator reads `DBT_ENVIRON` env var (default: `dev`) and queries `DATAVAULT_{DBT_ENVIRON}`. BKCC is always registered in DEV first via Streamlit app, then promoted to QA/PROD by CI.
If no BKCC found -> STOP. Must be registered before proceeding.
If found -> report the BKCC value.

### Step 1.9 — Source Registration Check
```bash
grep -r "<schema>" models/sources/_sources_staging_psa.yml
```
Report: source group already registered or new registration needed.

### STOP — Present Stage 1 Profile

Now present a summary table with ALL results from Steps 1.1-1.9:

| Check | Result |
|-------|--------|
| Table | PSA_PROD.<schema>.<table> |
| Rows | <count> (<tier>: Normal/Caution/Large) |
| Volume Actions | <actions per tier from Step 1.4> |
| Columns | <count> (breakdown) |
| BK | <source_column> (<type>) -> <ENTITY_BK> |
| NULL BK | <count> |
| Grain | <BK> + PSA_LOAD_DTS — unique / duplicates |
| BKCC | <value> for <REC_SRC> |
| Source | registered / new |
| Collision | none / found |
| Flags | _FIVETRAN_DELETED: Y/N, PSA_DELETE_IND: Y/N |

Ask me: "Please confirm BK, entity name, and domain folder. Any lookup tables?"

**WAIT for my response. Do NOT proceed until I confirm.**

---

### Step 1.10 — Write YAML Config
After I confirm, generate the YAML config file at:
`scripts/automation/configs/<entity>__<source>.yml`

YAML must include:
- All source columns with data types
- BK mapping (source_column -> staging_name)
- If user specified a cast (e.g., `TERM_ID::TEXT`), set `manual_logic: "TERM_ID::TEXT"` + `staging_datatype: "TEXT"`. If no cast given, omit `manual_logic`.
- BK `unique` field must use `"COMPOSITE: <BK_COL>, LOAD_DTS"` format to trigger grain test
- HK formula using RAW source column name (NOT BK alias)
- HASHDIFF markers on all data columns
- `_pipeline_metadata` with all flags from Step 1.7
- `psa_delete_filter: false` (NEVER filter deletes in v_psa_stg)
- BKCC and REC_SRC values from Step 1.8
- Volume config from Step 1.4:
  - `row_count: <count>`
  - `volume_tier: normal / caution / large`
  - `large_volume: true/false`
  - `cluster_by: [<BK_COLUMN>]` (if 50M+ rows)
  - `downstream_config:` (stored for future hub/sat generation)

**CRITICAL: The YAML must include ALL derived fields — `build.py` generates ONLY what the YAML contains:**
1. Raw BK passthrough (e.g., `TERM_ID` retained alongside BK alias `PAYMENT_TERM_BK`)
2. `LOAD_DTS` with `source_column: "(DERIVED)"` and `manual_logic: "CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)"` (or equivalent for ingestion source)
3. `REC_SRC` from BKCC ref table (e.g., `source_table: "SRC_BKCC"`)
4. `BKCC` from BKCC ref table (e.g., `source_table: "SRC_BKCC"`)
5. HK with `source_column: "(DERIVED)"` and `manual_logic: "HASH: <raw_bk_col>, BKCC"`
6. `HASHDIFF` with `source_column: "(DERIVED)"` and `manual_logic: "HASH: <all_data_cols>"` (excludes BK, metadata, technical)

The XLSX is a separate visual-review artifact. `build.py` reads the YAML directly — if derived fields are missing from the YAML, they will be missing from the generated SQL.

### Step 1.11 — Generate XLSX Tech Spec
Run:
```bash
python scripts/automation/generate_tech_spec.py \
  --config scripts/automation/configs/<entity>__<source>.yml \
  --outdir scripts/automation/mappings/
```

### STOP — XLSX Review

Tell me: "XLSX generated at `scripts/automation/mappings/<file>.xlsx`. Please open and review:
1. Tables tab: driver table + BKCC row with join condition
2. Tables tab: NO `WHERE psa_delete_ind = 'N'` filter
3. Columns tab: ALL source columns present (none dropped)
4. Columns tab: BK alias ADDED alongside raw column (not replacing)
5. Columns tab: derived fields at bottom (HK, HASHDIFF, BKCC, REC_SRC, LOAD_DTS)
6. Columns tab: HK uses raw source column names
7. Columns tab: HASHDIFF includes PSA_DELETE_IND + _FIVETRAN_DELETED (if present in source)
8. Columns tab: ALL system/metadata columns excluded from HASHDIFF: _FIVETRAN_SYNCED, _FIVETRAN_ID, MANDT, GLREQUEST, GLSOURCESYSTEM, GLDELFLAG, GLCHANGETIME
9. Columns tab: LOAD_DTS derivation matches ingestion source (Fivetran -> _FIVETRAN_SYNCED, SNP GLUE -> GLCHANGETIME-based, Custom -> PSA_LOAD_DTS)

Confirm approval before Stage 2."

**WAIT for my approval. Do NOT proceed to Stage 2 until I say approved.**

---

## STAGE 2: Code Generator

### Step 2.1 — Run Code Generator
```bash
python scripts/automation/src/main.py \
  --yaml-config scripts/automation/configs/<entity>__<source>.yml
```

### Step 2.2 — Verify Generated SQL
Open the generated SQL file and verify:
- 4-layer CTE: SRC -> LOGIC -> JOIN -> FINAL (NOT 6-layer)
- SRC driver: `SELECT * FROM {{ source(...) }}`
- SRC BKCC: `SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} WHERE rec_src = '...'`
- LOGIC: BK alias added, raw column also retained
- LOGIC: HASHDIFF EXCLUDES all system/metadata columns
- LOGIC: HASHDIFF INCLUDES PSA_DELETE_IND and _FIVETRAN_DELETED (only if flags are true)
- LOGIC: LOAD_DTS derivation matches the ingestion source pattern
- JOIN: BKCC cross-join `INNER JOIN SRC_BKCC ON '1' = '1'`
- FINAL: all columns present (TERM_ID, BK alias, HK, BKCC, REC_SRC, LOAD_DTS, HASHDIFF, all passthroughs)
- No QUALIFY in FINAL
- No WHERE psa_delete_ind filter

### Step 2.3 — Verify Generated YAML Tests
Open the generated YML file and verify:
- `dbt_utils.unique_combination_of_columns` on [<ENTITY_BK>, LOAD_DTS] — NOT [HK, LOAD_DTS]
- `not_null` on <ENTITY_BK>
- Both with `severity: warn`
- NO standalone `unique` test on BK
- Tests require `--vars '{"enable_staging_tests": true}'`

### Step 2.4 — Verify Source Entry
Check generated source entry: correct source group, database (PSA_PROD), schema, table.

### STOP — Code Review

Show me the generated SQL and YAML. Tell me the file paths.

**WAIT for my approval. Do NOT start Stage 3 until I say "looks good" or "implement" or "proceed".**

---

## STAGE 3: Code Implementer

### Step 3.1 — Branch Check
```bash
git branch --show-current
git status
```
If on main -> create feature branch. If on feature branch -> stay.

### Step 3.2 — Determine Domain Folder
```bash
find models/int_staging_views/ -name "*__<source>*" -type f | head -10
```
Use the same domain folder as existing models for this source system.

### Step 3.3 — Place Files
Copy SQL and YML to: `models/int_staging_views/<domain>/`

Before placing, check for duplicates:
```bash
find models/ -name "<model_name>.*"
```
If duplicates found -> STOP, resolve first.

### Step 3.4 — Register Source (if new — SEPARATE COMMIT)
If the source table is not yet registered:
```bash
# Add source entry to _sources_staging_psa.yml
git add models/sources/_sources_staging_psa.yml
git commit -m "Register source: <schema>.<table>"
```
This is committed SEPARATELY from model files for clean rollback.

### Step 3.5 — dbt Build (compile + run + test)
```bash
dbt build --select <model_name>
```
This single command compiles, runs, and tests the model in one pass.

**Staging tests auto-enable** for local sandbox (`target.name == 'default'`). The `--vars '{"enable_staging_tests": true}'` flag is only needed in dbt Cloud targets (dev/qa/prod) where staging tests are OFF by default.

Must complete with 0 errors/failures. If it fails, diagnose and fix (max 3 retries). If still failing -> STOP.

### Step 3.6 — Interpret Results
- `not_null` PASS + `unique_combination` PASS/WARN -> proceed to commit
- `not_null` FAIL -> STOP — NULL BKs, return to Stage 1
- `unique_combination` FAIL (actual failures) -> STOP — grain problem, return to Stage 1
- 0 tests executed -> verify `target.name` is `default`; if running in dbt Cloud, add `--vars '{"enable_staging_tests": true}'`

### Step 3.7 — Commit Model Files
Only after all tests pass:
```bash
git add models/int_staging_views/<domain>/<model_name>.sql
git add models/int_staging_views/<domain>/<model_name>.yml
git add scripts/automation/configs/<entity>__<source>.yml
git commit -m "Add v_psa_stg model: <model_name>

- Source: PSA_PROD.<schema>.<table>
- BK: <ENTITY_BK>
- Tests: unique_combination [BK, LOAD_DTS] + not_null [BK]
- Generated via automation pipeline"
```

### Step 3.8 — Final Report
Present:
```
Pipeline complete.
Branch:   <branch>
Model:    <model_name>
Location: models/int_staging_views/<domain>/
Build:    passed (compile + run + test)
Tests:    X/Y passed
Commits:  <list>
Ready for PR.
```

---

## RULES — DO NOT VIOLATE

1. Execute steps IN ORDER. Never skip ahead.
2. WAIT at every STOP for my explicit approval.
3. HK uses RAW source column names (not BK alias).
4. HASHDIFF uses `MD5_BINARY(UPPER(NULLIF(CONCAT(...))))` — same UPPER() wrapper as HK, consistent with all 2,141+ production models.
5. All raw source columns retained as passthroughs (BK alias is an addition).
6. `_FIVETRAN_SYNCED` keeps its original name.
7. No `WHERE psa_delete_ind = 'N'` in v_psa_stg.
8. No standalone `unique` test on BK.
9. Staging tests auto-enable for local sandbox (`target.name == 'default'`). Use `--vars '{"enable_staging_tests": true}'` only in dbt Cloud targets.
10. Source entry committed separately from model files.
11. XLSX review is MANDATORY between Stage 1 and Stage 2.
12. Check for duplicate files before placing in models/ directory.
13. HASHDIFF EXCLUDES (all ingestion sources): BK, HK, BKCC, REC_SRC, LOAD_DTS, PSA_LOAD_DTS, PSA_RECORD_SOURCE, _FIVETRAN_SYNCED, _FIVETRAN_ID, MANDT, GLREQUEST, GLSOURCESYSTEM, GLDELFLAG, GLCHANGETIME.
14. HASHDIFF INCLUDES (flag-driven): PSA_DELETE_IND + _FIVETRAN_DELETED (only if present in source, controlled by `_pipeline_metadata` flags).
15. LOAD_DTS derivation varies by ingestion source — Fivetran uses _FIVETRAN_SYNCED, SNP GLUE uses GLCHANGETIME for non-deletes, Custom uses PSA_LOAD_DTS. Detect and record the correct pattern.
16. If user specifies a BK cast (e.g., `TERM_ID::TEXT`), set `manual_logic` + `staging_datatype` in YAML. If no cast given, omit `manual_logic`. Never infer casts.

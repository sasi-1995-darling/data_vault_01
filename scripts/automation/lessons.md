# v_psa_stg Generator — Lessons Learned

> **Governance**: The skill ONLY follows lessons from the `## Approved` section.
> Anyone can propose lessons via PR to the `## Proposed` section.
> Moving lessons from Proposed → Approved requires approval from DataOps lead.
>
> Proposed lessons are **unnumbered bullet points**. The DataOps lead
> assigns the next sequential number when promoting to Approved.
> This prevents merge conflicts when multiple developers add
> lessons simultaneously.

---

## Supersession Manifest

Quick reference for lessons that have been superseded, consolidated, or reserved.

| Lesson | Status | Replaced by | Notes |
|--------|--------|-------------|-------|
| #17 | SUPERSEDED | Project-level `dbt_project.yml` config | Strikethrough in place |
| #47 | PARTIALLY SUPERSEDED | #66 (for SATs only) | HUB rule still applies |
| #55 | Reserved | Removed during consolidation | — |
| #57 | Reserved | Removed during consolidation | — |
| #87 | CONSOLIDATED | #76 | Duplicate `.venv/bin/python3` rule |
| #113 | SUPERSEDED | #122 | Dict-dump → surgical string insertion |
| #118 | Reserved | Consolidated into #120 | Referenced bug not reproducible |

## Approved

These lessons are verified and active — the skill follows them during generation.

### Phase 1.8b — Expert Model Analysis (15 models reviewed)
1. **HK HASH: components use raw source column names** — e.g., `HASH: TERM_ID, BKCC` not `HASH: PAYMENT_TERM_BK, BKCC`. Raw source columns must be retained as passthroughs in the FINAL output alongside their BK aliases — `build.py` computes HK in the FINAL layer where both are available. This also enables downstream satellite builds which reference raw source column names. *(See #89 for the complete rule including derived-BK exceptions: simple cast → raw column, derivation → BK alias.)*
2. **BK naming is entity-specific** — `STATEMENT_LINE_BK` not `ACCOUNT_BK` for statement line models
3. **SRC driver table always `SELECT *`** — never explicit column list for the main/driver table (v_psa_stg and sat builds only)

### Phase 2a — Validation Review
4. **PSA_DELETE_IND is data, NOT metadata** — include in HASHDIFF, do NOT put in exclusion lists
5. **_FIVETRAN_DELETED is data** — include in HASHDIFF when present
6. **pb_ prefix = PIT Bridge tables** — NOT "Business satellites"
7. **Use `data_tests:` not `tests:`** — `tests:` is deprecated in dbt 1.5+

### General Rules
8. **4-layer CTE only for new models** — do NOT convert existing 448+ legacy models
9. **LEFT JOIN is default for lookups** — INNER JOIN requires user justification + inline comment
10. **BKCC must exist before `dbt build`** — check DEV table first, stop if missing
11. **QUALIFY not DISTINCT** — always use `ROW_NUMBER()` with QUALIFY for dedup
12. **BKCC is last component in every HK** — HK, LNK_HK, all hash keys end with BKCC
13. **Register source in _sources_staging_psa.yml** — every new v_psa_stg needs a source entry
14. **Final QUALIFY is very rare in v_psa_stg** — avoid unless absolutely necessary
15. **All raw source columns preserved in output** — All raw source columns from the driver table must appear in the output with their original names. BK aliases are additional derived columns, not replacements. Technical columns (`_FIVETRAN_SYNCED`, `_FIVETRAN_ID`) retain their original names including underscore prefixes.

### 2026-04-01 — Integration Test Findings (validated by 2 integration tests)
16. **HK HASH: uses raw source column names in YAML, resolved at code gen time** — `build.py` computes deferred hashes in the FINAL layer where raw source columns are retained alongside BK aliases. YAML config `manual_logic` uses raw source names (e.g., `HASH: TERM_ID, BKCC`). Validated by both `retailers__appbot` (reference) and `payment_terms_lines__fib_ocf` (true end-to-end) integration tests.
17. **~~`--vars '{"enable_staging_tests": true}'` required for v_psa_stg test runs~~ (SUPERSEDED)** — The `enable_staging_tests` var was removed from the orchestrator (May 2026). Staging tests are now enabled at the project level in dev sandbox via `dbt_project.yml` configuration. The orchestrator no longer injects this var into dbt commands. Original issue: without the flag, `dbt test` silently reported zero tests — this was fixed by the project-level enablement.
18. **Both `data_tests:` and `tests:` keywords work in dbt-fusion** — Approved lesson #7 states `tests:` is deprecated, but both keywords are in active use across 400+ YAML files in the project. dbt-fusion 2.0 accepts both. The test enablement issue (`enable_staging_tests` var) was the real cause of "zero tests found", not the keyword choice.

### 2026-04-04 — DV Standards Correction: No Delete Flag Filtering at Staging
28. **NEVER filter on `_FIVETRAN_DELETED` or `PSA_DELETE_IND` at the staging layer** — These are data attributes tracked in HASHDIFF so satellites can record deletion state history. Filtering at staging silently drops deleted records from the vault, breaking historical accuracy. The ONLY valid staging WHERE clause is for confirmed system dummy/placeholder records where the business context is explicitly known and confirmed (e.g., `TERM_ID = 0` as an Oracle EBS system ghost — but only if confirmed by data profiling that such rows have no business meaning). Soft-delete flags (`_FIVETRAN_DELETED`, `PSA_DELETE_IND`) are never valid filter criteria. Models `v_psa_stg_payment_terms_text__ml_ebs` and `v_psa_stg_payment_terms_lines__ml_ebs` were corrected to remove these filters.
29. **Follow user-specified BK cast instructions exactly; otherwise use the raw column** — If the user provides an explicit cast for the BK in their request (e.g., `TERM_ID::TEXT`), set `manual_logic: "TERM_ID::TEXT"` and `staging_datatype: "TEXT"` on that column in the YAML config. The code generator (`sheets.py`) will emit the expression verbatim in the LOGIC layer. If no cast is specified, do not add one — use the raw source column directly. Never infer or add casts beyond what the user explicitly stated.

### 2026-04-02 — v_psa_stg_payment_terms_text__ml_ebs Session Findings
19. **XLSX generation is a hard STOP gate, not optional** — The XLSX tech spec must be generated and reviewed by the user BEFORE Stage 2 code generation runs. This is a mandatory checkpoint equivalent to the BK confirmation stop. Stage 1 is not complete without user approval of the XLSX. Skipping this caused code generation and implementation to proceed with unvalidated designs.
20. **WHERE clause must be applied in SRC_SRC CTE, not LOGIC layer** — Filtering in the SRC CTE reduces the row count before any column aliasing or joins occur, saving compute. Pattern: `SRC_SRC as ( SELECT * FROM {{ source(...) }} WHERE <filter> )`. Never place source-level filters in LOGIC_SRC.
21. **FINAL layer must explicitly select ALL columns: source + derived + BK join** — `build.py` does not auto-generate a complete FINAL SELECT. The FINAL layer must include: raw source columns, BK aliases, HK (derived), all data/technical columns, BKCC, REC_SRC, LOAD_DTS (derived), HASHDIFF (last). Any column present in LOGIC or from a JOIN must be explicitly listed in FINAL — no implicit SELECT *.
22. **HK must be explicitly computed in FINAL layer** — The hash key (e.g., `PAYMENT_TERM_HK`) is a derived column in the FINAL SELECT using `MD5_BINARY(UPPER(...))`. It does not come from the SRC or LOGIC layer. It references the raw source BK column (TERM_ID) and BKCC, both available in JOIN_RESULT.
23. **Raw source BK column must appear in FINAL alongside its alias** — When a source column is renamed to a BK (e.g., `TERM_ID AS PAYMENT_TERM_BK`), BOTH `TERM_ID` AND `PAYMENT_TERM_BK` must appear in the FINAL SELECT. Downstream satellites join on raw source column names. Dropping the raw column breaks the satellite build chain.
24. **Stage 2 output requires user review before Stage 3** — After code generation, the user must review the generated SQL and YAML files (LOGIC layer completeness, FINAL layer column order, WHERE clause placement, HK formula, HASHDIFF column list) before Stage 3 (compile/run/test/commit) proceeds.
25. **XLSX Manual Logic rule: blank if direct column, populated only for transformations** — If Source Column is a real column name (e.g., BKCC, REC_SRC, NAME), Manual Logic must be blank. Only populate Manual Logic when there is an actual transformation or derivation (e.g., HASH: ..., CONVERT_TIMEZONE(...), NULLIF(...)).
26. **Do NOT add standalone `unique` test on BK in v_psa_stg YAML** — PSA is append-only; the same BK appears across multiple load timestamps. A standalone `unique` on BK will fail every time. The grain is BK + LOAD_DTS, which is already enforced by `unique_combination_of_columns`. Only `not_null` is valid as a standalone BK column test.
27. **`dbt_utils.unique_combination_of_columns` requires `arguments:` wrapper for dbt 2.0/Fusion** — Correct format: `dbt_utils.unique_combination_of_columns: { arguments: { combination_of_columns: [...] }, config: { severity: warn } }`. Without `arguments:`, the test may fail to parse under dbt-fusion static parser.

### 2026-04-04 — Recurring Process Violation: XLSX Gate Must Gate Stage 2
30. **⛔ XLSX tech spec review is a hard gate between Stage 1 and Stage 2 — this is a recurring violation** — The XLSX must be generated immediately after the YAML config is written, presented to the user, and explicitly approved BEFORE any Stage 2 code generation (`main.py`) runs. This has been violated repeatedly in testing: the agent jumped from YAML config directly to `main.py --yaml-config` without generating or presenting the XLSX. The correct sequence is non-negotiable: (1) write YAML → (2) run `generate_tech_spec.py` → (3) ⛔ wait for user XLSX approval → (4) run `main.py`. YAML approval alone does not authorize Stage 2. Applies equally to direct Claude Code usage as to agent-to-agent handoffs.

### 2026-04-05 — Pre-Flight Check + DV Source Layer Standards
31. **Pre-flight collision check: confirm no existing v_psa_stg uses the same driver source table** — Before any Stage 1 profiling begins, search the repo (`models/int_staging_views/` AND `models/staging/`) for any existing model that already sources from the same PSA table. A staging model has a 1:1 relationship with its driver source table — duplicating this would create two staging paths for the same data. Use `grep -r "<source_table>" models/` to confirm. Only proceed if no collision exists.
32. **Staging WHERE clause: only for confirmed system dummy records, never soft-delete flags** — The only valid staging-layer filter is for known system-generated placeholder rows where business context is explicitly confirmed (e.g., `TERM_ID = 0` as an Oracle EBS ghost row — only if data profiling proves it has no business meaning). Soft-delete flags (`_FIVETRAN_DELETED`, `PSA_DELETE_IND`) are **never** valid filter criteria at staging — they are data attributes that must flow through to HASHDIFF so satellites can track deletion history. Filtering them silently drops records from the vault.

### 2026-04-06 — LOAD_DTS Derivation Correction for Fivetran Sources
33. **LOAD_DTS for Fivetran sources must derive from `_FIVETRAN_SYNCED`, NOT `PSA_LOAD_DTS`** — `_FIVETRAN_SYNCED` provides the true per-record change timestamp from Fivetran, while `PSA_LOAD_DTS` is the PSA batch load timestamp (same value for all records in a load batch). Using `PSA_LOAD_DTS` causes grain failures because multiple distinct records (e.g., deleted + non-deleted Fivetran pairs) share the same `PSA_LOAD_DTS` but have different `_FIVETRAN_SYNCED` values. The correct formula: `CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED) AS LOAD_DTS`. For SNP GLUE sources, use `GLCHANGETIME`. For custom/non-Fivetran sources, use `PSA_LOAD_DTS` as fallback.

### 2026-04-06 — XLSX Tech Spec Generator Bug Fixes (generate_tech_spec.py)
34. **BK identification requires BOTH `unique: "yes"` AND `not_null: "yes"`** — When scanning columns to find the BK, checking only `unique: "yes"` is insufficient because other grain columns (e.g., SEQUENCE_NUM, LOAD_DTS) also participate in uniqueness. The BK is the only column that is BOTH `unique` AND `not_null`. Using just `unique` caused SEQUENCE_NUM to overwrite the BK reference, producing wrong HK formula and staging column names. Fixed in `generate_tech_spec.py:271`.
35. **Raw source column must be retained as XLSX passthrough when BK has `manual_logic` (cast)** — When a BK has a cast (e.g., `TERM_ID::TEXT → PAYMENT_TERM_BK`), the raw source column (TERM_ID) must appear as a separate passthrough row in the XLSX Columns tab alongside the BK alias row. Without this, the raw column disappears from the tech spec, violating DV 2.x rules that all raw source columns must be preserved. Fixed in `generate_tech_spec.py:304-328`.
36. **YAML field values (`unique`, `not_null`, `manual_logic`) must propagate to XLSX — never hardcode blanks** — The data columns loop in generate_tech_spec.py must read `col.get("unique", "")`, `col.get("not_null", "")`, and `col.get("manual_logic", "")` from the YAML config, not hardcode empty strings. Grain columns like SEQUENCE_NUM have `unique: "yes"` in the YAML that must appear in the XLSX for reviewer verification. An automated XLSX validation script (`validate_tech_spec.py`) now enforces these rules post-generation.

### 2026-04-07 — ⛔ XLSX Generation is MANDATORY STOP Gate (Step 1.11-1.12)
37. **⛔ XLSX generation (Step 1.11) is MANDATORY after YAML config (Step 1.10). XLSX approval (Step 1.12) is a SEPARATE gate from YAML approval.** — The correct sequence is NON-NEGOTIABLE: (1) write YAML config → (2) RUN `python scripts/automation/generate_tech_spec.py` → (3) **⛔ STOP for user XLSX review** → (4) THEN proceed to Stage 2 (`main.py --yaml-config`). YAML approval does NOT authorize skipping to Stage 2. This has been violated 4+ times: jumping directly from YAML → Stage 2, bypassing XLSX generation and review entirely. The XLSX is the user's last chance to validate column ordering (BK → HK → data → technical → BKCC → REC_SRC → LOAD_DTS → HASHDIFF), detect missing/duplicate columns, and verify derived field formulas (HASH: and CONVERT_TIMEZONE) BEFORE code generation runs. Skipping this gate risks generating incorrect SQL with wrong column sequences, duplicate columns, or incomplete FINAL layer specs. Concurrent fix: `generate_tech_spec.py` now prevents duplicate derived fields by checking `existing_staging_cols` set before adding HK, BKCC, REC_SRC, LOAD_DTS, HASHDIFF (lines 265, 331-357, 414-464, 468-519). `validate_tech_spec.py` includes `_check_duplicate_staging_columns()` (lines 126-143) to fail if duplicates slip through. Both agent prompts and skill documentation must emphasize: ⛔ is non-negotiable.

### 2026-04-07 — YAML Config Must Include ALL Derived Fields for Code Generation
38. **YAML config is the machine-readable definition — `build.py` generates ONLY what the YAML contains.** — The YAML config consumed by `main.py --yaml-config` must include ALL columns that should appear in the generated SQL, including derived fields: (1) raw BK passthrough (e.g., `TERM_ID` alongside BK alias `PAYMENT_TERM_BK`), (2) `LOAD_DTS` with `manual_logic: "CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)"`, (3) `REC_SRC` from BKCC ref table, (4) `BKCC` from BKCC ref table, (5) HK with `manual_logic: "HASH: <raw_bk_col>, BKCC"`, (6) `HASHDIFF` with `manual_logic: "HASH: <all_data_cols>"`. The XLSX (`generate_tech_spec.py`) is a SEPARATE visual-review artifact — it auto-adds derived fields for display, but `build.py` reads the YAML directly, not the XLSX. If derived fields are missing from the YAML, they will be missing from the generated SQL. Root cause of the `payment_terms_tl__emtk_ebs_ap` bug where FINAL layer was missing HK, BKCC, REC_SRC, LOAD_DTS. The BK `unique` field must use `"COMPOSITE: <BK_col>, LOAD_DTS"` format (not just `"yes"`) to trigger the grain test via `tests.py`.

### 2026-04 — Raw Vault Automation: HUB/LNK/SAT Generation Lessons

39. **BK with ::TEXT cast: raw passthrough must strip the cast** — When BK has a cast expression (e.g., `VENDOR_SITE_ID::TEXT`), the raw BK passthrough in LOGIC and FINAL layers must be the base column name only (`VENDOR_SITE_ID`), not the expression. The BK alias line keeps the cast (`VENDOR_SITE_ID::TEXT AS SUPPLIER_SITE_BK`). Strip via `bk_column.split('::')[0]`. (Bug #22)

40. **`_find_active_state()` must validate JSON structure** — The state file lookup must check that JSON files have `model_name` and `steps_completed` keys before accepting them as valid pipeline state files. Profile JSONs and other artifacts in `.pipeline_state/` must be ignored. (Bug #23)

41. **`--profile-json` must run collision check** — The `_load_profile_json` path bypasses `_semantic_collision_check()`. Both profiling paths (MCP and JSON) must run the collision check and store results in state. `approve-profile` refuses without collision_check in state. (Bug #24)

42. **`_find_columns_sheet` must use layer prefix** — When multiple layers share a truncated model name (e.g., STG and SAT for `cost_est_hdr`), the sheet lookup must match the layer prefix (STG/HUB/LNK/SAT) to avoid reading the wrong sheet's columns. (Bug #25)

43. **SAT payload: PSA columns added once as metadata, not twice** — `PSA_DELETE_IND`, `PSA_LOAD_DTS`, `PSA_RECORD_SOURCE` must be in the section 4 skip list in `_build_sat_yaml_model`. They are added with proper ghost values in later sections. Including them as data AND metadata produces duplicate columns. Same for `_FIVETRAN_SYNCED`, `_FIVETRAN_ID`, `_FIVETRAN_DELETED`. (Bugs #26, #28)

44. **SAT watermark regex must handle per-REC_SRC pattern** — The `incremental_pattern` regex in `build.py` must allow `{{ this }} where rec_src = '...'` inside the subquery, not just `{{ this }})`. The `.*)` was too strict and caused double watermark injection. (Bug #27)

45. **SAT includes ONLY the parent HK — all other HKs/LHKs excluded** — When v_psa_stg has multiple HKs (e.g., `PLANNED_ORDER_HK`, `ITEM_HK`, `SUPPLIER_HK`, `LNK_PLANNED_ORDER_HK`), the SAT must include only the declared parent HK. All columns ending with `_HK` or `_LHK` that don't match the parent are skipped. The derived BK alias (e.g., `PLANNED_ORDER_BK`) is also excluded — it belongs in the parent hub, not the SAT. (Bug #29)

46. **ghost_record must be explicit `"null"` for payload columns** — Setting `ghost_record: ""` (empty string) causes `build.py` to render `'' AS <col>` (literal empty string) instead of `NULL AS <col>`. This fails type coercion on NUMBER, DATE, and TIMESTAMP columns. Always use `"ghost_record": "null"` for payload columns. (PR Review Fix #1)

47. **~~Normal tier SATs (< 50M): no watermark injection~~ (SUPERSEDED by lesson #66)** — When Source Layer Filter is intentionally empty (Normal tier), `build_src_layer` must NOT auto-inject the default watermark block. The condition must check `src_filter_condition.strip()` before injecting. Empty filter = no watermark. (PR Review Fix #2) — **NOTE: This rule applies to HUBs only. For SATs, lesson #66 reverts this: all SATs always get watermark injection regardless of volume tier.**

48. **LSAT/LMSAT parent key uses `_LHK` suffix** — Validators, PK detection, and FK fallback logic must accept both `_HK` and `_LHK` suffixes. Using `endswith("_HK")` alone rejects all link-attached satellite models. Use `endswith(("_HK", "_LHK"))`. (PR Review Fix #1-3)

49. **`LMSAT_` must be in satellite prefix checks** — `build.py`'s `is_satellite` detection and union-all ghost-record block must include `LMSAT_` alongside `SAT_`, `LSAT_`, `MSAT_`, `ESAT_`. Missing this causes LMSAT models to skip satellite-specific SQL behavior. (PR Review Fix #4)

50. **`--rec-src` must be validated against SQL injection** — The `rec_src` argument is interpolated directly into SQL strings. Validate against `^[A-Za-z0-9._]+$` regex before any use. (PR Review Fix #5)

51. **HK HASH uses raw source column names, not BK cast expressions** — `HASH: ID, BKCC` (correct), not `HASH: TO_CHAR(ID), BKCC` (wrong). The `TO_CHAR()`/`::TEXT` cast is only for the BK alias column derivation (e.g., `TO_CHAR(ID) AS PRODUCT_VARIANT_BK`). Each hub HK hashes only its own entity's raw BK + BKCC. Link HK hashes all parent raw BKs + BKCC. This is a refinement of lesson #1 — raw source column names means the base column (`ID`), not the cast expression (`TO_CHAR(ID)`).

52. **BKCC rec_src filter belongs in Source Layer Filter column, not Filter Conditions** — In the XLSX Tables tab, the `rec_src = '...'` condition for the BKCC source row must go in the "Source Layer Filter" column (SRC-level WHERE), not "Filter Conditions" (FINAL-layer WHERE). Fixed in `generate_tech_spec.py` line 211.

53. **Schema and table names always lowercase in YAML config and XLSX** — Regardless of user input casing, `cmd_init` must `.lower()` both `args.schema` and `args.table` before storing in state. Table names in dbt sources and PSA references are lowercase by convention. Fixed in `pipeline_orchestrator.py` lines 1658-1659.

54. **When manual_logic is populated, source_column must be (DERIVED) and source_table must be empty** — This tells `build.py` to place the logic in the LOGIC layer as a derived expression. BK aliases with `TO_CHAR()` casts are derived fields, not raw passthroughs. If source_column has a real column name AND manual_logic is populated, `build.py` misinterprets the column as both a passthrough and a derivation, causing duplicates or wrong placement.

55. *(Reserved — removed during consolidation)*

56. **Source Layer Filter / Final Layer Filter must include explicit WHERE** —
    build.py renders these verbatim into the CTE. Filter Conditions does NOT
    need WHERE (build.py adds it). This is how build.py distinguishes between
    SRC-level filters (verbatim) and FINAL-level conditions (auto-prefixed).

57. *(Reserved — removed during consolidation)*

58. **COALESCE/null replacement placement depends on column type:**
    - Required BK (grain-defining): COALESCE in STAGING — NULL BKs hash
      to identical values causing hub collisions. Use sentinel '-1'.
    - Optional BK or payload attribute: COALESCE in Business Vault
      (PB/PIT/REF) — NEVER in staging or raw vault.
    Raw vault stores 100% of source data as-is. Null replacement on
    payload is a soft business rule; belongs in BV only.





### 2026-04 — E2E Raw Vault Test: Multi-BK + Derived BK Fixes

59. **Derived BK expression must NOT leak into HK HASH formula** — When BK uses TO_CHAR(ID), the HK must hash the raw column ID, not the expression TO_CHAR(ID). The bk_raw_cols parser must strip function wrappers via regex and ::TEXT casts via split. (Bug #31)

60. **Hub BK datatype must reflect derivation, not source** — When BK is derived via TO_CHAR(NUMBER_COL), the hub BK column datatype must be TEXT, not the source column NUMBER. Check bk_has_func or manual_logic presence to override dtype. (XLSX Fix H1)

61. **Hub and LNK QUALIFY ORDER BY must always use LOAD_DTS** — Never use ingestion-specific columns (_FIVETRAN_SYNCED, GLCHANGETIME) in raw vault QUALIFY. LOAD_DTS is the canonical timestamp after staging. Ingestion columns are only valid in v_psa_stg SRC layer. (XLSX Fix H2/L1)

62. **SAT ghost record: raw BK payload columns use null ghost, not value_number** — Raw BK columns retained as payload in SAT (e.g., ID, PRODUCT_ID) must have ghost_record=null. They are NOT business keys in the SAT context — they are informational payload. Only the parent HK gets ghost=hash. (XLSX Fix LS1)

63. **STG SRC QUALIFY PARTITION BY must include ALL BK raw columns** — For multi-BK models, the dedup QUALIFY must partition by every raw BK column (e.g., ID, PRODUCT_ID) plus the ingestion timestamp. Missing a BK column allows duplicates to survive into the hash layer. (XLSX Fix ST1)

64. **Multi-BK models: use --additional-bk for extra BK aliases** — The primary `--bk` flag handles one BK expression (including composite BKs via comma-separated columns). For models needing additional independent BK aliases (e.g., `SUBSCRIBER_ID AS SUBSCRIBER_BK`), use `--additional-bk 'SUBSCRIBER_ID:SUBSCRIBER_BK'` (repeatable). This injects raw passthrough + BK alias columns into generate-yaml. `--hk` still controls HK formulas independently. *(Updated: previously required manual YAML editing; automated via lesson #127.)*

65. **HASHDIFF must exclude ALL BK raw columns, not just the primary** — When PRODUCT_ID is a raw BK column (for the secondary BK), it must be excluded from HASHDIFF. Any column used as input to ANY BK derivation is a BK raw col, not data. (XLSX Fix SC4)

66. **SAT/LSAT watermark: always inject regardless of volume tier** — ALL satellite models (SAT, LSAT, MSAT, LMSAT) must get the incremental watermark. The Normal tier no-watermark rule applies to HUBs only. This reverts lesson #47 for SATs specifically.

67. **SAT/LSAT YAML: no unique_key config** — FBIN uses append-only incremental strategy (set at dbt_project.yml level). unique_key is only needed for delete+insert strategy. make_yml.py must NOT add unique_key to SAT model configs.

68. **Source registration must happen during implement step** — The cmd_implement function must auto-register the PSA source table in _sources_staging_psa.yml before running dbt build. Without registration, dbt build fails with source not found. The _register_source() helper checks if schema+table already exist before adding.

69. **Hub final QUALIFY needs inline comment** — Add safety dedup comment before the final QUALIFY in hub models. This documents why the dedup exists (belt-and-suspenders for multi-source hubs) and matches existing production patterns.

70. **validate_tech_spec.py HK check: (DERIVED) is valid for multi-BK source columns** — When a secondary BK uses source_column=(DERIVED), the HK HASH formula validator should not flag (DERIVED) as a missing raw source column. The raw column is extracted from the manual_logic field, not source_column.


71. **NULL BK COALESCE prompt** — When null_bk_count > 0, cmd_approve_profile prompts user to choose `-1` (required), `-2` (optional), or no sentinel. Choice stored in state as null_bk_sentinel. cmd_generate_yaml wraps BK manual_logic with COALESCE if sentinel is set. (Implemented — KB 1.3)

72. **CLI inputs validated with regex** — `--schema`, `--table`, `--rec-src`, `--lnk-name`, `--multi-active-key`, `--domain` pass `IDENTIFIER_PATTERN`. `--bk` and `--secondary-bk` pass `BK_SAFE_CHARS` (rejects SQL terminators `;`, `--`, `/*`, `*/` and shell metacharacters). `--secondary-schema`, `--secondary-table`, `--secondary-alias`, `--secondary-bk-name` pass `IDENTIFIER_PATTERN`. Full BK expression validation implemented in H-1/H-2 audit follow-up (see lesson #125). (Code review fix #1)

73. **State files use atomic writes** — `_save_state` must use `tempfile.mkstemp` + `os.replace` (atomic on POSIX) to prevent corruption from concurrent pipeline runs. (Code review fix #3)

74. **No hardcoded tool paths** — `_get_dbt_binary` must use `DBT_BINARY` env var and PATH only. No developer-specific fallback paths. (Code review fix #4)

75. **YAML mutations require backup + re-parse** — `_register_source` must create `.bak` backup before writing, then re-parse with `yaml.safe_load` to detect corruption. Restores backup on failure. (Code review fix #5)

76. **ALWAYS use .venv/bin/python3 for automation** — System python3 does NOT have snowflake-connector-python installed. Every automation command must use `.venv/bin/python3 scripts/automation/pipeline_orchestrator.py`. This applies to ALL agent invocations, SKILL.md examples, and CLAUDE.md documentation.

77. **LOAD_DTS derivation depends on _FIVETRAN_DELETED presence, not just _FIVETRAN_SYNCED** — When `_FIVETRAN_DELETED` column EXISTS: use `CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)` (Fivetran handles deletes natively, _FIVETRAN_SYNCED is always reliable). When `_FIVETRAN_DELETED` does NOT exist AND `PSA_DELETE_IND` exists: use IFF pattern `CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, _FIVETRAN_SYNCED))` (PSA captures deletes separately, deleted records have stale _FIVETRAN_SYNCED).

78. **LNK HK hashes RAW source columns, not BK aliases — same rule as hub HK** — Per DV 2.1, ALL HKs (hub, link, SAT) must hash raw source column names. Link HK: `HASH: ID, PRODUCT_ID, BKCC` (raw columns), NOT `HASH: PRODUCT_VARIANT_BK, PRODUCT_BK, BKCC` (BK aliases). Consistency requires identical hash inputs across hub and link. Using BK aliases produces different hash values, breaking referential integrity.

79. **Ingestion detection: _FIVETRAN_SYNCED alone classifies as fivetran** — Some Fivetran connectors omit `_FIVETRAN_DELETED` or `_FIVETRAN_ID`. Requiring all three columns caused misclassification as "custom". Fix: check `_FIVETRAN_SYNCED in col_set` (not `FIVETRAN_COLS.issubset(col_set)`). Similarly, `GLCHANGETIME` alone classifies as snp_glue.

80. **MANDT is a SAP business field, not GLUE metadata** — Remove MANDT from SNP_GLUE_COLS and TECHNICAL_COLS. Keep in HASHDIFF_EXCLUDE (static SAP client ID, not change-tracked). MANDT appears as regular data in output, not technical metadata.

### 2026-04 — Multi-Table v_psa_stg Support

81. **When BK is a derivation (COALESCE/CONCAT), HK hashes the BK alias** — Hash logic already handles NULL. Use raw column only for simple casts (e.g., `HASH: ID, BKCC` for `TO_CHAR(ID)`). For derived BKs like `COALESCE(ORD_NAME, '-1')`, HK uses the alias: `HASH: ORDER_HEADER_BK, BKCC`.

82. **Secondary table columns MUST be renamed in LOGIC layer if same name exists in driver** — Pattern: `ORD.ID → ORD_ID`. Auto-rename using `{ALIAS}_{COL}` prefix. Collision detection runs during mini-profile. BK expressions must reference the renamed column name.

83. **Secondary table requires mini-profile for ingestion type detection** — Determines dedup QUALIFY ORDER BY: fivetran → `_FIVETRAN_SYNCED DESC`, snp_glue → `GLCHANGETIME DESC`, custom → `PSA_LOAD_DTS DESC`. Mini-profile queries INFORMATION_SCHEMA.COLUMNS only (no row count/grain check needed).

84. **QUALIFY on driver table ONLY when grain_valid=False** — Never add QUALIFY when profile confirms unique BK+LOAD_DTS. Previously the automation always added QUALIFY to the driver — this is wrong for valid-grain tables and was adding unnecessary compute. Implemented via `resolve_driver_qualify()` in `multi_table.py`.


85. **When user specifies secondary table without columns, ASK for lookup columns** — Don't guess what the user needs from the lookup table. Minimum: join key + BK source columns. Prompt displays available non-metadata columns.

86. **Secondary table schema/table always lowercase** — Lesson #53 applies to secondary tables. Enforced in `parse_secondary_state()`.

87. *(Consolidated into #76)* — Duplicate: `.venv/bin/python3` for automation commands.


88. **Join predicate columns must exist in Columns sheet with post-rename names** — `build.py` constructs the JOIN layer as `LOGIC_{alias}.{col}`, so the column must appear as a `staging_column_name` for that `source_table` in the Columns sheet. For secondary tables: the `child_table_join` is the column name only (e.g., `ORD_ID` not `ORD.ORD_ID`) — `build.py` qualifies it with `LOGIC_{alias}` using the alias from the table row. For driver tables: the `parent_table_join` column already exists in the Columns sheet. Validation check #23 and MT3 in `validate_tech_spec.py` enforce this.

89. **HK hash components: simple cast → raw column, derivation → BK alias** — When BK is a simple type-cast (TO_CHAR, ::TEXT, CAST AS), the HK hash formula uses the raw source column name (e.g., `HASH: ID, BKCC`). When BK is a derivation (COALESCE, CONCAT, IFF), the HK uses the BK alias (e.g., `HASH: ORDER_HEADER_BK, BKCC`). Link HKs apply this per-component: `HASH: ID, ORDER_HEADER_BK, BKCC` where ID is simple-cast and ORDER_HEADER_BK is COALESCE. Helper `_is_simple_cast_bk()` in `pipeline_orchestrator.py` decides.

90. **LNK HK naming uses table names, not BK entity names** — Link HK columns use the source table names (uppercased) for the entity segments: `LNK_{sec_table}_{driver_table}_HK` (e.g., `LNK_ORDER_FULFILLMENT_HK` not `LNK_ORDER_HEADER_FULFILLMENT_HK`). This matches the DV convention where links describe relationships between source tables.

91. **Raw Vault design prompt appears after approve-xlsx, not after implement** — When a pipeline has `objects == ['stg']`, the orchestrator shows a "RAW VAULT — Design Decision" prompt after `approve-xlsx` with two options: (A) continue STG-only with `generate-code`, or (B) use `add-raw-vault` to inject hub/lnk/sat into the existing pipeline. The `add-raw-vault` command does a surgical reset of only `generate-code` and downstream steps, preserving profile and XLSX approval. The old post-implement RAW VAULT prompt has been removed.

92. **Pipeline must validate --sec-bk-expr column references against post-rename column list** — If the BK expression references a column name that doesn't exist after collision detection + rename, STOP and raise ValueError with available columns and a "Did you mean?" suggestion. Caught during fulfillment E2E — user provided `COALESCE(ORD_NAME, '-1')` but `NAME` was not renamed (no collision), so correct expr was `COALESCE(NAME, '-1')`. Implemented in `validate_bk_references_renamed_columns()` check #2 in `multi_table.py`.

93. **BKCC can enter staging SQL via two paths — guard against dual injection** — Path A: Tables tab BKCC source row (added by `generate_tech_spec.py` when `bkcc_rec_src` is set, alias `ref_bkcc`). Path B: hardcoded `SRC_BKCC` CTE injection in `build.py` (when `bkcc_rec_src` is passed via YAML config). If both fire, JOIN_RESULT gets duplicate BKCC/REC_SRC columns. Guard in `build.py`: skip `SRC_BKCC` injection if Tables tab already has a `ref_business_key_collision` source row. The XLSX path (orchestrator `generate-code`) uses Path A; the YAML path (`main.py --yaml-config`) uses Path B. The guard ensures they are mutually exclusive. Discovered during Copilot PR review of Phase 4.

94. **When doing bulk find-and-replace for path prefixes, use exact-match anchoring** — Replace `"python3 scripts/"` not `".venv/bin/python3"` to avoid doubling paths that were already correct. Caught during Copilot PR review round 2 — 5 SKILL.md files had `.venv/bin/.venv/bin/python3` because the replacement matched the already-prefixed path. Also verify `_resolve_source_name()` path traversal: `Path(__file__).resolve().parent.parent` from `scripts/automation/` lands at `scripts/`, not repo root. Use `.parents[2]` to reach repo root.

### 2026-05 — Composite Grain & BK Cast Fixes

95. **BK derivation detection uses inverted logic: PLAIN_COLUMN_RE** — If the BK expression matches `^[A-Z_][A-Z0-9_]*$`, it's a raw column. ANYTHING else (functions, casts, operators, expressions) sets `source_column=(DERIVED)` and `source_table=""`. `_infer_bk_datatype()` infers `staging_datatype` from the expression (::TEXT→TEXT, TO_NUMBER→NUMBER, etc.). This replaces the fragile `bk_has_func`/`bk_has_cast` pattern matching that missed edge cases (original fix #95: `::TEXT` cast was missing `(DERIVED)`).

96. **When user provides --grain-columns, run two-phase grain validation** — Phase 1 (automatic): BK + LOAD_DTS → screening check. Phase 2 (triggered by --grain-columns): full composite + LOAD_DTS → definitive check. If composite grain is unique → grain_valid=True → no QUALIFY. If still duplicates → QUALIFY with composite columns. Phase 2 only runs when --grain-columns is provided. Without it, Phase 1 is definitive and QUALIFY injection is correct. The composite grain columns are stored in pipeline state and flow through to: (a) XLSX QUALIFY PARTITION BY columns, (b) COMPOSITE unique test field, (c) MSAT PK composition via state["sat"]["grain_columns"] — so users don't re-specify grain at SAT generation time. (See lesson #114 for ingestion-aware LOAD_DTS refinement.)

97. **source() first argument resolution** — (1) check if physical schema matches a source NAME directly (common case: name == schema), (2) if no match, check if physical schema matches any source's `schema:` override field (alias case: name != schema), (3) if still no match, use physical schema as-is (new unregistered source). Same resolution applies to `_register_source()` when finding where to append a table. `build.py` `_resolve_source_name()` accepts `rootdir` param (not `__file__` traversal) for locating `_sources_staging_psa.yml`. Majority of sources use name == schema; a few (e.g., `home_depot_ft_psa` → `custom_fivetran_home_depot_askuity_sdk`) use aliases.

98. **Approval gates (approve-profile, approve-xlsx, approve-code) require human review before proceeding** — The orchestrator records approvals as state transitions; the agent instructions (lesson #107) enforce that agents must show outputs and ask before running approve commands. When running the CLI directly, experienced engineers self-enforce review by inspecting profile/XLSX/code output before running the approve command. The `--stg-only` flag on `generate-code` remains as the hard code-level gate for the design decision. This prevents automated pipelines from bypassing human review checkpoints that exist to catch grain issues, column ordering errors, and HASHDIFF composition mistakes before code generation.

99. **Composite BK parser must handle commas inside function parentheses** — `COALESCE(NAME, '-1')` is a single BK expression, not two BK columns. Use `_split_bk_parts()` with paren-depth tracking instead of naive `str.split(",")`. Without this, any BK expression containing a function with comma-separated arguments (COALESCE, LEFT, CONCAT, IFF, etc.) would be incorrectly split into multiple BK columns, producing wrong raw_cols extraction and broken HK formulas. Caught during regression test development.

100. **BK validator `split('(')[-1]` fails for nested functions with string literals** — e.g., `COALESCE(NULLIF(UPPER(TRIM(COL)),''),'-1')` extracts `'-1'` instead of `COL`, failing IDENTIFIER_PATTERN validation. The naive approach splits on `(` and takes the last segment, which hits the string literal, not the column name. Fix: use regex to extract the innermost column identifier, skipping string literals. Workaround: pass the raw column name to `--bk`, add the full derivation expression in XLSX Columns tab. Caught during E2E stress test of multi-BK promo model.

101. **`_is_simple_cast_bk()` must match plain column names as the simplest case** — A raw column like `PROMO_NAME` is simpler than `TO_CHAR(ID)` — it's an identity transform. The `_SIMPLE_CAST_RE` regex only matched function/cast patterns (`TO_CHAR(...)`, `COL::TEXT`, `CAST(... AS ...)`), missing the base case of a plain identifier. This caused HK formulas to use BK alias instead of raw column name, failing XLSX validation check #9. Fix: add plain identifier pattern `r'|^[A-Za-z_]\w*$'` to `_SIMPLE_CAST_RE`. This is the HK-formula counterpart to the `PLAIN_COLUMN_RE` refactor in lesson #95. Caught during E2E stress test of promo model.

### 2026-05 — E2E Stress Test: Multi-BK Raw Vault (consolidated_promo_flow_input)

102. **`add-raw-vault` display prints `parent=?` for SAT because state key is `parent_hk` not `sat_parent_hk`** — The display code reads `sat_info.get('sat_parent_hk', '?')` but `cmd_add_raw_vault` stores the key as `parent_hk` (no `sat_` prefix). Cosmetic bug only — the state is correct, only the confirmation display is wrong. Fix: change the `.get()` key to `parent_hk` in the display block (~line 3900 of pipeline_orchestrator.py). Caught during E2E stress test.

103. **HUB BKCC column override requires manual YAML edit when entity BKCC differs from staging column name** — If the v_psa_stg model renames BKCC (e.g., `ERP_BKCC`→`BKCC`), the hub generator hardcodes `source_column: BKCC`. For hubs consuming a v_psa_stg with a non-standard BKCC column name, the YAML config must be manually edited to set `source_column: ERP_BKCC` and `staging_column_name: BKCC`. Feature request (P2): auto-detect BKCC column name from v_psa_stg YAML config and propagate to hub YAML. Validated during E2E test — the override worked correctly through YAML→XLSX→build.py.

104. **LNK FK tests to parent hubs not auto-generated when parent hubs are external** — The LNK YAML generator creates PK and row-count tests but omits `dbt_constraints.foreign_key` tests to parent hubs. This is expected when parent hubs (e.g., `hub_base_material`, `hub_key_account_group`) exist in different pipelines. Feature request: auto-generate FK tests for parent hubs that exist in the dbt project (discoverable via `ref()`), skip for unknown hubs with a TODO comment. Caught during E2E test — LNK SQL was correct but YAML schema incomplete.

105. **LMSAT generation gaps for complex models: PK denormalization, derived multi-active keys, and cross-reference lookups** — Three gaps identified in LMSAT generation: (1) PK `combination_of_columns` only includes `LNK_HK + VERSION_SEQ` but should also include denormalized BK columns (`PROMO_ID`, `PROMO_START_DATE_DT`, `PROMO_END_DATE_DT`) for composite grain, (2) NOT EXISTS block similarly misses denormalized BK columns, (3) `VERSION_SEQ` is a derived `ROW_NUMBER()` column but SAT generator treats it as a source column, (4) cross-reference lookup columns (from secondary/lookup tables) are not wired into SAT HASHDIFF or column list. These are P2/P3 scope features. Documented during E2E stress test.

106. **generate-code must require explicit design decision for STG-only pipelines** — When objects == ['stg'], generate-code refuses to run unless --stg-only flag is provided or add-raw-vault was already run. This prevents && chaining and Copilot auto-continuation from skipping the Raw Vault design decision prompt. approve-xlsx prints the prompt but cannot enforce the stop — generate-code enforces it by checking state["design_decision"]. sys.exit(1) breaks && chains.

107. **Agent must NEVER make design decisions on behalf of the user** — When the orchestrator prints a design decision prompt (Raw Vault options, domain selection, model naming), the agent MUST surface the full prompt to the user in chat and wait for explicit choice. The agent is a facilitator, not a decision-maker. The --stg-only flag prevents code-level bypass of the design decision gate, and agent instructions (in CLAUDE.md, copilot-instructions.md, and all agent .md files) prevent behavioral bypass. The --reviewed flag was removed from approve gates (May 2026) because this lesson's instruction rule is the authoritative enforcement layer — experienced engineers running the CLI directly do not need a redundant flag. Caught during E2E testing: Copilot auto-chose --stg-only without asking.

### 2026-05 — ADD-SOURCE Safety: Collision Report Visibility

108. **⛔ add-raw-vault must ALWAYS surface collision report (especially ADD-SOURCE) to the user** — When `_semantic_collision_check` detects a hub/lnk as `ADD-SOURCE`, the collision report was previously only printed if `blocked=True`. Since ADD-SOURCE is informational (not a blocker), the warning was silently swallowed. This is extremely dangerous: the user sees "Raw Vault objects added: hub" with no indication that `hub_retailer` already exists with 20 sources. If the user proceeds through generate-code → implement without the ADD-SOURCE surgical injection path working correctly, it could overwrite the production hub with a single-source version, breaking all downstream lineage. Fix: (1) Always print `_print_collision_report()` regardless of block status, (2) Add explicit ⚠️ warning when hub is ADD-SOURCE explaining the surgical injection behavior. The collision report must be visible at every decision point, not just on hard blocks.


### 2026-05 — Phase 4 Safety Hardening

109. **Pass user-provided grain columns to `--grain-columns` on `init`, not `profile`** — When the user specifies composite grain columns (e.g., `Grain: col_a, col_b, Load_dts`) in their initial request, the agent MUST include `--grain-columns "COL_A,COL_B,PSA_LOAD_DTS"` on the `init` command. The `profile` subcommand does NOT accept `--grain-columns`; it reads them from pipeline state set during `init`. Failing to pass grain columns at init causes single-phase validation (BK + PSA_LOAD_DTS only), which reports false-positive duplicates and forces the user to re-specify what they already provided. Also note: the user may say `Load_dts` but the actual PSA column is `PSA_LOAD_DTS` — always map to the real source column name.

110. **`--force` must NEVER overwrite hub or link files** — Hubs and links are shared models containing sources from multiple pipelines. `implement --force` may only overwrite STG and SAT files (single-pipeline ownership). Before Fix 1, `--force` could destroy a multi-source hub like `hub_payment_term` (5 sources) by replacing it with a single-source version. The orchestrator now always refuses to overwrite existing hub/link files regardless of `--force`.

111. **PreToolUse hook must block direct `.pipeline_state/` writes** — Pipeline state files (`.pipeline_state/*.json`) must only be modified by the orchestrator itself. Before Fix 2, an AI agent could directly edit state files to bypass approval gates or alter step history. Rule 7 in `pre_tool_guard.py` now blocks Write/Edit operations targeting `.pipeline_state/` paths.

112. **ALREADY-ADDED alias collision must warn and skip, not error** — When `implement` runs ADD-SOURCE and the source alias already exists in the hub, the orchestrator should print a warning and skip (rc=0) instead of failing (rc=1). This enables idempotent recovery: if a previous run partially completed (hub updated but SAT not placed), `implement --skip-hub` lets the user retry without re-touching the hub. Before Fix 3, a duplicate alias caused a hard error that blocked the entire run.

### 2026-05 — E2E Session Remediation (Payment Terms Pipeline)

113. **~~Source registration MUST use YAML dict manipulation, NOT string append~~ (SUPERSEDED by #122)** — The _register_source() function is the critical write path for _sources_staging_psa.yml. The old line-by-line string matching approach (find the schema block by pattern matching, insert new table lines) was fragile and caused collateral damage: it created new top-level source blocks instead of appending under the correct schema, and accidentally deleted unrelated source entries during cleanup (e.g., sap_bw_prd's z_zapopland/z_zapoplanm). The dict-dump approach described here was subsequently replaced by #122's surgical string insertion (`safe_load` for read + raw line insertion) to eliminate cosmetic drift from `yaml.dump()` re-serialization. See #122 for current implementation. (Remediation Fix #1)

114. **Composite grain validation (lesson #2 refinement): ingestion-aware load timestamp + two-phase check** — When user provides --grain-columns on init (e.g., "PAYMENT_TERM_BK,SETID,EFFDT,NET_TRMS_SEQ_NBR"), the profile must validate composite grain + ingestion-aware LOAD_DTS uniqueness instead of BK+PSA_LOAD_DTS. Ingestion type determines the LOAD_DTS column:
- **Fivetran sources** (has _FIVETRAN_DELETED or _FIVETRAN_SYNCED): use `CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)` — per-record change timestamp
- **SNP GLUE sources** (has GLCHANGETIME): use GLCHANGETIME — SAP change log time
- **Custom sources with audit cols**: use MODIFIED_DT+CREATION_DT (both if both exist); use only MODIFIED_DT if only it exists; use only CREATION_DT if only it exists
- **Custom sources without audit cols**: fall back to PSA_LOAD_DTS
Two-phase validation: (1) Automatic phase: BK+PSA_LOAD_DTS (screening check), (2) Composite phase (when --grain-columns provided): use composite grain + ingestion-aware LOAD_DTS (definitive check). If composite grain is unique → grain_valid: true → no QUALIFY needed (eliminates --force requirement). If still duplicates → inject QUALIFY with composite columns. The same composite grain columns are stored in pipeline state and flow through to: (a) v_psa_stg QUALIFY PARTITION BY, (b) unique test combination_of_columns, (c) Raw Vault PK composition. (Remediation Fix #2) (Custom source audit-column logic not yet implemented in cmd_profile — deferred to next phase.)

115. **Generate-yaml HK formula confirmed correct** — `_is_simple_cast_bk()` + `bk_raw_cols` logic at line 2998 correctly uses raw source column names for simple-cast BKs and BK alias only for derived BKs (COALESCE, CONCAT). Check 9 in `validate_tech_spec.py` validates this at XLSX generation time. Verified during E2E testing — 22/22 checks passed for both payment_terms models. No code change needed. (Remediation Finding #3 — investigated, confirmed working)

116. **Gate enforcement (lesson #107 operational): block --force approvals and && gate chains** — Approval gates (approve-profile, approve-xlsx, approve-code) require explicit human review between steps. PreToolUse hook Rule 9 denies any command with --force or --reviewed flags on approve-* commands. Rule 10 denies && chains that cross gate boundaries (2+ gate commands in one invocation). The scope is: approve-profile, approve-xlsx, approve-code (gates), plus generate-code and implement (design decision steps). Non-gate commands (generate-yaml, generate-xlsx, profile, show-*) can be chained freely. Each gate must be run in a separate terminal invocation with user review/approval between. This enforces lesson #107: agents and engineers must surface warnings/outputs to the user and await explicit confirmation before proceeding to the next gate. (Remediation Fix #4 — Rule 9 & Rule 10 in pre_tool_guard.py)

117. **dbt Cloud CLI pre-flight: run `dbt cancel` before build/test to clear stuck sessions** — The "Session occupied" error occurs when a prior dbt invocation left a lock on the dbt Cloud session. The fix is permanent: before running `dbt build` or `dbt test`, always run `dbt cancel 2>/dev/null` as a pre-flight to clear any stuck state. The _run_dbt() function now checks if args_list contains "build" or "test", and if so, runs the cancel pre-flight first. This is a no-op if there's no stuck session, but prevents the "Session occupied" hang that was blocking pipeline progress. Note: the "stream tail hang" (log output hangs after build succeeds) is a separate dbt Cloud bug that may be fixed in version 0.40.17 update (upgrade available in logs). (Remediation Fix #5)

119. **MSAT code generator must use grain_columns (full composite grain), NOT just multi_active_key, in WHERE NOT EXISTS and QUALIFY** — When a multi-active satellite has a composite grain (e.g., SETID+EFFDT+NET_TRMS_SEQ_NBR), the `_build_sat_yaml_model()` function was only using `multi_active_key` (typically a single column like "NET_TRMS_SEQ_NBR") for the WHERE NOT EXISTS join conditions and QUALIFY PARTITION BY clause. This produced incorrect dedup logic that missed grain columns SETID and EFFDT, causing potential duplicate inserts. Root cause: `--multi-active-key` at init captures only the "distinguishing" key for the multi-active pattern, while `--grain-columns` captures the full composite uniqueness grain. The generator must prefer `grain_columns` (from sat_def or state) over `multi_active_key.split(',')`. Fix: introduce `_grain_keys` variable that resolves from sat_def.grain_columns → state.grain_columns → multi_active_key.split(',') (fallback for backward compat). Apply `_grain_keys` to: (1) NOT EXISTS conditions, (2) PK string for XLSX Tables tab, (3) QUALIFY partition columns. Same fix needed in `build.py`'s `extract_pk_columns_from_existing_logic()` which reads PK from XLSX — but since the XLSX now gets the correct PK string, the downstream is automatically correct. Test: `test_msat_grain_columns.py` (4 scenarios). (Remediation Fix #6 — Root Cause)

118. *(Reserved — referenced bug was not reproducible; consolidated into #120)*

119. **MSAT code generator must use grain_columns (full composite grain), NOT just multi_active_key, in WHERE NOT EXISTS and QUALIFY** — When a multi-active satellite has a composite grain (e.g., SETID+EFFDT+NET_TRMS_SEQ_NBR), the `_build_sat_yaml_model()` function was only using `multi_active_key` (typically a single column like "NET_TRMS_SEQ_NBR") for the WHERE NOT EXISTS join conditions and QUALIFY PARTITION BY clause. This produced incorrect dedup logic that missed grain columns SETID and EFFDT, causing potential duplicate inserts. Root cause: `--multi-active-key` at init captures only the "distinguishing" key for the multi-active pattern, while `--grain-columns` captures the full composite uniqueness grain. The generator must prefer `grain_columns` (from sat_def or state) over `multi_active_key.split(',')`. Fix: introduce `_grain_keys` variable that resolves from sat_def.grain_columns → state.grain_columns → multi_active_key.split(',') (fallback for backward compat). Apply `_grain_keys` to: (1) NOT EXISTS conditions, (2) PK string for XLSX Tables tab, (3) QUALIFY partition columns. Same fix needed in `build.py`'s `extract_pk_columns_from_existing_logic()` which reads PK from XLSX — but since the XLSX now gets the correct PK string, the downstream is automatically correct. Test: `test_msat_grain_columns.py` (4 scenarios). (Remediation Fix #6 — Root Cause)

120. **SAT-only pipelines: validate parent hub exists + FK constraint is mandatory** — When user requests --objects "sat" without hub, the orchestrator must: (1) validate that --sat-parent-model exists in models/raw_vault/hub/ or models/raw_vault/link/ — warn if not found, (2) ALWAYS generate dbt_constraints.foreign_key test in SAT YAML pointing to the parent hub/link, regardless of whether hub was generated in this pipeline run — this is a DV 2.1 standard, not optional, (3) display proposed test configuration (PK, FK, row count) at the approve-code gate for user review. The FK constraint ensures orphan detection: records that make it into the child SAT without existing in the parent hub are flagged. This was validated during the payment_terms E2E session — FK to hub_payment_terms survived manual HUB removal and correctly remained in the MSAT YAML. Codify as standard: every SAT/LSAT/MSAT/LMSAT/ESAT must have FK to its parent. Note: the cmd_add_raw_vault() merge logic already correctly respects --objects (no auto-injection of HUB) — the bug described during E2E testing was not reproducible in the current code. (DV 2.1 referential integrity enforcement)

### 2026-05 — Source Registration Fix: Surgical String Insertion

122. **`_register_source()` replaced ruamel.yaml round-trip with surgical string insertion** — The old implementation used ruamel.yaml for round-trip YAML writes, which normalized indentation on write, causing cosmetic changes to nearby entries in `_sources_staging_psa.yml`. Fixed by switching to Option A: `safe_load` for reading/locating the source block + duplicate check, then raw line insertion via `_find_source_table_insert_line()` and `_detect_table_entry_indent()` helpers. Atomic write via `tempfile.mkstemp` + `os.replace` + `safe_load` validation. Produces clean 2-line diffs with zero cosmetic drift. Idempotent (returns False if table already registered). Tested with both direct-name and alias source resolution (lesson #97).


### 2026-05 — Ingestion-Aware Grain Validation

121. **Grain validation must use ingestion-aware LOAD_DTS expression, not raw PSA_LOAD_DTS** — For SNP GLUE sources, using `PSA_LOAD_DTS` in the grain check produces false-positive duplicates because the original record and its delete marker (PSA_DELETE_IND='Y') share the same GLCHANGETIME but get different PSA_LOAD_DTS values in different batches. The correct grain LOAD_DTS expression per ingestion type: fivetran → `CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)`, snp_glue → `IFF(PSA_DELETE_IND='Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ(SUBSTR(GLCHANGETIME,1,14)||'.'||SUBSTR(GLCHANGETIME,16),'YYYYMMDDHH24MISS.FF9')))`, custom → `PSA_LOAD_DTS`. This applies to BOTH Phase 1 (BK+LOAD_DTS) and Phase 2 (composite+LOAD_DTS) grain validation. Additionally, the previous concatenation-based `COUNT(DISTINCT BK || '~' || TO_VARCHAR(PSA_LOAD_DTS))` approach was replaced with `GROUP BY` counting to avoid timestamp formatting precision loss. Ingestion detection was moved before the grain check since it only needs column names (available from step 2).

123. **Two registrations, two artifacts, two workflows** — Source registration in this pipeline has two distinct artifacts that must never be conflated: (1) BKCC/REC_SRC in Snowflake `REF_BUSINESS_KEY_COLLISION`, registered via Streamlit app, validated by profile step [8/9]; (2) dbt source YAML in `_sources_staging_psa.yml`, auto-registered by orchestrator's `implement` command via `_register_source()` (lines 3920-4046), validated by profile step [9/9] via grep. The two checks query different artifacts and have different remediation paths. Agent messaging must distinguish them; orchestrator step [9/9] message must explicitly say "will be auto-registered during implement" rather than the ambiguous "needs registration." Validated against `fix/composite-grain-messaging` branch E2E where `prive_moen` was registered in BKCC table (step [8/9] passed) but not yet on branch's source YAML (step [9/9] reported NEW) — the warning text caused unnecessary alarm despite `implement` auto-handling registration.

124. **Stream dbt build output to prevent subagent black hole** — `_run_dbt()` used `subprocess.run(capture_output=True)` which buffers ALL stdout until the process exits. During `implement` step [3/5], the terminal goes silent for 2–5 minutes while dbt runs, causing AI subagents to interpret silence as completion and return early with "in progress" status. Fix: replaced with `subprocess.Popen` + line-by-line streaming to stdout. Also: Coordinator must NEVER manually edit `_sources_staging_psa.yml` — the orchestrator's `implement` command auto-registers sources. The debug log showed the Coordinator wasting 352s on a manual append → revert → investigate detour. Validator agent must use `timeout: 600000` (10 min) on `run_in_terminal` for implement commands.

125. **BK expression validation (defense-in-depth)** — All BK expressions (`--bk`, `--secondary-bk`) must pass `BK_SAFE_CHARS` regex and reject SQL terminators (`;`, `--`, `/*`, `*/`). All secondary identifier params (`--secondary-schema`, `--secondary-table`, `--secondary-alias`, `--secondary-bk-name`) must pass `IDENTIFIER_PATTERN`. Defense-in-depth: Snowflake connector rejects multi-statement by default, but input-boundary validation prevents SQL parser confusion and improves error messages. Extraction reinterpretation warning emitted when `_extract_raw_col_from_bk` output differs from input. *(Promoted from Proposed; security severity upgraded per H-1/H-2 audit.)*

126. **Subagent dispatch must respect orchestrator STOP gates** — The Coordinator MUST NOT dispatch a worker past a STOP gate. After each orchestrator command, the Coordinator presents results and waits for explicit user approval. Cross-gate dispatch (e.g., running `implement` immediately after `generate-code` without user review) is forbidden. For Option B (add-raw-vault), this requires splitting into Dispatch 3a (`approve-xlsx` + `add-raw-vault` + `generate-yaml` + `generate-xlsx` → present regenerated XLSX) + Dispatch 3b (`approve-xlsx` + `generate-code` + `show-code`) with a mandatory user gate between. Note: `add-raw-vault` clears `generate-yaml`, `generate-xlsx`, and `approve-xlsx` from state (orchestrator surgical reset at line 4718), so 3a must regenerate them before the user can review the RV-augmented XLSX. NEVER fabricate registration warnings — repeat ONLY what the orchestrator outputs. *(Promoted from Proposed; validated by multi-agent architecture audit.)*

127. **--additional-bk for multi-BK models** — When a v_psa_stg needs multiple independent BK aliases from one or more tables (e.g., `ID → SUBSCRIPTION_ORDER_BK` + `SUBSCRIBER_ID → SUBSCRIBER_BK`), use `--additional-bk 'RAW_COL:BK_ALIAS'` (repeatable, `action='append'`). This is purely additive: primary `--bk`/`--bk-name` semantics unchanged, composite BK comma-separation preserved, `--hk` handles HK formulas independently. The flag injects raw column passthrough + BK alias entry into generate-yaml columns. Validated by multi-table E2E (subscription_order__winn_prive).

### 2026-05 — MSAT Grain Column Exclusion Fix

128. **MSAT/LMSAT: grain_columns must exclude parent_hk to prevent duplicate PK/NOT EXISTS entries** — When `_build_sat_yaml_model()` builds PK and NOT EXISTS clauses for multi-active satellites, `parent_hk` is inserted first (position 0 in `pk_parts`, first WHERE condition in NOT EXISTS). If `--grain-columns` includes the parent HK name (e.g., `DELIVERY_HK,SERIALNO,LOAD_DTS`), the grain filter must exclude it. Both `_PK_EXCLUDE_COLS` and `_NE_EXCLUDE_COLS` sets must include `parent_hk.upper()`. Regular SAT/LSAT pipelines are unaffected because `is_multi_active` is False and the grain loop is skipped. Defense-in-depth: `extract_pk_columns_from_existing_logic` in `build.py` should dedup PK columns to catch any manual XLSX edits. Fixed in `pipeline_orchestrator.py` lines ~898 and ~953, and `build.py` line ~215.

### 2026-05 — Duplicate --bk Flag Guard

129. **`--bk` / `--bk-name` are single-value argparse flags — duplicates silently overwrite** — When `init` receives `--bk ID --bk-name SUBSCRIPTION_ORDER_BK --bk SUBSCRIBER_ID --bk-name SUBSCRIBER_BK`, argparse keeps only the LAST value (`SUBSCRIBER_ID` / `SUBSCRIBER_BK`), dropping the primary BK with zero warning. This caused `_build_hub_yaml_model` to derive `short_name: SUBSCRIBER` instead of `SUBSCRIPTION_ORDER`, producing a hub internally keyed on `SUBSCRIBER_HK` even though the hub file was correctly named via `--hub-name`. Fix: (1) hard-stop in `cmd_init` that counts `--bk` / `--bk-name` occurrences in `sys.argv` and exits with an actionable error message pointing to `--additional-bk RAW_COL:BK_ALIAS`; (2) safety-net warning in `_build_hub_yaml_model` when hub override entity name diverges from primary BK entity. Coordinator agents must use `--bk` for the **primary hub BK only** and `--additional-bk` for all other BKs.

### 2026-05 — Pre-Build Review + Incremental Dry-Run

130. **Pre-build code review + incremental dry-run validation** — The implement command now runs code review at step [3/8] BEFORE dbt build, saving warehouse costs when standards violations are detected. Additionally, step [5/8] runs `dbt run --empty` on Raw Vault models AFTER the initial build to validate incremental block SQL syntax. This catches errors (dangling AND, missing JOIN ON, bad column refs) inside `{% if is_incremental() %}` blocks that `dbt compile` cannot detect because `is_incremental()` returns False for new models. The dry-run only fires when Raw Vault models are present (skipped for STG-only pipelines). Dry-run failure blocks PR (syntax error will break next incremental load).

### 2026-06 — Credential-Safety & Process Lessons (Ratified Post-Packet)

Lessons in this subsection use the format: `Title — Enforcement: <target> | <core rule> | <packet proof> | *Ratification note:* <reasoning>`. They are cross-cutting process lessons rather than code-generation rules and intentionally carry an explicit enforcement-target annotation.

- **Canonical-home propagation rule (Finding-M lesson)** — **EXTRACTED 2026-06-19** to [`docs/conventions/canonical-home-rule.md`](../../docs/conventions/canonical-home-rule.md). The rule's own ratification note flagged a promotion trigger ("*promote to a standalone conventions doc when a second cross-cutting rule joins it*"); the trigger fired when the **enumeration discipline** rule reached its promotion threshold. The conventions directory is itself a load-bearing instance of the rule applied to itself. Cite the canonical home, not this entry, going forward.

- **Enumeration discipline (consumer-of-multi-exit-producer)** — **RATIFIED 2026-06-19** at [`docs/conventions/enumeration-discipline.md`](../../docs/conventions/enumeration-discipline.md). When specifying a consumer of a multi-exit-path producer (e.g., a sync Python function with 4 exit categories: return / `Exception` raise / `Exception` propagation / `BaseException` propagation), enumerate the producer's full exit-category set first before specifying the consumer's behaviour. Promotion record: 3 data points across C1.5 spec v3.2 → v3.3 → v3.4 + 2 confirmed falsifiable predictions. The companion **stopping-point** candidate (banked-with-prediction in the same file) is gated on build-phase confirmation and tracks build-phase bug classifications until promoted or refuted.

- **Fix+proof must ship atomically** — Enforcement: `code_reviewer.py` (warn-level, M5) | Any behavior-changing safety fix must ship in the same commit as the proving test that demonstrates the new behavior. Splitting fix and proof creates a window where the suite can be green-on-broken or red-on-correct. Packet proof: PR2 (audit-before-transform + inverted proving test) shipped as a single non-severable commit (`8fed502b`). | *Implementation note:* Trigger on commits touching `scripts/automation/src/triage/*` with no test file staged; surface as warning "confirm fix+proof atomicity (lessons.md rule): is the proving test for this fix included in this commit?" Framed as question (human conclusion), not assertion. False positives (doc-only changes, unrelated test edits) cost one reviewer glance. Implemented as check M5 in commit `393f985f`.

- **Cadence-as-signal operational rule** — Enforcement: human-only | Repeated same-class catches in one session are a signal to slow cadence and re-anchor state before further edits (verify bytes, restate assumptions, then continue). Logging the catch is necessary but not sufficient; pace adjustment is the control. | *Ratification note:* No commit-time signal available; documented as session/retrospective discipline.

- **Verification durability pair (must be applied together)** — Enforcement: human-only | (1) Verified results remain valid while their source bytes are unchanged (do not reset to UNVERIFIED after non-substantive table rebuilds). (2) Relayed line numbers/citations from prior sessions can drift; re-verify against current bytes before editing. Packet proof: PR3 corrected T3 map line drift (320→380) by reading source before patching. | *Ratification note:* Both halves are reviewer practice. Half 2 (re-verify line citations) is the closest of any four lessons to being mechanizable — could imagine a `code_reviewer.py` check flagging commits citing `file:line` to warn "verify against current bytes" — but it's a warning proxy, not enforcement, and fires on every legitimate line citation, training the ignore-reflex. Human-only is the honest call. Recorded here to prevent future "discovery" of the proxy without understanding the noise-cost tradeoff.

---

Lessons below are pending review. **Do NOT use these during generation** until approved.

### Approval Checklist

When moving a lesson from Proposed → Approved, choose its enforcement target:

| Can a machine enforce it? | Action | Example |
|---------------------------|--------|---------|
| **Yes — code pattern** | Add check to `code_reviewer.py` | Lesson #1 → `check_hk_uses_raw_columns()` |
| **Yes — pipeline behavior** | Implement in `pipeline_orchestrator.py` | Lesson #130 → step [5/8] dry-run |
| **No — affects generation** | Add to relevant agent's Key Rules section | Lesson #3 → Model Generator frontmatter |
| **No — human-only** | Leave in lessons.md, no further action | Lesson #6 → naming convention |

## Proposed

### 2026-06-20 — CI-Python Execution Before Claiming Gate Green (from PR #1821 triage-safety-tests first-run failure)

**Proposed by:** automation (entry 10 in `docs/triage-agent/lessons-learned.md` — recorded same day)
**Status:** Awaiting DataOps lead adjudication. Move to Approved if validated.

P1. **Execute the gate suite under the CI runner's Python version before claiming green** — Pre-push self-review's "Run the gate suite" step must use the gate's CI-pinned interpreter (e.g., Python 3.11 for `triage-tests.yaml`), not the developer's working Python. Version-sensitive behavior (recursion limits, stdlib internals, encoder thresholds) can pass on one Python and fail on another with no syntax-feature difference and no grep-able import change. The only pre-push catch is execution under the CI interpreter. Create or reuse a dedicated venv on that version (e.g., `/tmp/venv311/`) and record the version + pass count + duration in the commit message or pre-push block. Surfaced by PR #1821: `test_pathological_depth_handled_deterministically` passed under local Python 3.14 (the dev Python) and failed under CI's Python 3.11 because the JSON encoder's default recursion limit differs. The failure surfaced a deeper production gap (1 of 3 recursion sites guarded in `emit_single`'s per-payload `RecursionError` boundary), fixed in commit `53f1e7ad`.

P2. **File-level test-set reasoning ≠ runtime-level test-pass reasoning** — A "gate excludes that file" argument can be entirely correct as a file-set fact AND entirely miss the runtime failure variable (e.g., the Python version). PR #1821 originally claimed the merge-gate ran "green by subtraction" because the file containing 4 inherited failures was not in the gate's pytest list — bytes-true, but the gate suite ITSELF failed on first CI run for an unrelated reason (Python version sensitivity). File-level reasoning is static-set evidence; runtime-level reasoning requires execution. Do not substitute one for the other in pre-push self-review.

P3. **Bug-ledger classification: distinguish preventable-by-one-command from DA-uncatchable** — When recording a bug found by the project's own discipline, classify it: (a) *DA-uncatchable at design-time* (only execution after dependency upgrade surfaces it — e.g., Python 3.14 runtime incompat); (b) *DA-catchable structurally* (reviewer-grep can spot it — e.g., `@unique` enum decorator drift); (c) *DA-uncatchable mid-design* (the buggy form is the plausible-default a working programmer writes — e.g., C6 offset-stride bug `offset += page_limit`, caught only by adversarial cursor-advance review); (d) *preventable by one command* (the test was already written, the gate already authored, and one command pre-push would have caught it — e.g., PR #1821 boundary gap, caught only by running the gate under the CI's Python). The classes are not equivalent — class (d) has a one-command preventive that classes (a)-(c) do not, and conflating them flattens preventable-misses into the harder-bugs-caught-by-discipline column.

**Rationale.** The pipeline orchestrator and code reviewer have no built-in step that pins the Python version of the gate suite's pre-push validation. Adding a CI-Python venv as a documented requirement (and possibly as a Makefile target) is the lowest-friction way to close this class. The cost is one-time (`/tmp/venv311/` setup) and the gate suite runs in seconds; the cost of skipping it is one public-PR CI round-trip plus dual-finding triage under reviewer microscope.

**Cross-references.**
- `docs/triage-agent/lessons-learned.md` entry 10 (2026-06-20) — full narrative with the in-denominator ledger classification table.
- PR #1821 — public disclosure with the same two-class framing in the "Gate first-run finding" section.
- Commit `53f1e7ad` — the three-site bytes-mirror boundary completion fix.
- User-memory `quality-gates.md` Gate-5 — regression tests gate; this proposal would extend Gate-5 to specify the interpreter, not just "run the tests."

### 2026-07-29 — Link HK CTE-Staged Derivation (#1907)

**Proposed by:** automation (implementation of #1907 on `fix/1907-link-hk-cte-staged`)
**Status:** Awaiting DataOps lead adjudication. Move to Approved if validated.

P4. **Link HKs compose from participating hub HK *values*, not raw columns (DV 2.1) — via CTE-staged `HASH_FROM_HKS`** — A SELECT cannot reference a sibling alias, so hub HKs are pre-computed in a `HASH_STG` CTE and the link HK references them in FINAL as `MD5_BINARY(UPPER(CONCAT_WS('||', TO_VARCHAR(HUB1_HK), TO_VARCHAR(HUB2_HK), ...)))` — **no BKCC** (each hub HK already embeds its own). Two sources expressing the same relationship via matching hub HKs then produce the SAME link HK (join-correct across sources); raw-column composition does not. Supersedes the *link* clause of Approved lesson #51 ("Link HK hashes all parent raw BKs + BKCC"); #51's hub-HK clause is unchanged. Marker is `HASH_FROM_HKS:` from either the auto multi-table path or the manual `--hk "LNK_X_HK:@HUB1_HK,@HUB2_HK"` @-sigil (both converge on one marker). Renders `TO_VARCHAR` (not `CAST`) because bare `CONCAT_WS('||', <BINARY(16) hk>, ...)` does not compile in Snowflake, and `TO_VARCHAR`/`CAST` produce byte-identical hex — `TO_VARCHAR` additionally keeps the init-rv reverse-parser's hub (`CAST`) and link (`TO_VARCHAR`) extraction regexes textually disjoint (C-1) and makes the code reviewer's COALESCE/CAST-shaped `_HK_COMPONENT_RE` skip links (A2/A3/A4 and Q1/TRAP-01 no longer apply). Encoded in `build_final_layer`, `cmd_generate_yaml`, `_recover_stg_hash_keys`/`_recover_stg_final_columns`; locked by `tests/test_link_hk_cte_staged.py` (20 tests, incl. mutation guards + Snowflake-verified cross-source unification).

P5. **Verify an AI advisor/reviewer's *specific technical* claim against the live warehouse or the actual bytes before designing around it** — A confident, specific-sounding mechanism is still a CLAIM. #1907's design review asserted the reverse-parser's `CAST(\w+ AS VARCHAR)` regex "returns empty for link HKs after CTE-staging" because links would render bare `CONCAT_WS('||', HUB1_HK, HUB2_HK)`. Live Snowflake refuted the premise in ~30s: the bare form does not compile (`Invalid argument types … BINARY(16), VARCHAR(2), BINARY(16)`), so a cast is mandatory and the "empty regex" mechanism rested on SQL that cannot exist. The correct fix (deliberately render links with `TO_VARCHAR` to make the two regexes disjoint) surfaced only by testing the claim, not inheriting it. Companion to user-memory `verify-don't-inherit`: for SQL-shape and dependency-API claims, run the one-line probe (a literal `SELECT`, `inspect.signature`) before building on the assertion.

**Cross-references.**
- Issue #1907, PR on `fix/1907-link-hk-cte-staged`.
- `.github/instructions/raw-vault-link.instructions.md` (Link HK Composition) and `.github/knowledge/data-vault/07-link-modeling.md` (no-BKCC rule).
- Blocks promotion of code-reviewer `LNK_HK_INCLUDES_DCK` WARN→FAIL (the DCK-validator track's unblock).

## Archived

> **SUPERSEDED (2026-05-09)**: The following lessons document the architecture exploration
> journey for multi-agent dispatch in VS Code Copilot. They are preserved for institutional
> knowledge but are no longer active guidance. The working architecture is documented in
> `AGENTS.md` and the `.github/agents/*.agent.md` files.

- **VS Code Copilot `tools:` frontmatter restriction is NOT enforced for local agents** — **SUPERSEDED**: The working architecture uses `agents:` frontmatter + `runSubagent` dispatch instead of relying on `tools:` restriction to block terminal access. Debug log analysis (session `0f707dfc`) confirmed: with `tools: ["agent", "search", "read"]` in the coordinator's `.agent.md` frontmatter, the LLM still used `run_in_terminal` directly. Prompt engineering alone cannot prevent a capable LLM from using available tools. The resolution was `disable-model-invocation: true` on workers + correct `agents:` array on the Coordinator — not a PreToolUse hook.

- **PreToolUse hook design for multi-agent coordinator pattern** — **SUPERSEDED**: The PreToolUse hook approach was abandoned. The hook uses Claude Code tool names (`Write|Edit|Bash|Read`) which do NOT match VS Code tool names (`run_in_terminal`, `read_file`) — it is inert in VS Code Copilot sessions. The working enforcement uses `disable-model-invocation: true` on workers and `agents:` frontmatter on the Coordinator.

- **Multi-agent dispatch via `runSubagent` is NOT available in VS Code Copilot** — **SUPERSEDED (RESOLVED)**: `runSubagent` dispatches work correctly with `tools: ["agent"]` + `agents: ["DV Source Analyzer", "DV Model Generator", "DV Validator"]` in the Coordinator frontmatter. Workers use `disable-model-invocation: true`. Handoff buttons kept as fallback for direct invocation. The `/clear` workaround is no longer needed.


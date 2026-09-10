# Unified Data Vault Automation Platform (UDVAP) — Now Live

---

## TL;DR

We've built the **Unified Data Vault Automation Platform (UDVAP)** — an AI-assisted automation platform that generates complete Data Vault pipelines — **v_psa_stg + Hub + Link + Satellite** — from a single command, including **multi-table (lookup join) staging views**. What previously consumed **7-12 days across Data Modelers, Data Engineers, and PR Reviewers** now completes in **under 30 minutes**, with zero deviation from DV 2.x standards.

Either a **Data Modeler provides high-level design details** (model name, BK, HK, Raw Vault types, entity names) and a Data Engineer builds the entire pipeline from that — or **anyone with heuristic knowledge of the data domain and modeling concepts** can build a pipeline themselves — the automation enforces FBIN's Data Vault standards and principles by code, not by memory. You still need to know your BKs, entity names, and Raw Vault structure — the platform ensures those decisions are implemented correctly.

The platform now supports **multi-hash-key definitions** (hub HKs + link HKs) via `--hk` flags, **multi-BK pipelines** via `--additional-bk` for entities with secondary business keys, **composite grain validation** with two-phase checks, **custom LOAD_DTS column** via `--load-dts-column` for non-standard timestamp sources, **grain column HASHDIFF exclusion** (multi-active key columns are PK components, not change-tracked attributes), a **pre-build code review gate** (52 automated checks block deployment on FAIL), an **incremental dry-run step** (`dbt run --empty` validates incremental SQL correctness before merge), and a **coordinator → subagent agent architecture** with defense-in-depth enforcement. Input validation guards prevent common CLI mistakes: duplicate `--bk` flags are hard-stopped, HK specs require a minimum of 2 columns, and auto-generated link HKs are suppressed when the user provides explicit `--hk LNK_*` definitions. It has been validated across **918 automated tests** (30 test suites), **130 codified lessons learned**, and **52 compliance checks per model** (30 single-table + 14 multi-table + 8 lesson-enforcement). It is impossible to generate a model that violates FBIN standards because those standards are encoded directly in the code generator.

---

## The New Workflow — It's This Simple

```
 1. Create JIRA story for the new source table
 2. Create feature branch from JIRA
 3. Register BKCC if it's a new design (via Streamlit app in DEV)
 4. Open the feature branch in VS Code
 5. Select "DV Pipeline Coordinator" from the Copilot agent dropdown
 6. Describe your source — the Coordinator does the rest:
```

> Generate a v_psa_stg for PRIVE_MOEN.SUBSCRIPTION
> BK: ID → SUBSCRIBER_BK
> SUBSCRIPTION_HK : ID, BKCC
> SUBSCRIBER_HK : SUBSCRIBER_ID, BKCC
> LNK_SUBSCRIBER_SUBSCRIPTION_HK: SUBSCRIBER_ID, ID, BKCC
> REC_SRC: US.PRIVE_MOEN.SUBSCRIPTION
> Model name: v_psa_stg_subscription__winn_prive
> Domain: connected_device

**That's it.** The **DV Pipeline Coordinator** parses your request, confirms parameters, then dispatches specialized worker agents (Source Analyzer → Model Generator → Validator — plus an optional, read-only **Knowledge Advisor** conceptual design review after profiling) via subagent calls. Multiple hash key definitions — hub HKs, link HKs — are specified upfront. The Coordinator walks you through profiling, design, code generation, and deployment — with approval gates at every stage. After the XLSX review gate, the Coordinator prompts you to add Raw Vault objects (hub, link, sat) — all from the same pipeline. Review the output, approve, and your PR is ready.

Alternatively, you can use the `/generate-v-psa-stg` slash command directly — it invokes the same pipeline orchestrator under the hood.

### Already have a v_psa_stg? Start from Raw Vault directly:

> /generate-raw-vault v_psa_stg_dtc_fulfillment__winn_shopify
> Objects: HUB, LNK, SAT
> LNK name: order_fulfillment
> Parent HKs: FULFILLMENT_HK, ORDER_HEADER_HK
> SAT parent: LNK_ORDER_FULFILLMENT_HK → lnk_order_fulfillment (LSAT)

This uses the existing v_psa_stg as the upstream source and generates only the raw vault objects.

---

## The Before & After

```
+---------------------------------------------------------------------------+
|                        BEFORE (Manual Process)                            |
|                                                                           |
|  Day 1-2:   Data Modeler profiles source in Snowflake                     |
|             Identify BKs, grain, volume, ingestion type                   |
|             Determine hub/link/sat structure, entity naming                |
|                                                                           |
|  Day 2-4:   Data Modeler creates tech design document                     |
|             Map all columns, define hash keys, plan ghost records          |
|             Define HASHDIFF composition, column ordering                   |
|             Handoff to Data Engineer                                       |
|                                                                           |
|  Day 4-6:   Python parser generates SQL/YAML from tech design             |
|             Data Engineer manually reviews generated output                |
|             Missed items in review -> model fails at build time            |
|             Circle back to Modeler to fix mapping/tech design              |
|             Typos in mapping logic -> runtime errors                       |
|             Data realities (NULLs, grain issues) -> model revisits         |
|             Tests missed or over-added -> silent test gaps                 |
|                                                                           |
|  Day 6-7:   Register source, dbt compile -> debug -> fix -> repeat        |
|             Iterate until models compile and run cleanly                   |
|                                                                           |
|  Day 7-10+: PR review by senior engineer/reviewer                         |
|             Fix review findings (BKCC order? BK in HASHDIFF?              |
|             Ghost record values? Watermark formula?)                       |
|             Re-test -> re-review -> merge                                  |
|                                                                           |
|  People:    Data Modeler + Data Engineer + PR Reviewer                     |
|  Risk:      Silent data corruption if ANY detail is wrong                  |
|  Cost:      60-100+ hours across 3 roles per pipeline                      |
+---------------------------------------------------------------------------+

                              |
                              v

+---------------------------------------------------------------------------+
|                        AFTER (Automated)                                  |
|                                                                           |
|  Minute 1-5:   Engineer provides source table + business key              |
|                AI profiles source automatically (9 checks)                |
|                Lookup tables auto-profiled, collisions detected            |
|                                                                           |
|  Minute 5-10:  Engineer reviews auto-generated tech spec (XLSX)           |
|                30 DV 2.x compliance checks run automatically              |
|                                                                           |
|  Minute 10-15: Code generated deterministically                           |
|                4 SQL files + 4 YAML test files                            |
|                All hash formulas, ghost records, watermarks                |
|                guaranteed correct -- no typos, no missed items             |
|                                                                           |
|  Minute 15-25: Files placed, source registered, dbt compiled,             |
|                models materialized, tests executed -- all automated        |
|                                                                           |
|  People:    Any team member (Modeler, Engineer, or both)                   |
|  Risk:      Near zero -- standards enforced by code, not memory            |
|  Cost:      < 1 hour including engineer review time                        |
+---------------------------------------------------------------------------+
```

---

## Detailed Pipeline Flow

```
Engineer selects "DV Pipeline Coordinator" from VS Code Copilot agent dropdown
and describes the source:

  Schema: PRIVE_MOEN
  Table: SUBSCRIPTION
  BK: ID → SUBSCRIBER_BK
  --hk "SUBSCRIPTION_HK:ID,BKCC"
  --hk "SUBSCRIBER_HK:SUBSCRIBER_ID,BKCC"
  --hk "LNK_SUBSCRIBER_SUBSCRIPTION_HK:SUBSCRIBER_ID,ID,BKCC"
  REC_SRC: US.PRIVE_MOEN.SUBSCRIPTION
  Model name: v_psa_stg_subscription__winn_prive

  The Coordinator confirms parameters, then dispatches worker agents:
        |
        v
+---------------------------------------------------------------------------+
|  STAGE 1: Profile & Design (~5 min)                                       |
|                                                                           |
|  [1/9] DESCRIBE TABLE -> extract all columns + data types                 |
|  [2/9] COUNT(*) -> determine row count                                    |
|  [3/9] Volume classification -> Normal / Caution / Large                  |
|  [4/9] Sample 5 rows for visual review                                    |
|  [5/9] Grain validation -> BK + PSA_LOAD_DTS must be unique               |
|        Two-phase composite grain: Phase 1 checks single BK, Phase 2       |
|        checks composite BK. Clear messaging ("checking Phase 2...")        |
|  [6/9] NULL BK check -> prompt sentinel if NULLs found                    |
|  [7/9] Ingestion source detection -> Fivetran / SNP GLUE / Other          |
|  [8/9] BKCC lookup -> verify registered in REF_BUSINESS_KEY_COLLISION     |
|        BKCC clone uses DDL bypass (direct Python connector, skips MCP)     |
|  [9/9] Semantic collision check -> block if source already modeled        |
|                                                                           |
|  NEW: Multi-HK support (if --hk flags provided):                          |
|  - Multiple hash key definitions accepted at init/profile                 |
|  - Format: --hk "HK_NAME:COL1,COL2,..." (one per HK)                      |
|  - Hub HKs + Link HKs defined upfront, carried through all stages         |
|                                                                           |
|  NEW: Multi-BK support (if --additional-bk flags provided):               |
|  - Secondary business keys: --additional-bk "RAW_COL:BK_ALIAS"           |
|  - Additional BK columns included in HASHDIFF automatically              |
|  - Duplicate --bk flag detection: hard-stop with clear error message      |
|  - HK spec validation: minimum 2 columns required (BK + BKCC)            |
|                                                                           |
|  NEW: Secondary table mini-profile (if --secondary-table specified):      |
|  - Query secondary table columns + data types                             |
|  - Detect ingestion type (Fivetran / SNP GLUE / custom)                   |
|  - Column collision detection (auto-rename: ID -> ORD_ID)                 |
|  - BK expression validation against post-rename columns (lesson #92)      |
|  - QUALIFY dedup auto-generated for secondary source                      |
|  - Source name resolution for reserved words (ORDER, GROUP, etc.)         |
|                                                                           |
|  Then: Generate YAML config -> Generate XLSX tech spec                    |
|        Run 30 DV 2.x compliance checks automatically                      |
|                                                                           |
|  STOP: Engineer reviews XLSX in Excel -> Approves                         |
|                                                                           |
|  RAW VAULT DESIGN DECISION (prompted automatically):                      |
|     Option A -- Continue STG-only (generate-code)                         |
|     Option B -- Add Raw Vault objects (add-raw-vault command)              |
|                Hub: auto-derived from BK                                   |
|                Sat: requires --sat-parent-hk, --sat-parent-model           |
|                Lnk: requires --parent-hks                                  |
|     The add-raw-vault command preserves all prior steps and only           |
|     resets code generation -- no re-profiling or re-approval needed.       |
+---------------------------------------------------------------------------+
                                   |
                                   v
+---------------------------------------------------------------------------+
|  STAGE 2: Code Generation (~2 min)                                        |
|                                                                           |
|  For each object (v_psa_stg, hub, lnk, sat):                             |
|  - yaml_reader.py -> translates YAML config to generator format           |
|  - build.py -> generates 4-layer CTE SQL (SRC->LOGIC->JOIN->FINAL)        |
|    - Hash keys: MD5_BINARY(UPPER(CONCAT_WS(...)))                         |
|    - HASHDIFF: correct inclusions/exclusions enforced                      |
|    - Ghost records: DECODE with correct sentinel values                    |
|    - Watermarks: volume-aware (per-REC_SRC for >=50M rows)                |
|    - full_refresh = var('force_full_refresh', false) for all volume tiers  |
|    - NOT EXISTS delta detection (never MERGE)                              |
|  - make_yml.py -> generates YAML test files per layer                     |
|    - STG: unique_combination(BK, LOAD_DTS) + not_null(BK)                 |
|    - HUB: primary_key(HK) + row_count >= 4                                |
|    - SAT: primary_key(HK, LOAD_DTS) + FK to parent + row_count            |
|                                                                           |
|  SAT alias support: `msat`, `lsat`, `lmsat` auto-infer --sat-type.        |
|                                                                           |
|  Multi-table: secondary columns appear in LOGIC CTE with renames,         |
|  JOIN layer uses LOGIC_{alias}.{col} references, BKCC joins last.         |
|                                                                           |
|  Output: 4 SQL files + 4 YAML test files                                 |
|                                                                           |
|  STOP: Engineer reviews generated SQL -> Approves                         |
+---------------------------------------------------------------------------+
                                   |
                                   v
+---------------------------------------------------------------------------+
|  STAGE 3: Deploy & Test (~10 min)                                         |
|                                                                           |
|  [1/8] Conflict check -> ensure no duplicate files                        |
|  [2/8] Place files in correct model directories                           |
|        (int_staging_views/, raw_vault/hub/, raw_vault/sat/, etc.)         |
|  [2b/8] Auto-register source in _sources_staging_psa.yml                  |
|         (backup -> surgical string insertion -> validate YAML -> rollback) |
|         No more YAML formatting drift — reads with parser, writes exact    |
|  [2c/8] Clone ref_business_key_collision to sandbox schema                |
|  [3/8] Pre-build code review gate (52 checks)                             |
|        FAIL -> blocks build, reports findings, exit 1                     |
|        WARN -> proceeds with advisory messages                            |
|        Checks: hash key structure, BKCC join, HASHDIFF composition,       |
|        CTE naming, QUALIFY patterns, source suffix, lesson enforcement    |
|  [4/8] dbt build --full-refresh (-f -x) -> compile + materialize + test   |
|        _run_dbt() streams output line-by-line via Popen with              |
|        stderr=subprocess.STDOUT to prevent silent timeouts                |
|        Pre-flight: `dbt cancel` clears stuck Cloud CLI sessions           |
|  [5/8] Incremental dry-run (dbt run --empty) for Raw Vault models         |
|        Validates incremental SQL correctness (WHERE NOT EXISTS, etc.)      |
|        STG-only pipelines skip this step automatically                    |
|        Retry logic: 3 attempts on 'Session occupied' (10/20/30s delay)    |
|  [6/8] Post-build validation -> row count verification via Snowflake      |
|        SAT warns on zero rows, HUB fails on zero rows                     |
|  [7/8] dbt build log parser extracts PASS/WARN/ERROR from summary         |
|        No false positives from "Skipping constraint" messages              |
|  [8/8] Git summary -> lists all files ready to commit                     |
|                                                                           |
|  PIPELINE COMPLETE -- ready for PR                                        |
+---------------------------------------------------------------------------+
```

> **Phase 1.5 (optional) — Conceptual Design Review.** Between profiling and code
> generation the Coordinator *offers* a read-only design review by the **DV Knowledge
> Advisor** (see the Agent Architecture section). It surfaces modeling-level issues —
> construct choice, grain, business-key validity, satellite splits, link modeling, and
> hash-collision / BKCC traps — before any SQL exists. It is advisory and read-only;
> skipping it never blocks the pipeline.

---

## Multi-Table Support (NEW)

When a staging view needs data from a **secondary (lookup) table** — for example, pulling `ORDER_HEADER_BK` from the ORDER table into a FULFILLMENT staging view — the pipeline handles the entire complexity automatically:

```
                    FULFILLMENT (driver)              ORDER (secondary)
                    +------------------+              +-----------------+
                    | ID               |              | ID              |
                    | ORDER_ID    -----+--LEFT JOIN-->| NAME            |
                    | NAME             |              | ...             |
                    | STATUS           |              +-----------------+
                    | ...              |
                    +------------------+
                            |                              |
                            v                              v
                    Column collision detected:    ID -> ORD_ID
                                                 NAME -> ORD_NAME
                            |
                            v
                    BK expression validated:
                    COALESCE(ORD_NAME, '-1')  <-- uses renamed column
                            |
                            v
                    QUALIFY dedup auto-generated for ORDER source
                    QUALIFY ROW_NUMBER() OVER(PARTITION BY ID
                            ORDER BY _FIVETRAN_SYNCED DESC) = 1
```

### Multi-Table CLI Example

```bash
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

### What Gets Handled Automatically

| Feature | What Happens |
|---------|-------------|
| **Column collision** | Both tables have `ID` and `NAME` — secondary columns auto-renamed to `ORD_ID`, `ORD_NAME` |
| **BK validation** | `--secondary-bk` checked against post-rename columns; "Did you mean?" suggestions |
| **QUALIFY dedup** | Ingestion-aware: `_FIVETRAN_SYNCED` (Fivetran), `GLCHANGETIME` (SNP GLUE), `PSA_LOAD_DTS` (other) |
| **Source name case** | Reserved-word tables like `ORDER` resolved from source YAML with exact case for `source()` calls |
| **Join predicate** | Parsed automatically: `ORDER_ID = ORD.ID` → parent=ORDER_ID, child=ID (renamed to ORD_ID) |

---

## Why This Is a Breakthrough

### 1. Eliminates an Entire Class of Modeling Errors

These are the mistakes that have caused production issues in the past — and are now **impossible** to make:

 | Error | Consequence | How Automation Prevents It |
 | ----- | ----------- | ------------------------- |
 | BK included in HASHDIFF | Satellites re-insert identical data on every load | Code generator excludes BKs from HASHDIFF by rule |
 | BKCC missing from hash key | Hash collisions across source systems | BKCC is always the last component — enforced in code |
 | REC_SRC in hash key | System rename forces full hash regeneration | Reserved column list blocks it at input validation |
 | Wrong ghost record values | PIT/PB joins fail silently | Ghost records generated from a fixed template per column type |
 | Filtering on PSA_DELETE_IND | Deletion history lost from vault | Lesson #28 — delete flags are DATA, not filters |
 | SELECT DISTINCT instead of QUALIFY | Duplicate-masking in staging | Generator always uses ROW_NUMBER() + QUALIFY |
 | Missing `enable_staging_tests` var | Tests silently report zero failures | Orchestrator injects the var automatically |
 | Typos in mapping logic | Runtime SQL errors | Deterministic code gen — no hand-typed SQL |
 | Tests missed or over-added | Silent test gaps or false noise | Layer-appropriate tests auto-generated from column metadata |
 | Column collision in multi-table | Wrong column referenced in BK/HASHDIFF | Auto-rename + BK validation against post-rename columns (lesson #92) |
 | Duplicate `--bk` flag | argparse silently keeps last value, dropping primary BK | Hard-stop guard counts `--bk` tokens, blocks with clear error message |
 | Auto-generated link HK conflicts | Spurious `LNK_*_HK` collides with user-defined link HK | Auto-link HK suppressed when user provides any `--hk LNK_*` definition |
 | Grain columns in HASHDIFF | MSAT satellite treats grain cols as change-tracked attributes; unnecessary reinserts | Grain columns (multi-active key) auto-excluded from HASHDIFF — PK components are not change data |
 | Wrong LOAD_DTS derivation for custom sources | Satellite gets wrong load timestamp, history is corrupted | `--load-dts-column` allows custom column; overrides ingestion-type default with PSA_DELETE_IND fallback |
 | GLDELFLAG excluded from HASHDIFF | Soft deletes not detected as changes; SAT misses delete events | GLDELFLAG is business data for snp_glue sources — explicitly included in HASHDIFF |
 | Incremental SQL syntax error deployed | First incremental load fails in production | `dbt run --empty` dry-run validates incremental path before merge |
 | sat_ prefix for multi-active satellite | Naming violates DV 2.0 standard; confuses downstream consumers | H9 code review check detects sat_ with multi-active grain, suggests msat_ rename |

### 2. Catches Data Anomalies Early — Before Any Code Exists

The profiling stage detects issues **before a single line of SQL is written**:

- **NULL business keys** — prompts engineer for sentinel strategy (`-1` required / `-2` optional)
- **Grain violations** — BK + PSA_LOAD_DTS uniqueness check fails → wrong BK choice surfaced immediately
- **Volume tier** — tables > 50M rows automatically get watermarks; > 300M get clustering + full_refresh protection
- **Source collisions** — prevents duplicate v_psa_stg models for the same driver table (semantic collision check)
- **BKCC registration** — warns if BKCC isn't registered in DEV before any code runs
- **Ingestion source type** — auto-detects Fivetran vs SNP GLUE vs other, drives LOAD_DTS derivation
- **Column collisions** (multi-table) — detects shared column names and auto-renames with alias prefix
- **BK expression validation** — ensures secondary BK references only valid post-rename column names

### 3. Self-Healing & Continuous Improvement

The platform learns from every mistake:

- **130 codified lessons** from 70+ bugs discovered across Phase 3, Phase 4, and E2E reliability hardening
- Every bug fix adds a lesson → lesson drives code change → automated test prevents recurrence
- Agent reads lessons at session start — same mistake never happens twice
- Pipeline state is crash-safe (atomic writes) with automatic rollback on corruption. State files are per-model (`<model_name>.json`), safe for concurrent use across different models. Same-model concurrency is a human coordination responsibility (no file locking).
- Source registration uses backup/validate/rollback — corrupted YAML is auto-restored
- All agent skills include prompt injection guardrails — query results, XLSX data, and YAML content are treated as untrusted; instructions embedded in data values are never executed
- **BK input sanitization** — `_extract_raw_col_from_bk()` extracts valid identifier fragments from BK expressions, silently dropping non-identifier characters. Intentional for cast handling (`TERM_ID::TEXT`). A UX warning for unexpected character stripping is a planned enhancement.
- **Duplicate `--bk` guard** — argparse silently overwrites when `--bk` is passed twice; orchestrator counts `--bk` tokens (including `--bk=VALUE` form) and hard-stops with a clear error, directing the user to `--additional-bk` for secondary BKs.
- **HK spec validation** — each `--hk` definition must contain at least 2 columns (BK + BKCC); orchestrator blocks init/profile if fewer are provided.
- **Auto-link HK suppression** — when the user provides any `--hk LNK_*` definition, the orchestrator suppresses auto-generated link HKs that would conflict.
- **Domain path validation** — `--domain` parameter is validated with `re.match(r'^[a-z][a-z0-9_]*$')` to prevent path traversal attacks (e.g., `../../etc`)
- **Pre-flight `dbt cancel`** — before build/run/test commands, orchestrator clears stuck Cloud CLI sessions that would cause "Session occupied" errors
- **Dry-run retry logic** — incremental dry-run retries up to 3 times on "Session occupied" errors (exponential backoff: 10s, 20s, 30s)
- **Source suffix validation** — warns when model source suffix doesn't match the PSA schema naming convention (catches copy-paste errors early)
- **Pre-build code review gate** — 52 automated checks (including lesson-enforcement N1/N2/E3/E4/C4) run before `dbt build`; FAIL findings block deployment, preventing known anti-patterns from reaching Snowflake

### 4. Standards Compliance — Always, Not Sometimes

| Standard | How It's Enforced |
|----------|-------------------|
| 4-layer CTE (SRC→LOGIC→JOIN→FINAL) | Code generator only produces this pattern |
| DV 2.x column ordering (HK→LOAD_DTS→REC_SRC→HASHDIFF→payload) | Hard-coded in build.py column sequencing |
| MD5_BINARY with UPPER + CONCAT_WS + COALESCE/NULLIF/TRIM | Hash formula is a template — not hand-written |
| Ghost records with correct DECODE values | Generated from column-type lookup table |
| NOT EXISTS delta detection (not MERGE) | Final layer filter is auto-generated |
| Per-REC_SRC watermarks for high-volume tables | Volume tier detection drives watermark injection |
| Test coverage (PK, FK, row count, unique combo) | make_yml.py auto-generates layer-appropriate tests |
| 100% data rule (no filtering at staging/raw vault) | No WHERE clause on delete flags — enforced by Lesson #28 |
| Secondary table QUALIFY dedup | Ingestion-aware dedup auto-generated for all lookup joins |
| Column collision rename consistency | BK/HASHDIFF validated against post-rename column set |

### 5. Cost & Time Savings

| Metric | Manual (Modeler + Engineer + Reviewer) | Automated | Savings |
|--------|----------------------------------------|-----------|---------|
| Total elapsed time | 7-12 days | < 1 hour | **95%+** |
| Modeler time (profiling + tech design) | 2-4 days | 5 min (auto-profiled) | **~98%** |
| Engineer time (code gen + debug + fix) | 3-5 days | 15 min (review only) | **~97%** |
| PR Reviewer time | 1-2 days | < 1 hour (review generated output) | **~90%** |
| Back-and-forth cycles (Modeler ↔ Engineer) | 2-4 round trips | 0 (deterministic) | **100%** |
| Test files written manually | 4 | 0 (auto-generated) | **100%** |
| Source registration | Manual YAML edit | Automated with backup/rollback | **100%** |
| Risk of silent data corruption | High (human error) | Near zero (code-enforced) | **~99%** |

**Snowflake Compute & CI/CD Cost Savings:**

- **Fewer model re-runs** — Manual errors (wrong hash key, missing BKCC, BK in HASHDIFF) cause build failures that require fix → rebuild → retest cycles. Each cycle burns Snowflake compute. Automation gets it right the first time, reducing model runs to the minimum.
- **Sandbox testing is never skipped** — The pipeline enforces dbt compile → run → test in DEV before any PR is opened. Without this, issues surface in CI/CD — first in the DEV PR build, then in QA and PROD deployments — where compute costs are higher, failed runs block other deployments, and each re-run burns additional warehouse credits.
- **Proper layered tests without redundancy** — The test generator assigns tests to the correct layer. Heavy-compute validation tests (HK not_null, REC_SRC not_null, HASHDIFF not_null) are placed only on raw vault tables where they belong — never on v_psa_stg views where those columns don't exist yet. This eliminates duplicate tests and unnecessary compute on staging views that scan full PSA tables.
- **CI/CD pipeline efficiency** — Fewer failed builds in QA/PROD means fewer dbt Cloud job re-runs, less warehouse idle time waiting for fixes, and faster PR throughput across the team.

For a team generating **10-15 new pipelines per quarter**, this translates to **75-180 person-days saved per quarter** across all three roles — time that can be redirected to business vault logic, data quality improvements, and new domain onboarding.

---

## What's Included

| Component | Type | What It Does |
|-----------|------|-------------|
| **Pipeline Orchestrator** | Python State Machine (~5,919 lines) | 10 pipeline steps with 3 STOP gates + 1 design decision point — enforces step ordering, validates inputs, tracks state per model. Multi-HK support, composite grain validation, custom LOAD_DTS column, grain column HASHDIFF exclusion, pre-build code review gate (52 checks), incremental dry-run with retry, post-build row count verification, git summary. Domain path validation prevents traversal attacks. `_run_dbt()` streams build output line-by-line via Popen with `stderr=subprocess.STDOUT` to prevent silent timeouts. Pre-flight `dbt cancel` clears stuck sessions for build/run/test commands. |
| **Multi-Table Module** | Python Module (546 lines) | Secondary/lookup table support: collision detection, auto-rename, BK validation, QUALIFY dedup, source name resolution |
| **Source Profiler** | Python + Snowflake MCP | Auto-profiles tables: 9 checks including volume tier, grain validation, NULL BK detection, BKCC lookup, semantic collision check |
| **Tech Spec Generator** | Python Module (969 lines) | Produces reviewable XLSX with layer-specific tabs (MAPPING, SRC_TO_TGT, column metadata) |
| **Tech Spec Validator** | Python Module (1,611 lines) | 30 automated DV 2.x compliance checks (22 single-table + 8 multi-table) |
| **Code Generator** | Python Module (863 lines) | Deterministic SQL generation: 4-layer CTE, hash keys, HASHDIFF, ghost records, watermarks, NOT EXISTS delta |
| **Test Generator** | Python Module (256 lines) | Auto-generates layer-appropriate YAML test files (PK, FK, row count, unique combo) |
| **Source Registrar** | Python (tri-state) | Adds PSA source to `_sources_staging_psa.yml` with surgical string insertion (no YAML formatting drift) + backup/validate/rollback — crash-safe |
| **5 Pipeline Agents** | Agent Definitions (.agent.md) | Coordinator → Subagent pattern: **DV Pipeline Coordinator** (primary entry point — select from Copilot agent dropdown) dispatches to DV Source Analyzer (Stage 1) → *(optional)* DV Knowledge Advisor (Phase 1.5 — read-only conceptual design review) → DV Model Generator (Stage 2) → DV Validator (Stage 3). Model-tiered: Sonnet 4.6 for judgment, Haiku 4.5 for validation. |
| **8 AI Skills** | Agent Skills (SKILL.md) | Auto-activated workflows: staging, raw vault, tech design, implementation, code review, conventional commits, pipeline handoff, modeling advisor + dbt-labs community skills |
| **5 User Commands** | Prompt Files (.prompt.md) | Fallback triggers (bypass Coordinator): `/generate-v-psa-stg`, `/generate-raw-vault`, `/add-source`, `/run-tests`, `/phase4-sat-bv-iteration` |
| **10-Rule Enforcement Hook** | Python PreToolUse Hook (451 lines) | Blocks direct file creation — forces everything through the pipeline. Maps hub/sat/lnk files back to parent pipeline. Blocks Coordinator from running terminal commands directly. **Note: Active in Claude Code CLI only. VS Code Copilot does not invoke PreToolUse hooks — the orchestrator's `_check_prerequisites()` state machine is the primary enforcer in VS Code.** |
| **BKCC Clone Bypass** | Python DDL Handler | DDL statements skip MCP, go directly to Python connector. Log distinguishes "direct (DDL bypass)" from "fallback". |
| **Post-Build Validator** | Python Module | Row count verification via Snowflake after dbt build. SAT warns on zero, HUB fails on zero. |
| **130 Codified Lessons** | Markdown (lessons.md) | Governed knowledge base: every bug fix adds a lesson → agent reads at session start → same mistake never happens twice |
| **Code Reviewer** | Python Module (3,293 lines) | 63 automated DV 2.x checks across categories A–N + Q (O and P reserved-pending per CODE_REVIEW_CHECKS.md): naming conventions, hash key structure, BKCC join patterns, CTE structure, HASHDIFF composition, QUALIFY dedup, source/layer integrity, lesson enforcement (N1-N2, E3-E4, C4), sat grain analysis (H9), and conceptual modeling (Q1-Q2). FAIL blocks build; WARN is advisory. |
| **918 Automated Tests** | pytest (30 test suites) | 918 tests covering BK validation, hub/link/sat generation, multi-table, multi-HK, semantic collision, pipeline preflight, pre-build review, incremental dry-run, post-build validation, code review categories, and tech spec generation |

---

## Agent Architecture

The platform uses a **Coordinator → Subagent pattern** where a single user-facing agent dispatches work to specialized sub-agents via `runSubagent`/`agent` tool calls.

| Agent | Model (advisory¹) | Role |
|-------|-------|------|
| **DV Pipeline Coordinator** | Sonnet 4.6 | User-facing orchestrator, dispatches to sub-agents, manages pipeline state |
| **DV Source Analyzer** | Sonnet 4.6 | Profiles sources, validates data quality, runs 9 profiling checks |
| **DV Knowledge Advisor** *(optional, read-only)* | Sonnet 4.6 | Phase 1.5 conceptual design review — construct choice, grain, business key, satellite splits, link modeling, hash-collision / BKCC traps, checked against `.github/knowledge/data-vault/`. Returns `FINDING / RISK / OK` with citations. Never edits code or runs dbt. |
| **DV Model Generator** | Sonnet 4.6 | Generates YAML/XLSX/SQL via orchestrator, handles multi-HK and multi-table |
| **DV Validator** | Haiku 4.5 | Runs dbt build, validates results, reports PASS/WARN/ERROR — cost-optimized |

¹ `model:` frontmatter in agent files is **advisory only** — VS Code Copilot uses whichever model the user selects in the dropdown. If precise model control matters, the user must set the dropdown explicitly.

### Phase 1.5 — Conceptual Design Review (optional)

Between source profiling (Stage 1) and code generation (Stage 2), the Coordinator **offers** — never imposes — a read-only conceptual design review by the **DV Knowledge Advisor**. This is the cheapest point to catch *modeling* issues that neither the orchestrator (mechanics) nor `code_reviewer.py` (syntax) covers: construct choice, grain, business-key validity, satellite splits, link modeling, and hash-collision / BKCC traps.

- **Offer, don't impose** — the Coordinator asks *"Would you like the DV Knowledge Advisor to review the proposed construct, grain, and business key before we generate? (yes / skip)"*. Skipping is always valid and never blocks the pipeline.
- **Read-only** — if accepted, the advisor is dispatched in REVIEW mode with the entity/model name, confirmed BK(s) and grain, HK definitions, REC_SRC/BKCC, and whether Raw Vault objects are contemplated. It checks the design against `.github/knowledge/data-vault/` and returns findings as `FINDING / RISK / OK` with citations. It never edits models, changes parameters, or generates code.
- **⛔ STOP — Design Findings** — the Coordinator presents the findings verbatim, then asks how to proceed: (a) proceed as-is, (b) adjust parameters and re-run Phase 0/1, or (c) plan Raw Vault objects for Phase 2's Option B. The Coordinator does not decide — the user does.

The advisor is grounded in the DV 2.x knowledge base at `.github/knowledge/data-vault/` — the same corpus that backs the Category Q ("Conceptual Modeling") checks in `code_reviewer.py`.

### Defense-in-Depth Enforcement

Three layers are designed to prevent the AI from bypassing safety controls. **In the deployed VS Code Copilot environment, Layer 1 is the sole hard enforcer.** Layers 2 and 3 provide additional protection in Claude Code CLI or as prompt-based guardrails.

- **Layer 1: Orchestrator State Machine (primary enforcer)** — `_check_prerequisites()` in `pipeline_orchestrator.py` enforces step ordering. Every command validates that all prerequisite steps have completed and been approved before allowing execution. This is the **only layer that actively blocks operations** in VS Code Copilot. Domain path validation (`re.match(r'^[a-z][a-z0-9_]*$')`) prevents traversal attacks at the input boundary.
- **Layer 2: PreToolUse Hook (Claude Code CLI only)** — Deterministic Python script (`pre_tool_guard.py`, 451 lines, 10 rules) blocks direct file creation and forces everything through the pipeline. **This hook is NOT active in VS Code Copilot** — VS Code does not implement the PreToolUse hook protocol. The Coordinator Terminal Guard (`coordinator_terminal_guard.py`) is also inert in VS Code. When VS Code adds hook protocol support, this layer will activate automatically.
- **Layer 3: Anti-Injection Instructions (prompt-based)** — Coordinator prompt includes explicit instructions to treat all data values (query results, XLSX content, YAML content) as untrusted. Instructions embedded in data values are never executed. Context sanitization prevents SKILL.md Bash permission leaks.

### Model Tier Optimization

- **Sonnet 4.6** — Used for judgment work: source profiling, design decisions, code generation orchestration
- **Haiku 4.5** — Used for validation work: running dbt build, parsing logs, reporting results. Running `dbt build` doesn't need Sonnet-level reasoning — the intelligence is in the deterministic Python orchestrator, not the LLM.

### ADD-SOURCE Approval Gate

When adding a new source to an existing hub, the agent must present:
- **Option A**: Include hub (add CTE to existing hub model)
- **Option B**: SAT only (generate satellite without modifying hub)

The engineer explicitly chooses before any existing model is modified.

### VS Code Settings

Team-shared settings including Copilot subagent configuration are committed to the repo. `.code-workspace.template` provides a base for personal overrides without polluting the shared config.

---

## Token Efficiency & Caching (measured)

These findings come from measuring real end-to-end pipeline sessions in the VS Code
agent debug log (per-call `inputTokens` / `cachedTokens` / `outputTokens` / `ts`) — not
from vendor benchmarks.

**The scary ratio is mostly cached re-send, not waste.** A measured 33-call pipeline
session showed 2,438,352 input tokens vs 45,468 output (~54:1) — but **79% of that
input was served from cache**, and at the content level (what you type vs what the
agent writes) the ratio is ~1:1. The 54:1 is mechanical prompt-prefix accumulation,
which prompt caching is built to make cheap. **We are not wasting tokens structurally:
79% cache hit + a deterministic code generator is a healthy setup.**

**The one real leak is cache cold-starts.** Four mid-session calls dropped to
`cachedTokens = 0` and reprocessed the entire 90K–109K-token prompt at full price —
those four calls alone were **~79% of all full-price tokens** (i.e. of the ~21% *not*
served from cache — a different figure than the 79% hit rate above, which it happens to
match). A second pipeline session showed the same shape (5 cold-starts = 85% of
full-price). A 153-call
*non-pipeline* session had only **one** cold-start — so **cold-starts track pipeline
shape (STOP gates + subagent dispatches), not session length.**

**Two causes — only one is behaviorally fixable:**

| Cause | Trigger | Measured | Fix |
|-------|---------|----------|-----|
| **Idle-gate** | User takes minutes to respond at a STOP gate; the prompt cache lapses (measured warm window ~3.8–6.5 min) | **3 of 4** (7, 10, 20 min of think-time) | Respond promptly at gates — *behavioral* |
| **Long-dispatch** | A subagent (Snowflake profiling, `dbt build`) runs past the cache window before the Coordinator resumes | **1 of 4** (subagent ran 6.5 min) | *Structural* — needs a keep-alive; no clean VS Code lever today |

**What it's worth (bracketed, not promised):**

| Scenario | Effective cost | Note |
|----------|---------------|------|
| Current | **~29%** of raw input | measured |
| Fix idle-gate cold-starts (gate hygiene) | **~18%** (≈1.6×) | achievable, behavioral |
| Also fix the dispatch cold-start | **~13–14%** (≈2×) | ceiling; needs keep-alive |

**Load-bearing assumption:** every effective-cost figure covers **input tokens only** — it applies
Anthropic **cache-read ≈ 0.1× base input (10× cheaper)** to cached tokens and **1.0×** to cold
input, and **excludes output tokens** (billed separately, priced higher), so ~29% is a prompt-input
proxy, not total cost. It does **not** add the **cache-write premium (~1.25×)** — that write cost is
*ignored*, which is why ~29% slightly *understates* true input cost. If the read multiplier changes,
all three figures move together.

**TTL is bracketed, not pinned:** the largest gap that stayed *warm* was ~3.8 min; the
smallest that went *cold* was ~6.5 min. So the true warm window is in (3.8, 6.5) min —
consistent with a ~5-min TTL but not isolated to it. Treat **"respond within ~3 min"**
as a *safe* target, not a hard threshold, until a boundary-case session pins it.

### Per-turn context tax (what re-sends every call)

Measured from the repo's own files:

| Bucket | ~tokens | Loaded |
|--------|---------|--------|
| `.github/copilot-instructions.md` | 1.2K | every turn |
| `AGENTS.md` + `CLAUDE.md` | 3.7K | every turn |
| Active agent file (Coordinator) | 5.9K | only in that agent's context |
| Worker agent file (each) | 1.7–2.0K | isolated per subagent |
| rules + scoped instructions | ~8.6K | on file match |
| skills / knowledge base / `lessons.md` | — | on-demand only, **not** per turn |

The always-on, repo-controlled prefix is **~11–15K tokens** — reasonable and cacheable.
The lever is cache *warmth*, not prefix *size*.

### Self-check — read your own effective cost off any session log

Zero-dependency, no LLM, no network:

```bash
bash scripts/automation/cache_hit_check.sh                    # newest session log
bash scripts/automation/cache_hit_check.sh path/to/main.jsonl # a specific log
```

It prints per-call cache hit%, cold-starts, the input:output ratio, and effective
billed % — so cost is something you *measure in seconds*, not argue from a benchmark.

---

## Who Can Use This — And How

### Option A: Modeler Provides Design, Engineer Builds

```
 Data Modeler                          Data Engineer
 -----------                           -------------
 "Here's the source: FULFILLMENT      Opens feature branch in VS Code
  BK = ID                             Types the prompt with Modeler's specs
  Entity = FULFILLMENT                 Adds --secondary-table ORDER for lookup
  Hub = hub_fulfillment                AI runs the full pipeline
  LSAT parent = lnk_order_fulfillment  Reviews generated output
  Link connects to ORDER_HEADER_HK"   Approves at each gate
                                       PR ready in ~25 minutes
```

### Option B: Domain-Knowledgeable Engineer Builds It Directly — Standards Are Guaranteed

Any engineer who understands the data domain and modeling concepts (BK selection, entity naming, hub/link/sat structure) can run the pipeline directly — no separate Modeler handoff required. The automation enforces every FBIN Data Vault standard — column ordering, hash formulas, ghost records, test composition, BKCC placement — so the platform guarantees correct implementation of your design decisions.

### The Simplified Developer Experience

```
 +------------------+     +------------------+     +------------------+
 | 1. Create JIRA   |     | 2. Create branch |     | 3. Register BKCC |
 |    story for     |---->|    from JIRA     |---->|    if new design  |
 |    new source    |     |    (feature/...)  |     |    (Streamlit)   |
 +------------------+     +------------------+     +--------+---------+
                                                            |
                                                            v
 +------------------+
 | 4. Open branch   |
 |    in VS Code    |
 +--------+---------+
          |
          v
 +--------------------------------------------------------------+
 | 5. Select "DV Pipeline Coordinator" from Copilot dropdown    |
 |                                                               |
 |   "Generate v_psa_stg for SHOPIFY_MOEN.FULFILLMENT"          |
 |   BK: ID → FULFILLMENT_BK                                    |
 |   REC_SRC: US.SHOPIFY_MOEN.FULFILLMENT                       |
 |   Model: v_psa_stg_dtc_fulfillment__winn_shopify             |
 |   Secondary: ORDER table for ORDER_HEADER_BK                 |
 |   HK: FULFILLMENT_HK, ORDER_HEADER_HK, LNK_ORDER_FULFIL..   |
 |                                                               |
 |   Coordinator confirms params, dispatches worker agents.     |
 |   After XLSX approval, prompts to add Raw Vault objects      |
 |   (hub, lnk, sat) — no separate command needed.               |
 |                                                               |
 | 6. AI walks you through 9 pipeline steps with 3 STOP gates  |
 | 7. Review generated SQL at each gate                          |
 | 8. Pipeline deploys, tests pass -> PR ready                   |
 +--------------------------------------------------------------+
```

**From JIRA story to PR-ready models — in a single sitting.**

---

## What This Means for Each Team

### Data Engineering
- New source onboarding drops from over a week to an afternoon
- Focus shifts from mechanical SQL writing to business key analysis and domain modeling
- Every model ships with correct hash keys, ghost records, watermarks, and tests — first time
- No more back-and-forth with Modelers over typos, missed columns, or wrong hash compositions
- PR reviews become a quick validation of generated output, not a line-by-line DV standards audit
- **Multi-table joins are handled automatically** — collision detection, renaming, and QUALIFY dedup

### Modeling Team
- Tech designs are auto-generated and auto-validated — no more spreadsheet drift
- Column ordering, HASHDIFF composition, and ghost record values are guaranteed correct
- Volume-aware configurations (watermarks, clustering) applied automatically based on row count
- High-level design inputs (BK, entity name, RV types) are all that's needed — the platform handles the rest
- 52 compliance checks catch issues at design time, eliminating "fix the mapping" round trips

### QA Team
- Every generated model includes layer-appropriate tests (PK, FK, row count, unique combo)
- 52 DV 2.x compliance checks run before code generation — issues caught at design time, not test time
- Staging test enablement (`enable_staging_tests` var) is handled automatically — no more silent zero-test runs
- Consistent test patterns across all generated models — no more ad-hoc test coverage gaps

---

## E2E Validated Examples

### Shopify Fulfillment (Multi-Table + Raw Vault)

The fulfillment pipeline was the first **multi-table + Raw Vault** E2E validation:

```
Source:     PSA_PROD.SHOPIFY_MOEN.FULFILLMENT (992,793 rows, Fivetran)
Lookup:     PSA_PROD.SHOPIFY_MOEN.ORDER (reserved-word table name)
Collisions: ID -> ORD_ID, NAME -> ORD_NAME (auto-detected + renamed)

Generated:  v_psa_stg_dtc_fulfillment__winn_shopify  (VIEW)
            hub_fulfillment                           (298,306 rows)
            lnk_order_fulfillment                     (298,306 rows)
            lsat_order_fulfillment__winn_shopify       (394,174 rows)

dbt build:  PASS=18  WARN=0  ERROR=0  SKIP=0
Tests:      3x not_null/unique_combo, 3x primary_key, 3x row_count, 1x foreign_key
Constraints: 3 PK constraints + 1 FK constraint created (RELY)
```

### Privé Subscription (Multi-HK + Composite Grain)

The subscription pipeline validated **multi-hash-key definitions** and **composite grain**:

```
Source:     PSA_PROD.PRIVE_MOEN.SUBSCRIPTION (548 rows, Fivetran)
Hash Keys:  SUBSCRIPTION_HK (ID, BKCC)
            SUBSCRIBER_HK (SUBSCRIBER_ID, BKCC)
            LNK_SUBSCRIBER_SUBSCRIPTION_HK (SUBSCRIBER_ID, ID, BKCC)

Generated:  v_psa_stg_subscription__winn_prive  (VIEW)
            hub_subscription                     (new)
            lnk_subscriber_subscription          (new)
            sat_subscription__winn_prive          (569 rows)

dbt build:  PASS=14  WARN=0  ERROR=0  SKIP=0
Grain:      Composite BK validated via two-phase check
Post-build: Row counts verified via Snowflake (SAT: 569, HUB: >0)
```

---

## What's Next

| Phase | Scope | Status |
|-------|-------|--------|
| Phase 3 | v_psa_stg automation | Merged (PR #1635) |
| Phase 4 | Raw Vault (Hub/Link/SAT) + Multi-table + Add-source | Merged |
| Phase 4.5 | Agent Architecture Hardening — Coordinator → Subagent pattern, defense-in-depth, multi-HK, multi-BK (`--additional-bk`), composite grain, input validation guards, auto-link HK suppression, post-build validation | Complete |
| Phase 4.6 | Pre-Build Review & Incremental Validation — 52-check code reviewer (H9 sat grain, N1/N2/E3/E4/C4 lesson checks), incremental dry-run (`dbt run --empty`), custom LOAD_DTS column, grain col HASHDIFF exclusion, GLDELFLAG inclusion, retry on session-occupied, source suffix validation | Complete |
| Phase 5 | Business Vault (PIT/PB/DIM/FACT) | Planned |
| Phase 6 | Automated PR Review Agent + CI compliance gate for legacy models | Planned |

---

## Try It

Want to see it in action? Open VS Code Copilot Chat and select **"DV Pipeline Coordinator"** from the agent dropdown.

### Path A: New source (end-to-end)

Select the Coordinator agent and type:

> Generate a v_psa_stg for SAP_ECC_PRD.Z_EKPO
> BK: EBELN,EBELP → PO_ITEM_BK
> REC_SRC: USOHNO.SAP.ECCPRD.Z_EKPO
> Model: v_psa_stg_po_item__sap_ecc

The Coordinator parses your request, confirms all parameters (schema, table, BK, BK name, model name, domain), then dispatches worker agents through the full pipeline.

Alternatively, use the `/generate-v-psa-stg` slash command for a more structured input:

> /generate-v-psa-stg SAP_ECC_PRD --table Z_EKPO --bk "EBELN,EBELP" --bk-name "PO_ITEM_BK" --rec-src "USOHNO.SAP.ECCPRD.Z_EKPO" --model-name "v_psa_stg_po_item__sap_ecc"

### Path B: Existing v_psa_stg (Raw Vault only)

When the staging view already exists and you need to add hub/link/sat:

> /generate-raw-vault v_psa_stg_po_item__sap_ecc
> Objects: HUB, SAT
> SAT parent HK: PO_ITEM_HK
> SAT parent model: hub_po_item

The AI verifies the v_psa_stg exists, collects the raw vault design inputs, and generates hub/link/sat models using the same orchestrator pipeline.

The Coordinator walks you through every phase — profiling, design, code generation, and deployment — with approval gates at every stage. It dispatches specialized worker agents (Source Analyzer, Model Generator, Validator) and presents results at each STOP gate for your review.

---

*Questions? Reach out to the DataOps Engineering team.*

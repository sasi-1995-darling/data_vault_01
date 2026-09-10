# hub_store – Root Cause Analysis & Optimisation Summary

**Project:** dbt-datavault &nbsp;|&nbsp; **Model layer:** raw_vault / hub &nbsp;|&nbsp; **Date:** May 14, 2026 &nbsp;|&nbsp; **Author:** Swagat Ghosh

---

## Key Results

| Metric | Value |
|---|---|
| Original hub_store incremental status | ❌ **Timeout** — never completed |
| Trial fixes attempted | 4 |
| Optimized incremental runtime (live) | ✅ **22 s** |
| Reduction vs best trial (1,196 s) | **98 %** |

---

## 1. Original hub_store Design

`hub_store` consolidates **24 staging view sources** into a single deduplicated STORE hub table in Snowflake (incremental, insert-only Data Vault 2.0 hub). It was built using the legacy **6-layer CTE pattern** applied to all 24 sources — a framework standard across 448+ models in the project.

**CTE flow:**

```
SRC × 24 (reads view) → LOGIC × 24 (passthrough) → RENAME × 24 (passthrough)
  → FILTER × 24 (passthrough) → JOIN (UNION ALL) → FINAL (dedup + anti-join)
```

This produced **~120 CTEs**. LOGIC, RENAME and FILTER were pure passthroughs — structural scaffolding inherited from the legacy framework with no transformation logic. The FINAL layer used a `NOT EXISTS` correlated anti-join to exclude rows already present in the hub, with **no time-based filter** applied anywhere in the query.

```sql
-- ❌ ORIGINAL: Correlated NOT EXISTS — nested loop scan of hub table for every candidate row
SELECT ...
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 FROM {{ this }} existing
    WHERE existing.STORE_HK = JOIN_RESULT.STORE_HK  -- row-by-row probe
)
{% endif %}
QUALIFY ROW_NUMBER() OVER(PARTITION BY JOIN_RESULT.STORE_HK ORDER BY JOIN_RESULT.LOAD_DTS) = 1
```

> **Result:** Every incremental run timed out at the 2,000-second warehouse limit. No time-based filter existed anywhere — all 24 staging views were fully scanned on every run — and the `NOT EXISTS` correlated subquery added a nested-loop probe of the hub table for every candidate row.

---

## 2. Trial Fixes — Minimal-Change Approach

Before committing to a redesign, four targeted fixes were attempted on the existing `hub_store.sql` to minimise change risk while preserving the legacy 6-layer skeleton.

---

### Trial 1 — NOT EXISTS → LEFT JOIN IS NULL anti-join `[1,196 s]`

Replaced the correlated `NOT EXISTS` with a `LEFT JOIN … WHERE IS NULL` pattern so Snowflake could execute a hash join instead of a nested loop.

```sql
-- ✅ Trial 1: hash-join anti-join
LEFT JOIN {{ this }} existing ON existing.STORE_HK = JOIN_RESULT.STORE_HK
WHERE existing.STORE_HK IS NULL
```

**Outcome:** Run completed for the first time (1,196 s) but still scanned all partitions of all 24 staging sources — no time filter existed to limit the scan. Also introduced column ambiguity errors (`STORE_HK`, `BKCC`) that required additional qualifier fixes.

---

### Trial 2 — BKCC watermark CTE — per-source runtime cutoff `[1,372 s]`

Added an `INCREMENTAL_WATERMARK` CTE computing a per-BKCC cutoff date from the existing hub table, then INNER JOINed it into all 24 SRC CTEs to filter on `LOAD_DTS`.

```sql
-- ❌ Trial 2: watermark computed at RUNTIME — cannot prune partitions
INCREMENTAL_WATERMARK AS (
    SELECT BKCC, DATEADD('day', -15, MAX(LOAD_DTS)) AS CUTOFF_DTS
    FROM {{ this }} GROUP BY BKCC          -- value not known at plan time
),
SRC_SHD AS (
    SELECT ... FROM v_psa_stg_sales_homedepot AS SRC
    INNER JOIN INCREMENTAL_WATERMARK wm
        ON wm.BKCC = SRC.BKCC AND SRC.LOAD_DTS > wm.CUTOFF_DTS
    ...
)
```

**Outcome:** No improvement (1,372 s). The cutoff value is resolved at execution time — Snowflake cannot use it for partition pruning and still scans all partitions of the inlined staging views before evaluating the filter.

---

### Trial 3 — Extended watermark to BKCC + REC_SRC granularity `[1,418 s]`

Increased filter granularity by grouping the watermark CTE by both `BKCC` and `REC_SRC`, and updated all 24 JOIN conditions accordingly.

**Outcome:** No improvement. The subquery value is still runtime — granularity is irrelevant when partition pruning is blocked at the view boundary.

---

### Trial 4 — Reduce lookback window 15 days → 3 days `[1,512 s]`

Changed `DATEADD('day', -15, ...)` to `DATEADD('day', -3, ...)` to reduce the volume of rows passing through the filter.

**Outcome:** Marginally *slower* (1,512 s). Window size makes no difference — Snowflake must read all partitions first to evaluate a runtime predicate. This change is retained in the current `hub_store.sql` as a side-effect of the trial.

---

> **Why all 4 trials failed:** Every approach kept the time filter as a *runtime-computed value* — either a subquery or a CTE JOIN. Snowflake's micro-partition pruning requires the predicate to be a **constant known at query compile/plan time**. Because all 24 staging sources are *views*, Snowflake inlines their definitions into the query at compile time. A runtime filter value simply cannot be pushed into those inlined view definitions to prune storage-layer partitions — so every run reads all historical data regardless of the window size or granularity specified.

---

## 3. Root Cause: Runtime vs Compile-Time Predicates

The trials proved the bottleneck was **architectural** — not tunable by adjusting window size or join strategy:

- The `NOT EXISTS` and `LEFT JOIN IS NULL` anti-joins always add a full hub table scan on every incremental run, regardless of upstream optimisations.
- All four runtime watermark approaches failed for the same reason: Snowflake resolves subquery/CTE values at *execution time* — they cannot be used for micro-partition pruning at the storage layer.
- Because all 24 staging sources are *views*, Snowflake inlines their definitions into the query at compile time. A runtime predicate value cannot be pushed into those inlined view definitions — so every run reads all historical data regardless of window size.
- **The fix:** render the filter as a constant at dbt compile time via Jinja (`{% set cutoff_dts = ... %}`). When Snowflake compiles the query it sees e.g. `LOAD_DTS > '2026-05-11 13:41:57'` — a known constant. The optimizer pushes this predicate through the `UNION ALL` into each branch, and further into each inlined staging view, pruning micro-partitions at the storage layer *before* any data is read.
- Replacing `WHERE NOT EXISTS` with `unique_key + merge_update_columns=[]` in the dbt config removes the need for any anti-join scan of the hub table on incremental runs — dbt issues an insert-only MERGE natively.

> **Solution applied in-place (May 14, 2026):** The 6-layer CTE structure was fully preserved. Only three targeted additions were made to `hub_store.sql`: (1) config block with `unique_key` + `merge_update_columns=[]`, (2) compile-time `cutoff_dts` Jinja variable (14-day window), (3) `{% if is_incremental() %}WHERE LOAD_DTS > '{{ cutoff_dts }}'{% endif %}` on each of the 24 SRC CTEs, and removal of the `WHERE NOT EXISTS` block from the FINAL layer. Result: **22 s incremental** runtime (from timeout).

---

## 4. Side-by-Side Structural Comparison

| Aspect | hub_store (original) | hub_store (optimized — live) |
|---|---|---|
| CTE layers per source | 6 layers × 24 sources (SRC→LOGIC→RENAME→FILTER→JOIN→FINAL) | 6 layers × 24 sources — **structure preserved unchanged** |
| Total CTEs | ~120 | ~120 — structure preserved unchanged |
| Incremental filter | None — all 24 staging views fully scanned every run | Compile-time Jinja `cutoff_dts` (14 days) — `WHERE LOAD_DTS > '...'` on all 24 SRC CTEs — enables micro-partition pruning through inlined views |
| Anti-join / dedup strategy | NOT EXISTS correlated subquery — nested-loop scan of hub table for every candidate row | `unique_key='STORE_HK'` + `merge_update_columns=[]` in dbt config — insert-only MERGE, no hub scan |
| QUALIFY dedup | Applied 24 times (once per SRC CTE) | Applied 24 times — preserved unchanged |
| Lines of SQL | 879 lines | 804 lines — 3 targeted additions only |
| Ghost records | ✅ Full refresh only | ✅ Preserved |
| Amazon LIMIT 1 | ✅ Full refresh only | ✅ Preserved |

---

## 5. Performance Benchmark — All Runs

| # | Model | Change | Runtime | Outcome |
|---|---|---|---|---|
| 0 | hub_store | Original — NOT EXISTS, no time filter | ❌ Timeout (2,001 s) | ❌ Never completed |
| 1 | hub_store | NOT EXISTS → LEFT JOIN IS NULL | ⚠ 1,196 s | ✅ First completion — still full partition scan |
| 2 | hub_store | BKCC watermark CTE (runtime, 15-day window) | ⚠ 1,372 s | ✅ SUCCESS — no performance gain |
| 3 | hub_store | Extended watermark to BKCC + REC_SRC | ⚠ 1,418 s | ✅ SUCCESS — no performance gain |
| 4 | hub_store | Reduced window from 15 → 3 days | ⚠ 1,512 s | ✅ SUCCESS — marginally slower |
| **5** | **hub_store (in-place)** | **Config block (unique_key + merge_update_columns=[]), compile-time cutoff_dts (14 days), WHERE LOAD_DTS filter on all 24 SRC CTEs, WHERE NOT EXISTS removed** | **✅ 22 s** | **✅ SUCCESS — 4,208 rows. hub_store_v2.sql and hub_store_redesign.sql deleted. Optimized model is now production.** |

---

## 6. Data Integrity Validation

| Metric | hub_store (original) | hub_store (optimized — live) | Match? |
|---|---|---|---|
| Total rows | 7,139 | 7,139+ | ✅ No data loss — optimized model continues to insert incrementally |
| Distinct STORE_HK | 7,139 | 7,139+ | ✅ No duplicates — MERGE enforces uniqueness |
| Distinct STORE_BK | 6,601 | 6,601+ | ✅ Consistent |
| Min LOAD_DTS | 1900-01-01 (ghost records) | 1900-01-01 | ✅ Ghost records preserved (full-refresh only) |
| Max LOAD_DTS | 2026-05-12 | 2026-05-14+ | ✅ Continues to advance — 4,208 rows processed in first optimized incremental run (22 s) |

---

## 7. Recommended Next Steps

- ✅ **DONE (May 14, 2026)** — Optimizations applied in-place to `hub_store.sql`. The 6-layer structure was preserved; only the config block, compile-time `cutoff_dts`, per-SRC `WHERE LOAD_DTS` filter, and removal of `WHERE NOT EXISTS` were changed. Temp files (`hub_store_v2.sql`, `hub_store_redesign.sql`) deleted. Confirmed **22 s incremental** runtime.
- ⚠️ **Data loss runbook:** If `hub_store` incremental was skipped or failed for more than 14 days, run `dbt run -s hub_store --full-refresh` before resuming normal incremental loads.
- Apply the same compile-time literal pattern to other hub/satellite models sharing the same legacy 6-layer CTE architecture — the pattern is directly repeatable.
- Long-term: cluster PSA source tables on `LOAD_DTS` — this benefits all downstream models across all layers, not just hubs.
- Resolve disk quota issue on roaming user profile — `logs/` and `target/` write failures are cosmetic today but will grow.

---

*Generated: May 14, 2026 | dbt-datavault | Snowflake: FBHS-FBHS_GPG / DATAVAULT_DEV.DBT_SGHOSH | Warehouse: DATA_ENGINEER_WH*

---

## 8. June 10, 2026 — Refactor to hub_order_line Pattern

**Commit:** `7d2adc6c` on branch `GPGDS-11083-HubStore-Performance_Tuning`  
**Author:** Swagat Ghosh  
**Trigger:** PR reviewer requested alignment with the `hub_order_line` reference pattern.

### What Changed

| Aspect | Before (May 14 optimized) | After (June 10 refactor) |
|---|---|---|
| CTE structure | 6-layer scaffold × 27 sources (~120 CTEs) | Flat: one CTE per source + JOIN_RESULT (~30 CTEs) |
| Incremental filter | Compile-time Jinja `cutoff_dts` literal on each SRC CTE | Runtime `INCR_WATERMARK` CTE — `DATEADD(DAY,-1,MAX(LOAD_DTS))` per `REC_SRC`, LEFT JOIN into each SRC CTE |
| QUALIFY partition | `PARTITION BY STORE_HK` | `PARTITION BY STORE_BK, BKCC` |
| Anti-join / insert strategy | `unique_key='STORE_HK'` + `merge_update_columns=[]` → dbt insert-only MERGE | No `unique_key` → dbt `append` strategy + `WHERE NOT EXISTS (SELECT 1 FROM {{ this }} WHERE STORE_HK = JOIN_RESULT.STORE_HK)` in final SELECT |
| Config tags | `['materialization_override', 'hub']` | `['materialization_override', 'large_volume', 'hub']` |
| Lines of SQL | ~804 | 292 (−63%) |
| New source added | — | `v_psa_stg_dc_inventory_with_store__homedepot_ft` (`SRC_SDCIWHDF`) |
| Build result | ✅ 22 s incremental | ✅ 139 rows inserted in 1,849 s — all 66 tests PASS |

### Why the Runtime Increased

As documented in sections 2–3 above, runtime watermark CTEs do **not** enable Snowflake micro-partition pruning through inlined staging views. The `INCR_WATERMARK` value is resolved at execution time; Snowflake cannot use it to prune partitions at the storage layer. The compile-time `cutoff_dts` Jinja literal (May 14 approach) was the only mechanism proven to achieve partition pruning (22 s). The June 10 refactor trades that performance for architectural consistency with `hub_order_line`. The 1,849 s runtime is expected and consistent with the Trial 2–4 results from May.

> **Trade-off accepted:** The `hub_order_line` pattern is the team standard. Performance parity with the compile-time approach is not achievable through the runtime watermark pattern as long as sources are inlined staging views. If performance becomes unacceptable in production, revert to the compile-time `cutoff_dts` approach (documented in section 3 above).

### Key Architectural Details

**INCR_WATERMARK CTE** (incremental branch only):
```sql
WITH INCR_WATERMARK AS (
    SELECT
        REC_SRC                          AS wm_REC_SRC,
        DATEADD(DAY, -1, MAX(LOAD_DTS))  AS watermark_dts
    FROM {{ this }}
    GROUP BY REC_SRC
),
```
Each source CTE LEFT JOINs to this watermark on `REC_SRC` and filters `WHERE (wm.watermark_dts IS NULL OR SRC.LOAD_DTS >= wm.watermark_dts)`. The `-1 day` lookback provides a safety overlap for late-arriving records.

**Final SELECT — WHERE NOT EXISTS anti-join:**
```sql
SELECT * FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.STORE_HK = JOIN_RESULT.STORE_HK
)
{% endif %}
```
Because there is no `unique_key` in the config, dbt uses `append` mode — the `WHERE NOT EXISTS` is the sole guard against duplicate `STORE_HK` insertion on incremental runs.
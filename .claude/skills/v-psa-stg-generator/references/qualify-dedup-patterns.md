# QUALIFY Dedup Patterns Reference

## Three QUALIFY Patterns

### Pattern A: Lookup Table Dedup in SRC CTE
Most common (~30 models). Deduplicates secondary/lookup tables before joining.

```sql
SRC_R as (
    SELECT join_key, col1, col2
    FROM {{ source('schema', 'lookup_table') }} as SRC
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY join_key ORDER BY PSA_LOAD_DTS DESC)) = 1
)
```

**Key**: ORDER is `DESC` — we want the **latest** version of the lookup record.

### Pattern B: Primary Source Dedup in SRC CTE
Used when driver table has source-level duplicates (~8 models).

```sql
SRC_S as (
    SELECT * FROM {{ source('schema', 'driver_table') }} as SRC
    QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY candidate_bk ORDER BY PSA_LOAD_DTS)
)
```

**Key**: ORDER is typically `ASC` — we want the **earliest** record.
**When to use**: Data profiling shows BK duplicates within the same PSA_LOAD_DTS.

### Pattern C: Final SELECT Dedup — LEGACY ONLY, PROHIBITED for new v_psa_stg
Exists in ~10 legacy models. **Do NOT use this pattern when generating new v_psa_stg models.**

If the grain (BK + LOAD_DTS) has duplicates after joining, the root cause must be fixed upstream:
- Lookup table producing fan-out → add Pattern A dedup to the SRC CTE
- Driver table has source duplicates → add Pattern B dedup to the SRC CTE
- Join logic is incorrect → fix the join conditions

Masking grain issues with a FINAL QUALIFY hides data problems and makes debugging harder.

```sql
-- LEGACY PATTERN (do NOT use for new models)
FINAL as (
    SELECT * FROM JOIN_RESULT
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY ENTITY_BK ORDER BY LOAD_DTS DESC, PSA_LOAD_DTS DESC)) = 1
)
```

## Delete Flag Handling (PSA_DELETE_IND and _FIVETRAN_DELETED)

**NEVER filter on `PSA_DELETE_IND` or `_FIVETRAN_DELETED` at the staging layer.** These are data attributes tracked in HASHDIFF so satellites can record deletion state history. Filtering at staging silently drops deleted records from the vault, breaking historical accuracy.

- `PSA_DELETE_IND` → include in HASHDIFF (`hashdiff: "yes"`), pass through as data
- `_FIVETRAN_DELETED` → include in HASHDIFF (`hashdiff: "yes"`), pass through as data

The ONLY valid staging WHERE clause is for confirmed system dummy/placeholder records with explicit business justification (e.g., `TERM_ID <> 0` when TERM_ID=0 is a known Oracle EBS ghost row, confirmed by data profiling). Do NOT add filters speculatively.

Note: Some legacy models use `WHERE psa_delete_ind = 'N'` (Profitero, Appbot). These were built before this standard was established. Do NOT replicate this pattern in new v_psa_stg models. See lesson #28.

## Decision Guide
```
Does the source table have duplicate BKs?
├── No → No QUALIFY needed in SRC
└── Yes → Is it the driver table or a lookup?
    ├── Driver → Pattern B (ASC, earliest record)
    └── Lookup → Pattern A (DESC, latest record)

After joining, is the grain (BK + LOAD_DTS) unique?
├── Yes → No QUALIFY in FINAL ✓
└── No → DO NOT add QUALIFY in FINAL. Instead:
    ├── Check if a lookup is causing fan-out → add Pattern A to that SRC CTE
    ├── Check if driver has duplicates → add Pattern B to driver SRC CTE
    └── Check join conditions for correctness
```

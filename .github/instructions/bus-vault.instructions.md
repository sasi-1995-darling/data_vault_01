---
applyTo: "models/bus_vault/**"
description: "Standards for business vault tables — PIT, PIT Bridge, DIM, FACT, REF"
---

# Business Vault Model Standards (Interactive Editing)

## Layer Separation Rule (MANDATORY)
- **PIT/PB models contain ALL business logic** — joins, filters, calculations, CASE statements
- **DIM/FACT models are 1:1 wrappers** — column selection and aliasing ONLY
- Anti-pattern: `CASE WHEN ...` or `WHERE status = 'Active'` in a DIM or FACT model
- Correct: Apply logic in PIT/PB, then DIM/FACT simply `SELECT columns FROM pit_/pb_`

## PIT (Point-in-Time) Tables

### Structure
- Source from hub + latest satellite records (QUALIFY ROW_NUMBER DESC)
- Standard columns: `PIT_REC_SRC`, `SNAPSHOTDATE`, `PIT_LOAD_DTS`
- Hub columns pass through: `<entity>_HK`, `<entity>_BK`, `REC_SRC`, `BKCC`

### Satellite Join Pattern
```sql
SRC_SAT as (
    SELECT * FROM {{ ref('sat_entity__source') }}
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY <entity>_HK ORDER BY LOAD_DTS DESC)) = 1
)
```

### Prefix Convention for Satellite Columns
- When multiple satellites join, prefix ambiguous columns: `SAT_<source>_<column>`
- Example: `SAT_WINN_PSA_DELETE_IND`, `SAT_ML_PSA_DELETE_IND`

## PIT Bridge (PB) Tables
- Join multiple links/hubs for transactional fact grain
- All business logic (amounts, calculations, status derivation) lives here
- Must include all FK hash keys for downstream FACT views

## DIM Views
- Materialized as `view`
- 1:1 on a PIT table — SELECT + alias only
- Column aliasing for business-friendly names (e.g., `CUSTOMER_BK as CUSTOMER_ID`)
- No WHERE clauses, no CASE statements, no JOINs

## FACT Views
- Materialized as `view`
- 1:1 on a PB table — SELECT + alias only
- Same rules as DIM: no logic, no filters

## REF (Reference) Tables
- Materialized as `table`
- Static/slow-changing reference data
- PK constraint required (`dbt_constraints.primary_key`)

## Materialization Summary
| Prefix | Materialization |
|--------|----------------|
| `pit_` | table |
| `pb_`  | table |
| `dim_` | view |
| `fact_` | view |
| `ref_` | table |

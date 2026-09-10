---
applyTo: "models/raw_vault/sat/**"
description: "Standards for satellite tables — interactive editing guidance"
---

# Satellite Model Standards (Interactive Editing)

## Incremental Guard
- `NOT EXISTS` must compare **parent HK + HASHDIFF** (never grain columns)
- Pattern: `WHERE NOT EXISTS (SELECT 1 FROM {{ this }} WHERE <parent>_HK = src.<parent>_HK AND HASHDIFF = src.HASHDIFF)`
- Never use `LOAD_DTS` in the NOT EXISTS clause

## HASHDIFF Inclusions/Exclusions
- **Include**: all data columns, `PSA_DELETE_IND`, `_FIVETRAN_DELETED`
- **Exclude**: HK, BK, BKCC, REC_SRC, LOAD_DTS, `_FIVETRAN_ID`, `_FIVETRAN_SYNCED`, `PSA_LOAD_DTS`

## Source Constraint
- One satellite = one REC_SRC (single source per satellite model)
- Global `MAX(LOAD_DTS)` watermark is correct (no REC_SRC scoping needed)

## Ghost Records
- Ghost record for HK uses same sentinel as parent hub
- Ghost HASHDIFF: `MD5_BINARY('GHOST')`

## Config
- `full_refresh = var("force_full_refresh", false)` — always present
- Materialization: `incremental`

## Test Coverage
- `dbt_constraints.primary_key` on `(parent_HK, LOAD_DTS)`
- `dbt_constraints.foreign_key` referencing parent hub HK (required)
- `dbt_expectations.expect_table_row_count_to_be_between` (min_value: 4)

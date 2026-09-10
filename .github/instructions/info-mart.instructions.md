---
applyTo: "models/info_mart/**"
description: "Standards for information mart models — reports, facts, and domain views"
---

# Information Mart Standards (Interactive Editing)

## Purpose
Info mart models serve end consumers (BI tools, reports, APIs). They SELECT from
business vault (DIM/FACT views) and may join multiple dimensions to facts.

## Naming Conventions
| Prefix | Purpose |
|--------|---------|
| `rpt_` / `rep_` | Report-specific views |
| `fact_` | Mart-level fact aggregations |
| `im_` | General info mart views |

## Domain Folders
Models are organized by business domain under `models/info_mart/`:
- `sales/`, `supply_chain/`, `direct_spend/`, `pos/`, `planning/`, etc.
- Place new models in the appropriate domain folder

## Standards
- Materialized as `view` (default) unless performance requires `table`
- Source ONLY from `bus_vault` layer models (DIM, FACT, REF) — never from raw_vault directly
- Column names should be business-friendly (no `_HK`, no `_BK` suffixes exposed)
- Use LEFT JOINs when joining dimensions to facts (dimensions may have ghost records)

## Testing
- `rep_` models: No schema tests required (QA team owns singular tests)
- `fact_` / `im_` models: PK constraint recommended if grain is well-defined
- Performance-sensitive models: add `dbt_expectations.expect_table_row_count_to_be_between`

## Anti-Patterns
- Do NOT add business logic here — it belongs in PIT/PB layer
- Do NOT reference `v_psa_stg_*` or `hub_*` / `sat_*` models directly
- Do NOT use `SELECT *` — explicitly list columns for downstream contract stability

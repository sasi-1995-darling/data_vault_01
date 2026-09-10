---
paths:
  - "dbt_project.yml"
  - "models/**"
  - "macros/**"
---

# Architecture & Project Structure

## Project Overview
Fortune Brands Innovations (FBIN) Data Vault 2.x implementation in dbt on Snowflake.
- 2,141+ SQL models across staging, raw vault, business vault, and info mart layers
- PSA (Persistent Staging Area) is the source/building block — all raw data lands in PSA first
- dbt version: 1.5+ with Fusion/static parser enabled

## Directory Structure
```
models/
  staging/base/          # base_<entity>__<source> (174 models) — LEGACY (AutomateDV pipeline)
  staging/stage/         # stage tables (163 models) — LEGACY (AutomateDV pipeline)
  int_staging_views/     # v_psa_stg_* views (448 models)
  raw_vault/hub/         # hub_* incremental (151 models)
  raw_vault/sat/         # sat_*, lsat_*, msat_*, esat_* incremental (388 models)
  raw_vault/link/        # lnk_*, tlink_* incremental (115 models)
  bus_vault/pit/         # pit_* tables (some large volume override to incremental)
  bus_vault/pit_bridge/  # pb_* tables (some large volume override to incremental)
  bus_vault/dim/         # dim_* views
  bus_vault/fact/        # fact_* views (some large volume override to incremental)
  bus_vault/reference/   # ref_* tables
  bus_vault/flat_logic/  # flat logic views
  info_mart/<domain>/    # rpt_*, rep_*, fact_*, im_* views/tables
tests/                   # Singular tests: pk_, de_, dt_, c_, u_, v_, t_, re_ prefixes
macros/                  # 9 custom DQ macros + utility macros
seeds/                   # Reference data seeds
```
Note: `staging/base/` and `staging/stage/` are legacy pipelines built with the AutomateDV package. They still run but are not being refactored — all new development uses `int_staging_views/`.

## 4-Layer CTE Standard
New models use 4 layers: **SRC → LOGIC → JOIN → FINAL**
- Legacy models (448+) use 6-layer (SRC → LOGIC → RENAME → FILTER → JOIN → FINAL) — RENAME/FILTER were always passthrough
- SRC driver table `SELECT *`: applies to **v_psa_stg and sat builds only**; all other model types use explicit column lists
- SRC secondary/lookup: explicit columns only (join key + needed columns)
- SRC BKCC: `SELECT BKCC, REC_SRC` with WHERE filter inline

## Schema Naming
- PSA source: `PSA_PROD.<schema>.<table>` — ALL environments read from PSA_PROD
- Sources use: `psa_{{env_var('DBT_SOURCE_ENV')}}` where `DBT_SOURCE_ENV=prod`
- Target schemas: `DATAVAULT_DEV`, `DATAVAULT_QA`, `DATAVAULT_PROD`

## Environment Awareness
```bash
DBT_ENVIRON=dev          # dev | qa | prod
DBT_SOURCE_ENV=prod      # Always prod (PSA_PROD)
```
- Warehouse assignment is dynamic via `dbt_project.yml` and dbt Cloud environment variables
- Local development uses env vars: `DBT_WAREHOUSE_DEFAULT`, `DBT_WAREHOUSE_STAGING`, etc.
- dbt Cloud environments override these per target (dev/qa/prod)

## Table Naming Conventions
| Layer | Prefix | Materialization |
|-------|--------|----------------|
| Base staging | `base_<entity>__<source>` | view |
| Int staging | `v_psa_stg_<entity>__<source>` | view |
| Hub | `hub_` | incremental |
| Satellite | `sat_`, `lsat_`, `msat_`, `esat_` | incremental |
| Link | `lnk_`, `tlink_` | incremental |
| PIT | `pit_` | table (large volume: incremental) |
| PIT Bridge | `pb_` | table (large volume: incremental) |
| Dimension | `dim_` | view |
| Fact | `fact_` | view (large volume: incremental) |
| Reference | `ref_` | table |
| Report | `rpt_`, `rep_` | view (legacy) |
| Info Mart | `im_` | varies |

Satellite variants: `sat_` = standard, `lsat_` = link satellite (parent is a link), `msat_` = multi-active, `esat_` = effectivity satellite.

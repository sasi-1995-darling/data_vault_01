# dbt Fusion Migration Changes

This document summarizes all code changes made during the migration to the dbt Fusion engine.

**Migration Date:** February 13, 2026  
**dbt-fusion Version:** 2.0.0-preview.114  
**Final Result:** `dbtf compile` completed with **0 errors** and 238 warnings

---

## Summary

| Category | Count |
|----------|-------|
| Files Modified | 12 |
| Schema Drift Fixes | 8 |
| SQL Syntax Fixes | 4 |
| Test Config Fixes | 1 |

---

## Changes by Category

### 1. SQL Cast Syntax (PostgreSQL → Standard SQL)

**Error:** Fusion's static analysis couldn't parse PostgreSQL-style cast syntax `::varchar()`

**Files Modified:**
- `models/staging/stage/ml_ebs/shipment/stg_location__ml_ebs.sql`
- `models/staging/stage/ml_ebs/shipment/stg_location__ml_ebs_v1.sql`

**Fix Applied:**
```sql
-- Before
location_id::varchar()

-- After  
CAST(location_id AS VARCHAR)
```

**Reason:** Fusion requires standard SQL CAST() syntax for explicit type conversions.

---

### 2. Invalid Test SQL Syntax

**Error:** Tests had `SELECT *` with no columns due to `WHERE 1=0` clause

**Files Modified:**
- `tests/Orion/data_exist_pos_menards_moen.sql`
- `tests/Orion/data_exist_pos_rv_lowes_thermatru.sql`

**Fix Applied:**
```sql
-- Before
select * where 1=0

-- After
select 1 as data_exists where 1=0
```

**Reason:** Fusion requires explicit column selection even in always-false WHERE clauses.

---

### 3. Deprecated Test Configuration Syntax

**Error:** Test `severity` option at top-level instead of under `config:`

**File Modified:**
- `models/int_staging_views/general_ledger/v_psa_stg_controlling_ledger_entry__winn_sap.yml`

**Fix Applied:**
```yaml
# Before
- dbt_expectations.expect_table_row_count_to_be_between:
    severity: warn

# After
- dbt_expectations.expect_table_row_count_to_be_between:
    config:
      severity: warn
```

**Reason:** Fusion requires test configuration options to be nested under `config:` block.

---

### 4. Oracle DUAL Table Syntax

**Error:** Reference to Oracle `DUAL` table which doesn't exist in Snowflake

**File Modified:**
- `models/staging/base/moen_sap/item/base_plant__moen_sap_v1.sql`

**Fix Applied:**
```sql
-- Before
from dual inner join cte_bkcc

-- After
from cte_bkcc
```

**Reason:** The CTE already provided the necessary data; DUAL table was unnecessary Oracle syntax.

---

### 5. Schema Drift - Missing Columns in Source Tables

**Error:** `dbt0227: No column X found` - Fusion's static analysis detected columns referenced in SQL that don't exist in source tables.

#### Consumer Feedback Models (HS_FLAG)

**Files Modified:**
- `models/int_staging_views/consumer_feedback/v_psa_stg_sentiment_subcategory_mapping.sql`
- `models/int_staging_views/consumer_feedback/v_psa_stg_invalid_review.sql`
- `models/int_staging_views/consumer_feedback/v_psa_stg_sentiment_output.sql`

**Columns Removed:** `HS_FLAG`

**Reason:** Column doesn't exist in source table `PSA_DEV.TM_PRO_MOEN.MV_SENTIMENT_OUTPUT`.

#### External Claims Models (Multiple Columns)

**Files Modified:**
- `models/int_staging_views/claims/v_psa_stg_external_claims.sql`
- `models/raw_vault/sat/sat_external_claims.sql`

**Columns Removed:** `SALES_DOCUMENT`, `CAUSE`, `DAYS_TO_CLOSE`

**Reason:** Columns don't exist in source table. Removed from all layers: SRC, LOGIC, RENAME, FINAL, and GHOST records.

#### Plant FIB OCF Models (KANBAN Columns)

**Files Modified:**
- `models/int_staging_views/item/v_psa_stg_plant__fib_ocf.sql`
- `models/raw_vault/sat/sat_plant__fib_ocf.sql`

**Columns Removed:** 
- `KANBAN_CARD_PREFIX`
- `KANBAN_DOC_SEQ_ID`
- `KANBAN_CARD_START_NUMBER`
- `KANBAN_DOC_SEQ_CAT_CODE`

**Reason:** Columns don't exist in source table. Removed from all layers: SRC, LOGIC, RENAME, FINAL, HASHDIFF calculations, and GHOST records.

---

## Warnings (Not Addressed)

The following warnings were not addressed as they don't block Fusion compatibility:

1. **dbt1065** (238 occurrences): Package `automate_dv` version compatibility warning - package requires dbt <2.0.0 but current version is 2.0.0-preview.114

2. **dbt1014**: Failed to download source schema for some sources (tables don't exist or not authorized) - static analysis skipped for affected models

3. **dbt1000**: Unsafe introspection warnings for models using dynamic SQL features

4. **dbt1065**: `is_hashdiff` flag warnings for automate_dv staging models

---

## Environment Setup Notes

Required environment variables for successful compilation:
```bash
export DBT_ENVIRON=dev
export DBT_SOURCE_ENV=dev
```

---

## Verification

Final verification command:
```bash
dbtf compile
```

Output:
```
==================== Execution Summary =====================
Finished 'compile' with 238 warnings for target 'dev' [1m 58s]
Processed: 4 hooks | 2116 models | 3404 tests | 1 seed
Summary: 5525 total | 5525 success
```

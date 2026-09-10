# Profiling Queries — Stage 1 SQL Templates

## Table Discovery

```sql
-- Describe table structure
DESCRIBE TABLE PSA_PROD.<schema>.<table>;

-- Row count
SELECT COUNT(*) AS ROW_COUNT FROM PSA_PROD.<schema>.<table>;

-- Sample data (5 rows)
SELECT * FROM PSA_PROD.<schema>.<table> LIMIT 5;
```

## Business Key Profiling

```sql
-- Grain validation: BK + PSA_LOAD_DTS must be unique
SELECT <bk_col>, PSA_LOAD_DTS, COUNT(*) AS dupes
FROM PSA_PROD.<schema>.<table>
GROUP BY <bk_col>, PSA_LOAD_DTS
HAVING COUNT(*) > 1
LIMIT 10;

-- Composite BK grain validation
SELECT <bk_col1>, <bk_col2>, PSA_LOAD_DTS, COUNT(*) AS dupes
FROM PSA_PROD.<schema>.<table>
GROUP BY <bk_col1>, <bk_col2>, PSA_LOAD_DTS
HAVING COUNT(*) > 1
LIMIT 10;

-- BK cardinality
SELECT COUNT(DISTINCT <bk_col>) AS distinct_bk,
       COUNT(*) AS total_rows
FROM PSA_PROD.<schema>.<table>;
```

## NULL BK Check

```sql
-- NULL BK count and percentage
SELECT COUNT(*) AS null_count,
       (SELECT COUNT(*) FROM PSA_PROD.<schema>.<table>) AS total_count,
       ROUND(COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM PSA_PROD.<schema>.<table>), 0), 2) AS null_pct
FROM PSA_PROD.<schema>.<table>
WHERE <bk_col> IS NULL;

-- Composite BK: any component NULL
SELECT COUNT(*) AS null_count
FROM PSA_PROD.<schema>.<table>
WHERE <bk_col1> IS NULL OR <bk_col2> IS NULL;
```

## BKCC Lookup

```sql
-- Search by table name hint
SELECT BKCC, REC_SRC, REC_SRC_DESC
FROM DATAVAULT_DEV.RAW_VAULT.REF_BUSINESS_KEY_COLLISION
WHERE rec_src LIKE '%<TABLE_HINT>%'
  AND DEACTIVATED_IND = 'N';

-- List all active BKCC entries (fallback when search returns 0)
SELECT BKCC, REC_SRC, REC_SRC_DESC
FROM DATAVAULT_DEV.RAW_VAULT.REF_BUSINESS_KEY_COLLISION
WHERE DEACTIVATED_IND = 'N'
ORDER BY REC_SRC;
```

## Technical Column Detection

```sql
-- Check for _FIVETRAN columns
SELECT COLUMN_NAME
FROM PSA_PROD.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = '<SCHEMA>'
  AND TABLE_NAME = '<TABLE>'
  AND COLUMN_NAME IN ('_FIVETRAN_DELETED', '_FIVETRAN_SYNCED', '_FIVETRAN_ID',
                       'PSA_DELETE_IND', 'PSA_LOAD_DTS', 'PSA_RECORD_SOURCE');
```

## Data Type Distribution

```sql
-- Column types for mapping
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH,
       NUMERIC_PRECISION, NUMERIC_SCALE, IS_NULLABLE
FROM PSA_PROD.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = '<SCHEMA>'
  AND TABLE_NAME = '<TABLE>'
ORDER BY ORDINAL_POSITION;
```

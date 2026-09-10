---
description: "Compare a model's columns against its PSA source table to detect schema drift"
---

# Diff Model vs Source

Compare a v_psa_stg model's column list against the actual PSA source table to detect
added, removed, or renamed columns.

## Step 1 — Identify the Model

If `$ARGUMENTS` is provided, use it as the model name. Otherwise use the currently open file.

## Step 2 — Get Model Columns

Read the model SQL and extract the column list from the FINAL CTE's SELECT clause.

## Step 3 — Get Source Columns (if snow-mcp available)

```sql
SELECT COLUMN_NAME, DATA_TYPE, ORDINAL_POSITION
FROM <PSA_DB>.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = '<schema>' AND TABLE_NAME = '<table>'
ORDER BY ORDINAL_POSITION;
```

## Step 4 — Compare

Present a diff table:
| Column | In Model | In Source | Status |
|--------|----------|-----------|--------|
| NEW_COL | No | Yes | **Added in source** |
| OLD_COL | Yes | No | **Removed from source** |
| EXISTING | Yes | Yes | OK |

## Step 5 — Recommend

- New columns: suggest adding to HASHDIFF (if data) or noting as metadata
- Removed columns: flag as breaking change — model needs update
- Type changes: flag for review (may affect casting in LOGIC CTE)

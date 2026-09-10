---
description: "Diagnose failures from the last dbt build run using run_results.json and Snowflake"
---

# Diagnose dbt Build Failures

Investigate the most recent dbt build failures:

## Step 1 — Identify Failures

Read `target/run_results.json` and filter to entries where `status` is `"error"` or `"fail"`.
List each failure: node name, status, execution time, and the first 5 lines of the error message.

## Step 2 — Inspect Each Failure

For each failed node:
- Read the model SQL file (`models/` path from the node's `original_file_path`)
- If it's a test failure, read the test definition (YAML schema or singular test SQL)
- Identify: what does this model/test do? What data does it expect?

## Step 3 — Query Snowflake (if snow-mcp is available)

For test failures, query Snowflake to find sample violating rows:
- `not_null` failures: `SELECT * FROM <table> WHERE <column> IS NULL LIMIT 5`
- `unique` failures: `SELECT <column>, COUNT(*) FROM <table> GROUP BY 1 HAVING COUNT(*) > 1 LIMIT 5`
- `primary_key` failures: same as unique on the PK columns

For model errors: check if the source table exists and has recent data.

## Step 4 — Categorize and Summarize

For each failure, assign a root cause category:
- **Data quality**: bad/missing data from source
- **Schema drift**: source column added/removed/renamed
- **Code bug**: logic error in SQL (typo, wrong join, missing COALESCE)
- **Config error**: dbt_project.yml, YAML schema, or materialization issue
- **Environment**: permissions, warehouse size, timeout

## Step 5 — Present Structured Summary

```
## Build Failure Diagnosis

**Total**: N failures out of M nodes executed
**Severity breakdown**: X critical, Y high, Z medium

| Model/Test | Type | Root Cause | Severity | Fix |
|------------|------|-----------|----------|-----|
| ... | ... | ... | ... | ... |

### Immediate Actions
1. Fix [highest severity item] first because [reason]
2. ...
```

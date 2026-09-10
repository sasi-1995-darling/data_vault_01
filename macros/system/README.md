# System Macros

## `gc_diff_analysis.sql`
**Production validation** - Compares dbt models vs Snowflake production objects
- Maps DEV/QA → PROD databases (`DATAVAULT_DEV` → `DATAVAULT_PROD`)
- Identifies missing/orphaned tables and schemas
- Stores results in `metrics.gc_diff_comparison`

```sql
{{ gc_diff_analysis() }}  -- Run and store results
{{ gc_diff_analysis(store_results=false) }}  -- Analysis only
```

## `cleanup_pr_schemas.sql`
**PR cleanup** - Drops dbt Cloud PR schemas after merge/close
- Finds schemas matching `DBT_CLOUD_PR_{job_id}_{pr_number}` pattern
- Supports dry-run mode for safety

```sql
{{ cleanup_pr_schemas(job_id=123, pr_number=456) }}  -- Dry run
{{ cleanup_pr_schemas(job_id=123, pr_number=456, dry_run=false) }}  -- Execute
```

## `generate_schema_name.sql`
**Schema naming** - Custom schema generation logic for different environments
- Handles PR schemas vs normal deployment schemas
- Supports forced PR schema via API variables
- Environment-aware naming (dev/qa/prod)

*Used automatically by dbt - no manual execution needed*
---
description: "Look up the BKCC and REC_SRC registration for a given entity or model"
---

# Lookup BKCC / REC_SRC

Find the BKCC (Business Key Collision Code) and REC_SRC for a given entity.

## Step 1 — Search Existing Models

Search for the entity in existing v_psa_stg models:

```bash
grep -r "BKCC" models/int_staging_views/ | grep -i "$ARGUMENTS"
```

## Step 2 — Check YAML Configs

Look in the pipeline state or YAML configs for registered BKCC values:

```bash
find scripts/automation/.pipeline_state -name "*.yaml" | xargs grep -l "$ARGUMENTS"
```

## Step 3 — Query Snowflake (if snow-mcp available)

```sql
SELECT BUSINESS_KEY_COLLISION_CODE, REC_SRC, ENTITY_NAME
FROM DEV_DV.INFORMATION_SCHEMA.REF_BUSINESS_KEY_COLLISION
WHERE ENTITY_NAME ILIKE '%$ARGUMENTS%'
ORDER BY ENTITY_NAME;
```

## Output Format

Present as a table:
| Entity | BKCC | REC_SRC | Source Model |
|--------|------|---------|--------------|

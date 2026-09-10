---
description: "Generate dbt unit tests for a PIT or PB model by analyzing its business logic"
mode: "agent"
tools: ["search", "read", "editFile", "createFile"]
---

# Generate Unit Tests for Business Vault Model

Generate dbt `unit_tests:` YAML for a PIT or PB model using the DocuSign AI-assisted
unit testing pattern: parse logic → summarize → validate → generate mock data → output.

## Scope

**Apply to**: `pit_*`, `pb_*` models only.
**Do NOT use for**: v_psa_stg, hub, sat, link, dim, fact, ref, rep models.

## Workflow

### Step 1 — Read the Model

If `$ARGUMENTS` is provided, use it as the model name. Otherwise use the currently open file.
Read the full SQL and identify:
- Source refs (which hub/sat/link models it joins)
- CASE statements and derived columns
- JOIN conditions (especially multi-satellite joins)
- QUALIFY / ROW_NUMBER patterns
- NULL handling (COALESCE, IFNULL, ghost record logic)

### Step 2 — Summarize Logic

Present a structured summary to the user:

```
Model: pit_customer
Sources: hub_customer_v1, sat_customer__winn_sap, sat_customer__ml_ebs
Logic Branches:
  1. SAT_WINN latest record (QUALIFY ROW_NUMBER DESC by CUSTOMER_HK)
  2. SAT_ML latest record (same pattern)
  3. JOIN on CUSTOMER_HK
  4. COALESCE(SAT_WINN.NAME1, SAT_ML.NAME) as CUSTOMER_NAME
Derived Columns:
  - PIT_REC_SRC (static: 'PIT_CUSTOMER')
  - PIT_LOAD_DTS (CURRENT_TIMESTAMP)
  - CUSTOMER_NAME (COALESCE across sources)
Edge Cases:
  - Customer exists in hub but no satellite record (ghost HK join)
  - Customer exists in both SATs with conflicting data (COALESCE precedence)
```

**STOP** — Ask the user to validate this interpretation before proceeding.

### Step 3 — Generate Unit Test YAML

After user confirms, generate `unit_tests:` block:

```yaml
unit_tests:
  - name: test_<model>_<scenario>
    description: "<what this tests>"
    model: <model_name>
    given:
      - input: ref('<source_model>')
        rows:
          - {COLUMN1: 'value1', COLUMN2: 'value2'}
    expect:
      rows:
        - {DERIVED_COL: 'expected_value'}
```

### Step 4 — Generate Test Scenarios

For each model, generate at minimum:

| Category | Scenario |
|----------|----------|
| **Positive** | Happy path — all sources have data, logic produces expected output |
| **Negative** | Missing source data — satellite has no matching row (ghost record path) |
| **Edge: NULL** | Key columns are NULL — test COALESCE/IFNULL handling |
| **Edge: Temporal** | Multiple records per HK — verify QUALIFY picks latest |
| **Edge: Conflict** | Same entity in multiple sources — verify precedence/merge logic |

### Step 5 — Output Location

Place the unit test YAML in the same schema file as the model's existing tests:
- If `models/bus_vault/pit/<domain>/_pit_<entity>.yml` exists, append `unit_tests:` section
- If no schema file exists, create one following yaml-schema-standards

### Step 6 — Validate

After generating, ask the user to review the expected output values.
The AI generates the mock inputs but **the user validates expected outputs** —
only they know the correct business intent.

## Important

- dbt unit tests require dbt 1.8+ (verify with `dbt --version` if unsure)
- Unit test `given:` inputs must include ALL columns the model SELECTs from that ref
- The `expect:` section must match the model's output column names exactly
- Use realistic but simple mock data (1-3 rows per scenario)
- Do NOT generate unit tests for RV models — they have no business logic

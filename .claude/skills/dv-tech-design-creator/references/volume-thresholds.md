# Volume Thresholds — Row Count Classification

## Thresholds and Actions

| Row Count | Classification | YAML Config | Actions |
|-----------|---------------|-------------|---------|
| < 50M | Normal | `large_volume: false` | Standard v_psa_stg view. No special config needed. |
| 50M-300M | Caution | `large_volume: false` | Add `cluster_by` recommendation to YAML. Flag in XLSX for reviewer. Add SQL header comment: `-- CAUTION: 50-300M rows. Consider cluster_by for downstream hub/sat.` |
| > 300M | Large Volume | `large_volume: true` | Auto-set flag. Stage 2 adds SQL header comment only. |

## v_psa_stg Views vs. Incremental Models

**v_psa_stg models are views** — they are recreated every run. Therefore:
- `on_schema_change` does NOT apply to views
- `full_refresh = false` does NOT apply to views
- `{{ config() }}` with incremental settings is NOT used for v_psa_stg

The `large_volume: true` flag is **metadata for downstream consumers**:
- Stage 2 adds a SQL header comment: `-- LARGE VOLUME (>300M rows): Downstream hub/sat should use INCR_WATERMARK, full_refresh=false, tags=['large_volume']`
- When `build.py` generates hub/sat/link models (incremental materialization), it reads this flag and applies `{{ config(full_refresh=false, on_schema_change='append_new_columns', tags=['large_volume']) }}`

## Recording in YAML Config

```yaml
_pipeline_metadata:
  large_volume: true   # or false
  row_count: 450000000 # approximate, for documentation
```

The `row_count` is informational only — it is not used by Stage 2 code generation. It provides context for reviewers and auditors.

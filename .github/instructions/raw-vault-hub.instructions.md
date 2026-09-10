---
applyTo: "models/raw_vault/hub/**"
description: "Standards for hub tables — interactive editing guidance"
---

# Hub Model Standards (Interactive Editing)

## Incremental Guard
- `NOT EXISTS` must compare **HK only** (not BK, not LOAD_DTS)
- Pattern: `WHERE NOT EXISTS (SELECT 1 FROM {{ this }} WHERE <entity>_HK = src.<entity>_HK)`

## Ghost Records
- Three sentinels: key `0` (unknown), key `-1` (not applicable), key `-2` (error)
- Use `DECODE(ghost.KEY, 0, ..., -1, ..., -2, ...)` pattern
- Ghost HK: `MD5_BINARY(UPPER(CONCAT_WS('||', sentinel_value, BKCC_value)))`

## Watermark
- When multiple REC_SRC feed one hub, scope watermark per REC_SRC:
  `WHERE LOAD_DTS > (SELECT MAX(LOAD_DTS) FROM {{ this }} WHERE REC_SRC = '<this_source>')`
- Single-source hubs use global `MAX(LOAD_DTS)` watermark

## Config
- `full_refresh = var("force_full_refresh", false)` — always present
- Materialization: `incremental` with `unique_key` on HK

## Test Coverage
- `dbt_constraints.primary_key` on HK (required)
- `dbt_expectations.expect_table_row_count_to_be_between` (min_value: 4 = ghosts + data)

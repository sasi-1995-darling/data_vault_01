---
applyTo: "models/raw_vault/link/**"
description: "Standards for link tables — interactive editing guidance"
---

# Link Model Standards (Interactive Editing)

## Incremental Guard
- `NOT EXISTS` must compare **LNK HK only** (not component HKs, not LOAD_DTS)
- Pattern: `WHERE NOT EXISTS (SELECT 1 FROM {{ this }} WHERE LNK_<entity>_HK = src.LNK_<entity>_HK)`

## Link HK Composition
- LNK HK is derived from all participating hub HKs concatenated
- Pattern: `MD5_BINARY(UPPER(CONCAT_WS('||', hub1_HK, hub2_HK, ..., hubN_HK)))`
- Order of HKs in the concat must be consistent across all source CTEs

## Multi-Source Links
- Each source gets its own `SRC_` and `LOGIC_` CTE
- All sources UNION into a single `JOIN_` CTE before the FINAL select
- Use `QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_<entity>_HK ORDER BY LOAD_DTS))=1` per source CTE
- Non-applicable hub references use ghost key `-2` (error sentinel):
  ```sql
  MD5_BINARY(UPPER(CONCAT_WS('||',
      COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
  )))  as PURCHASING_ORG_HK
  ```

## Watermark (Multi-Source)
- When multiple REC_SRC feed one link, scope watermark per REC_SRC:
  `WHERE LOAD_DTS > (SELECT MAX(LOAD_DTS) FROM {{ this }} WHERE REC_SRC = '<this_source>')`
- Single-source links use global `MAX(LOAD_DTS)` watermark

## Required Columns
- `LNK_<entity>_HK` — link hash key (PK)
- All participating hub HKs (e.g., `PO_ITEM_HK`, `PO_HEADER_HK`, `SUPPLIER_HK`)
- `LOAD_DTS` — earliest appearance timestamp
- `REC_SRC` — record source identifier

## Degenerate Attributes
- Links may carry degenerate attributes (e.g., `PO_LINE_NUMBER`) that exist only in the link context
- These are NOT tracked for change (no HASHDIFF) — they are insert-only with the link record

## Transactional Links (`tlink_`)
- Same structure as standard links but carry transaction-level data columns
- May include amount, quantity, or date columns directly on the link
- Still incremental with `NOT EXISTS` on the LNK HK

## Ghost Records
- Three sentinels: key `0` (unknown), key `-1` (not applicable), key `-2` (error)
- Ghost LNK HK: `MD5_BINARY(UPPER(CONCAT_WS('||', sentinel_hub1, sentinel_hub2, ...)))`

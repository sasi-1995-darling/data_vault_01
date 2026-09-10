# Hashing, Ghost Records & LOAD_DTS (FBIN Mechanics)

> The mechanical reference the advisor cites when a modeling decision touches HK/HASHDIFF
> composition, ghosts, or timestamps. Formulas are FBIN-exact. Cross-reference:
> `.github/skills/v-psa-stg-generator/references/hash-key-formulas.md`.

## Hash key (HK)

```sql
MD5_BINARY(UPPER(CONCAT_WS('||',
    COALESCE(NULLIF(TRIM(CAST(raw_col1 AS VARCHAR)), ''), '^^')
  , COALESCE(NULLIF(TRIM(CAST(raw_col2 AS VARCHAR)), ''), '^^')
  , COALESCE(NULLIF(TRIM(CAST(BKCC       AS VARCHAR)), ''), '^^')
))) AS ENTITY_HK
```

Rules that drive modeling correctness:
- **Raw source column names**, not BK aliases (`CAST(PO_HEADER_ID …)`, not `CAST(PO_ITEM_BK …)`).
- **BKCC is always the last component.**
- `MD5_BINARY` → `BINARY(16)` (FBIN), not SHA1/`BINARY(20)`.
- `^^` is the in-hash NULL/empty sentinel (after `TRIM`).
- **Link HK** = `MD5_BINARY(UPPER(CONCAT_WS('||', hub1_HK, …, hubN_HK)))`, consistent order.
- **Composite-BK trap** (post-#1907): composing the link HK from hub HK **values** (above)
  eliminates the byte-collision with the line hub HK — hub-HK values share no raw
  components. Legacy raw-column links duplicated the shared leading component instead. See
  [08-modeling-traps.md](08-modeling-traps.md#trap-01--composite-bk-link-hk-collides-with-the-line-hub-hk).

## HASHDIFF

```sql
MD5_BINARY(UPPER(NULLIF(CONCAT(
      IFNULL(TRIM(data_col1::text), '^^')
    , '||', IFNULL(TRIM(data_col2::text), '^^')
    , '||', IFNULL(TRIM(data_col3::text), '^^')
), '^^||^^'))) AS HASHDIFF
```

| HASHDIFF **includes** | HASHDIFF **excludes** |
|-----------------------|------------------------|
| All payload/data columns | `*_HK`, `*_BK`, `BKCC`, `REC_SRC`, `LOAD_DTS` |
| `PSA_DELETE_IND` | `_FIVETRAN_ID`, `_FIVETRAN_SYNCED`, `_FIVETRAN_DELETED`* |
| `_FIVETRAN_DELETED` (data) | `PSA_LOAD_DTS`, `PSA_RECORD_SOURCE` |
| `GLDELFLAG` (data) | grain / multi-active key columns |
| | custom `LOAD_DTS` source column (if user-specified) |
| | `GLREQUEST`, `GLSOURCESYSTEM`, `GLCHANGETIME` |

\* `_FIVETRAN_DELETED` is **included** as *data* (it records deletion state), while
`_FIVETRAN_ID`/`_FIVETRAN_SYNCED` are *metadata* and excluded. Do not conflate them
(Lessons #4, #5, #28).

## Ghost records (three, FBIN)

Raw-vault hub/sat/link models emit **three** ghosts via `UNION ALL` inside
`{% if not is_incremental() %}` (full-refresh only):

| Value | Hub/Sat `BKCC` label | Link meaning |
|-------|----------------------|--------------|
| `0` | `GHOST RECORD-SYSTEM` | Unknown |
| `-1` | `GHOST RECORD-nullkey-required` | Not applicable |
| `-2` | `GHOST RECORD-nullkey-optional` | Error |

- Ghost HK: `MD5_BINARY(GR.VALUE)` for `0/-1/-2` (hub/sat); link ghost HK reuses the
  sentinel through the link-HK formula.
- Ghost `HASHDIFF`: `MD5_BINARY('')` (or `MD5_BINARY('GHOST')` in some sat variants — match
  the model's convention).
- Ghost `LOAD_DTS`: `'1900-01-01T00:00:00'::TIMESTAMP_NTZ`.
- Purpose: outer joins / PIT lookups never return NULL keys.

See [02-fbin-deviations.md](02-fbin-deviations.md#ghost-sentinel-semantics-differ-by-construct)
for the link-vs-sat semantic split (TRAP-05).

## `LOAD_DTS` derivation (ingestion-type-specific)

| Ingestion | Expression |
|-----------|-----------|
| Fivetran | `CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)` |
| SNP GLUE | `IFF(PSA_DELETE_IND='Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ(SUBSTR(GLCHANGETIME,1,14)||'.'||SUBSTR(GLCHANGETIME,16),'YYYYMMDDHH24MISS.FF9')))` |
| Other | `CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)` |

- NULL dates → `'1900-01-01'::TIMESTAMP`. Always UTC.
- Fivetran's `_FIVETRAN_SYNCED` gives a true per-record change time → resolves sat grain at
  `BK + LOAD_DTS`.

## `REC_SRC`

- Format: `Location.System.Application.Table` (e.g. `USOHNO.SAP.ECCPRD.Z_EKPO`).
- **Looked up** from `REF_BUSINESS_KEY_COLLISION` alongside BKCC (grain: one row per
  REC_SRC). Never hardcoded. **Never** part of any HK.

## BKCC (in one place)

- 1:1 with the **business concept**, not the source system.
- Looked up (never hardcoded), joined via `INNER JOIN SRC_BKCC ON '1' = '1'`.
- **Last** HK component; **never** in HASHDIFF; **never** concatenated into the BK.
- Registered in DEV (Streamlit) **before** `dbt build`. See
  [02-fbin-deviations.md](02-fbin-deviations.md).

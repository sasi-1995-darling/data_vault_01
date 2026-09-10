# HASHDIFF Exclusion Rules

## Definitive Exclusion List
HASHDIFF excludes **these and ONLY these**:

### Technical Metadata (exclude)
- `_FIVETRAN_ID` — Fivetran sync ID (metadata)
- `_FIVETRAN_SYNCED` — Fivetran sync timestamp (metadata)
- `PSA_LOAD_DTS` — PSA load timestamp
- `PSA_RECORD_SOURCE` — PSA record source

### Data Vault Metadata (exclude)
- `LOAD_DTS` — derived load timestamp
- `REC_SRC` — record source identifier
- `BKCC` — business key control column

### Keys (exclude)
- Any `_HK` column (hash keys)
- Any `_BK` column (business keys)
- The raw source columns that compose the BK

## Definitive Inclusion List
HASHDIFF **INCLUDES** these — they are DATA, not metadata:

- `PSA_DELETE_IND` — tracks soft delete state (business-relevant state change)
- `_FIVETRAN_DELETED` — tracks hard delete detection from Fivetran (business-relevant)
- All other data columns from the **primary/driver table**: dates, amounts, quantities, descriptions, statuses

### Why PSA_DELETE_IND and _FIVETRAN_DELETED are DATA
- `PSA_DELETE_IND` tracks whether a source record was soft-deleted — it IS business-relevant data (state change). It must be in HASHDIFF so satellites detect when a record is deleted/undeleted.
- `_FIVETRAN_DELETED` tracks when Fivetran detects a hard delete in the source system — same reasoning.
- **Common mistake**: Treating these as technical metadata and excluding them.

### Source-System Metadata (exclude)
SAP-specific system columns that are NOT business data:
- `MANDT` — SAP client number (technical routing)
- `GLREQUEST` — request ID
- `GLSOURCESYSTEM` — source system marker
- `GLDELFLAG` — deletion flag (SAP technical, not the same as PSA_DELETE_IND)
- `GLCHANGETIME` — change timestamp (SAP technical)

### Secondary/Lookup Table Columns
- Generally **NOT** included in HASHDIFF
- Only primary/driver table data columns go into HASHDIFF
- Lookup values are assumed stable (deduplicated via QUALIFY)

## Decision Flowchart
```
Is the column from the driver table?
├── No → EXCLUDE (lookup columns not in HASHDIFF)
└── Yes → Continue
    Is it an HK or BK column (or raw column composing a BK)?
    ├── Yes → EXCLUDE
    └── No → Continue
        Is it PSA_DELETE_IND or _FIVETRAN_DELETED?
        ├── Yes → INCLUDE (these are data columns)
        └── No → Continue
            Is it technical metadata (_FIVETRAN_ID, _FIVETRAN_SYNCED, PSA_LOAD_DTS, PSA_RECORD_SOURCE)?
            ├── Yes → EXCLUDE
            └── No → Continue
                Is it DV metadata (LOAD_DTS, REC_SRC, BKCC)?
                ├── Yes → EXCLUDE
                └── No → INCLUDE in HASHDIFF
```

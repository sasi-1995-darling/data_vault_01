# BKCC Reference

## Overview
BKCC (Business Key Control Column) prevents key collisions when multiple source systems contribute to the same Data Vault hub. BKCC is appended to every hash key computation.

## Table: REF_BUSINESS_KEY_COLLISION
- Location: `DATAVAULT_<ENV>.RAW_VAULT.REF_BUSINESS_KEY_COLLISION`
- Columns: `REC_SRC` (PK), `REC_SRC_DESC`, `BKCC`, `DEACTIVATED_IND`, `DEACTIVATED_DATE`, `LOAD_DATE`

## BKCC Value Format
- Format: `<Present_Participle_Verb>_<Noun>` (title case, underscore-separated)
- Same BKCC shared across all tables within the same OpCo
- Examples: `Hiding_Tiger`, `Crouching_Dragon`, `Swimming_Ocean`

## OpCo-to-BKCC Mapping (Key Entries)
| BKCC | OpCo / Source | Tables |
|------|---------------|--------|
| `Hiding_Tiger` | Moen/WINN (SAP ECC) | 160+ |
| `Crouching_Dragon` | Master Lock (ML EBS) | 30+ |
| `Swimming_Ocean` | Larson (PeopleSoft) | 24+ |
| `Kicking_Panda` | ThermaTru (E21 + GP) | 22+ |
| `Jumping_River` | Fiberon (OCF) | 18+ |
| `Diving_Sea` | Emtek (EBS) | 7 |
| `Leaking_Water` | Flo/Smart Water (IoT) | 25+ |
| `Grouping_Brand` | Profitero (all 6 brands) | 60+ |
| `Laughing_Hyena` | Lowes VPP (POS) | 11 |
| `Running_Horse` | Amazon VC | 16 |
| `Talking_Tom` | Home Depot (Askuity) | 8 |

## Registration Workflow (CRITICAL)
1. **Construct REC_SRC** following naming conventions (see below)
2. **Look up OpCo's existing BKCC** — reuse if OpCo already has one
3. **Register REC_SRC + BKCC pair** via Streamlit app in DEV only
4. App checks uniqueness across DEV, QA, PROD before insert
5. Promotion: DEV → QA → PROD via CI/CD (GitHub Actions)
6. **Snowflake MCP is read-only** — cannot INSERT via MCP, must use Streamlit

## REC_SRC Naming Conventions

### Convention 1: On-Premise
Format: `LOCATION.SYSTEM.APPLICATION.TABLE`
- Location: `USOHNO`, `USWIOC`, `USSDBR`, `USOHMA`, `USCLOUD`, `CAONTO`, `FBIN`
- System: `SAP`, `ORCL`, `MSSQL`, `SNFL`, `INFORMATICA`
- Application: `ECCPRD`, `EBSPRD`, `EBSEMTK`, `PSFTPRD`, `E21PRD`, `GPPRD`, `OCFPRD`
- Table: Source table name (e.g., `Z_T001`, `PS_VENDOR`)

Examples:
- `USOHNO.SAP.ECCPRD.Z_EKPO` (SAP PO Item)
- `USWIOC.ORCL.EBSPRD.PO_HEADERS_ALL` (Oracle EBS PO Header)
- `USSDBR.ORCL.PSFTPRD.PS_VENDOR` (PeopleSoft Vendor)

### Convention 2: Cloud/SaaS
Format: `COUNTRY.SERVICE.OBJECT`
- Country: `US`, `FBIN`
- Service: `API`, `API_FT`, `CSV`, `PROFITERO_<BRAND>`, `FLO_DYNAMODB`, `APPBOT`, etc.

Examples:
- `US.PROFITERO_WINN.PRODUCTS` (Profitero Winn)
- `US.FLO_DYNAMODB.INCIDENTS` (Flo IoT)
- `US.API.AMAZON_VC.SALES_BY_ASIN` (Amazon Vendor Central)

## Multi-Concept Pattern
BKCC is 1:1 with **business concept**, NOT source system:
1. Same concept, same source → standard single BKCC
2. Same concept, two sources → same BKCC (traces to originating system)
3. Different concepts, same source → different BKCCs per concept

**Anti-pattern**: Never override BKCC in staging SQL code. Register correctly in the table instead.

## How to Verify BKCC Exists
```sql
SELECT BKCC, REC_SRC
FROM DATAVAULT_DEV.RAW_VAULT.REF_BUSINESS_KEY_COLLISION
WHERE REC_SRC = '<your_rec_src_value>'
  AND DEACTIVATED_IND = 'N';
```
If empty result → BKCC not registered → STOP and tell user.

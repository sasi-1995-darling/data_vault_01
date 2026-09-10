# FBIN Deviations from Generic DV 2.1 Doctrine

> **The most important file in this KB.** Generic Data Vault advice that is *canon-correct
> but repo-wrong* is the #1 way an advisor misleads FBIN engineers. When [doctrine](01-doctrine-dv21.md)
> and this file conflict **inside this repo, FBIN wins.** Every row below is traceable to a
> rule file, an Approved lesson, or a real model.

## Master reconciliation table

| # | Topic | Generic DV 2.1 | FBIN actual | Source |
|---|-------|----------------|-------------|--------|
| 1 | Hash function | SHA1 | **`MD5_BINARY`** | `.claude/rules/02` |
| 2 | Hash storage | `BINARY(20)` | **`BINARY(16)`** (MD5) | `.claude/rules/02` |
| 3 | Hub/link/sat load | Insert-only; hub/link `MERGE` + `last_seen_date` | **dbt `incremental`, `delete+insert`** (MERGE prohibited) | `dv21_knowledge_bank` §15, `rules/02` |
| 4 | Column naming | `dv_hashkey_hub_*`, `dv_load_timestamp` | **UPPERCASE** `<ENTITY>_HK`, `LOAD_DTS`, `REC_SRC`, `BKCC`, `HASHDIFF` | `rules/02` |
| 5 | Table naming | `HUB_*`, `SAT_RV_*` | **lowercase** `hub_*`, `sat_*__<source>` | `CLAUDE.md` |
| 6 | In-hash NULL sentinel | `''` (empty string) | **`'^^'`** via `COALESCE(NULLIF(TRIM(...),''),'^^')` | `references/hash-key-formulas.md` |
| 7 | Ghost keys | one zero-key ghost (`-1`/`-2` for null BK) | **three** ghosts: `0`, `-1`, `-2` (via `UNION ALL` in `{% if not is_incremental() %}`) | `rules/02`, sat/link instructions |
| 8 | Ghost sentinel meaning | uniform | **context-dependent** (see [table below](#ghost-sentinel-semantics-differ-by-construct)) | link vs sat instructions |
| 9 | MSAT `NOT EXISTS` | HK + multi-active key only (no HASHDIFF) | **HK + multi-active key + HASHDIFF** | `rules/02` (explicit deviation note) |
| 10 | Effectivity open record | `EFFECTIVE_END = NULL` | **`end_date = '9999-12-31'`** (`CONVERT_TIMEZONE('UTC', …)`) | `macros/load_esat.sql` |
| 11 | Satellite grain PK | `(parent_HK, LOAD_DTS)` | same — but grain tests must contain **ONLY** `*_HK` + `LOAD_DTS` (+ dep-child keys). No HASHDIFF in PK | Lesson H10, `dv-code-reviewer` |
| 12 | Source reference | `{{ source() }}` on landing tables | **`{{ ref('v_psa_stg_…') }}`** — RV reads staging *views*, not raw sources | `rules/02`, Category I |
| 13 | Staging null-BK fix location | staging | staging (same) — but FBIN also carries `PSA_DELETE_IND`/`_FIVETRAN_DELETED` as **data in HASHDIFF**, never filtered | Lesson #28 |
| 14 | REC_SRC format | `Geo.System.App.Module` dot-notation | **`Location.System.Application.Table`** e.g. `USOHNO.SAP.ECCPRD.Z_EKPO` | `rules/02` |
| 15 | BKCC source | value chosen at modeling time | **looked up** from `REF_BUSINESS_KEY_COLLISION` (grain = one row per REC_SRC); never hardcoded | `rules/02`, Category D |
| 16 | Dependent child / degenerate | dep-child in SAT PK | FBIN links carry **degenerate attributes** (e.g. `PO_LINE_NUMBER`) insert-only, no HASHDIFF | link instructions |
| 17 | CTE structure | n/a (platform-specific) | **4-layer `SRC → LOGIC → JOIN → FINAL`** for new models; legacy 6-layer left as-is | `copilot-instructions`, Lesson #8 |
| 18 | Dedup | `SELECT DISTINCT` acceptable | **`QUALIFY ROW_NUMBER()`** only — `DISTINCT` prohibited | Lesson #11 |

## Ghost sentinel semantics differ by construct

FBIN reuses the values `0 / -1 / -2` but they **mean different things** for links vs
hubs/satellites. Do not conflate them.

| Value | Hub / Satellite meaning | Link meaning |
|-------|-------------------------|--------------|
| `0` | `GHOST RECORD-SYSTEM` | Unknown |
| `-1` | `nullkey-required` (a required BK was NULL) | Not applicable |
| `-2` | `nullkey-optional` (an optional BK was NULL) | Error |

- Hub/sat ghost `BKCC`: `DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')`
- Link non-applicable hub reference uses ghost key **`-2`** (error sentinel) via
  `MD5_BINARY(UPPER(CONCAT_WS('||', COALESCE(NULLIF(TRIM(CAST('-2' AS VARCHAR)),''),'^^'))))`.

Source: `.github/instructions/raw-vault-link.instructions.md` (0=unknown/-1=N-A/-2=error)
vs `.claude/rules/02` (0=SYSTEM/-1=required/-2=optional).

## FBIN-only constructs the generic literature does not name

| FBIN prefix | What it is | Note |
|-------------|-----------|------|
| `lsat_` | **Link satellite** — descriptive attributes on a link | Standard DV concept, FBIN-named |
| `msat_` | **Multi-active satellite** — deviation #9 applies | |
| `esat_` | **Effectivity satellite** — driving key, `end_date '9999-12-31'` (deviation #10) | `macros/load_esat.sql` |
| `lmsat_` | **Link multi-active satellite** — multi-active attrs *on a link* | Combined variant; many exist (e.g. `lmsat_price_availability__*`) |
| `tlink_` | **Transactional (non-historized) link** — carries transaction payload directly | e.g. `tlink_invoice_line_transaction`; a `sat_*_detail` may still hang off it |
| `pit_` / `pb_` | PIT table / **PIT Bridge** | `pb_` is **PIT Bridge**, NOT "business satellite" (Lesson #6) |

## `LOAD_DTS` derivation is ingestion-type-specific (FBIN)

Generic doctrine says "system insert time." FBIN **derives** `LOAD_DTS` from the source's
change signal so satellite grain resolves correctly:

| Ingestion | `LOAD_DTS` expression |
|-----------|-----------------------|
| Fivetran | `CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)` |
| SNP GLUE | `IFF(PSA_DELETE_IND='Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ(SUBSTR(GLCHANGETIME,1,14)||'.'||SUBSTR(GLCHANGETIME,16),'YYYYMMDDHH24MISS.FF9')))` |
| Other / custom | `CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)` |

NULL dates → `'1900-01-01'::TIMESTAMP`. Always UTC.

## Testing deviates by layer (FBIN)

| Layer | FBIN test rule |
|-------|----------------|
| `v_psa_stg` | `not_null` on BK + `unique_combination_of_columns` on **BK + LOAD_DTS**. **No standalone `unique` on BK** (PSA is append-only — Lesson #26). Use `data_tests:` |
| Raw vault | `dbt_constraints.primary_key` + `foreign_key` (required, presence-only H11) + row count ≥ 4 |
| BV tables (PIT/PB/REF) | PK constraints + metrics tests |
| DIM/FACT views | **QA team owns singular tests** — do NOT add YAML tests |
| `rep_` | No tests |

## The one-line summary for the advisor

> Give **DV 2.1 reasoning**, but **FBIN mechanics**: MD5/BINARY(16), UPPERCASE columns,
> lowercase tables, `^^` in-hash sentinel, 0/-1/-2 ghosts, BKCC-last-and-looked-up,
> `ref()` on staging views, 4-layer CTE, `QUALIFY` not `DISTINCT`, and MSAT `NOT EXISTS`
> that includes HASHDIFF.

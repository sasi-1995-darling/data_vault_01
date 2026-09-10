# Satellite Variants — Choosing the Flavor

> **Priority topic** (top pain point). Once you know a source element is a *satellite*
> ([03](03-construct-selection.md)), pick the right flavor. The wrong flavor produces
> silent data loss (missed active rows) or HASHDIFF churn.

## Variant decision guide

```
Does the satellite describe a HUB or a LINK?
├── LINK → is it multi-active on the link?
│          ├── YES → lmsat_  (link multi-active satellite)
│          └── NO  → lsat_   (standard link satellite)
│                    └── tracks the link's OPEN/CLOSE lifecycle (driving key)? → esat_
└── HUB → can MULTIPLE rows be active for one parent at the same time?
          ├── YES (e.g. many phones, many emails) → msat_  (multi-active)
          └── NO → is the payload an immutable event with measures?
                   ├── YES → not a sat — use a transactional link (tlink_)
                   └── NO  → sat_  (standard satellite)
```

## The variants (doctrine → FBIN)

| Variant | Use when | FBIN prefix | Grain PK | HASHDIFF? |
|---------|----------|-------------|----------|-----------|
| **Standard** | Default; one active row per parent; history via delta | `sat_` | `(HK, LOAD_DTS)` | Yes |
| **Link satellite** | Descriptive attrs of a *relationship* | `lsat_` | `(LNK_HK, LOAD_DTS)` | Yes |
| **Multi-active (MAS)** | Several rows active simultaneously per parent | `msat_` | `(HK, <sub-key>, LOAD_DTS)` | Yes* |
| **Link multi-active** | Multi-active attrs on a link | `lmsat_` | `(LNK_HK, <sub-key>, LOAD_DTS)` | Yes* |
| **Effectivity** | Track a driving-key relationship's open/close; **no payload** | `esat_` | `(LNK_HK, LOAD_DTS)` | (start/end only) |
| **Non-historized** | Immutable event/reference; payload folded into a `tlink_` | `tlink_` | link grain | No |

\* **FBIN MSAT deviation**: the `NOT EXISTS` incremental guard checks **HK + multi-active
key + HASHDIFF** (generic DV 2.1 checks HK + multi-active key only). This prevents duplicate
rows when the same multi-active key re-arrives with identical data. *(Source:
[02-fbin-deviations.md](02-fbin-deviations.md), `.claude/rules/02`.)*

## Standard satellite (`sat_`)

- The default. Delta-driven: a new row is inserted only when `HASHDIFF` differs from the
  latest row for that parent HK.
- **One source per satellite** (`sat_<entity>__<source>`). Different `REC_SRC` = different
  satellite.
- Incremental guard: `NOT EXISTS` on **parent HK + HASHDIFF** — never grain columns, never
  `LOAD_DTS`. *(`.github/instructions/raw-vault-sat.instructions.md`)*

## Multi-active satellite (`msat_` / `lmsat_`)

Use when a **set** of rows is simultaneously true for one parent (phone numbers, contacts,
price points per marketplace). The multi-active sub-key (e.g. `PHONE_TYPE`, `MARKETPLACE`)
is part of the PK.

- Do **not** reach for MAS just because a child table repeats — first ask whether it is a
  **dependent child** (→ line-as-hub or link) per [04](04-grain-and-bk-selection.md#dependent-children).
- FBIN examples: `msat_po_action__emtk_ebs`, `lmsat_price_availability__winn_profitero_share`.
- Remember the FBIN HASHDIFF-in-`NOT EXISTS` deviation above.

## Effectivity satellite (`esat_`)

Tracks the **lifecycle of a driving-key relationship** — which link is currently "in
effect" for a given driving key — and holds **no descriptive payload** (payload belongs in
standard satellites).

FBIN specifics (`macros/load_esat.sql`):
- Parameters: `linkpk`, driving key `hkdk`, non-driving FKs `hkfk`, staging table.
- The **open** record is marked `end_date = CONVERT_TIMEZONE('UTC', '9999-12-31')::TIMESTAMP_TZ(9)`
  — **not** NULL (deviation #10 in [02](02-fbin-deviations.md)).
- A change is detected when the driving key exists in both target and stage but the stage
  FKs differ → a new version is inserted and the prior record is end-dated (via the macro's
  insert logic).
- Use for relationships where "the current partner can change" (e.g. an item's current
  primary vendor, a account's current sales rep).

## Status & record-tracking (modeled as `sat_` variants)

- **Status tracking** — a status/state column tracked over time. FBIN models this as a
  standard satellite whose payload is the status column(s).
- **Record tracking** — presence/absence of a record in the source. Model as a thin
  satellite carrying the delete indicator (`PSA_DELETE_IND` / `_FIVETRAN_DELETED`), which are
  **data in HASHDIFF**, never filtered out (Lesson #28).

## Non-historized / transactional (`tlink_`)

When the "satellite" describes an **immutable event** (an order line, a ledger posting), do
not build a separate satellite — carry the measures **on a transactional link** (`tlink_`).
A `sat_*_detail` may still hang off the `tlink_` for slowly-changing descriptive columns
(e.g. `sat_invoice_line_tran_detail__emtk_ebs` off `tlink_invoice_line_transaction`).

## The single-parent rule (applies to every variant)

Every column in a satellite must be attributable to the **same** parent HK. If a column
describes a *different* concept, you need a different satellite — or your parent is wrong.
Never snowflake (SAT-to-SAT), never span two parents.

## Quick self-check

1. Hub or link parent? (drives `sat_`/`msat_` vs `lsat_`/`lmsat_`/`esat_`)
2. Can multiple rows be active at once? → multi-active, and remember the HASHDIFF-in-guard
   deviation.
3. Is this really a dependent child or an immutable event? → not a MAS.
4. One source per satellite? Single parent for every column?

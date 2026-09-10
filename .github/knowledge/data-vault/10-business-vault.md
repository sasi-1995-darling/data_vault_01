# Business Vault & Information Mart — Where Logic Lives

> The layer-separation rules that stop business logic from leaking into the wrong place.
> Enforced by `.github/instructions/bus-vault.instructions.md` and
> `.github/instructions/info-mart.instructions.md`.

## The three-layer contract

| Layer | Allowed | Forbidden |
|-------|---------|-----------|
| **Raw Vault** (hub/link/sat) | Passive integration: hash + land, 100% data | Any interpretation, filtering, calculation |
| **Business Vault** (`pit_`, `pb_`, `ref_`, flat_logic) | Soft rules, derived attrs, multi-source assembly, N-way matches, calculations | Source-faithful loss (that's RV's job) |
| **Information Mart** (`dim_`, `fact_`, `rpt_`/`rep_`/`im_`) | Business-friendly names, survivorship, filtering for BI | **Any** business logic; exposing hash keys |

## PIT (`pit_`) and PIT Bridge (`pb_`)

- **PIT** = point-in-time snapshot across a hub + its satellites (latest version per
  `PARTITION BY <HK> ORDER BY LOAD_DTS DESC`). Standard columns: `PIT_REC_SRC`,
  `SNAPSHOTDATE`, `PIT_LOAD_DTS`; hub columns pass through.
- **PIT Bridge (`pb_`)** = joins multiple links/hubs for a transactional fact grain. **All**
  business logic (amounts, calculations, status derivation, N-way matches) lives here.
  `pb_` means **PIT Bridge**, *not* "business satellite" (Lesson #6).
- When multiple satellites join, prefix ambiguous columns `SAT_<source>_<column>` (e.g.
  `SAT_WINN_PSA_DELETE_IND`).

## When to add a PIT / Bridge

- A hub with **3+ satellites** that are frequently queried together → PIT (query-performance
  materialization; doctrine WARN-04 in DVOS terms).
- A relationship/fact spanning **multiple links/hubs** → Bridge.
- These are **performance + assembly** structures — they do not change grain semantics, they
  pre-join for consumers.

## Multi-way matches assemble here (not in raw links)

The 3-way PO↔GR↔invoice match, survivorship across same-as links, and any "these keys don't
always co-occur" assembly happen in **PIT/Bridge**, consuming the pairwise raw links. This is
the correct home for the logic that [07-link-modeling.md](07-link-modeling.md) tells you to
keep **out** of the Raw Vault.

## DIM / FACT views — 1:1 wrappers only

- `dim_` is 1:1 on a `pit_`; `fact_` is 1:1 on a `pb_`. **Select + alias only.**
- **No** `CASE WHEN`, **no** `WHERE`, **no** `JOIN`, **no** calculations. If you need any of
  those, the logic belongs in the PIT/PB. *(TRAP-10.)*
- Materialized as `view`.
- **Hash keys are never exposed** in the mart — business keys and descriptive attributes
  only.
- **Testing**: the QA team owns singular tests for DIM/FACT — do **not** add YAML schema
  tests (would duplicate).

## Derived / calculated attributes

A calculated attribute (credit score, lifetime value) is loaded into a **standard satellite**
whose "source" is the calculation, then consumed like any other satellite. No special layer
is required — the calc is just another source. *(DVOS principle #7.)*

## Reference data (`ref_`)

- Static / slowly-changing reference tables, materialized as `table`, PK constraint required.
- The BKCC source of truth `ref_business_key_collision.sql` is the one model that
  legitimately reads `source()` (TRAP-11 exemption).

## Quick self-check

1. Is every calculation/filter in PIT/PB (not in DIM/FACT)?
2. Are DIM/FACT strictly select+alias, no hash keys exposed?
3. Are multi-way matches assembled in the BV, consuming pairwise raw links?
4. Did you avoid adding YAML tests to DIM/FACT (QA owns those)?

# Modeling Traps Catalog

> Real, production-grade failures that **pass `code_reviewer.py` syntax checks** but corrupt
> data or silently break joins. Each entry: **symptom → root cause → fix**. When a new trap
> is found in production, add it here.

---

## TRAP-01 — Composite-BK link HK collides with the line hub HK

- **Symptom**: A header↔line link "works" but rows join to the wrong parent, or PK/uniqueness
  behaves impossibly. Two logically distinct objects share a hash key.
- **Root cause**: FBIN hashes each **raw column** separately with `CONCAT_WS('||', …)`.
  Because `CONCAT_WS('||','A||B','C')` == `CONCAT_WS('||','A','B','C')` == `'A||B||C'`, a link
  HK built from `(INVOICE_ID, LINE_NUMBER, BKCC)` hashes **byte-identical** to a line hub HK
  built from the composite BK `(INVOICE_ID|LINE_NUMBER, BKCC)`.
- **Fix (preferred, post-#1907)**: compose the link HK from the participating **hub HK
  values**, not raw columns — `MD5_BINARY(UPPER(CONCAT_WS('||', TO_VARCHAR(INVOICE_LINE_HK),
  TO_VARCHAR(INVOICE_HK))))`. Hub HK values are distinct 32-char hashes with **no raw
  components**, so a link HK cannot byte-collide with a composite-BK hub HK — the trap is
  eliminated structurally (and `Q1` returns clean: no raw component list to compare). This
  is the platform default — the auto multi-table path and `--hk "LNK_X_HK:@HUB1_HK,@HUB2_HK"`
  both render `HASH_FROM_HKS`.
- **Legacy raw-column workaround** (only when a link HK must still hash raw BKs — existing
  models before regeneration): build the link HK from the **full component business keys**,
  duplicating the shared leading component: `(INVOICE_ID, INVOICE_ID, LINE_NUMBER, BKCC)` →
  `'A||A||B||C'`. The duplicated `INVOICE_ID` is **intentional**; add a config comment.
  **Never "clean up" the duplicate.**
- **Provenance**: memory `supplier-ap-invoice-modeling`; PR #1908 composite-BK path.
- **Detectable?** Yes — implemented as `Q1` (`check_link_hk_component_collision`, WARN):
  flags two distinct HKs in one staging model with identical component lists (matches the
  `'^^'`, `'-1'`, and `'-2'` null-fallback sentinels). `Q1` is a **syntactic subset** — it
  compares component lists **within a single staging model** only. Where the DV Knowledge
  Advisor and `Q1` disagree on a collision, the advisor's **cross-model reasoning is
  authoritative**.

---

## TRAP-02 — Cross-domain foreign HK built with the wrong BKCC

- **Symptom**: A cross-domain link (e.g. invoice → PO) is empty or drops most rows; the FK
  test "passes" only because ghosts absorb the misses.
- **Root cause**: The foreign hub HK was recomputed using the **local model's BKCC** instead
  of the **foreign hub's owning BKCC**. Links carry no BKCC; each component HK must embed its
  *own* hub's BKCC. A mismatched BKCC → a different hash → never matches the real hub HK.
- **Fix**: Reproduce the **owning hub's exact HK expression** (same raw columns, same order,
  same BKCC) for every foreign component. Confirm the source-system/BKCC split per opco first.
- **Provenance**: memory `supplier-ap-invoice-modeling`.
- **Detectable?** Partially — WARN when a staging model computes a `*_HK` for a hub it does
  not own using the local BKCC.

---

## TRAP-03 — Collapsed wide UoW link across keys that don't co-occur

- **Symptom**: Freight/tax/misc lines vanish or orphan; row counts don't reconcile to source.
- **Root cause**: A single wide link (`PO↔GR↔invoice`) assumes all keys are present together.
  In AP they are not — PO-flip without GR, GR not yet invoiced. Rows lacking a participant are
  dropped or forced onto a ghost.
- **Fix**: Model pairwise links separately (`lnk_po_invoice_line`, `lnk_gr_invoice_line`) and
  assemble the multi-way match in the **Business Vault** (PIT/bridge). Apply the
  **co-occurrence test** ([07-link-modeling.md](07-link-modeling.md#the-co-occurrence-test-wide-uow-vs-separate-links)).
- **Provenance**: memory `supplier-ap-invoice-modeling`.

---

## TRAP-04 — Mutable / non-conformable natural key as a hub BK

- **Symptom**: History "moves" when a user edits a document number; the same entity appears
  under two keys; two sources' keys never integrate.
- **Root cause**: A user-editable (`INVOICE_NUM`), smart, or source-specific value was chosen
  as the hub BK. Hub BKs must be immutable and conformable.
- **Fix**: Use a **surrogate BK** from the source's immutable system ID (`INVOICE_ID`); let
  **BKCC + REC_SRC** namespace it. Run the five disqualifiers in
  [04-grain-and-bk-selection.md](04-grain-and-bk-selection.md#the-disqualifiers-a-candidate-bk-fails-if-any-are-true).
- **Provenance**: memory `supplier-ap-invoice-modeling` (RESOLVED 2026-07-19).

---

## TRAP-05 — Ghost sentinel meaning conflated between links and sats

- **Symptom**: A link's "not applicable" case is labeled `nullkey-required`, or a hub ghost
  is treated as "error", producing misleading BKCC labels in outer joins.
- **Root cause**: `0 / -1 / -2` mean **different things** for links vs hubs/sats:
  - Hub/sat: `0`=SYSTEM, `-1`=nullkey-required, `-2`=nullkey-optional.
  - Link: `0`=unknown, `-1`=not applicable, `-2`=error.
- **Fix**: Use the construct-appropriate semantics and `DECODE` label. See
  [02-fbin-deviations.md](02-fbin-deviations.md#ghost-sentinel-semantics-differ-by-construct).

---

## TRAP-06 — HASHDIFF includes structural columns (or excludes real data)

- **Symptom**: Every load inserts a "changed" row (churn), or true changes are missed.
- **Root cause**: HASHDIFF wrongly **includes** HK/BK/BKCC/REC_SRC/LOAD_DTS/grain columns or
  Fivetran metadata; or wrongly **excludes** `PSA_DELETE_IND` / `_FIVETRAN_DELETED` /
  `GLDELFLAG` (which are **data**).
- **Fix**: HASHDIFF **includes** payload + delete indicators; **excludes** HK, BK, BKCC,
  REC_SRC, LOAD_DTS, `_FIVETRAN_ID`, `_FIVETRAN_SYNCED`, `PSA_LOAD_DTS`, grain/multi-active
  keys, custom `LOAD_DTS` source, `GLREQUEST`, `GLSOURCESYSTEM`, `GLCHANGETIME`. See
  [09-hashing-and-ghosts.md](09-hashing-and-ghosts.md).
- **Provenance**: Lessons #4, #5, #28.

---

## TRAP-07 — HASHDIFF (or grain test) placed in the satellite PK

- **Symptom**: True duplicates are silently masked; the grain test passes but the sat has
  dupes at `(HK, LOAD_DTS)`.
- **Root cause**: `HASHDIFF` (or `REC_SRC`/`BKCC`/metadata) added to the `primary_key` /
  `unique_combination_of_columns` list. A different HASHDIFF makes duplicate business rows
  look unique.
- **Fix**: Grain test lists **only** `*_HK` + `LOAD_DTS` (+ dependent-child keys). `LOAD_DTS`
  is **required** — the canonical sat grain is `(parent_HK, LOAD_DTS)`. *(Lesson H10.)*

---

## TRAP-08 — Filtering delete flags at the staging layer

- **Symptom**: Deleted records disappear from the vault; deletion history is unrecoverable;
  counts drift from source.
- **Root cause**: `WHERE _FIVETRAN_DELETED = false` or `WHERE PSA_DELETE_IND = 'Y'` at
  staging. These are **data attributes** tracked in HASHDIFF so satellites record deletion
  state — filtering them breaks the 100% data rule.
- **Fix**: Never filter on soft-delete flags at staging. The only valid staging `WHERE` is a
  **confirmed** system dummy/placeholder row (e.g. `TERM_ID = 0` proven meaningless by
  profiling). *(Lesson #28.)*

---

## TRAP-09 — Multi-active satellite missing the HASHDIFF guard (FBIN)

- **Symptom**: Re-arriving multi-active rows with identical data insert duplicate versions.
- **Root cause**: Applying the *generic* DV 2.1 MAS rule (`NOT EXISTS` on HK + multi-active
  key only). FBIN requires **HK + multi-active key + HASHDIFF**.
- **Fix**: Include HASHDIFF in the MSAT `NOT EXISTS`. See
  [02-fbin-deviations.md](02-fbin-deviations.md#master-reconciliation-table) (row 9).

---

## TRAP-10 — Business logic leaking into DIM/FACT views

- **Symptom**: `CASE WHEN` / `WHERE status='Active'` / joins inside a `dim_`/`fact_` view;
  logic diverges between reports.
- **Root cause**: Skipping the PIT/PB layer. DIM/FACT must be 1:1 wrappers (select + alias).
- **Fix**: Put **all** logic in PIT/PB; make DIM/FACT column selection + aliasing only. See
  [10-business-vault.md](10-business-vault.md).

---

## TRAP-11 — Reference-source (`source()`) used inside the raw vault

- **Symptom**: Category I / layer-direction review failure; RV coupled to landing tables.
- **Root cause**: A raw-vault model reads `{{ source() }}` directly instead of the staging
  view. RV must read `{{ ref('v_psa_stg_…') }}`.
- **Fix**: Route through the staging view. The only code-level exception is
  `ref_business_key_collision.sql` (the BKCC source of truth), which legitimately uses
  `source()`. *(rules/02, Category I.)*

---

## How the advisor uses this catalog

When reviewing a design, walk the relevant traps and report **symptom + why-it-applies +
fix**, citing the file. **Never auto-fix** — present the finding and let the user decide.

Deterministic enforcement status: TRAP-06 (Category B — B4/B5/B6), TRAP-07 (H10), TRAP-09
(the sat `NOT EXISTS` HASHDIFF guard, J1), TRAP-10 (I3), and TRAP-11 (I2/I4) are **already
enforced** by `code_reviewer.py`. TRAP-01 is enforced by `Q1`, but only as a **syntactic
subset** (single-model component comparison). TRAP-02 needs **cross-model** context and
stays with the DV Knowledge Advisor, not static analysis. Where the advisor and Category Q
disagree, the advisor is authoritative.

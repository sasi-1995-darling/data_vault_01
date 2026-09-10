# Grain & Business-Key Selection

> **Priority topic** (top pain point). The grain and the business key are the two decisions
> that, once wrong, are the most expensive to reverse — every HK, every satellite, every
> link inherits them. Pair with [03-construct-selection.md](03-construct-selection.md).

## What "grain" means here

The **grain** of a construct is the level of detail at which one row = one thing:

- **Hub grain** = one row per **business key value** (per BKCC).
- **Link grain** = one row per **unique combination of participating hub keys** (per UoW).
- **Satellite grain** = one row per **`(parent_HK, LOAD_DTS)`** — one version per change.

State the grain in one sentence before modeling. If you cannot, you are not ready to model.

## Choosing the business key (BK)

A good business key is **stable, business-recognized, and unique within its BKCC**.

### The disqualifiers (a candidate BK fails if ANY are true)

| Disqualifier | Why it fails | What to do |
|--------------|--------------|-----------|
| **Mutable** (users can edit it) | A hub BK must never change; editing it re-keys history | Use a surrogate/immutable ID |
| **Not conformable across sources** | If two systems can't agree the key means the same entity, it can't integrate | Per-source BK + BKCC, or a surrogate |
| **Requires a column a source lacks** | Composite natural key needs a field one system doesn't have | Surrogate, or narrow the scope |
| **Reused / recycled** | Same value points at different entities over time | Add a discriminator or use surrogate |
| **Smart key** (encodes attributes) | Attributes change → key churns | Store the encoding as payload, key on the ID |

> **Worked disqualification** *(memory: supplier-ap-invoice; RESOLVED 2026-07-19)*: for
> `hub_supplier_invoice` the natural key was rejected because **(a)** `INVOICE_NUM` is
> user-correctable (mutable → disqualifying); **(b)** the natural key needs `ORG_ID` which
> SAP lacks (no cross-system conformance); **(c)** an Oracle AP invoice is *never* the same
> document as a SAP one (no cross-system identity to conform); **(d)** BKCC/REC_SRC already
> carry the namespace. → **surrogate `INVOICE_ID`** as the header BK. The line BK **extends**
> it: `INVOICE_ID | LINE_NUMBER`.

### Natural vs surrogate — decision

```
Is there a stable, immutable, business-recognized identifier that all
in-scope sources share (or can be conformed to)?
├── YES → NATURAL business key
└── NO  → SURROGATE business key from the source's own immutable ID
          + rely on BKCC + REC_SRC to namespace it
          (do NOT invent a hash-of-attributes as a "key")
```

A surrogate BK is still a **real source column** (an immutable system ID like
`INVOICE_ID`), not a fabricated value. FBIN never mints new keys in staging.

## Composite business keys

When the grain requires multiple columns (e.g. `PO_HEADER_ID + LINE_NUM`), the BK is the
**ordered set** of those columns, and the HK hashes each raw column separately with BKCC
last (see [09-hashing-and-ghosts.md](09-hashing-and-ghosts.md)).

> **Critical hashing trap — composite BK link HK collision.** Under FBIN's raw-column HK
> convention, `CONCAT_WS('||', 'A||B', 'C')` == `CONCAT_WS('||', 'A', 'B', 'C')` == `'A||B||C'`.
> So a naive header↔line link HK built from `(INVOICE_ID, LINE_NUMBER, BKCC)` hashes
> **byte-identical** to the line hub HK built from `(INVOICE_ID|LINE_NUMBER, BKCC)`. Two
> different objects, same HK → silent join corruption.
> **Fix (preferred, post-#1907)**: compose the link HK from the participating **hub HK
> values** (`TO_VARCHAR(INVOICE_LINE_HK), TO_VARCHAR(INVOICE_HK)`), not raw columns — hub-HK
> values share no raw components, so the collision cannot occur. The **legacy raw-column
> workaround** (existing models pre-regeneration) duplicates the shared leading component:
> `(INVOICE_ID, INVOICE_ID, LINE_NUMBER, BKCC)` → `'A||A||B||C'`; the duplicated `INVOICE_ID`
> is **intentional**, never "clean it up". *(memory: supplier-ap-invoice; PR #1908, #1907.
> Full detail in [08-modeling-traps.md](08-modeling-traps.md).)*

## Dependent children

A **dependent child** is a component that cannot stand alone — it is meaningful only within
its parent (e.g. an invoice *line number* means nothing without its invoice).

Three valid patterns (pick per grain, not by habit):

1. **Line-as-hub (composite BK)** — `hub_<entity>_line` with BK = `parent_id | line_number`.
   Use when the line is referenced by its own relationships/attributes (FBIN "Pattern A" for
   supplier invoice lines).
2. **Degenerate attribute on a link** — the line number rides on the link, insert-only, no
   HASHDIFF. Use when the line only exists to disambiguate a relationship.
3. **SAT PK promotion** — the dependent key becomes part of the satellite PK (multi-active
   style). Use for repeating groups that are not independently referenced.

> A dependent child is **not** the same as a multi-active satellite — different problems,
> different patterns. See [05-satellite-variants.md](05-satellite-variants.md).

## Header vs line (transaction documents)

Most transaction documents (PO, invoice, sales order) need **two** hubs:

- `hub_<doc>_header` — BK = the document id (surrogate if the natural key is mutable).
- `hub_<doc>_line` — BK = `header_id | line_number` (composite, dependent child).

…joined by a **header↔line link** (mind the collision trap above), with foreign-match links
(PO-match, GR-match) hanging **off the line**, and the multi-way match assembled in the
**Business Vault**. *(FBIN "Pattern A", locked for supplier invoice.)*

## BKCC's role in the grain

BKCC makes the *same* natural key from *different* business contexts distinct. It is **1:1
with the business concept**, looked up from `REF_BUSINESS_KEY_COLLISION` (grain: one row per
`REC_SRC`), and is always the **last** HK component. It is **never** part of the BK column
itself and **never** in HASHDIFF. See [02-fbin-deviations.md](02-fbin-deviations.md#master-reconciliation-table).

## Quick self-check before you generate

1. Can you state the grain in one sentence?
2. Does the BK survive all five disqualifiers?
3. If composite, have you guarded the **link-HK collision** (duplicated leading component)?
4. Is every dependent child modeled with an intentional pattern (not by accident)?
5. Is BKCC registered in `REF_BUSINESS_KEY_COLLISION` for this `REC_SRC`?

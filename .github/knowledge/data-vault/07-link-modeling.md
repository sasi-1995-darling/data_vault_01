# Link Modeling

> **Priority topic** (top pain point). Links are where two subtle failures hide: **orphans**
> (from collapsing keys that don't co-occur) and **silent non-joins** (from cross-domain BKCC
> mistakes in the link HK). Pair with [08-modeling-traps.md](08-modeling-traps.md).

## What a link is (and is not)

- A link records that **2+ hub keys co-occur** in a relationship or event.
- Its HK is derived from **all participating hub HKs** concatenated:
  `MD5_BINARY(UPPER(CONCAT_WS('||', hub1_HK, hub2_HK, …, hubN_HK)))` — order **must** be
  consistent across every source CTE. *(link instructions)*
- A link carries **no descriptive attributes**. Descriptions go in a `lsat_`. The only
  columns allowed on the link body are **degenerate attributes** that exist solely in the
  relationship context (e.g. `PO_LINE_NUMBER`), insert-only, no HASHDIFF.
- **Links do not carry BKCC.** Each component HK already embeds its *own* hub's BKCC. (This
  is the root of the cross-domain trap below.)

## The co-occurrence test (wide UoW vs separate links)

The single most important link decision: **do these keys always appear together?**

```
Do ALL the keys always co-occur in ONE source row?
├── YES → one Unit-of-Work (UoW) link is safe
│         e.g. lnk_invoice_customer_sales_org — single-source sell-side, keys co-occur
└── NO  → SEPARATE links (one per relationship that can stand alone)
          collapsing them orphans rows when a key is absent
```

- **Wide UoW link** is legitimate **only** when co-occurrence is guaranteed (usually a
  single source where the row itself proves all keys are present together).
- **Separate links** whenever a participant can be missing. A PO can be flipped **without**
  a goods receipt; a GR may **not yet** be invoiced. A wide `PO↔GR↔invoice` link would leave
  freight/tax/misc lines orphaned when they don't match. → model `lnk_po_invoice_line` and
  `lnk_gr_invoice_line` **separately**. *(memory: supplier-ap-invoice-modeling)*

## Multi-way matches belong in the Business Vault

Do **not** assemble a 3-way (or N-way) match as one collapsed raw link. Build the pairwise
links in the Raw Vault, then **assemble the match in the Business Vault** (PIT / bridge),
where soft rules and non-co-occurrence are handled. This keeps the Raw Vault 100%-faithful
and puts the interpretive logic where it belongs ([10-business-vault.md](10-business-vault.md)).

## Cross-domain link HK composition (the silent non-join)

When a link spans domains (e.g. an invoice-side model referencing a PO foreign key), the
**foreign hub HK must be built with the foreign hub's OWN BKCC**, not the local model's BKCC.

> **The bug**: invoice-side staging recomputes the PO foreign HK using the *invoice's* BKCC
> instead of the *PO's* owning BKCC → the recomputed HK never matches the real
> `hub_po_*` HK → the link **silently never joins**. **Fix**: build the PO foreign HK with the
> PO domain's BKCC (confirm the source-system split per opco first).
> *(memory: supplier-ap-invoice-modeling)*

Rule of thumb: **every component HK in a link is computed exactly as its owning hub computes
it** — same raw columns, same order, same BKCC. If you can't reproduce the owning hub's HK
expression, you are not ready to build the link.

## Driving keys (for effectivity)

A **driving key** is the subset of a link's keys that determines "which relationship is
currently in effect." Example: for an *item → primary-vendor* relationship, the item is the
driving key; the vendor can change over time. The **effectivity satellite** (`esat_`) tracks
open/close for the driving key. See [05-satellite-variants.md](05-satellite-variants.md#effectivity-satellite-esat_).

- Choose the driving key by asking: *"holding what constant do the other keys rotate?"*
- Only relationships with a genuine "current partner" need effectivity — don't add `esat_`
  reflexively.

## Same-as links (SAL) — entity resolution

A **same-as link** asserts two hub rows are the **same real-world entity** (e.g. the
Salesforce customer and the ERP customer are one person). FBIN/doctrine placement:

- The SAL lives in the **Raw Vault** alongside hubs and links.
- It connects **two HKs from the same hub** (both customer HKs).
- **Survivorship** ("which record's values win") is an **Information Mart** concern, not the
  SAL. The SAL only asserts identity.
- Match metadata (confidence score, algorithm) goes in a standard satellite off the SAL.

Use a SAL when the same entity has different keys across sources and you need to
de-duplicate without destroying source-faithful history.

## Transactional links (`tlink_`)

For immutable events with measures, carry the payload **on the link** (non-historized) rather
than a separate satellite: `tlink_invoice_line_transaction`, `tlink_po_line_transaction`.
Slowly-changing descriptive columns can still live in a `sat_*_detail` hanging off the
`tlink_`.

## Multi-source links & watermarks (FBIN mechanics)

- Each source gets its own `SRC_`/`LOGIC_` CTE, all `UNION`ed into `JOIN_` before `FINAL`.
- Dedup per source with `QUALIFY ROW_NUMBER() OVER(PARTITION BY LNK_HK ORDER BY LOAD_DTS)=1`.
- **Multi-source** watermark is scoped per `REC_SRC`; **single-source** uses global
  `MAX(LOAD_DTS)`.
- Incremental guard: `NOT EXISTS` on the **LNK HK only** (never component HKs, never
  `LOAD_DTS`).
- Non-applicable hub reference → ghost key `-2` (error sentinel).

## Quick self-check

1. Does every participant pass the co-occurrence test? (else split the link)
2. Is any N-way match being collapsed into one raw link? (move it to the BV)
3. Is every component HK built with its **owning hub's** BKCC and column order?
4. Does the link carry only degenerate attributes (no descriptions, no BKCC)?
5. Does any relationship need a driving key / effectivity — or a same-as link?

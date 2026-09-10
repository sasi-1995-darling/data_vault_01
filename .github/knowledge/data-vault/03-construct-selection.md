# Construct Selection — Hub vs Link vs Satellite

> **Priority topic** (top pain point). Decide *what kind of object* a source element
> becomes. Get this wrong and everything downstream inherits the error. Pair with
> [04-grain-and-bk-selection.md](04-grain-and-bk-selection.md) (which BK) and
> [05-satellite-variants.md](05-satellite-variants.md) (which satellite flavor).

## The one-question test for each construct

| If the element is… | It is a… | FBIN object |
|--------------------|----------|-------------|
| A **business concept** the enterprise identifies and talks about ("customer", "PO", "material") | **Hub** | `hub_<concept>` |
| A **relationship / co-occurrence** of 2+ concepts ("PO line ↔ supplier", "invoice ↔ customer ↔ sales org") | **Link** | `lnk_<relationship>` |
| A **descriptive attribute** of one concept or one relationship ("PO status", "customer address") | **Satellite** | `sat_`/`lsat_`/`msat_`/`esat_` |
| An **immutable transaction/event** with its own measures | **Transactional link** | `tlink_<event>` |
| An **assertion that two hub rows are the same entity** | **Same-as link** | `lnk_..._sa` / SAL |

## Decision tree

```
Is it a thing the business names and keys independently?
├── YES → HUB.  (Does it need its own natural key? → 04-grain-and-bk-selection.md)
└── NO
    ├── Is it a relationship between 2+ hubs?
    │   ├── YES → LINK
    │   │        ├── Is it an immutable event with measures (order line, txn)?
    │   │        │   └── YES → TRANSACTIONAL LINK (tlink_)  [payload on the link]
    │   │        ├── Does it just connect keys (no measures)?
    │   │        │   └── YES → standard LINK (lnk_)  [+ esat_ if lifecycle matters]
    │   │        └── Is it "these two hub rows are the same real entity"?
    │   │            └── YES → SAME-AS LINK (survivorship lives in the mart)
    │   └── NO → it describes a hub or a link → SATELLITE
    │            └── which flavor? → 05-satellite-variants.md
    └── Not sure it belongs in the vault at all? → is it reference data / a calc?
             ├── static reference → ref_ (Business Vault) or non-historized sat
             └── derived/calculated → Business Vault satellite (source = the calc)
```

## Hub — when and how

**A hub exists for a business key, not for a table.** One source table can feed several
hubs (header + line), and several sources can feed one hub (passive integration).

Create a hub when:
- The concept has a **stable, business-recognized identifier** (see BK rules in [04](04-grain-and-bk-selection.md)).
- The concept is **referenced by** relationships (links) or **described by** attributes (sats).

Do **not** create a hub when:
- The "key" is really a **relationship** (e.g. an association/junction table → that's a link).
- The "key" is **only unique within a parent** (e.g. line number) → that's a **dependent
  child**; the hub's BK is the *composite* (`header_id + line_number`) or the concept is a
  degenerate attribute on a link. See [04](04-grain-and-bk-selection.md#dependent-children).
- The value is a **descriptor** (status, type, category) → satellite payload, or a
  reference table.

> **FBIN reality**: "vendor" == "supplier". There is no `hub_vendor` for procurement;
> the buy-side party master is `hub_supplier_v2`. `hub_vendor_order` is a *false friend*
> (Amazon 1P sell-side). Always confirm the concept, not the column name.
> *(memory: supplier-ap-invoice-modeling)*

## Link — when and how

**A link captures that keys co-occur.** Its own HK is derived from all participating hub
HKs (see [09-hashing-and-ghosts.md](09-hashing-and-ghosts.md)); it carries **no descriptive
attributes** (those go in a `lsat_`), only degenerate attributes that exist solely in the
relationship context (e.g. `PO_LINE_NUMBER`).

The **co-occurrence test** decides whether relationships collapse into one wide link or
split into several:

- **Keys always appear together in one source** → a single Unit-of-Work (UoW) link is fine
  (e.g. `lnk_invoice_customer_sales_org` — single-source sell-side where all keys co-occur).
- **Keys do NOT always co-occur** → **separate links**. Modeling a wide link across keys
  that can be absent orphans rows.
  Example: a 3-way PO ↔ GR ↔ invoice match. A PO can be flipped without a goods receipt; a
  GR may not yet be invoiced. → model `lnk_po_invoice_line` and `lnk_gr_invoice_line`
  **separately**, and **assemble the 3-way match in the Business Vault (PIT/bridge)** — never
  as one collapsed raw link. *(memory: supplier-ap-invoice-modeling; see [07](07-link-modeling.md))*

## Satellite — when and how

A satellite holds the **descriptive payload** of exactly one parent. The parent is a hub
(`sat_`) or a link (`lsat_`). Choosing the *flavor* (standard / multi-active / effectivity /
link-multi-active / non-historized) is [05-satellite-variants.md](05-satellite-variants.md).

Two structural rules that are easy to violate:
- **Single parent.** Every column must be attributable to the *same* parent HK. A column
  that describes a different concept means you need a different satellite (or the parent is
  wrong).
- **One source per satellite.** FBIN convention: `sat_<entity>__<source>`. Different
  `REC_SRC` = different satellite. This keeps the per-source watermark and HASHDIFF clean.

## Anti-patterns caught here

- **Table-driven modeling** — creating one hub per source table instead of one hub per
  business key. (See [12-anti-patterns.md](12-anti-patterns.md).)
- **A link that carries descriptive attributes** instead of a `lsat_`.
- **A hub for a dependent child** (line number as its own hub BK without the parent).
- **A collapsed wide link** across keys that don't co-occur → orphans.

## Quick self-check before you generate

1. Is every hub a business key the enterprise recognizes? *(not a table, not a descriptor)*
2. Does every link pass the co-occurrence test?
3. Does every satellite have exactly one parent and one source?
4. Have you deferred multi-source/3-way assembly to the Business Vault?

If any answer is "no", stop and revisit — the pipeline will happily generate the wrong shape.

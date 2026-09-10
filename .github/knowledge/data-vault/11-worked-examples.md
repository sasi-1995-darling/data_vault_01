# Worked Examples

> Concrete FBIN modeling decisions, so the advisor can reason by analogy. Two have full
> design records on `main`; the supplier-invoice walkthrough is inline (its design record
> lives on a feature branch, not `main`).

## Example 1 — Purchase Order / Supply Chain

- **Design record**: [docs/dv_purchase_order.md](../../../docs/dv_purchase_order.md)
  (conceptual + business diagrams).
- **Shape**: header + line hubs, PO↔supplier and PO↔item links, goods-movement link carrying
  `PO_ITEM_HK` (GR ↔ PO line), purchase-requisition hubs.
- **Why it's instructive**: shows passive integration (Emtek Oracle EBS + others feeding
  conformed procurement hubs) and the header/line split with the PO line as the anchor for
  downstream match links.

## Example 2 — Sales Invoicing

- **Design record**: [docs/dv_sales_invoice.md](../../../docs/dv_sales_invoice.md).
- **Shape**: invoice centered on the shipment event; **wide UoW links** (e.g.
  `lnk_invoice_customer_sales_org…`) are legitimate here because it is **single-source
  sell-side data where all keys co-occur** — the exact condition the co-occurrence test
  ([07-link-modeling.md](07-link-modeling.md#the-co-occurrence-test-wide-uow-vs-separate-links))
  requires for a wide link.
- **Contrast with AP** (below): the same "wide link" instinct is **wrong** on the buy-side,
  where keys do *not* co-occur.

## Example 3 — Supplier (AP) Invoice — a decision walkthrough

> Source: verified modeling memory + Approved lessons. The full design record
> (`docs/dv_supplier_invoice.md`) currently lives on the `feature/gpgds-11454-ap-supplier-invoice`
> branch, **not `main`** — do not link it as if present here.

This case exercises almost every priority decision in this KB:

1. **Concept, not column** ([03](03-construct-selection.md)): "vendor" == "supplier". No
   `hub_vendor`; the party master is `hub_supplier_v2`. `hub_vendor_order` is a *false friend*
   (Amazon 1P sell-side) — do **not** anchor AP work on it.
2. **BK disqualification** ([04](04-grain-and-bk-selection.md)): natural key rejected
   (`INVOICE_NUM` mutable; needs `ORG_ID` SAP lacks; Oracle≠SAP identity). → **surrogate
   `INVOICE_ID`** header BK; line BK = `INVOICE_ID | LINE_NUMBER`.
3. **Pattern A (dependent child)**: line-as-hub (composite BK) + header↔line link + line sat.
4. **Separate match links** ([07](07-link-modeling.md)): PO-match and GR-match links hang off
   the **line**; the 3-way PO↔GR↔invoice match is assembled in the **Business Vault**
   (PIT/bridge), never a collapsed raw link — because AP keys don't co-occur (freight/tax/misc
   lines would orphan).
5. **Composite-BK link-HK collision** ([08 TRAP-01](08-modeling-traps.md#trap-01--composite-bk-link-hk-collides-with-the-line-hub-hk)):
   compose the header↔line link HK from the **hub HK values** (`TO_VARCHAR(INVOICE_LINE_HK),
   TO_VARCHAR(INVOICE_HK)`; the platform default post-#1907) — hub-HK values share no raw
   components, so the collision cannot occur. The legacy raw-column form duplicated the
   shared leading component `(INVOICE_ID, INVOICE_ID, LINE_NUMBER, BKCC)`.
6. **Cross-domain BKCC** ([08 TRAP-02](08-modeling-traps.md#trap-02--cross-domain-foreign-hk-built-with-the-wrong-bkcc)):
   the PO foreign HK on the invoice side must be built with the **PO's** BKCC, not the
   invoice's.
7. **Source-specific gap**: the AP-lines landing gap was **ml_ebs-specific** (Moen), not
   global; the build was anchored on `emtk_ebs` (BKCC `Diving_Sea`).

**Takeaway for the advisor**: sell-side sales-invoice and buy-side supplier-invoice look
similar but diverge on the co-occurrence test and BK conformance. Reason from the *decisions*,
not the surface resemblance.

## How to use these

When a user describes a new source, find the closest analog above, then walk the priority
decisions ([03](03-construct-selection.md)→[07](07-link-modeling.md)) and the relevant traps
([08](08-modeling-traps.md)). Cite the analog and state where the new case **differs** — the
differences are where modeling errors hide.

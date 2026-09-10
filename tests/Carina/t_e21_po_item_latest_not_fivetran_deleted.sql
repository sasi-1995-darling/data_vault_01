{{ config(severity = 'warn') }}
/*
    Guard test — GPGDS-11405 / 11406 OTD foundational dates.

    FACT_PO_ITEM (ORIGINAL_PROMISED_DATE) and FACT_PO_RECEIPT (PROMISED_DATE_*,
    ORIGINAL_PROMISED_DATE) take the latest E21 record per PO_ITEM_HK from
    msat_po_item__tt_e21. The pit dedup prefers non Fivetran-deleted rows
    (defensive), on the empirical basis that the newest record per key is never
    a Fivetran soft-delete — verified 0 of 5,146,443 keys on 2026-07-17, even
    though 48.6% of raw history rows are soft-deleted.

    This test warns if that assumption ever breaks (a soft-delete becomes the
    newest record for a key), so the design can be reviewed before it can skew
    the surfaced dates. Severity is WARN because the pit dedup already prevents
    a stale date from surfacing unless EVERY row for a key is deleted.
*/
select
    PO_ITEM_HK
from {{ ref('msat_po_item__tt_e21') }}
qualify row_number() over (partition by PO_ITEM_HK order by LOAD_DTS desc) = 1
    and _FIVETRAN_DELETED = true

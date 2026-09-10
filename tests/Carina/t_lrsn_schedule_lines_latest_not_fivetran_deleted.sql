{{ config(severity = 'warn') }}
/*
    Guard test — GPGDS-11405 OTD supplier ship dates.

    FACT_PO_ITEM SUPPLIER_SHIP_DATE_LATEST/EARLIEST come from Larson PSFT
    schedule lines aggregated in stg_pb_po_item__lrst_psft, which does NOT
    filter Fivetran soft-deletes (verified 0 soft-deletes across the sat today).
    The bridge keeps the latest row per (po_item_hk, SCHED_NBR) then takes
    MAX/MIN SHIP_DATE.

    This test warns if any latest schedule line is soft-deleted, so a delete
    filter can be added deliberately (Larson has no CREATION_DATE, so the 500-day
    age-split used for the EBS/Fusion receipt schedule lines is not applicable)
    before deleted rows can skew the aggregated ship dates.
*/
select
    po_item_hk,
    SCHED_NBR
from {{ ref('sat_po_item_schedule_lines__lrsn_psft') }}
qualify row_number() over (partition by po_item_hk, SCHED_NBR order by load_dts desc) = 1
    and _FIVETRAN_DELETED = true

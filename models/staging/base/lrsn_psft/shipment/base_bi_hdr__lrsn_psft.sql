with cte_hdr as (select * from {{ source("bronze_lrsn_psft", "ps_bi_hdr") }})

select distinct
    cte_hdr.business_unit
    , cte_hdr.invoice
    , cte_hdr.bill_to_cust_id
    , cte_hdr.bill_status
    , cte_hdr.invoice_type
    , cte_hdr.sales_person
    , cte_hdr.invoice_amount
    , cte_hdr.invoice_dt
    , cte_hdr.dt_invoiced
    , cte_hdr.entry_type
    , cte_hdr.entry_reason
    , cte_hdr.order_no
    , cte_hdr.ship_to_cust_id
    , cte_hdr.ship_from_bu
    , cte_hdr.sold_to_cust_id
    , cte_hdr.user1
from cte_hdr
where cte_hdr._fivetran_deleted = false

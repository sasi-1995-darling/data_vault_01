with cte_lne as (select * from {{ source("bronze_lrsn_psft", "ps_bi_line") }})

select distinct
    cte_lne.business_unit
    , cte_lne.invoice
    , cte_lne.line_seq_num
    , cte_lne.unit_of_measure
    , cte_lne.qty
    , cte_lne.unit_amt
    , cte_lne.gross_extended_amt
    , cte_lne.net_extended_amt
    , cte_lne.net_extended_bse
    , cte_lne.tax_amt
    , cte_lne.tax_amt_bse
    , cte_lne.tot_discount_amt
    , cte_lne.entry_type
    , cte_lne.order_no
    , cte_lne.order_int_line_no
    , cte_lne.product_id
    , cte_lne.ship_from_bu
    , cte_lne.ship_to_cust_id
    , cte_lne.ship_to_addr_num
    , cte_lne.ship_date
    , cte_lne.sold_to_cust_id
    , cte_lne.sold_to_addr_num
    , cte_lne.user2
from cte_lne
where cte_lne._fivetran_deleted = false

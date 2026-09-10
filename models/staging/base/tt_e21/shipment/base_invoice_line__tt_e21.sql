with cte_invitem as (select * from {{ source("bronze_tt_e21", "invitem") }})

select
    cte_invitem.mstr_inv_numb
    , cte_invitem.invoice_numb
    , cte_invitem.order_numb
    , cte_invitem.ord_item
    , trim(cte_invitem.part_code) as part_code
    , cte_invitem.item_no
    , cte_invitem.ship_qty
    , cte_invitem.item_status
    , cte_invitem.item_list_price
    , cte_invitem.item_sales_amt
    , cte_invitem.item_cogs_amt
    , cte_invitem.item_priceid
    , cte_invitem.item_rep
    , cte_invitem.qty
    , cte_invitem.item_price
    , cte_invitem.cost_ctr
from cte_invitem
where cte_invitem._fivetran_deleted = false

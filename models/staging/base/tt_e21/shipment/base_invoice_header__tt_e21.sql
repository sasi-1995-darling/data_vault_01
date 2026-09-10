with cte_invhead as (select * from {{ source("bronze_tt_e21", "invhead") }})

select
    cte_invhead.mstr_inv_numb
    , to_char(cte_invhead.invoice_numb) as invoice_numb
    , cte_invhead.order_date
    , cte_invhead.ship_date
    , cte_invhead.post_date
    , cte_invhead.cost_ctr
    , cte_invhead.invc_type
    , cte_invhead.cust_code
    , cte_invhead.billto_code
    , cte_invhead.order_numb
    , cte_invhead.carr_code
    , cte_invhead.met_of_ship
    , cte_invhead.terms_code
    , cte_invhead.billname
    , cte_invhead.billadd1
    , cte_invhead.billadd2
    , cte_invhead.billadd3
    , cte_invhead.billcity
    , cte_invhead.billst
    , cte_invhead.billzip
    , cte_invhead.billcountry
    , cte_invhead.schfld5
    , case when cte_invhead.schfld5 is null then 1
        when cte_invhead.schfld5 in ('61', '65', '66', '67') then 0
        else 1
    end as multiplier
from cte_invhead
where cte_invhead._fivetran_deleted = false

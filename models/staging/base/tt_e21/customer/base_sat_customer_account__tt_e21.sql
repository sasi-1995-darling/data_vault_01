with cte_pg as (
    select *
    from {{ source("bronze_tt_e21", "shiphead") }}
    where -- _fivetran_deleted = false and 
    nullif(trim(cust_code), '') is not null
)

, cust_fil as (
    select
        cust_code
        , shipname
        , billname
        , shipto_code
        , billto_code
        , max(order_date) as latest_order_date
        , max(_fivetran_synced) as max_fivetran_synced
    from cte_pg
    where cust_code = shipto_code
    group by all
)

select
    cust_code
    , shipname
    , billname
    , shipto_code
    , billto_code
    , latest_order_date as order_date
    , max_fivetran_synced as _fivetran_synced
from cust_fil
qualify row_number() over (partition by cust_code order by latest_order_date desc) = 1

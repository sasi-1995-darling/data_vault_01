with cte_map as (select distinct
        sku_nbr
        , category
        , svp1
        , merch_dept1
        , class1_3
        , sub_class1_1
        , sku1_2
        , manuf_part_number
        , run_date
        , 'Moen' as home_depot_account
    from {{ source('homedepot_pos_askuity', 'hd_askuity_master_itemattributes') }}
    where home_depot_account like 'Moen%'
)
, cte_bkcc as (select * from {{ ref('ref_business_key_collision') }}
where rec_src = 'US.ASKUITY.HOMEDEPOT.HD_ASKUITY_MASTER_ITEMATTRIBUTES')

select distinct
    cte_map.*
    , cte_bkcc.rec_src
    , cte_bkcc.bkcc
from cte_map
inner join cte_bkcc on 1=1
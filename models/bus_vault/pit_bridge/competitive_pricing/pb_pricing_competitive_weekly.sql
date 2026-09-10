with cte_comp_pricing as (
    select * from {{ ref('stg_pricing_competitive_profitero_weekly_agg') }}
    union all
    select * from {{ ref('pb_stg_pricing_competitive_profitero_share_weekly_agg') }}
)    

select 
      row_number() over(order by 1) as seq_id
    , current_timestamp as snapshot_dts
    , date
    , customer_product_id
    , product_id
    , date_key
    , product_bk
    , product_key
    , retailer_bk
    , retailer_key
    , brand_bk
    , brand_key    
    , data_source
    , availability_percent
    , average_regular_price
    , minimum_regular_price
    , maximum_regular_price
    , mode_regular_price
    , average_promotion_price
    , minimum_promotion_price
    , maximum_promotion_price
    , mode_promotion_price
    , bkcc
    , rec_src
from cte_comp_pricing
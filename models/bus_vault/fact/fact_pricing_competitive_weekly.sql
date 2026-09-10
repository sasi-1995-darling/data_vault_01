select 
      date
    , customer_product_id
    , product_id
    , product_bk
    , product_key
    , retailer_bk
    , retailer_key
    , data_source
    , brand_bk
    , brand_key        
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
from {{ ref('pb_pricing_competitive_weekly') }}
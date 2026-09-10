{{ config(alias='dim_product_v2' + ('_competitive_pricing' if target.schema not in ['dev', 'qa', 'prod'] else '')) }}


SELECT
          product_bk
        , product_name
        , model
        , bkcc
        , rec_src
        , rpc
        , ean
        , upc
        , map_price
        , sentiment_src
        , src_id
        , room_area
        , connected_products_class
        , fire_resistant_attr
        , smart_attr
        , customer_product_id
        , level_1
        , level_2
        , connected_flag
        , product_family
        , brand_id
FROM {{ ref('dim_product_v2') }}
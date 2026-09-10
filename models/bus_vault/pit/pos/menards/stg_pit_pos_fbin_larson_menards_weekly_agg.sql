{{
    config(
        materialized='ephemeral'
    )
}}

with cte_data__larson_menards_weekly as (

    select * from {{ ref('stg_pit_pos_fbin_larson_menards_weekly') }}
)

select
    item_id
    , store_hk
    , transaction_date
    , transaction_datekey
    , reporting_channel
    , reporting_customer
    , sku
    , store_id
    , sum(pos_qty) as pos_qty
    , sum(consumer_dollars) as consumer_dollars
    , sku_status
    , sum(gross_dollars) as gross_dollars
    , brand
    , max(shipping_city) as shipping_city
    , max(shipping_state) as shipping_state
    , max(shipping_zip) as shipping_zip
    , max(product_dest_zip) as product_dest_zip
    , sum(inv_qty) as inv_qty
    , sum(inv_consumer_dollars) as inv_consumer_dollars
    , bkcc
    , rec_src
from
    cte_data__larson_menards_weekly
group by all



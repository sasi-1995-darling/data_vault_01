{{
    config(
        materialized='ephemeral'
    )
}}

select
    coalesce(pb_hd.item, 'N/A') as item_id
    , pb_hd.store_hk
    , pb_hd.transaction_date
    , pb_hd.reporting_channel
    , pb_hd.sku
    , pb_hd.store_id
    , pb_hd.sku_status
    , pb_hd.pos_qty
    , pb_hd.consumer_dollars
    , pb_hd.gross_dollars
    , pb_hd.inv_qty
    , pb_hd.inv_consumer_dollars
    , pb_hd.shipping_city
    , pb_hd.shipping_state
    , pb_hd.shipping_zip
    , pb_hd.product_dest_zip
    , 'HOME DEPOT' as reporting_customer
    , case when pb_hd.brand = 'Larson' then 'LARSON'
        else upper(pb_hd.brand)
    end as brand
    , pb_hd.bkcc
    , pb_hd.rec_src
from {{ ref('stg_pit_pos_fbin_homedepot') }} as pb_hd
where pb_hd.brand not in ('Masterlock', 'SentrySafe', 'Moen_CSI', 'Moen_Vendordrill_Data')

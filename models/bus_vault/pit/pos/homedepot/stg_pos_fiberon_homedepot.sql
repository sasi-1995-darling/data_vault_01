{{
    config(
        materialized='ephemeral'
    )
}}


select
     xref.item_hk as item_id
    , pb_hd.store_hk
    , pb_hd.transaction_date
    , pb_hd.transaction_datekey
    , pb_hd.reporting_channel
    , pb_hd.sku
    , pb_hd.store_id
    , pb_hd.sku_status
    , pb_hd.pos_qty
    , pb_hd.consumer_dollars
    , pb_hd.gross_dollars
    , pb_hd.inv_qty
    , pb_hd.inv_consumer_dollars
    , 'HOME DEPOT' as reporting_customer
    , 'FIBERON' as brand
    , pb_hd.bkcc
    , pb_hd.rec_src
from {{ ref('stg_pit_pos_fbin_homedepot') }} as pb_hd
    left join {{ ref('stg_pos_fiberon_item_lookup') }} as xref
        on pb_hd.sku = xref.sku_nbr
where pb_hd.brand in ('Fiberon')

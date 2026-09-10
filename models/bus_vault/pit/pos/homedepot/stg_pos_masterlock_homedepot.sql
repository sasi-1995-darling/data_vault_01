{{
    config(
        materialized='ephemeral'
    )
}}


 with tmlc_basematerial_item_map as (
    select
        base_material_key 
        , first_value(item_hk) over (partition by base_material_key order by item_hk) as item_id
    from {{ ref('pb_items_by_plant') }}
    qualify row_number() over(partition by base_material_key order by item_hk)=1
)


select
     bxref.item_id
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
    , case
        when pb_hd.brand in ('MasterLock','Masterlock') then 'MASTER LOCK'
        when pb_hd.brand = 'SentrySafe' then 'SENTRYSAFE'
        else pb_hd.brand
    end as brand
    , pb_hd.bkcc
    , pb_hd.rec_src
from {{ ref('stg_pit_pos_fbin_homedepot') }} as pb_hd
    left join {{ ref('ref_pos_home_depot_tmlc_xref') }} as xref
        on pb_hd.sku = xref.hd_item and pb_hd.brand in ('MasterLock','Masterlock', 'SentrySafe')
    left join tmlc_basematerial_item_map as bxref
        on xref.base_material_hk = bxref.base_material_key
where pb_hd.brand in ('MasterLock','Masterlock', 'SentrySafe')

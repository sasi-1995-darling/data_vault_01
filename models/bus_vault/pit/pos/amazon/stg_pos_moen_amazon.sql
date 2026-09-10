{{
    config(
        materialized='ephemeral'
    )
}}

with
moen_pos_base as (
    select
       *
    from {{ ref('stg_pit_pos_fbin_amazon') }} as pos
    where pos.brand like 'Moen%'
),

cte_basematerial_item_map as (
    select distinct
        base_material_key
        , first_value(item_hk) over (partition by base_material_key order by item_hk) as item_id
    from {{ ref('pb_items_by_plant') }}
)

, item_date as (
    select distinct
        p.sku as amazon_asin
        , map.item_id
        , x.model_style_number
        , p.transaction_date
    from moen_pos_base as p
        left join {{ ref('ref_pos_amazon_moen_xref') }} as x
            on p.sku = x.asin
        left join cte_basematerial_item_map as map
            on x.base_material_hk = map.base_material_key
)


, gross_price_item_date as (
    select
        id.item_id
        , id.transaction_date
        , id.model_style_number
        , gp.gross_aup
        , row_number() over (partition by id.model_style_number, id.transaction_date order by gp.shipment_datekey) as rn
    from item_date as id
        left join {{ ref('ref_xref_gross_price') }} as gp
            on id.item_id = gp.item_hk and gp.key_account_number = '112' and gp.brand = 'MOEN'
                and TO_VARCHAR(id.transaction_date,'YYYYMMDD') >= gp.shipment_datekey
)


select
    i.item_id as item_id
    , pos.store_hk
    , pos.transaction_date
    , pos.transaction_datekey
    , pos.reporting_channel
    , pos.sku
    , pos.store_id
    , pos.sku_status
    , pos.pos_qty
    , pos.consumer_dollars
    , pos.pos_qty * gp.gross_aup as gross_dollars
    , pos.inv_qty
    , pos.inv_consumer_dollars
    , 'AMAZON' as reporting_customer
    , 'MOEN' as brand
    , pos.bkcc
    , pos.rec_src
from moen_pos_base as pos
    left join {{ ref('ref_pos_amazon_moen_xref') }} as x
    on pos.sku = x.asin
    left join cte_basematerial_item_map as i
    on x.base_material_hk = i.base_material_key
    left join gross_price_item_date as gp
    on x.model_style_number = gp.model_style_number and gp.rn = 1 and pos.transaction_date = gp.transaction_date


{{
    config(
        materialized='ephemeral'
    )
}}


with cte_sat_pos_customer_sales__lowes as (

    select * from {{ ref('sat_pos_customer_sales__lowes') }}
    where brand = 'MASTER LOCK'
)

, cte_sat_pos_customer_sales__lowes__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_pos_customer_sales__lowes'
        ,hk_field='customer_sales_hk') }}
)

, cte_sat_pos_customer_location__lowes as (

    select * from {{ ref('sat_pos_customer_location__lowes') }}
)

, cte_sat_pos_customer_location__lowes_latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_pos_customer_location__lowes'
        ,hk_field='customer_location_hk') }}
)

, cte_basematerial_item_map as (
    select distinct
        base_material
        , first_value(item_id) over (partition by base_material order by item_id nulls last) as item
        , brand
    from {{ ref('ref_item_master') }}
    where brand = 'TMLC'
)

, item_date as (
    select distinct p.item_id as lowes_item_id, map.item as item_id, x.tmlc_sku, p.end_date
    from cte_sat_pos_customer_sales__lowes__latest as p
    left join {{ ref('ref_pos_lowes_tmlc_xref') }} as x
        on p.item_id = x.lowes_sku
    left join cte_basematerial_item_map map 
        on x.tmlc_sku = map.base_material
)

, gross_price_item_date as (
    select id.item_id, id.end_date, gp.gross_aup, id.tmlc_sku,
         row_number () over (partition by id.tmlc_sku, id.end_date ORDER BY gp.shipment_date) as rn
    from item_date as id
    left join {{ ref('ref_xref_gross_price') }} as gp
        on gp.item_id = id.item_id and gp.key_account_number = '55' and gp.brand = 'MASTER LOCK'
        and id.end_date >= gp.shipment_date
)

select
    p.customer_sales_hk as product_customer_hk
    --, dateadd(day, 1, p.end_date) as transaction_date
    , p.end_date as transaction_date
    , 'RT' as reporting_channel
    , to_char(coalesce(i.item, x.tmlc_sku, p.item_id)) as item
    , 'LOWES' as reporting_customer
    , p.item_id as sku --need Lowe's Xref
    , h.location_bk as location_id
    , p.ty_sales_units as pos_qty
    , p.ty_sales as consumer_dollars
    , p.ty_available_inventory_units as inv_qty
    , p.ty_available_inventory_sales as inv_consumer_dollars
    , 'N/A' as sku_status
    , gp.gross_aup * p.ty_sales_units as gross_dollars
    , p.brand
    , l.city as shipping_city
    , l.state as shipping_state
    , l.zip as shipping_zip
    , '' as product_dest_zip
from cte_sat_pos_customer_sales__lowes__latest as p
    left join cte_sat_pos_customer_location__lowes_latest as l
        on p.customer_location_hk = l.customer_location_hk
    left join {{ ref('hub_customer_location') }} as h
        on l.customer_location_hk = h.customer_location_hk and h.customer = 'LOWES'
    left join {{ ref('ref_pos_lowes_tmlc_xref') }} as x
        on p.item_id = x.lowes_sku
    left join cte_basematerial_item_map as i
        on x.tmlc_sku = i.base_material
    left join gross_price_item_date as gp
            on x.tmlc_sku = gp.tmlc_sku and gp.rn = 1 and p.end_date = gp.end_date


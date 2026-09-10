-- depends on: {{ ref('hub_customer_location') }}

{{
    config(
        materialized='ephemeral'
    )
}}

with decoded_location_channel as (
    select
        l.*
        , case when l.type = 'HOME DEPOT DIRECT' then 'DTC'
            when l.type = 'HOME DEPOT CORE RETAIL' then 'In Store'
        end as channel
    from {{ ref('sat_pos_customer_location__hd_askuity') }} as l
)

, in_store_channel as (
    select
        p.product_customer_hk
        , p.day as transaction_date
        , 'RT' as reporting_channel
        , p.manuf_part_number as item
        , p.sku_nbr as sku
        , p.d_store_nbr as location_id
        , p.sku_status
        , p.sales_units as pos_qty
        , p.sales as consumer_dollars
        , null as gross_dollars
        , i.str_oh_units_dly as inv_qty
        , to_number(i.str_oh, 15, 2) as inv_consumer_dollars
        , p.home_depot_account as brand
        , l.city as shipping_city
        , l.state as shipping_state
        , l.zip as shipping_zip
        , null as product_dest_zip
    from {{ ref('sat_pos_product_customer__hd_askuity') }} as p
        left join decoded_location_channel as l
            on p.customer_location_hk = l.customer_location_hk and l.channel = 'In Store'
        left join {{ ref('sat_pos_product_customer_inventory__hd_askuity') }} as i
            on p.product_inventory_hk = i.product_inventory_hk
    where p.fulfillment_channel = 'In Store'
)

, dtc_channel as (
    select
        p.product_customer_hk
        , p.day as transaction_date
        , 'EC' as reporting_channel
        , p.manuf_part_number as item
        , p.sku_nbr as sku
        , p.d_store_nbr as location_id
        , p.sku_status
        , p.sales_units as pos_qty
        , p.sales as consumer_dollars
        , null as gross_dollars
        , i.str_oh_units_dly as inv_qty
        , to_number(i.str_oh, 15, 2) as inv_consumer_dollars
        , p.home_depot_account as brand
        , l.city as shipping_city
        , l.state as shipping_state
        , l.zip as shipping_zip
        , null as product_dest_zip
    from {{ ref('sat_pos_product_customer__hd_askuity') }} as p
        left join decoded_location_channel as l
            on p.customer_location_hk = l.customer_location_hk and l.channel = 'DTC'
        left join {{ ref('sat_pos_product_customer_inventory__hd_askuity') }} as i
            on p.product_inventory_hk = i.product_inventory_hk
    where p.fulfillment_channel = 'DTC'
)

, rest_ec_channel as (
    select
        p.product_customer_hk
        , p.day as transaction_date
        , 'EC' as reporting_channel
        , p.manuf_part_number as item
        , p.sku_nbr as sku
        , p.d_store_nbr as location_id
        , p.sku_status
        , p.sales_units as pos_qty
        , p.sales as consumer_dollars
        , null as gross_dollars
        , null as inv_qty
        , null as inv_consumer_dollars
        , p.home_depot_account as brand
        , l.city as shipping_city
        , l.state as shipping_state
        , l.zip as shipping_zip
        , null as product_dest_zip
    from {{ ref('sat_pos_product_customer__hd_askuity') }} as p
        left join {{ ref('sat_pos_customer_location__hd_askuity') }} as l
            on p.customer_location_hk = l.customer_location_hk
    where p.fulfillment_channel not in ('DTC', 'In Store')
)

, union_all_channels as (
    select * from in_store_channel
    union all
    select * from dtc_channel
    union all
    select * from rest_ec_channel
)

, tmlc_basematerial_item_map as (
    select distinct
        base_material
        , first_value(item_id) over (partition by base_material order by item_id nulls last) as item
    from {{ ref('ref_item_master') }} where brand = 'TMLC'
)

, tmlc_pos as (
    select
        coalesce(case when bxref.base_material is not null then bxref.item else
                xref.tmlc_base_material
        end, 'N/A') as item
        , uac.product_customer_hk
        , uac.transaction_date
        , uac.reporting_channel
        , uac.sku
        , uac.location_id
        , uac.sku_status
        , uac.pos_qty
        , uac.consumer_dollars
        , uac.gross_dollars
        , uac.inv_qty
        , uac.inv_consumer_dollars
        , uac.shipping_city
        , uac.shipping_state
        , uac.shipping_zip
        , uac.product_dest_zip
        --uac.HD_ITEM,
        --uac.TMLC_BASE_MATERIAL,
        , 'HOME DEPOT' as reporting_customer
        , case
            when uac.brand = 'Masterlock' then 'MASTER LOCK'
            when uac.brand = 'SentrySafe' then 'SENTRYSAFE'
            else uac.brand
        end as brand
    from union_all_channels as uac
        left join {{ ref('ref_pos_home_depot_tmlc_xref') }} as xref
            on uac.sku = xref.hd_item and uac.brand in ('Masterlock', 'SentrySafe')
        left join tmlc_basematerial_item_map as bxref
            on xref.tmlc_base_material = bxref.base_material
    where uac.brand in ('Masterlock', 'SentrySafe')
)

, moen_known_item_attributes as (
    select distinct
        sku_nbr
        , first_value(manuf_part_number) over (partition by sku_nbr order by run_date desc) as manuf_part_number
    from {{ ref('ref_pos_home_depot_itemattributes') }}
    where manuf_part_number != 'UNKNOWN' and brand = 'MOEN'
)

, pos_moen_resolve_unknowns_from_knowns as (
    select
        pos.* exclude item
        , kim.manuf_part_number as item
    from union_all_channels as pos
        left join moen_known_item_attributes as kim on pos.sku = kim.sku_nbr
    where pos.item = 'UNKNOWN' and pos.brand like 'Moen%'
)

, moen_pos_base as (
    select
        pos.* exclude item
        , pos.item
    from union_all_channels as pos
    where pos.item != 'UNKNOWN' and pos.brand like 'Moen%'
    union all
    select
        * exclude item
        , coalesce(item, 'UNKNOWN') as item
    from pos_moen_resolve_unknowns_from_knowns
)

, moen_item_no_match_master as (
    select distinct item as item_id from moen_pos_base
    minus
    select distinct item_id from {{ ref('ref_item_master') }}
)

, moen_item_match_master as (
    select distinct
        item as pos_item_id
        , rim.item_id as rim_item_id
    from moen_pos_base as pos
        left join {{ ref('ref_item_master') }} as rim on pos.item = rim.item_id
    where pos.brand like 'Moen%'
)

, moen_item_map as (
    select
        pos_item_id
        , rim_item_id
    from moen_item_match_master where rim_item_id is not null
    union
    select
        pos.item_id as pos_item_id
        , rim.item_id as rim_item_id
    from moen_item_no_match_master as pos
        left join {{ ref('ref_item_master') }} as rim on upper(rim.item_id) = upper(split_part(pos.item_id, '-', 0))
)

, moen_pos as (
    select
        coalesce(mim.rim_item_id, pos.item, 'N/A') as item
        , pos.product_customer_hk
        , pos.transaction_date
        , pos.reporting_channel
        , pos.sku
        , pos.location_id
        , pos.sku_status
        , pos.pos_qty
        , pos.consumer_dollars
        , pos.gross_dollars
        , pos.inv_qty
        , pos.inv_consumer_dollars
        , pos.shipping_city
        , pos.shipping_state
        , pos.shipping_zip
        , pos.product_dest_zip
        --uac.HD_ITEM,
        --uac.TMLC_BASE_MATERIAL,		
        , 'HOME DEPOT' as reporting_customer
        , 'MOEN' as brand
    from moen_pos_base as pos
        left join moen_item_map as mim on pos.item = mim.pos_item_id
)

, rest_pos as (
    select
        coalesce(uac.item, 'N/A') as item
        , uac.product_customer_hk
        , uac.transaction_date
        , uac.reporting_channel
        , uac.sku
        , uac.location_id
        , uac.sku_status
        , uac.pos_qty
        , uac.consumer_dollars
        , uac.gross_dollars
        , uac.inv_qty
        , uac.inv_consumer_dollars
        , uac.shipping_city
        , uac.shipping_state
        , uac.shipping_zip
        , uac.product_dest_zip
        --uac.HD_ITEM,
        --uac.TMLC_BASE_MATERIAL,		
        , 'HOME DEPOT' as reporting_customer
        , case when uac.brand = 'Larson' then 'LARSON'
            else upper(uac.brand)
        end as brand
    from union_all_channels as uac
    where uac.brand not in ('Masterlock', 'SentrySafe', 'Moen_CSI', 'Moen_Vendordrill_Data')
)


select * from tmlc_pos -- brands "Masterlock and SentrySafe"
union all
select * from moen_pos -- brands "Moen"
union all
select * from rest_pos -- rest brands

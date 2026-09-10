{{
    config(
        materialized='ephemeral'
    )
}}


with cte_sat_inventory_masterlock__lowes as (
    select 
              store_hk
            , item_id
            , end_date
            , ty_sales_units
            , ty_sales
            , ty_available_inventory_units
            , ty_available_inventory_sales
            , 'MASTER LOCK' as brand
            , load_dts
            , rec_src
    from {{ ref('sat_sales_inventory__masterlock_lowes') }}
    where start_date < '2026-01-31' --Talend deprecated, Fivetran source added from this start_date forward 2026-02-10
)

, cte_sat_inventory_masterlock__lowes_latest as (
    select * from cte_sat_inventory_masterlock__lowes
    qualify row_number() over(partition by store_hk,item_id,end_date order by load_dts desc)=1
)

, cte_sat_inventory_masterlock__lowes_ft_api as ( --added Fivetran source, api migrated from Talend 2026-02-10
    select 
          store_hk
        , item_id
        , start_date
        , end_date
        , ty_sales_units
        , ty_sales
        , ty_available_inventory_units
        , ty_available_inventory_sales
        , 'MASTER LOCK' as brand
        , load_dts
        , rec_src
    from {{ ref('sat_sales_inventory__masterlock_lowes_ft_api') }} 
    where start_date >= '2026-01-31'
)

, cte_sat_inventory_masterlock__lowes_ft_api_latest as (
    {{ generate_cte_satellite_latest('cte_sat_inventory_masterlock__lowes_ft_api','store_hk, item_id, start_date, end_date') }}
)

, cte_sat_inventory_masterlock__lowes_latest_union as (
    select * from cte_sat_inventory_masterlock__lowes_latest
    union all
    select 
              store_hk
            , item_id
            , end_date
            , ty_sales_units
            , ty_sales
            , ty_available_inventory_units
            , ty_available_inventory_sales
            , brand
            , load_dts
            , rec_src
    from cte_sat_inventory_masterlock__lowes_ft_api_latest
)

, cte_sat_store__lowes as (

    select * from {{ ref('sat_store__lowes') }}
)

, cte_sat_store__lowes_latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_store__lowes'
        ,hk_field='store_hk') }}
)

, cte_basematerial_item_map as (
    select distinct
        base_material_key
        , first_value(item_hk) over (partition by base_material_key order by item_hk) as item_id
    from {{ ref('pb_items_by_plant') }}
)

, item_date as (
    select distinct
        p.item_id as lowes_item_id
        , map.item_id
        , x.tmlc_sku
        , p.end_date
    from cte_sat_inventory_masterlock__lowes_latest_union as p
        left join {{ ref('ref_pos_lowes_tmlc_xref') }} as x
            on p.item_id = x.lowes_sku
        left join cte_basematerial_item_map as map
            on x.base_material_hk = map.base_material_key
)

, gross_price_item_date as (
    select
        id.item_id
        , id.end_date
        , gp.gross_aup
        , id.tmlc_sku
        , row_number() over (partition by id.tmlc_sku, id.end_date order by gp.shipment_datekey) as rn
    from item_date as id
        left join {{ ref('ref_xref_gross_price') }} as gp
            on id.item_id = gp.item_hk and gp.key_account_number = '55' and gp.brand = 'MASTER LOCK'
                and TO_VARCHAR(TO_DATE(id.end_date,'YYYY-MM-DD'),'YYYYMMDD') >= gp.shipment_datekey
)

select
    i.item_id
    , h.store_hk as store_hk
    , dateadd(day, 1, p.end_date) as transaction_date
    , TO_VARCHAR(transaction_date,'YYYYMMDD') as transaction_datekey
    , 'RT' as reporting_channel
    , 'LOWES' as reporting_customer
    , p.item_id as sku --need Lowe's Xref
    , h.store_bk as store_id
    , p.ty_sales_units as pos_qty
    , p.ty_sales as consumer_dollars
    , p.ty_available_inventory_units as inv_qty
    , round(p.ty_available_inventory_sales, 2) as inv_consumer_dollars
    , 'N/A' as sku_status
    , gp.gross_aup * p.ty_sales_units as gross_dollars
    , p.brand
    , l.delivery_city as shipping_city
    , l.delivery_state as shipping_state
    , l.delivery_code as shipping_zip
    , '' as product_dest_zip
    , h.bkcc
    , h.rec_src
from
    {{ ref('hub_store') }} as h
    left join cte_sat_store__lowes_latest as l
        on h.store_hk = l.store_hk
    inner join cte_sat_inventory_masterlock__lowes_latest_union as p
        on h.store_hk = p.store_hk
    left join {{ ref('ref_pos_lowes_tmlc_xref') }} as x
        on p.item_id = x.lowes_sku
    left join cte_basematerial_item_map as i
        on x.base_material_hk = i.base_material_key
    left join gross_price_item_date as gp
        on x.tmlc_sku = gp.tmlc_sku and gp.rn = 1 and p.end_date = gp.end_date


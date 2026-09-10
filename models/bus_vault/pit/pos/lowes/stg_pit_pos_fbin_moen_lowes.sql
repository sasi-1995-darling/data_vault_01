{{
    config(
        materialized='ephemeral'
    )
}}


with cte_sat_data_moen__latest as (

    select * from {{ ref('stg_moen_lowes_union') }}
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
        , x.moen_us
        , p.end_date
    from cte_sat_data_moen__latest as p
        left join {{ ref('ref_pos_lowes_moen_xref') }} as x
            on p.item_id = x.lowes_sku
        left join cte_basematerial_item_map as map
            on x.base_material_hk = map.base_material_key
)

, gross_price_item_date as (
    select
        id.item_id
        , id.end_date
        , id.moen_us
        , gp.gross_aup
        , row_number() over (partition by id.moen_us, id.end_date order by gp.shipment_datekey) as rn
    from item_date as id
        left join {{ ref('ref_xref_gross_price') }} as gp
            on id.item_id = gp.item_hk and gp.key_account_number = '112' and gp.brand = 'MOEN'
                --and TO_VARCHAR(TO_DATE(id.end_date,'YYYY-MM-DD'),'YYYYMMDD') >= gp.shipment_datekey
                and TO_VARCHAR(id.end_date,'YYYYMMDD') >= gp.shipment_datekey
)

, lowes_base as (
    select
        p.* exclude(item_id)
        , p.item_id as sku
        , h.store_bk as store_id
        , i.item_id
        , gp.gross_aup as gross_price
        , a.retail_price
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
        inner join cte_sat_data_moen__latest as p
            on h.store_hk = p.store_hk
        left join {{ ref('ref_pos_lowes_moen_xref') }} as x
            on p.item_id = x.lowes_sku
        left join cte_basematerial_item_map as i
            on x.base_material_hk = i.base_material_key
        left join gross_price_item_date as gp
            on x.moen_us = gp.moen_us and gp.rn = 1 and p.end_date = gp.end_date
        left join
            (select
                end_date
                , item_id
                , div0(sum(ty_sales), sum(ty_sales_units)) as retail_price
            from cte_sat_data_moen__latest 
            group by end_date, item_id) as a
            on p.item_id = a.item_id and p.end_date = a.end_date
)

, lowes_union as (
    select
        *
        , 'IN STORE' as fulfillment_type
    from lowes_base
    union
    select
        *
        , 'SHIP TO CUSTOMER' as fulfillment_type
    from lowes_base
)

, lowes_metrics as (
    select
        *
        , case when fulfillment_type = 'IN STORE' then 'RT' else 'EC' end as reporting_channel
        , case
            when fulfillment_type = 'IN STORE' then ty_sales - coalesce(ty_fulfilled_internet_sales, 0) else
                coalesce(ty_fulfilled_internet_sales, 0)
        end as consumer_dollars_sold
        ,
        case
            when fulfillment_type = 'IN STORE' then ty_sales_units - coalesce(ty_fulfilled_internet_units, 0) else
                coalesce(ty_fulfilled_internet_units, 0)
        end as units_sold
        ,
        case when fulfillment_type = 'IN STORE' then ty_available_inventory_sales end as gross_inventory_dollars
        , case when fulfillment_type = 'IN STORE' then ty_available_inventory_units end as inventory_units
    from lowes_union
)

select distinct     --added distinct to remove duplication caused by identical transaction records exising in sales inventory and tsm datasets
    item_id
   -- , customer_sales_hk as product_customer_hk
    , store_hk
    , dateadd(day, 1, end_date) as transaction_date
    , TO_VARCHAR(transaction_date,'YYYYMMDD') as transaction_datekey
    , reporting_channel
    , 'LOWES' as reporting_customer
    , trim(sku) as sku --added trim to remove duplication caused by identical transaction records exising in sales inventory and tsm datasets
    , store_id
    , trim(units_sold) as pos_qty --added trim to remove duplication caused by identical transaction records exising in sales inventory and tsm datasets
    , trim(consumer_dollars_sold) as consumer_dollars   --added trim to remove duplication caused by identical transaction records exising in sales inventory and tsm datasets
    , trim(inventory_units) as inv_qty  --added trim to remove duplication caused by identical transaction records exising in sales inventory and tsm datasets
    , round(retail_price * inventory_units, 2) as inv_consumer_dollars
    , 'N/A' as sku_status
    , gross_price * units_sold as gross_dollars
    , brand
    , shipping_city
    , shipping_state
    , shipping_zip
    , product_dest_zip
    , bkcc
    , rec_src
from lowes_metrics
where abs(coalesce(consumer_dollars_sold, 0)) + abs(coalesce(units_sold, 0))
    + abs(coalesce(retail_price * inventory_units, 0)) + abs(coalesce(inventory_units, 0)) > 0

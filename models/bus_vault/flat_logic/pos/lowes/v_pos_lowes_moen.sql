{{
    config(
        materialized='ephemeral'
    )
}}


with cte_sat_pos_customer_sales__lowes as (

    select * from {{ ref('sat_pos_customer_sales__lowes') }}
    where brand = 'MOEN'
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
    where brand = 'MOEN'
)

, item_date as (
    select distinct p.item_id as lowes_item_id, x.moen_us, p.end_date
    from cte_sat_pos_customer_sales__lowes__latest as p
    left join {{ ref('ref_pos_lowes_moen_xref') }} as x
        on p.item_id = x.lowes_sku
    where p.brand = 'MOEN'
)

, gross_price_item_date as (
    select id.moen_us, id.end_date, gp.gross_aup,
         row_number () over (partition by id.moen_us, id.end_date ORDER BY gp.shipment_date) as rn
    from item_date as id
    left join {{ ref('ref_xref_gross_price') }} as gp
        on gp.item_id = id.moen_us and gp.key_account_number = '112'
        and id.end_date >= gp.shipment_date
)

, lowes_base as (
    select p.*
        , h.location_bk as location_id
        , to_char(coalesce(i.item, x.moen_us, p.item_id)) as item
        , gp.gross_aup as gross_price
        , a.retail_price
        , l.city as shipping_city
        , l.state as shipping_state
        , l.zip as shipping_zip
        , '' as product_dest_zip
    from cte_sat_pos_customer_sales__lowes__latest as p
        left join cte_sat_pos_customer_location__lowes_latest as l
            on p.customer_location_hk = l.customer_location_hk
        left join {{ ref('hub_customer_location') }} as h
            on l.customer_location_hk = h.customer_location_hk and h.customer = 'LOWES'
        left join {{ ref('ref_pos_lowes_moen_xref') }} as x
            on p.item_id = x.lowes_sku
        left join cte_basematerial_item_map as i
            on x.moen_us = i.base_material
        left join gross_price_item_date as gp
            on x.moen_us = gp.moen_us and gp.rn = 1 and p.end_date = gp.end_date
        left join
            (select end_date
                   , item_id
                   , div0(sum(ty_sales), sum(ty_sales_units)) as retail_price
            from cte_sat_pos_customer_sales__lowes__latest
            group by end_date, item_id) as a
            on p.item_id = a.item_id and p.end_date = a.end_date

)

, lowes_union as (
    select *, 'IN STORE' as fulfillment_type from lowes_base
    union
    select *, 'SHIP TO CUSTOMER' as fulfillment_type from lowes_base
)

, lowes_metrics as (
    select *,
        case when fulfillment_type = 'IN STORE' then 'RT' else 'EC' end as reporting_channel,
        case
            when fulfillment_type = 'IN STORE' then ty_sales - coalesce(ty_fulfilled_internet_sales, 0) else
                coalesce(ty_fulfilled_internet_sales, 0)
        end as consumer_dollars_sold
        ,
        case
            when fulfillment_type = 'IN STORE' then ty_sales_units - coalesce(ty_fulfilled_internet_units, 0) else
                coalesce(ty_fulfilled_internet_units, 0)
        end as units_sold
        ,
        case when fulfillment_type = 'IN STORE' then ty_available_inventory_sales end as gross_inventory_dollars,
        case when fulfillment_type = 'IN STORE' then ty_available_inventory_units end as inventory_units
    from lowes_union
)

select
    customer_sales_hk as product_customer_hk
    , dateadd(day, 1, end_date) as transaction_date
    , reporting_channel
    , item
    , 'LOWES' as reporting_customer
    , item_id as sku
    , location_id
    , units_sold as pos_qty
    , consumer_dollars_sold as consumer_dollars
    , inventory_units as inv_qty
    , retail_price * inventory_units as inv_consumer_dollars
    , 'N/A' as sku_status
    , gross_price * units_sold as gross_dollars
    , brand
    , shipping_city
    , shipping_state
    , shipping_zip
    , product_dest_zip
from lowes_metrics
where abs(coalesce(consumer_dollars_sold, 0)) + abs(coalesce(units_sold, 0)) + 
abs(coalesce(retail_price * inventory_units, 0)) + abs(coalesce(inventory_units, 0)) > 0
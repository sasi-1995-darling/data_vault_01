{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_data__moen_menards_history as (

    select
        *
        , 'MOEN' as brand
    from {{ ref('sat_sales_inventory_history__moen_menards') }}
)

, cte_sat_data__moen_menards_history_latest as (
    select * from cte_sat_data__moen_menards_history
    qualify
        1
        = row_number()
            over (partition by store_hk, item, file_name, file_row_number, load_dts, hashdiff order by load_dts desc)
)

, cte_sat_data__moen_menards_history_latest_transformed as (
    select
        brand
        , try_to_date(replace(right(file_name, 15), '.csv.gz', ''), 'YYYYMMDD') as date
        , store_hk
        , replace(replace(location, chr(0), ''), '"', '') as location
        , replace(replace(item, chr(0), ''), '"', '') as sku
        , replace(replace(item_name, chr(0), ''), '"', '') as item_name
        , replace(replace(sku, chr(0), ''), '"', '') as base_material
        , try_cast(replace(replace(unit_sales, chr(0), ''), '"', '') as integer) as unit_sales
        , try_cast(replace(replace(replace(replace(dollar_sales, chr(0), ''), '"', ''), '$', ''), ',', '') as integer)
            as dollar_sales
        , try_cast(
            regexp_replace(total_units_on_hand, '[^0-9]', '')
            as integer
        ) as inv_qty


        , try_cast(
            regexp_replace(total_dollar_cost_on_hand, '[^0-9\.]', '')
            as decimal(18, 2)
        ) as inv_consumer_dollars
        , 'RT' as reporting_channel
        , 'MENARDS' as reporting_customer
    from cte_sat_data__moen_menards_history_latest
)


, cte_sat_data__moen_menards_weekly as (

    select
        *
        , 'MOEN' as brand
    from {{ ref('sat_sales_inventory_weekly__moen_menards') }}
)

, cte_sat_data__moen_menards_weekly_latest as (
    select * from cte_sat_data__moen_menards_weekly
    qualify 1 = row_number() over (partition by store_hk, item, _file, _line, load_dts, hashdiff order by load_dts desc)
)

, cte_sat_data__moen_menards_weekly_latest_transformed as (
    select
        brand
        , try_to_date(replace(right(_file, 12), '.csv', ''), 'YYYYMMDD') as date
        , store_hk
        , location
        , item as sku
        , item_name
        , sku as base_material
        , try_cast(unit_sales as integer) as unit_sales
        , try_cast(replace(replace(dollar_sales, '$', ''), ',', '') as integer) as dollar_sales
        , try_cast(
            regexp_replace(total_units_on_hand, '[^0-9]', '')
            as integer
        ) as inv_qty

        , try_cast(
            regexp_replace(total_dollar_cost_on_hand, '[^0-9\.]', '')
            as decimal(18, 2)
        ) as inv_consumer_dollars
        , 'RT' as reporting_channel
        , 'MENARDS' as reporting_customer

    from cte_sat_data__moen_menards_weekly_latest
)

, pos_union as (
    select
        brand
        , date
        , store_hk
        , location
        , sku
        , item_name
        , base_material
        , unit_sales
        , dollar_sales
        , inv_qty
        , inv_consumer_dollars
        , reporting_channel
        , reporting_customer
    from cte_sat_data__moen_menards_history_latest_transformed
    union all
    select
        brand
        , date
        , store_hk
        , location
        , sku
        , item_name
        , base_material
        , unit_sales
        , dollar_sales
        , inv_qty
        , inv_consumer_dollars
        , reporting_channel
        , reporting_customer
    from cte_sat_data__moen_menards_weekly_latest_transformed
)

, cte_sat_store_ll__menards as (

    select * from {{ ref('sat_store_location_lookup__menards') }}
)

, cte_sat_store_ll__menards_latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_store_ll__menards'
        ,hk_field='store_hk') }}
)


, cte_sat_store_history__menards as (

    select * from {{ ref('sat_store_history__menards') }}

)

, cte_sat_store_history__menards_latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_store_history__menards'
        ,hk_field='store_hk') }}
)


, cte_basematerial_item_map as (
    select distinct
        base_material
        , first_value(item_hk) over (partition by base_material_key order by item_hk) as item_id
    from {{ ref('pb_items_by_plant') }}
    where brand = 'MOEN'
)

, item_date as (
    select distinct
        p.sku as menards_item_id
        , map.item_id
        , p.base_material
        , p.date
    from pos_union as p
        left join cte_basematerial_item_map as map
            on p.base_material = map.base_material
)


, gross_price_item_date as (
    select
        id.item_id
        , id.date
        , gp.gross_aup
        , id.base_material
        , row_number() over (partition by id.base_material, id.date order by gp.shipment_datekey) as rn
    from item_date as id
        left join {{ ref('ref_xref_gross_price') }} as gp
            on id.item_id = gp.item_hk and gp.key_account_number = '112' and gp.brand = 'MOEN'
                and to_varchar(id.date, 'YYYYMMDD') >= gp.shipment_datekey
)



select
    i.item_id
    , h.store_hk
    , p.date as transaction_date
    , to_varchar(transaction_date, 'YYYYMMDD') as transaction_datekey
    , p.reporting_channel
    , p.reporting_customer
    , p.sku
    , replace(replace(h.store_bk, chr(0), ''), '"', '') as store_id
    , p.unit_sales as pos_qty
    , p.dollar_sales as consumer_dollars
    , 'N/A' as sku_status
    , gp.gross_aup * p.unit_sales as gross_dollars
    , p.brand
    , coalesce(l1.city, l2.city) as shipping_city
    , coalesce(l1.state, l2.state) as shipping_state
    , coalesce(l1.postal_cd, l2.postal_cd) as shipping_zip
    , '' as product_dest_zip
    , p.inv_qty
    , p.inv_consumer_dollars
    , h.bkcc
    , h.rec_src
from
    {{ ref('hub_store') }} as h
    left join cte_sat_store_ll__menards_latest as l1
        on h.store_hk = l1.store_hk
    left join cte_sat_store_history__menards_latest as l2
        on h.store_hk = l2.store_hk
    inner join pos_union as p
        on h.store_hk = p.store_hk
    left join cte_basematerial_item_map as i
        on p.base_material = i.base_material
    left join gross_price_item_date as gp
        on p.base_material = gp.base_material and gp.rn = 1 and p.date = gp.date
where (consumer_dollars <> 0) and sku <> 'Total'

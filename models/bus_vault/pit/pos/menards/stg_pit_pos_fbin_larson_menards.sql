{{
    config(
        materialized='ephemeral'
    )
}}


with cte_sat_data__larson_menards as (

    select
        *
        , 'LARSON' as brand
    from {{ ref('sat_sales_inventory__larson_menards') }}
)

, cte_sat_data__larson_menards_latest as (
    select * from cte_sat_data__larson_menards
)

, cte_sat_data__larson_menards_latest_transformed as (
    select
        store_hk
        , day
        , try_to_date(day) as end_date
        , brand
        , item as sku
        , try_cast(replace(replace(unit_sales, '(', '-'), ')', '') as integer) as derv_pos_qty
        , try_cast(replace(replace(replace(sales, '$', ''), '(', '-'), ')', '') as decimal(15, 2))
            as derv_consumer_dollars
        , coalesce(
            try_cast(
                replace(
                    replace(total_units_on_hand, '(', '-')
                    , ')', ''
                )
                as integer
            )
            , 0
        ) as inv_qty
        , coalesce(
            try_cast(
                nullif(
                    replace(
                        replace(
                            replace(
                                replace(trim(total_cost_on_hand), ',', '')
                                , '$', ''
                            )
                            , '(', '-'
                        )
                        , ')', ''
                    )
                    , ''
                ) as decimal(15, 2)
            )
            , 0
        ) as inv_consumer_dollars
    from cte_sat_data__larson_menards_latest
    where (derv_consumer_dollars <> 0 or inv_qty <> 0)
        and day <> 'Day'
)

, cte_sat_agg as (
    select
        store_hk
        , end_date
        , 'RT' as reporting_channel
        , 'MENARDS' as reporting_customer
        , sku
        , brand
        , max(derv_pos_qty) as pos_qty
        , max(derv_consumer_dollars) as consumer_dollars
        , max(inv_qty) as inv_qty
        , max(inv_consumer_dollars) as inv_consumer_dollars
        , 'N/A' as sku_status
    from cte_sat_data__larson_menards_latest_transformed
    group by all
)

, cte_sat_store_ll__menards as (

    select * from {{ ref('sat_store_location_lookup__menards') }}
)

, cte_sat_store_ll__menards_latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_store_ll__menards'
        ,hk_field='store_hk') }}
)

, cte_basematerial_item_map as (
    select distinct
        base_material_key
        , first_value(item_hk) over (partition by base_material_key order by item_hk) as item_id
    from {{ ref('pb_items_by_plant') }}
    where brand = 'LARSON'
)

, item_date as (
    select distinct
        p.sku as menards_item_id
        , map.item_id
        , x.larson_item_id
        , p.end_date
    from cte_sat_agg as p
        left join {{ ref('ref_pos_menards_larson_xref') }} as x
            on p.sku = x.menards_sku
        left join cte_basematerial_item_map as map
            on x.base_material_hk = map.base_material_key
)


, gross_price_item_date as (
    select
        id.item_id
        , id.end_date
        , gp.gross_aup
        , id.larson_item_id
        , row_number() over (partition by id.larson_item_id, id.end_date order by gp.shipment_datekey) as rn
    from item_date as id
        left join {{ ref('ref_xref_gross_price') }} as gp
            on id.item_id = gp.item_hk and gp.key_account_number = '6915' and gp.brand = 'LARSON'
                and to_varchar(id.end_date, 'YYYYMMDD') >= gp.shipment_datekey
)


select
    i.item_id
    , h.store_hk
    , p.end_date as transaction_date
    , to_varchar(transaction_date, 'YYYYMMDD') as transaction_datekey
    , p.reporting_channel
    , p.reporting_customer
    , p.sku
    , h.store_bk as store_id
    , p.pos_qty
    , p.consumer_dollars
    , 'N/A' as sku_status
    , gp.gross_aup * p.pos_qty as gross_dollars
    , p.brand
    , l.city as shipping_city
    , l.state as shipping_state
    , l.postal_cd as shipping_zip
    , '' as product_dest_zip
    , p.inv_qty
    , p.inv_consumer_dollars
    , h.bkcc
    , h.rec_src
from
    {{ ref('hub_store') }} as h
    left join cte_sat_store_ll__menards_latest as l
        on h.store_hk = l.store_hk
    inner join cte_sat_agg as p
        on h.store_hk = p.store_hk
    left join {{ ref('ref_pos_menards_larson_xref') }} as x
        on p.sku = x.menards_sku
    left join cte_basematerial_item_map as i
        on x.base_material_hk = i.base_material_key
    left join gross_price_item_date as gp
        on x.larson_item_id = gp.larson_item_id and gp.rn = 1 and p.end_date = gp.end_date

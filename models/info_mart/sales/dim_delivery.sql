-- dim delivery

with cte_hub_delivery as (
    select * from {{ ref('hub_delivery') }}
)

, cte_sat_delivery_detail__emtk_ebs as (
    select * from {{ ref('sat_delivery_detail__emtk_ebs') }}
)

, cte_sat_delivery_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_delivery_detail__emtk_ebs'
        ,hk_field='delivery_hk') }}
)

, cte_sat_delivery_detail__emtk_ebs__renamed as (
    select
        delivery_hk
        , delivery_detail_id as src_detail_id
        , creation_date as src_created_at
        , date_requested as requested_at
        , date_scheduled as scheduled_at
        , earliest_pickup_date as earliest_pickup_at
        , latest_pickup_date as latest_pickup_at
        , batch_id
        , ship_method_code
        , tracking_number
        , cust_po_number
        , service_level
        , mode_of_transport
        , load_dts as valid_from
    from cte_sat_delivery_detail__emtk_ebs__latest
)

, cte_final as (
    select
        hub.delivery_hk as dim_delivery_pk
        , hub.delivery_bk
        , hub.brand
        , sat.src_detail_id
        , sat.src_created_at
        , sat.requested_at
        , sat.scheduled_at
        , sat.earliest_pickup_at
        , sat.latest_pickup_at
        , sat.batch_id
        , sat.ship_method_code
        , sat.tracking_number
        , sat.cust_po_number
        , sat.service_level
        , sat.mode_of_transport
        , sat.valid_from
    from cte_hub_delivery as hub
        inner join cte_sat_delivery_detail__emtk_ebs__renamed as sat
            on hub.delivery_hk = sat.delivery_hk
)

select * from cte_final

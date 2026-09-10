-- dim customer ship location 

with cte_hub_customer_ship_location as (
    select * from {{ ref('hub_customer_ship_location') }}
)

, cte_sat_customer_ship_location_detail__emtk_ebs as (
    select * from {{ ref('sat_customer_ship_detail__emtk_ebs') }}
)

, cte_sat_customer_ship_location_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_customer_ship_location_detail__emtk_ebs'
        ,hk_field='customer_ship_location_hk') }}
)

, cte_sat_customer_ship_location_detail__emtk_ebs__renamed as (
    select
        customer_ship_location_hk
        , location_id
        , location
        , site_use_id
        , request_id
        , program_application_id
        , program_id
        , program_update_date
        , orig_system_reference
        , country
        , address1
        , address2
        , address3
        , address4
        , city
        , postal_code
        , state
        , province
        , county
        , address_key
        , address_style
        , address_lines_phonetic
        , address_effective_date
        , object_version_number
        , created_by_module
        , application_id
        , timezone_id
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_sat_customer_ship_location_detail__emtk_ebs__latest
)

, cte_customer_ship_location as (
    select
        hub.customer_ship_location_hk as dim_customer_ship_location_pk
        , hub.brand
        , sat.location_id
        , sat.location
        , sat.site_use_id
        , sat.request_id
        , sat.program_application_id
        , sat.program_id
        , sat.program_update_date
        , sat.orig_system_reference
        , sat.country
        , sat.address1
        , sat.address2
        , sat.address3
        , sat.address4
        , sat.city
        , sat.postal_code
        , sat.state
        , sat.province
        , sat.county
        , sat.address_key
        , sat.address_style
        , sat.address_lines_phonetic
        , sat.address_effective_date
        , sat.application_id
        , sat.timezone_id
        , sat.src_created_at
        , sat.src_last_updated_at
        , sat.valid_from
    from cte_hub_customer_ship_location as hub
        inner join cte_sat_customer_ship_location_detail__emtk_ebs__renamed as sat
            on hub.customer_ship_location_hk = sat.customer_ship_location_hk

)

, cte_default as (
    select
        CAST(MD5_BINARY(-1) as BINARY(16)) as dim_customer_ship_location_pk
        , null as sub_brand
        , null as location_id
        , null as "location"
        , null as site_use_id
        , null as request_id
        , null as program_application_id
        , null as program_id
        , null as program_update_date
        , null as orig_system_reference
        , null as country
        , null as address1
        , null as address2
        , null as address3
        , null as address4
        , null as city
        , null as postal_code
        , null as state
        , null as province
        , null as county
        , null as address_key
        , null as address_style
        , null as address_lines_phonetic
        , null as address_effective_date
        , null as application_id
        , null as timezone_id
        , null as src_created_at
        , null as src_last_updated_at
        , TO_TIMESTAMP('1900-01-01') as valid_from
)

, cte_final as (
    select * from cte_customer_ship_location
    union all
    select * from cte_default
)

select * from cte_final

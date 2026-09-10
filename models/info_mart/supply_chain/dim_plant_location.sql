--dim_plant_location type 1
with cte_hub_plant_location as (
    select * from {{ ref('hub_plant_location') }}
)

, cte_sat_plant_location_detail__emtk_ebs as (
    select * from {{ ref('sat_plant_location_detail__emtk_ebs') }}
)

, cte_sat_plant_location_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_plant_location_detail__emtk_ebs'
        ,hk_field='plant_location_hk') }}
)

, cte_sat_plant_location_detail__emtk_ebs_renamed as (
    select
        plant_location_hk
        , organization_code as plant_code
        , location_code as plant_location_code
        , location_id as src_location_id
        , description as plant_location_name
        , address_line_1
        , address_line_2
        , town_or_city
        , country
        , postal_code
        , region_1 as region
        , region_2 as state_abrev
        , derived_locale
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_sat_plant_location_detail__emtk_ebs__latest
)

, cte_final as (

    select
        hub_pl.plant_location_hk as dim_plant_location_pk
        , hub_pl.plant_location_bk as src_plant_location_bk
        , hub_pl.brand
        , sat_pld.plant_code
        , sat_pld.plant_location_code
        , sat_pld.src_location_id
        , sat_pld.plant_location_name
        , sat_pld.address_line_1
        , sat_pld.address_line_2
        , sat_pld.town_or_city
        , sat_pld.country
        , sat_pld.postal_code
        , sat_pld.region
        , sat_pld.state_abrev
        , sat_pld.derived_locale
        , sat_pld.src_created_at
        , sat_pld.src_last_updated_at
        , sat_pld.valid_from
    from cte_hub_plant_location as hub_pl
        inner join cte_sat_plant_location_detail__emtk_ebs_renamed as sat_pld
            on hub_pl.plant_location_hk = sat_pld.plant_location_hk
)

select * from cte_final

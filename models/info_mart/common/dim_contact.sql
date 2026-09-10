-- dim_contact type 1
with cte_hub_contact as (
    select * from {{ ref('hub_contact') }}
)

, cte_sat_contact_detail__emtk_ebs as (
    select * from {{ ref('sat_contact_detail__emtk_ebs') }}
)

, cte_sat_contact_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_contact_detail__emtk_ebs'
        ,hk_field='contact_hk') }}
)

, cte_sat_contact_detail__emtk_ebs_renamed as (
    select
        contact_hk
        , contact_point_type as contact_type
        , status as contact_status
        , try_to_boolean(primary_flag) as is_primary
        , email_address
        , phone_country_code
        , phone_area_code
        , phone_number
        , phone_extension
        , phone_line_type
        , raw_phone_number
        , contact_point_purpose
        , transposed_phone_number
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_sat_contact_detail__emtk_ebs__latest
)

, cte_final as (

    select
        hub_c.contact_hk as dim_contact_pk
        , hub_c.contact_bk as src_contact_bk
        , hub_c.brand
        , sat_cd.contact_type
        , sat_cd.contact_status
        , sat_cd.is_primary
        , sat_cd.email_address
        , sat_cd.phone_country_code
        , sat_cd.phone_area_code
        , sat_cd.phone_number
        , sat_cd.phone_extension
        , sat_cd.phone_line_type
        , sat_cd.raw_phone_number
        , sat_cd.contact_point_purpose
        , sat_cd.transposed_phone_number
        , sat_cd.src_created_at
        , sat_cd.src_last_updated_at
        , sat_cd.valid_from
    from cte_hub_contact as hub_c
        inner join cte_sat_contact_detail__emtk_ebs_renamed as sat_cd
            on hub_c.contact_hk = sat_cd.contact_hk
)

select * from cte_final

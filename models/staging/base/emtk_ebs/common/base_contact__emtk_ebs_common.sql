with cte_hz_contact_points as (
    select
        contact_point_id::varchar as contact_point_id--BK
        , contact_point_type
        , status
        , owner_table_name
        , owner_table_id
        , primary_flag
        , orig_system_reference
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , creation_date
        , created_by
        , last_update_login
        , request_id
        , program_application_id
        , program_id
        , program_update_date
        , email_format
        , email_address
        , phone_area_code
        , phone_country_code
        , phone_number
        , phone_extension
        , phone_line_type
        , raw_phone_number
        , object_version_number
        , created_by_module
        , application_id
        , contact_point_purpose
        , primary_by_purpose
        , transposed_phone_number
    from {{ source('emtk_ebs_common__ar', 'hz_contact_points') }}
    where _fivetran_deleted = false
)

, cte_union_default as (
    /* because links to contact may not exist */
    select
        '-1' as contact_point_id --BK
        , null as contact_point_type
        , null as status
        , null as owner_table_name
        , null as owner_table_id
        , null as primary_flag
        , null as orig_system_reference
        , null as last_update_date
        , '1900-01-01' as _fivetran_synced
        , null as last_updated_by
        , null as creation_date
        , null as created_by
        , null as last_update_login
        , null as request_id
        , null as program_application_id
        , null as program_id
        , null as program_update_date
        , null as email_format
        , null as email_address
        , null as phone_area_code
        , null as phone_country_code
        , null as phone_number
        , null as phone_extension
        , null as phone_line_type
        , null as raw_phone_number
        , null as object_version_number
        , null as created_by_module
        , null as application_id
        , null as contact_point_purpose
        , null as primary_by_purpose
        , null as transposed_phone_number
)

, cte_final as (
    select *
    from cte_hz_contact_points

    union all

    select *
    from cte_union_default
)

select * from cte_final

with cte_fnd_lookup_values as (
    select
        lookup_type
        , lookup_code
        , meaning
        , enabled_flag
        , end_date_active
        , attribute1
        , attribute10
        , attribute11
        , attribute12
        , attribute13
        , attribute14
        , attribute15
        , attribute2
        , attribute3
        , attribute4
        , attribute5
        , attribute6
        , attribute7
        , attribute8
        , attribute9
        , attribute_category
        , created_by
        , creation_date
        , description
        , language
        , last_updated_by
        , last_update_date
        , _fivetran_synced
        , last_update_login
        , leaf_node
        , security_group_id
        , source_lang
        , start_date_active
        , tag
        , territory_code
        , view_application_id
        , zd_edition_name
        , zd_sync

    from {{ source('emtk_ebs_common__applsys', 'fnd_lookup_values') }}
    where enabled_flag = 'Y'
    and end_date_active is null
    and lookup_type <> ' PON_INIT_LIST_STATUS' -- has leading space making it a dupe of 'PON_INIT_LIST_STATUS'
    /*qualify to remove duplicated records and pull the most recent loaded version of unique lookup_codes _SRCC 2026-01-14*/
    qualify 1= row_number() over (partition by lookup_type, lookup_code, view_application_id, meaning order by _fivetran_synced desc)
)

select * from cte_fnd_lookup_values

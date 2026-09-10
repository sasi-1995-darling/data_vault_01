with cte_mtl_categories_b as (
    select
        category_id
        , structure_id
        , segment1
        , segment2
        , segment11
        , summary_flag
        , enabled_flag
        , attribute1
        , attribute2
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , creation_date
        , created_by
        , last_update_login
        , web_status
        , supplier_enabled_flag
        , zd_edition_name
        , zd_sync
    from {{ source('emtk_ebs_common__inv', 'mtl_categories_b') }}
    where _fivetran_deleted = false
)

, cte_mtl_categories_tl as (
    select
        category_id
        , language
        , source_lang
        , description
        , last_update_date
        , last_updated_by
        , creation_date
        , created_by
        , last_update_login
        , zd_edition_name
        , zd_sync
    from {{ source('emtk_ebs_common__inv', 'mtl_categories_tl') }}
    where _fivetran_deleted = false
        and language = 'US'
)

, cte_final as (
    select
        catb.category_id
        , catl.description
        , catb.structure_id
        , catb.segment1
        , catb.segment2
        , catb.segment11
        , catb.summary_flag
        , catb.enabled_flag
        , catb.attribute1
        , catb.attribute2
        , catb.last_update_date
        , catb._fivetran_synced
        , catb.last_updated_by
        , catb.creation_date
        , catb.created_by
        , catb.last_update_login
        , catb.web_status
        , catb.supplier_enabled_flag
        , catb.zd_edition_name
        , catb.zd_sync
        , catl.language
        , catl.source_lang
        , catl.last_update_date as tl_last_update_date
        , catl.last_updated_by as tl_last_updated_by
        , catl.creation_date as tl_creation_date
        , catl.created_by as tl_created_by
        , catl.last_update_login as tl_last_update_login
        , catl.zd_edition_name as tl_zd_edition_name
        , catl.zd_sync as tl_zd_sync
    from cte_mtl_categories_b as catb
        inner join cte_mtl_categories_tl as catl
            on catb.category_id = catl.category_id
)

select * from cte_final

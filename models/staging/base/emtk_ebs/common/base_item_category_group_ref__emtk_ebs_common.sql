with cte_mtl_category_sets_b as (
    select
        category_set_id
        , structure_id
        , validate_flag
        , control_level
        , default_category_id
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , creation_date
        , created_by
        , last_update_login
        , mult_item_cat_assign_flag
        , control_level_updateable_flag
        , mult_item_cat_updateable_flag
        , hierarchy_enabled
        , validate_flag_updateable_flag
        , user_creation_allowed_flag
        , raise_item_cat_assign_event
        , raise_alt_cat_hier_chg_event
        , raise_catalog_cat_chg_event
        , zd_edition_name
        , zd_sync
    from {{ source('emtk_ebs_common__inv', 'mtl_category_sets_b') }}
    where _fivetran_deleted = false
)

, cte_mtl_category_sets_tl as (
    select
        category_set_id
        , language
        , source_lang
        , category_set_name
        , description
        , last_update_date
        , last_updated_by
        , creation_date
        , created_by
        , last_update_login
        , zd_edition_name
        , zd_sync
    from {{ source('emtk_ebs_common__inv', 'mtl_category_sets_tl') }}
    where _fivetran_deleted = false
        and language = 'US'
)

, cte_final as (
    select
        csetb.category_set_id
        , csettl.category_set_name
        , csettl.description
        , csetb.structure_id
        , csetb.validate_flag
        , csetb.control_level
        , csetb.default_category_id
        , csetb.last_update_date
        , csetb._fivetran_synced
        , csetb.last_updated_by
        , csetb.creation_date
        , csetb.created_by
        , csetb.last_update_login
        , csetb.mult_item_cat_assign_flag
        , csetb.control_level_updateable_flag
        , csetb.mult_item_cat_updateable_flag
        , csetb.hierarchy_enabled
        , csetb.validate_flag_updateable_flag
        , csetb.user_creation_allowed_flag
        , csetb.raise_item_cat_assign_event
        , csetb.raise_alt_cat_hier_chg_event
        , csetb.raise_catalog_cat_chg_event
        , csetb.zd_edition_name
        , csetb.zd_sync
        , csettl.language
        , csettl.source_lang
        , csettl.last_update_date as tl_last_update_date
        , csettl.last_updated_by as tl_last_updated_by
        , csettl.creation_date as tl_creation_date
        , csettl.created_by as tl_created_by
        , csettl.last_update_login as tl_last_update_login
        , csettl.zd_edition_name as tl_zd_edition_name
        , csettl.zd_sync as tl_zd_sync
    from cte_mtl_category_sets_b as csetb
        inner join cte_mtl_category_sets_tl as csettl
            on csetb.category_set_id = csettl.category_set_id
)

select * from cte_final

with cte_mtl_system_items_tl as (
    select
        inventory_item_id
        , organization_id
        , language
        , source_lang
        , description
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , creation_date
        , created_by
        , last_update_login
        , long_description
    from {{ source('emtk_ebs_common__inv', 'mtl_system_items_tl') }}
    where _fivetran_deleted = false
)

, cte_item_base_bk as (
    select
        segment1 -- BK
        , inventory_item_id
        , organization_id
    from {{ source('emtk_ebs_common__inv', 'mtl_system_items_b') }}
    where _fivetran_deleted = false
)

, cte_ap_financials_system_params_all as (
    select
        inventory_organization_id --join filter
        , org_id --join filter
    from {{ source('emtk_ebs_sales__ap', 'financials_system_params_all') }}
    where _fivetran_deleted = false
)

, cte_duplicates as (
    select duplicate_victim
    from {{ ref('duplicate_victims') }}
    where source_system = 'emtk_ebs'
    and source_table = 'mtl_system_items_b'
    and field_name = 'inventory_item_id'        
)

, cte_final as (
    select
        fp.org_id -- BK
        , msi.segment1 -- BK
        , msit.inventory_item_id
        , msit.organization_id
        , msit.language
        , msit.source_lang
        , msit.description
        , msit.last_update_date
        , msit._fivetran_synced
        , msit.last_updated_by
        , msit.creation_date
        , msit.created_by
        , msit.last_update_login
        , msit.long_description
    from cte_mtl_system_items_tl as msit
        inner join cte_item_base_bk as msi
            on msit.inventory_item_id = msi.inventory_item_id
                and msit.organization_id = msi.organization_id
        inner join
            cte_ap_financials_system_params_all as fp
            on msi.organization_id = fp.inventory_organization_id
    where not exists (
            select 1 as constant
            from cte_duplicates as dup
            where dup.duplicate_victim = msi.inventory_item_id
        ) -- remove true duplicates
)

select * from cte_final

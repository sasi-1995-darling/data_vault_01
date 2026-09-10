with cte_mtl_item_categories as (
    select
        inventory_item_id
        , organization_id
        , category_set_id
        , category_id
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
    from {{ source('emtk_ebs_common__inv', 'mtl_item_categories') }}
    where _fivetran_deleted = false
)

, cte_ap_financials_system_params_all as (
    select
        inventory_organization_id --join filter
        , org_id --join filter
    from {{ source('emtk_ebs_sales__ap', 'financials_system_params_all') }}
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

, cte_duplicates as (
    select duplicate_victim
    from {{ ref('duplicate_victims') }}
    where source_system = 'emtk_ebs'
    and source_table = 'mtl_system_items_b'
    and field_name = 'inventory_item_id'        
)

, cte_final as (
    select
        fp.org_id -- hub BK
        , msi.segment1 -- hub BK
        , mic.category_set_id -- sat CDK
        , mic.category_id -- sat CDK
        , mic.inventory_item_id
        , mic.organization_id
        , mic.last_update_date
        , mic._fivetran_synced
        , mic.last_updated_by
        , mic.creation_date
        , mic.created_by
        , mic.last_update_login
        , mic.request_id
        , mic.program_application_id
        , mic.program_id
        , mic.program_update_date
    from cte_mtl_item_categories as mic
        inner join
            cte_ap_financials_system_params_all as fp
            on mic.organization_id = fp.inventory_organization_id
        inner join cte_item_base_bk as msi
            on mic.inventory_item_id = msi.inventory_item_id
                and mic.organization_id = msi.organization_id
    where not exists (
            select 1 as constant
            from cte_duplicates as dup
            where dup.duplicate_victim = msi.inventory_item_id
        ) -- remove true duplicates
)

select * from cte_final

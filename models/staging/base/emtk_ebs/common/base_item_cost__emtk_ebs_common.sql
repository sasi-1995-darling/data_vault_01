with cte_cst_item_costs as (
    select
        inventory_item_id --Join Key
        , organization_id -- Join Key
        , last_update_date
        , _fivetran_synced
        , creation_date
        , cost_type_id
        , item_cost
        , unburdened_cost
        , burden_cost
        , material_cost
        , material_overhead_cost

        , pl_material
        , pl_material_overhead
        , pl_outside_processing
        , pl_resource
        , pl_overhead
        , pl_item_cost

        , tl_material
        , tl_material_overhead
        , tl_outside_processing
        , tl_resource
        , tl_overhead
        , tl_item_cost

        , request_id
        , last_update_login
        , cost_update_id
        , last_updated_by
        , created_by
        , outside_processing_cost
        , overhead_cost
        , resource_cost
        , program_application_id
        , inventory_asset_flag
        , program_id
        , based_on_rollup_flag
        , shrinkage_rate
        , lot_size
        , defaulted_flag
        , program_update_date

    from {{ source('emtk_ebs_common__bom', 'cst_item_costs') }}
    where _fivetran_deleted = false
        and cost_type_id = 5 -- limit to FIFO cost type for unique BKs
)

, cte_item_bk_lookup as (
    select
        org_id -- BK
        , segment1 -- BK
        , organization_id -- Join key        
        , inventory_item_id -- Join key

    from {{ ref('base_item_base__emtk_ebs_common') }}
)

, cte_final as (
    select
        ibl.org_id -- BK
        , ibl.segment1 -- BK
        , cic.organization_id --  Join key          
        , cic.inventory_item_id -- Join key
        , cic.last_update_date
        , cic._fivetran_synced
        , cic.creation_date
        , cic.cost_type_id
        , cic.item_cost
        , cic.unburdened_cost
        , cic.burden_cost
        , cic.material_cost
        , cic.material_overhead_cost

        , cic.pl_material
        , cic.pl_material_overhead
        , cic.pl_outside_processing
        , cic.pl_resource
        , cic.pl_overhead
        , cic.pl_item_cost

        , cic.tl_material
        , cic.tl_material_overhead
        , cic.tl_outside_processing
        , cic.tl_resource
        , cic.tl_overhead
        , cic.tl_item_cost

        , cic.request_id
        , cic.last_update_login
        , cic.cost_update_id
        , cic.last_updated_by
        , cic.created_by
        , cic.outside_processing_cost
        , cic.overhead_cost
        , cic.resource_cost
        , cic.program_application_id
        , cic.inventory_asset_flag
        , cic.program_id
        , cic.based_on_rollup_flag
        , cic.shrinkage_rate
        , cic.lot_size
        , cic.defaulted_flag
        , cic.program_update_date

    from cte_cst_item_costs as cic
        inner join cte_item_bk_lookup as ibl -- inner join to keep just valid item bks
            on cic.inventory_item_id = ibl.inventory_item_id
                and cic.organization_id = ibl.organization_id
)

select * from cte_final

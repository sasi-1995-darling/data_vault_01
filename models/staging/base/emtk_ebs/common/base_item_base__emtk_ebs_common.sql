with cte_mtl_system_items_b as (
    select
        segment1 -- BK
        , inventory_item_id
        , organization_id
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , creation_date
        , created_by
        , last_update_login
        , summary_flag
        , description
        , attribute_category
        , attribute1
        , attribute2
        , attribute3
        , attribute4
        , attribute5
        , attribute6
        , attribute7
        , attribute8
        , attribute9
        , attribute11
        , attribute12
        , attribute13
        , attribute15
        , purchasing_item_flag
        , shippable_item_flag
        , customer_order_flag
        , internal_order_flag
        , inventory_item_flag
        , inventory_asset_flag
        , purchasing_enabled_flag
        , customer_order_enabled_flag
        , internal_order_enabled_flag
        , so_transactions_flag
        , mtl_transactions_enabled_flag
        , stock_enabled_flag
        , bom_enabled_flag
        , build_in_wip_flag
        , returnable_flag
        , taxable_flag
        , allow_item_desc_update_flag
        , receipt_required_flag
        , list_price_per_unit
        , price_tolerance_percent
        , expense_account
        , encumbrance_account
        , unit_weight
        , weight_uom_code
        , end_assembly_pegging_flag
        , replenish_to_order_flag
        , wip_supply_type
        , wip_supply_subinventory
        , primary_uom_code
        , primary_unit_of_measure
        , allowed_units_lookup_code
        , cost_of_sales_account
        , sales_account
        , default_include_in_rollup_flag
        , inventory_item_status_code
        , planning_make_buy_code
        , rounding_control_type
        , min_minmax_quantity
        , reservable_type
        , invoiceable_item_flag
        , invoice_enabled_flag
        , request_id
        , program_application_id
        , program_id
        , program_update_date
        , costing_enabled_flag
        , cycle_count_enabled_flag
        , item_type
        , mrp_planning_code
        , ato_forecast_control
        , check_shortages_flag
        , orderable_on_web_flag
        , back_orderable_flag
        , web_status
        , object_version_number
        , ont_pricing_qty_source
        , attribute16
        , attribute17
        , process_execution_enabled_flag
        , recipe_enabled_flag
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

, cte_union_default as (
    /* because inventory_item_id can be NULL on ra_customer_trx_lines_all */
    select
        -1 as org_id
        , '-1' as segment1 -- BK
        , null as inventory_item_id -- BK
        , null as organization_id
        , null as last_update_date
        , '1900-01-01' as _fivetran_synced
        , null as last_updated_by
        , null as creation_date
        , null as created_by
        , null as last_update_login
        , null as summary_flag
        , null as description
        , null as attribute_category
        , null as attribute1
        , null as attribute2
        , null as attribute3
        , null as attribute4
        , null as attribute5
        , null as attribute6
        , null as attribute7
        , null as attribute8
        , null as attribute9
        , null as attribute11
        , null as attribute12
        , null as attribute13
        , null as attribute15
        , null as purchasing_item_flag
        , null as shippable_item_flag
        , null as customer_order_flag
        , null as internal_order_flag
        , null as inventory_item_flag
        , null as inventory_asset_flag
        , null as purchasing_enabled_flag
        , null as customer_order_enabled_flag
        , null as internal_order_enabled_flag
        , null as so_transactions_flag
        , null as mtl_transactions_enabled_flag
        , null as stock_enabled_flag
        , null as bom_enabled_flag
        , null as build_in_wip_flag
        , null as returnable_flag
        , null as taxable_flag
        , null as allow_item_desc_update_flag
        , null as receipt_required_flag
        , null as list_price_per_unit
        , null as price_tolerance_percent
        , null as expense_account
        , null as encumbrance_account
        , null as unit_weight
        , null as weight_uom_code
        , null as end_assembly_pegging_flag
        , null as replenish_to_order_flag
        , null as wip_supply_type
        , null as wip_supply_subinventory
        , null as primary_uom_code
        , null as primary_unit_of_measure
        , null as allowed_units_lookup_code
        , null as cost_of_sales_account
        , null as sales_account
        , null as default_include_in_rollup_flag
        , null as inventory_item_status_code
        , null as planning_make_buy_code
        , null as rounding_control_type
        , null as min_minmax_quantity
        , null as reservable_type
        , null as invoiceable_item_flag
        , null as invoice_enabled_flag
        , null as request_id
        , null as program_application_id
        , null as program_id
        , null as program_update_date
        , null as costing_enabled_flag
        , null as cycle_count_enabled_flag
        , null as item_type
        , null as mrp_planning_code
        , null as ato_forecast_control
        , null as check_shortages_flag
        , null as orderable_on_web_flag
        , null as back_orderable_flag
        , null as web_status
        , null as object_version_number
        , null as ont_pricing_qty_source
        , null as attribute16
        , null as attribute17
        , null as process_execution_enabled_flag
        , null as recipe_enabled_flag
)

, cte_final as (
    select
        fp.org_id -- BK
        , msi.segment1 -- BK
        , msi.inventory_item_id
        , msi.organization_id
        , msi.last_update_date
        , msi._fivetran_synced
        , msi.last_updated_by
        , msi.creation_date
        , msi.created_by
        , msi.last_update_login
        , msi.summary_flag
        , msi.description
        , msi.attribute_category
        , msi.attribute1
        , msi.attribute2
        , msi.attribute3
        , msi.attribute4
        , msi.attribute5
        , msi.attribute6
        , msi.attribute7
        , msi.attribute8
        , msi.attribute9
        , msi.attribute11
        , msi.attribute12
        , msi.attribute13
        , msi.attribute15
        , msi.purchasing_item_flag
        , msi.shippable_item_flag
        , msi.customer_order_flag
        , msi.internal_order_flag
        , msi.inventory_item_flag
        , msi.inventory_asset_flag
        , msi.purchasing_enabled_flag
        , msi.customer_order_enabled_flag
        , msi.internal_order_enabled_flag
        , msi.so_transactions_flag
        , msi.mtl_transactions_enabled_flag
        , msi.stock_enabled_flag
        , msi.bom_enabled_flag
        , msi.build_in_wip_flag
        , msi.returnable_flag
        , msi.taxable_flag
        , msi.allow_item_desc_update_flag
        , msi.receipt_required_flag
        , msi.list_price_per_unit
        , msi.price_tolerance_percent
        , msi.expense_account
        , msi.encumbrance_account
        , msi.unit_weight
        , msi.weight_uom_code
        , msi.end_assembly_pegging_flag
        , msi.replenish_to_order_flag
        , msi.wip_supply_type
        , msi.wip_supply_subinventory
        , msi.primary_uom_code
        , msi.primary_unit_of_measure
        , msi.allowed_units_lookup_code
        , msi.cost_of_sales_account
        , msi.sales_account
        , msi.default_include_in_rollup_flag
        , msi.inventory_item_status_code
        , msi.planning_make_buy_code
        , msi.rounding_control_type
        , msi.min_minmax_quantity
        , msi.reservable_type
        , msi.invoiceable_item_flag
        , msi.invoice_enabled_flag
        , msi.request_id
        , msi.program_application_id
        , msi.program_id
        , msi.program_update_date
        , msi.costing_enabled_flag
        , msi.cycle_count_enabled_flag
        , msi.item_type
        , msi.mrp_planning_code
        , msi.ato_forecast_control
        , msi.check_shortages_flag
        , msi.orderable_on_web_flag
        , msi.back_orderable_flag
        , msi.web_status
        , msi.object_version_number
        , msi.ont_pricing_qty_source
        , msi.attribute16
        , msi.attribute17
        , msi.process_execution_enabled_flag
        , msi.recipe_enabled_flag
    from
        cte_mtl_system_items_b as msi
        inner join
            cte_ap_financials_system_params_all as fp
            on msi.organization_id = fp.inventory_organization_id
    where not exists (
            select 1 as constant
            from cte_duplicates as dup
            where dup.duplicate_victim = msi.inventory_item_id
        ) -- remove true duplicates

    union all

    select * from cte_union_default
)

select * from cte_final

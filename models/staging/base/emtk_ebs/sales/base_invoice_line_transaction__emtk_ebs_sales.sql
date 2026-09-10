/*
    Transactional LINK: Invoice-line Transaction
*/

with
cte_ra_customer_trx_lines_all as (
    select
        customer_trx_line_id::varchar as customer_trx_line_id -- BK
        , interface_line_attribute6
        , interface_line_attribute3
        , creation_date
    from {{ source('emtk_ebs_sales__ar', 'ra_customer_trx_lines_all') }}
    where _fivetran_deleted = false
)

, cte_mtl_material_transactions as (
    select
        transaction_id::varchar as transaction_id
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
        , inventory_item_id
        , organization_id
        , subinventory_code
        , transaction_type_id
        , transaction_action_id
        , transaction_source_type_id
        , transaction_source_id
        , transaction_source_name
        , transaction_quantity
        , transaction_uom
        , primary_quantity
        , transaction_date
        , variance_amount
        , acct_period_id
        , transaction_reference
        , reason_id
        , distribution_account_id
        , transaction_group_id
        , actual_cost
        , transaction_cost
        , prior_cost
        , new_cost
        , currency_conversion_date
        , quantity_adjusted
        , operation_seq_num
        , picking_line_id
        , trx_source_line_id
        , trx_source_delivery_id
        , physical_adjustment_id
        , transfer_transaction_id
        , transaction_set_id
        , rcv_transaction_id
        , completion_transaction_id
        , source_code
        , source_line_id
        , vendor_lot_number
        , transfer_organization_id
        , transfer_subinventory
        , shipment_number
        , freight_code
        , prior_costed_quantity
        , final_completion_flag
        , material_account
        , material_overhead_account
        , resource_account
        , outside_processing_account
        , overhead_account
        , cost_group_id
        , transfer_cost_group_id
        , move_order_line_id
        , pick_slip_number
        , cost_category_id
        , owning_organization_id
        , xfr_owning_organization_id
        , planning_organization_id
        , xfr_planning_organization_id
        , ship_to_location_id
        , transaction_mode
        , transaction_batch_id
        , transaction_batch_seq
        , parent_transaction_id
        , original_transaction_temp_id
        , cogs_recognition_percent
    from {{ source('emtk_ebs_sales__inv', 'mtl_material_transactions') }}
    where _fivetran_deleted = false
    -- limiting to type of "Sales order issue" for performance              
        and transaction_type_id = 33
)

, cte_final as (
    select
        rctla.customer_trx_line_id
        , mtt.transaction_id
        , mtt.trx_source_line_id --join keys
        , mtt.trx_source_delivery_id --join keys
        -- all fields from mtl_material_transactions
        , mtt.last_update_date
        , mtt._fivetran_synced
        , mtt.last_updated_by
        , mtt.creation_date
        , mtt.created_by
        , mtt.last_update_login
        , mtt.request_id
        , mtt.program_application_id
        , mtt.program_id
        , mtt.program_update_date
        , mtt.inventory_item_id
        , mtt.organization_id
        , mtt.subinventory_code
        , mtt.transaction_type_id
        , mtt.transaction_action_id
        , mtt.transaction_source_type_id
        , mtt.transaction_source_id
        , mtt.transaction_source_name
        , mtt.transaction_quantity
        , mtt.transaction_uom
        , mtt.primary_quantity
        , mtt.transaction_date
        , mtt.variance_amount
        , mtt.acct_period_id
        , mtt.transaction_reference
        , mtt.reason_id
        , mtt.distribution_account_id
        , mtt.transaction_group_id
        , mtt.actual_cost
        , mtt.transaction_cost
        , mtt.prior_cost
        , mtt.new_cost
        , mtt.currency_conversion_date
        , mtt.quantity_adjusted
        , mtt.operation_seq_num
        , mtt.picking_line_id
        , mtt.physical_adjustment_id
        , mtt.transfer_transaction_id
        , mtt.transaction_set_id
        , mtt.rcv_transaction_id
        , mtt.completion_transaction_id
        , mtt.source_code
        , mtt.source_line_id
        , mtt.vendor_lot_number
        , mtt.transfer_organization_id
        , mtt.transfer_subinventory
        , mtt.shipment_number
        , mtt.freight_code
        , mtt.prior_costed_quantity
        , mtt.final_completion_flag
        , mtt.material_account
        , mtt.material_overhead_account
        , mtt.resource_account
        , mtt.outside_processing_account
        , mtt.overhead_account
        , mtt.cost_group_id
        , mtt.transfer_cost_group_id
        , mtt.move_order_line_id
        , mtt.pick_slip_number
        , mtt.cost_category_id
        , mtt.owning_organization_id
        , mtt.xfr_owning_organization_id
        , mtt.planning_organization_id
        , mtt.xfr_planning_organization_id
        , mtt.ship_to_location_id
        , mtt.transaction_mode
        , mtt.transaction_batch_id
        , mtt.transaction_batch_seq
        , mtt.parent_transaction_id
        , mtt.original_transaction_temp_id
        , mtt.cogs_recognition_percent
    from cte_ra_customer_trx_lines_all as rctla
        inner join cte_mtl_material_transactions as mtt
            on try_to_number(rctla.interface_line_attribute6) = mtt.trx_source_line_id
                and try_to_number(rctla.interface_line_attribute3) = mtt.trx_source_delivery_id
                and to_date(mtt.transaction_date) = to_date(rctla.creation_date)

)

select * from cte_final

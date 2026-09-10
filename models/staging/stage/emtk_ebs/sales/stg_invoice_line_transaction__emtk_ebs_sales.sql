{%- set yaml_metadata -%}
source_model: 'base_invoice_line_transaction__emtk_ebs_sales'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  invoice_line_bk: 'customer_trx_line_id'
  invoice_line_transaction_bk: ['customer_trx_line_id', 'transaction_id']
hashed_columns:
  invoice_line_hk: 
    columns:
    - 'invoice_line_bk'
    - 'brand'
  invoice_line_transaction_hk: 
    columns:
    - 'invoice_line_transaction_bk'
    - 'brand'
  invoice_line_transaction_hdiff:
    is_hashdiff: true
    columns:
    - 'customer_trx_line_id'
    - 'transaction_id'
    - 'trx_source_line_id'
    - 'trx_source_delivery_id '
    - 'last_update_date'
    - 'last_updated_by'
    - 'creation_date'
    - 'created_by'
    - 'last_update_login'
    - 'request_id'
    - 'program_application_id'
    - 'program_id'
    - 'program_update_date'
    - 'inventory_item_id'
    - 'organization_id'
    - 'subinventory_code'
    - 'transaction_type_id'
    - 'transaction_action_id'
    - 'transaction_source_type_id'
    - 'transaction_source_id'
    - 'transaction_source_name'
    - 'transaction_quantity'
    - 'transaction_uom'
    - 'primary_quantity'
    - 'transaction_date'
    - 'variance_amount'
    - 'acct_period_id'
    - 'transaction_reference'
    - 'reason_id'
    - 'distribution_account_id'
    - 'transaction_group_id'
    - 'actual_cost'
    - 'transaction_cost'
    - 'prior_cost'
    - 'new_cost'
    - 'currency_conversion_date'
    - 'quantity_adjusted'
    - 'operation_seq_num'
    - 'picking_line_id'
    - 'physical_adjustment_id'
    - 'transfer_transaction_id'
    - 'transaction_set_id'
    - 'rcv_transaction_id'
    - 'completion_transaction_id'
    - 'source_code'
    - 'source_line_id'
    - 'vendor_lot_number'
    - 'transfer_organization_id'
    - 'transfer_subinventory'
    - 'shipment_number'
    - 'freight_code'
    - 'prior_costed_quantity'
    - 'final_completion_flag'
    - 'material_account'
    - 'material_overhead_account'
    - 'resource_account'
    - 'outside_processing_account'
    - 'overhead_account'
    - 'cost_group_id'
    - 'transfer_cost_group_id'
    - 'move_order_line_id'
    - 'pick_slip_number'
    - 'cost_category_id'
    - 'owning_organization_id'
    - 'xfr_owning_organization_id'
    - 'planning_organization_id'
    - 'xfr_planning_organization_id'
    - 'ship_to_location_id'
    - 'transaction_mode'
    - 'transaction_batch_id'
    - 'transaction_batch_seq'
    - 'parent_transaction_id'
    - 'original_transaction_temp_id'
    - 'cogs_recognition_percent'

    
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict['source_model'] %}
{% set derived_columns = metadata_dict['derived_columns'] %}
{% set hashed_columns = metadata_dict['hashed_columns'] %}

{{ automate_dv.stage(include_source_columns=true,
                     source_model=source_model,
                     derived_columns=derived_columns,
                     null_columns=none,
                     hashed_columns=hashed_columns,
                     ranked_columns=none) }}

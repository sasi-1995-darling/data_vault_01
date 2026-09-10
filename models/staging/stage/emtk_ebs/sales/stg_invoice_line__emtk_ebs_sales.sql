{%- set yaml_metadata -%}
source_model: 'base_invoice_line__emtk_ebs_sales'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  invoice_line_bk: to_char(customer_trx_line_id)
  item_bk: ['item_org_id', 'item_segment1']
  invoice_line_item_bk: ['customer_trx_line_id', 'item_org_id', 'item_segment1']
hashed_columns:
  invoice_line_hk: 
    columns:
    - 'invoice_line_bk'
    - 'brand'
  item_hk:
    columns:
    - 'item_bk'
    - 'brand'
  invoice_line_item_hk:
    columns:
    - 'invoice_line_item_bk'
    - 'brand'
  invoice_line_hdiff:
    is_hashdiff: true
    columns:
    - 'customer_trx_line_id'
    - 'customer_trx_id'
    - 'last_update_date'
    - 'last_updated_by'
    - 'creation_date'
    - 'created_by'
    - 'last_update_login'
    - 'line_number'
    - 'reason_code'
    - 'inventory_item_id'
    - 'description'
    - 'previous_customer_trx_id'
    - 'previous_customer_trx_line_id'
    - 'quantity_ordered'
    - 'quantity_credited'
    - 'quantity_invoiced'
    - 'unit_standard_price'
    - 'unit_selling_price'
    - 'sales_order'
    - 'sales_order_line'
    - 'sales_order_date'
    - 'line_type'
    - 'attribute1'
    - 'attribute2'
    - 'attribute3'
    - 'attribute4'
    - 'attribute5'
    - 'attribute6'
    - 'attribute7'
    - 'attribute8'
    - 'attribute9'
    - 'attribute10'
    - 'request_id'
    - 'program_application_id'
    - 'program_id'
    - 'program_update_date'
    - 'rule_start_date'
    - 'interface_line_context'
    - 'interface_line_attribute1'
    - 'interface_line_attribute2'
    - 'interface_line_attribute3'
    - 'interface_line_attribute4'
    - 'interface_line_attribute5'
    - 'interface_line_attribute6'
    - 'extended_amount'
    - 'revenue_amount'
    - 'link_to_cust_trx_line_id'
    - 'attribute11'
    - 'attribute12'
    - 'attribute13'
    - 'attribute14'
    - 'attribute15'
    - 'tax_rate'
    - 'tax_exemption_id'
    - 'memo_line_id'
    - 'uom_code'
    - 'interface_line_attribute10'
    - 'interface_line_attribute12'
    - 'interface_line_attribute9'
    - 'vat_tax_id'
    - 'autotax'
    - 'tax_exempt_flag'
    - 'tax_exempt_number'
    - 'sales_tax_id'
    - 'location_segment_id'
    - 'org_id'
    - 'taxable_amount'
    - 'warehouse_id'
    - 'translated_description'
    - 'payment_set_id'
    - 'ship_to_customer_id'
    - 'ship_to_address_id'
    - 'ship_to_site_use_id'
    - 'tax_line_id'
    - 'line_recoverable'
    - 'tax_recoverable'
    - 'tax_classification_code'
    - 'amount_due_original'
    - 'acctd_amount_due_original'
    - 'payment_trxn_extension_id'
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

{%- set yaml_metadata -%}
source_model: 'base_invoice__emtk_ebs_sales'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  invoice_bk: ['org_id', 'trx_number', 'interface_header_attribute1']
  sales_agency_bk: ['org_id', 'salesrep_number']
  invoice_sales_agency_bk: ['org_id', 'trx_number', 'interface_header_attribute1', 'salesrep_number']
hashed_columns:
  invoice_hk: 
    columns:
    - 'invoice_bk'
    - 'brand'
  sales_agency_hk: 
    columns:
    - 'sales_agency_bk'
    - 'brand'
  invoice_sales_agency_hk:
    - 'invoice_sales_agency_bk'
    - 'brand'
  invoice_hdiff:
    is_hashdiff: true
    columns:
    - 'org_id'
    - 'trx_number'
    - 'interface_header_attribute1'
    - 'interface_header_attribute2'
    - 'cust_trx_type_id'
    - 'transaction_type'
    - 'customer_trx_id'
    - 'trx_date'
    - 'last_update_date'
    - 'last_updated_by'
    - 'creation_date'
    - 'created_by'
    - 'last_update_login'
    - 'bill_to_contact_id'
    - 'batch_id'
    - 'batch_source_id'
    - 'reason_code'
    - 'sold_to_customer_id'
    - 'bill_to_customer_id'
    - 'bill_to_site_use_id'
    - 'ship_to_customer_id'
    - 'ship_to_contact_id'
    - 'ship_to_site_use_id'
    - 'remit_to_address_id'
    - 'term_id'
    - 'term_due_date'
    - 'previous_customer_trx_id'
    - 'primary_salesrep_id'
    - 'printing_original_date'
    - 'printing_last_printed'
    - 'printing_option'
    - 'printing_count'
    - 'printing_pending'
    - 'purchase_order'
    - 'customer_reference'
    - 'customer_reference_date'
    - 'territory_id'
    - 'attribute1'
    - 'attribute2'
    - 'attribute3'
    - 'attribute4'
    - 'attribute5'
    - 'attribute6'
    - 'attribute8'
    - 'attribute9'
    - 'attribute10'
    - 'orig_system_batch_name'
    - 'request_id'
    - 'program_application_id'
    - 'program_id'
    - 'program_update_date'
    - 'complete_flag'
    - 'receipt_method_id'
    - 'attribute11'
    - 'attribute12'
    - 'attribute13'
    - 'attribute14'
    - 'attribute15'
    - 'ship_via'
    - 'ship_date_actual'
    - 'fob_point'
    - 'customer_bank_account_id'
    - 'interface_header_attribute3'
    - 'interface_header_attribute4'
    - 'interface_header_attribute5'
    - 'interface_header_attribute6'
    - 'interface_header_context'
    - 'interface_header_attribute10'
    - 'interface_header_attribute12'
    - 'interface_header_attribute9'
    - 'status_trx'
    - 'doc_sequence_value'
    - 'paying_customer_id'
    - 'paying_site_use_id'
    - 'created_from'
    - 'payment_server_order_num'
    - 'approval_code'
    - 'ct_reference'
    - 'bill_template_id'
    - 'upgrade_method'
    - 'legal_entity_id'
    - 'payment_trxn_extension_id'
    - 'payment_attributes'

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

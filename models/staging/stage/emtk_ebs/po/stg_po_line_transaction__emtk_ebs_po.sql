{%- set yaml_metadata -%}
source_model: 'base_po_line_transaction__emtk_ebs_po'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  po_line_transaction_bk: 'transaction_id' 
  po_line_bk: 'po_line_id'  
hashed_columns:
  po_line_transaction_link_hk:
    columns:
    - 'po_line_transaction_bk'
    - 'po_line_bk'
    - 'brand'    
  po_line_transaction_hk: 
    columns:
    - 'po_line_transaction_bk'
    - 'brand'        
  po_line_hk: 
    columns:
    - 'po_line_bk'
    - 'brand'    
  po_line_transaction_hdiff:
    is_hashdiff: true
    columns:
    - 'transaction_id'
    - 'po_line_id'
    - 'last_update_date'
    - 'last_updated_by'
    - 'creation_date'
    - 'created_by'
    - 'last_update_login'
    - 'request_id'
    - 'program_application_id'
    - 'program_id'
    - 'program_update_date'
    - 'transaction_type'
    - 'transaction_date'
    - 'quantity'
    - 'unit_of_measure'
    - 'shipment_header_id'
    - 'shipment_num'
    - 'shipped_date'
    - 'shipment_line_id'
    - 'user_entered_flag'
    - 'source_document_code'
    - 'destination_type_code'
    - 'primary_quantity'
    - 'primary_unit_of_measure'
    - 'uom_code'
    - 'employee_id'
    - 'parent_transaction_id'
    - 'po_header_id'
    - 'po_line_location_id'
    - 'po_distribution_id'
    - 'po_revision_num'
    - 'po_unit_price'
    - 'currency_conversion_date'
    - 'routing_header_id'
    - 'deliver_to_person_id'
    - 'deliver_to_location_id'
    - 'vendor_id'
    - 'vendor_site_id'
    - 'organization_id'
    - 'subinventory'
    - 'location_id'
    - 'inspection_status_code'
    - 'vendor_lot_num'
    - 'rma_reference'
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
    - 'attribute11'
    - 'attribute12'
    - 'attribute13'
    - 'attribute14'
    - 'attribute15'
    - 'reason_id'
    - 'destination_context'
    - 'source_doc_unit_of_measure'
    - 'source_doc_quantity'
    - 'interface_transaction_id'
    - 'group_id'
    - 'country_of_origin_code'
    - 'oe_order_header_id'
    - 'oe_order_line_id'
    - 'customer_id'
    - 'customer_site_id'
    - 'from_subinventory'   

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

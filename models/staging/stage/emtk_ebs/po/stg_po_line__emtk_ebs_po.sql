{%- set yaml_metadata -%}
source_model: 'base_po_line__emtk_ebs_po'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  po_line_bk: 'po_line_id'  
  purchase_order_bk: ['po_header_org_id', 'po_header_segment1']
hashed_columns:
  po_line_link_hk:
    columns:
    - 'po_line_bk'
    - 'purchase_order_bk'
    - 'brand'    
  po_line_hk: 
    columns:
    - 'po_line_bk'
    - 'brand'    
  purchase_order_hk:
    columns:
    - 'purchase_order_bk'
    - 'brand'    
  po_line_hdiff:
    is_hashdiff: true
    columns:
    - 'po_line_id'
    - 'po_header_org_id'
    - 'po_header_segment1'
    - 'last_update_date'
    - 'last_updated_by'
    - 'po_header_id'
    - 'line_type_id'
    - 'line_num'
    - 'last_update_login'
    - 'creation_date'
    - 'created_by'
    - 'item_id'
    - 'category_id'
    - 'item_description'
    - 'unit_meas_lookup_code'
    - 'quantity_committed'
    - 'list_price_per_unit'
    - 'unit_price'
    - 'quantity'
    - 'note_to_vendor'
    - 'qty_rcv_tolerance'
    - 'over_tolerance_error_flag'
    - 'cancel_flag'
    - 'cancelled_by'
    - 'cancel_date'
    - 'vendor_product_num'
    - 'capital_expense_flag'
    - 'negotiated_by_preparer_flag'
    - 'attribute1'
    - 'price_type_lookup_code'
    - 'closed_code'
    - 'request_id'
    - 'program_application_id'
    - 'program_id'
    - 'program_update_date'
    - 'closed_date'
    - 'closed_by'
    - 'po_line_org_id'
    - 'retroactive_date'
    - 'contract_id'
    - 'order_type_lookup_code'
    - 'purchase_basis'
    - 'base_unit_price'
    - 'manual_price_change_flag'
    - 'clm_total_amount_ordered'
    - 'po_header_org_id'
    - 'po_header_segment1'

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

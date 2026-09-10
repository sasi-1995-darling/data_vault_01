{%- set yaml_metadata -%}
source_model: 'base_purchase_order__emtk_ebs_po'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  purchase_order_bk: ['org_id', 'poh_segment1']
  supplier_bk: 'sup_segment1'
  supplier_site_bk: 'vendor_site_id'      
hashed_columns:
  po_supplier_link_hk:
    columns:
    - 'purchase_order_bk'
    - 'supplier_bk'
    - 'supplier_site_bk'
    - 'brand'    
  purchase_order_hk: 
    columns:
    - 'purchase_order_bk'
    - 'brand'      
  supplier_hk: 
    columns:
    - 'supplier_bk'
    - 'brand'    
  supplier_site_hk: 
    columns:
    - 'supplier_site_bk'
    - 'brand'        
  purchase_order_hdiff:
    is_hashdiff: true
    columns:
    - 'org_id'
    - 'poh_segment1'  
    - 'sup_segment1'
    - 'vendor_site_id'
    - 'po_header_id'
    - 'agent_id'
    - 'full_name'
    - 'type_lookup_code'
    - 'last_update_date'
    - 'last_updated_by'
    - 'last_update_login'
    - 'creation_date'
    - 'created_by'
    - 'vendor_id'
    - 'vendor_contact_id'
    - 'ship_to_location_id'
    - 'bill_to_location_id'
    - 'terms_id'
    - 'fob_lookup_code'
    - 'freight_terms_lookup_code'
    - 'rate_date'
    - 'from_header_id'
    - 'start_date'
    - 'authorization_status'
    - 'revision_num'
    - 'revised_date'
    - 'approved_flag'
    - 'approved_date'
    - 'note_to_vendor'
    - 'note_to_receiver'
    - 'print_count'
    - 'printed_date'
    - 'confirming_order_flag'
    - 'comments'
    - 'acceptance_required_flag'
    - 'closed_date'
    - 'user_hold_flag'
    - 'cancel_flag'
    - 'frozen_flag'
    - 'attribute15'
    - 'closed_code'
    - 'request_id'
    - 'program_application_id'
    - 'program_id'
    - 'program_update_date'
    - 'wf_item_key'
    - 'change_summary'
    - 'document_creation_method'
    - 'submit_date'
    - 'supplier_notif_method'
    - 'email_address'
    - 'clm_effective_date'
    - 'clm_document_number'

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

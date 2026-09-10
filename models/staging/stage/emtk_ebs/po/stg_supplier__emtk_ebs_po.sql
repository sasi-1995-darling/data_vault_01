{%- set yaml_metadata -%}
source_model: 'base_supplier__emtk_ebs_po'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  supplier_bk: 'segment1'
hashed_columns:
  supplier_hk: 
    columns:
    - 'supplier_bk'
    - 'brand'  
  supplier_hdiff:
    is_hashdiff: true
    columns:
    - 'segment1'    
    - 'vendor_id'
    - 'last_update_date'
    - 'last_updated_by'
    - 'vendor_name'
    - 'vendor_name_alt'
    - 'last_update_login'
    - 'creation_date'
    - 'created_by'
    - 'vendor_type_lookup_code'
    - 'one_time_flag'
    - 'bill_to_location_id'
    - 'terms_id'
    - 'always_take_disc_flag'
    - 'pay_date_basis_lookup_code'
    - 'pay_group_lookup_code'
    - 'num_1099'
    - 'start_date_active'
    - 'payment_method_lookup_code'
    - 'qty_rcv_tolerance'
    - 'qty_rcv_exception_code'
    - 'enforce_ship_to_location_code'
    - 'receipt_days_exception_code'
    - 'receiving_routing_id'
    - 'state_reportable_flag'
    - 'federal_reportable_flag'
    - 'attribute1'
    - 'program_update_date'
    - 'tax_reporting_name'
    - 'party_id'
    - 'tca_sync_num_1099'
    - 'tca_sync_vendor_name'
    - 'tca_sync_vat_reg_num'

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

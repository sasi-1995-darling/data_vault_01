{%- set yaml_metadata -%}
source_model: 'base_supplier_site__emtk_ebs_po'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  supplier_site_bk: 'vendor_site_id'
hashed_columns:
  supplier_site_hk: 
    columns:
    - 'supplier_site_bk'
    - 'brand'      
  supplier_site_hdiff:
    is_hashdiff: true
    columns:
    - 'vendor_site_id'
    - 'last_update_date'
    - 'last_updated_by'
    - 'vendor_id'
    - 'vendor_site_code'
    - 'vendor_site_code_alt'
    - 'last_update_login'
    - 'creation_date'
    - 'created_by'
    - 'purchasing_site_flag'
    - 'rfq_only_site_flag'
    - 'pay_site_flag'
    - 'address_line1'
    - 'address_lines_alt'
    - 'address_line2'
    - 'address_line3'
    - 'city'
    - 'state'
    - 'zip'
    - 'province'
    - 'country'
    - 'area_code'
    - 'phone'
    - 'ship_to_location_id'
    - 'bill_to_location_id'
    - 'freight_terms_lookup_code'
    - 'inactive_date'
    - 'fax'
    - 'fax_area_code'
    - 'telex'
    - 'payment_method_lookup_code'
    - 'accts_pay_code_combination_id'
    - 'prepay_code_combination_id'
    - 'pay_group_lookup_code'
    - 'terms_id'
    - 'pay_date_basis_lookup_code'
    - 'always_take_disc_flag'
    - 'ap_tax_rounding_rule'
    - 'tax_reporting_site_flag'
    - 'attribute1'
    - 'program_update_date'
    - 'org_id'
    - 'address_line4'
    - 'county'
    - 'address_style'
    - 'tp_header_id'
    - 'ece_tp_location_code'
    - 'country_of_origin_code'
    - 'supplier_notif_method'
    - 'email_address'
    - 'primary_pay_site_flag'
    - 'location_id'
    - 'party_site_id'
    - 'tca_sync_state'
    - 'tca_sync_province'
    - 'tca_sync_county'
    - 'tca_sync_city'
    - 'tca_sync_zip'
    - 'tca_sync_country'
    - 'legal_business_name'

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

{%- set yaml_metadata -%}
source_model: 'base_customer_ship_location__emtk_ebs_sales'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  customer_ship_location_bk: 'location_id'
hashed_columns:
  customer_ship_location_hk: 
    columns:
    - 'customer_ship_location_bk'
    - 'brand'
  customer_ship_location_hdiff:
    is_hashdiff: true
    columns:
    - 'location_id'
    - 'location'
    - 'site_use_id'
    - 'last_update_date'
    - 'last_updated_by'
    - 'creation_date'
    - 'created_by'
    - 'last_update_login'
    - 'request_id'
    - 'program_application_id'
    - 'program_id'
    - 'program_update_date'
    - 'orig_system_reference'
    - 'country'
    - 'address1'
    - 'address2'
    - 'address3'
    - 'address4'
    - 'city'
    - 'postal_code'
    - 'state'
    - 'province'
    - 'county'
    - 'address_key'
    - 'address_style'
    - 'address_lines_phonetic'
    - 'address_effective_date'
    - 'object_version_number'
    - 'created_by_module'
    - 'application_id'
    - 'timezone_id'

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

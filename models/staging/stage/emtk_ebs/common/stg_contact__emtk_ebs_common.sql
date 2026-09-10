{%- set yaml_metadata -%}
source_model: 'base_contact__emtk_ebs_common'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  contact_bk: 'contact_point_id'
hashed_columns:
  contact_hk: 
    columns:
    - 'contact_bk'
    - 'brand'      
  contact_hdiff:
    is_hashdiff: true
    columns:
    - 'contact_point_id'
    - 'contact_point_type'
    - 'status'
    - 'owner_table_name'
    - 'owner_table_id'
    - 'primary_flag'
    - 'orig_system_reference'
    - 'last_update_date'
    - 'last_updated_by'
    - 'creation_date'
    - 'created_by'
    - 'last_update_login'
    - 'request_id'
    - 'program_application_id'
    - 'program_id'
    - 'program_update_date'
    - 'email_format'
    - 'email_address'
    - 'phone_area_code'
    - 'phone_country_code'
    - 'phone_number'
    - 'phone_extension'
    - 'phone_line_type'
    - 'raw_phone_number'
    - 'object_version_number'
    - 'created_by_module'
    - 'application_id'
    - 'contact_point_purpose'
    - 'primary_by_purpose'
    - 'transposed_phone_number'   
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

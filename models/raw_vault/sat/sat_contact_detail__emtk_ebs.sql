{%- set yaml_metadata -%}
source_model: 'stg_contact__emtk_ebs_common'
src_pk: 
    - 'contact_hk'
src_hashdiff: 'contact_hdiff'
src_payload:
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
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict['source_model'] %}
{% set src_pk = metadata_dict['src_pk'] %}
{% set src_hashdiff = metadata_dict['src_hashdiff'] %}
{% set src_payload = metadata_dict['src_payload'] %}
{% set src_ldts = metadata_dict['src_ldts'] %}
{% set src_source = metadata_dict['src_source'] %}


{{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                   src_payload=src_payload, src_eff=none,
                   src_ldts=src_ldts, src_source=src_source,
                   source_model=source_model) }}

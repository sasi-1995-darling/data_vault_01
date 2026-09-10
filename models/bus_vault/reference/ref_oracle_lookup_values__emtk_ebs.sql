{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: 'stg_oracle_lookup_values__emtk_ebs_common'
src_pk: 'oracle_lookup_hk'
src_extra_columns: 
    - 'lookup_type'
    - 'lookup_code'
    - 'meaning'
    - 'enabled_flag'
    - 'end_date_active'
    - 'attribute1'
    - 'attribute10'
    - 'attribute11'
    - 'attribute12'
    - 'attribute13'
    - 'attribute14'
    - 'attribute15'
    - 'attribute2'
    - 'attribute3'
    - 'attribute4'
    - 'attribute5'
    - 'attribute6'
    - 'attribute7'
    - 'attribute8'
    - 'attribute9'
    - 'attribute_category'
    - 'created_by'
    - 'creation_date'
    - 'description'
    - 'language'
    - 'last_updated_by'
    - 'last_update_date'
    - '_fivetran_synced'
    - 'last_update_login'
    - 'leaf_node'
    - 'security_group_id'
    - 'source_lang'
    - 'start_date_active'
    - 'tag'
    - 'territory_code'
    - 'view_application_id'
    - 'zd_edition_name'
    - 'zd_sync'
src_ldts: 'load_dts'
src_source: 'rec_src'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.ref_table(src_pk=metadata_dict["src_pk"],
                   src_extra_columns=metadata_dict["src_extra_columns"], 
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}
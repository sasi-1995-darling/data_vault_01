{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: 'stg_item_category_ref__emtk_ebs_common'
src_pk: 'category_id'
src_extra_columns: 
    - 'brand'
    - 'category_description'
    - 'structure_id'
    - 'item_category'
    - 'item_sub_category'
    - 'segment11'
    - 'summary_flag'
    - 'enabled_flag'
    - 'attribute1'
    - 'attribute2'
    - 'last_update_date'
    - 'last_updated_by'
    - 'creation_date'
    - 'created_by'
    - 'last_update_login'
    - 'web_status'
    - 'supplier_enabled_flag'
    - 'zd_edition_name'
    - 'zd_sync'
    - 'language'
    - 'source_lang'
    - 'tl_last_update_date'
    - 'tl_last_updated_by'
    - 'tl_creation_date'
    - 'tl_created_by'
    - 'tl_last_update_login'
    - 'tl_zd_edition_name'
    - 'tl_zd_sync'
src_ldts: 'load_dts'
src_source: 'rec_src'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.ref_table(src_pk=metadata_dict["src_pk"],
                   src_extra_columns=metadata_dict["src_extra_columns"], 
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}
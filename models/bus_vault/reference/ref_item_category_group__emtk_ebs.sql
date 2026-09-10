{{ config(materialized='view') }}

{%- set yaml_metadata -%}
source_model: 'stg_item_category_group_ref__emtk_ebs_common'
src_pk: 'category_set_id'
src_extra_columns: 
    - 'category_set_name'
    - 'description'
    - 'structure_id'
    - 'validate_flag'
    - 'control_level'
    - 'default_category_id'
    - 'last_update_date'
    - 'last_updated_by'
    - 'creation_date'
    - 'created_by'
    - 'last_update_login'
    - 'mult_item_cat_assign_flag'
    - 'control_level_updateable_flag'
    - 'mult_item_cat_updateable_flag'
    - 'hierarchy_enabled'
    - 'validate_flag_updateable_flag'
    - 'user_creation_allowed_flag'
    - 'raise_item_cat_assign_event'
    - 'raise_alt_cat_hier_chg_event'
    - 'raise_catalog_cat_chg_event'
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
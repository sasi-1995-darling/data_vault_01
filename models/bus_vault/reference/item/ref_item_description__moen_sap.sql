{%- set yaml_metadata -%}

source_model: 'stg_item_description__moen_sap'
src_pk: item_hk
src_extra_columns: 
    - item_id
    - material_desc
    - language
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{
    automate_dv.ref_table(
        src_pk=metadata_dict["src_pk"],
        src_extra_columns=metadata_dict["src_extra_columns"],
        src_ldts=metadata_dict["src_ldts"],
        src_source=metadata_dict["src_source"],
        source_model=metadata_dict["source_model"],
    )
}}
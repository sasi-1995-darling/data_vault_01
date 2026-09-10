{%- set yaml_metadata -%}

source_model: 'stg_category_map__ml_ebs'
src_pk: ref_id
src_extra_columns: 
        - base_material
        - item_category
        - item_sub_category
        - item_class
        - category
        - sub_category
        - class
        - sub_class
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

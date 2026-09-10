{%- set yaml_metadata -%}

source_model: 'base_item_description__moen_sap_v1'
derived_columns:
    load_dts: current_timestamp()
    item_bk: matnr
    item_id: matnr
    material_desc: maktg
    language: spras
hashed_columns:
    item_hk: 
        - item_bk
        - bkcc
    hdiff:
        is_hashdiff: true
        columns:
           - 'item_id'
           - 'material_desc'
           - 'language'
           
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict["source_model"] %}
{% set derived_columns = metadata_dict["derived_columns"] %}
{% set hashed_columns = metadata_dict["hashed_columns"] %}

{{
    automate_dv.stage(
        include_source_columns=true,
        source_model=source_model,
        derived_columns=derived_columns,
        hashed_columns=hashed_columns,
        ranked_columns=none,
    )
}}
{%- set yaml_metadata -%}

source_model: 'base_item_sales_data__moen_sap_v1'
derived_columns:
    load_dts: GLCHANGETIME_DTTM
    item_bk: MATNR
hashed_columns:
    item_hk: 
        - MATNR
        - bkcc
    hash_diff:
        is_hashdiff: true
        columns:
            - LVORM
            - VMSTA
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{
    automate_dv.stage(
        include_source_columns=true,
        source_model=metadata_dict["source_model"],
        derived_columns=metadata_dict["derived_columns"],
        null_columns=metadata_dict["null_columns"], 
        hashed_columns=metadata_dict["hashed_columns"],
    )
}}
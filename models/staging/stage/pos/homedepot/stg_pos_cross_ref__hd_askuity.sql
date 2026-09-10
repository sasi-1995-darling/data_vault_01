{%- set yaml_metadata -%}

source_model: 'base_pos_cross_ref__hd_askuity'
derived_columns:
    load_dts: current_timestamp()
hashed_columns:
    customer_sku_hk:
        - hd_item
        - bkcc
    base_material_hk: 
        - tmlc_base_material
        - bkcc
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{
    automate_dv.stage(
        include_source_columns=true,
        source_model=metadata_dict["source_model"],
        derived_columns=metadata_dict["derived_columns"],
        hashed_columns=metadata_dict["hashed_columns"],
    )
}}
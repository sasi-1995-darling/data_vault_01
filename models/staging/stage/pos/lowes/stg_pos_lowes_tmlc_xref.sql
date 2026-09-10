{%- set yaml_metadata -%}

source_model: 'base_pos_lowes_tmlc_xref'
derived_columns:
    load_dts: current_timestamp()
hashed_columns:
    customer_sku_hk:
        - lowes_sku
        - bkcc        
    base_material_hk: 
        - tmlc_sku
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
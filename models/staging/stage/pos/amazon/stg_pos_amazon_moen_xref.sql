{%- set yaml_metadata -%}

source_model: 'base_pos_amazon_moen_xref'
derived_columns:
    load_dts: _fivetran_synced
hashed_columns:
    customer_sku_hk:
        - asin
        - bkcc
    base_material_hk:
        - model_style_number
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
{%- set yaml_metadata -%}

source_model: 'base_product__delighted_edp'
derived_columns:
    load_dts: current_timestamp()
    rec_src: "!DELIGHTED"
    product_name_bk:
        - product_name
hashed_columns:
    product_hk:
        - product_name
    hdiff:
        is_hashdiff: true
        columns:
            - product_name
            - product_desc

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
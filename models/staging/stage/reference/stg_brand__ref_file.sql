{%- set yaml_metadata -%}

source_model: 'base_brand__ref_file'
derived_columns:
    load_dts: current_timestamp()
    rec_src: rec_src
    brand_bk:
        - system_brand
hashed_columns:
    brand_hk:
        - system_brand
    hdiff:
        is_hashdiff: true
        columns:
            - business_unit
            - brand
            - sub_brand
            - system_brand
            - competitor

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
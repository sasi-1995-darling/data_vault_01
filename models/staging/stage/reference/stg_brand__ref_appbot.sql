{%- set yaml_metadata -%}

source_model: 'base_brand__ref_appbot'
derived_columns:
    load_dts: current_timestamp()
    rec_src: rec_src
    brand_bk:
        - brand
hashed_columns:
    brand_hk:
        - brand
    hdiff:
        is_hashdiff: true
        columns:
            - brand

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
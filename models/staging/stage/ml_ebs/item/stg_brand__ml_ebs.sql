{%- set yaml_metadata -%}

source_model: 'base_brand__ml_ebs'
derived_columns:
    rec_src: rec_src
    load_dts: current_timestamp()
    brand_bk:
        - registered_brand
hashed_columns:
    brand_hk: 
        - registered_brand
    hdiff:
        is_hashdiff: true
        columns:
        - registered_brand

{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}

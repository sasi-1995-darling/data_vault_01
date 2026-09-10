{%- set yaml_metadata -%}

source_model: 'base_category_sets_tl__ml_ebs'
derived_columns:
    rec_src: "!ML EBS"
    load_dts: current_timestamp()
    brand: '!TMLC'
hashed_columns:
    item_category_sets_tl_hk: 
        - category_set_id
        - brand
    hdiff:
        is_hashdiff: true
        columns:
        - category_set_id
        - category_set_name
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}

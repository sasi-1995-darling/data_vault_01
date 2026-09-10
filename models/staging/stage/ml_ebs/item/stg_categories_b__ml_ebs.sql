{%- set yaml_metadata -%}

source_model: 'base_categories_b__ml_ebs'
derived_columns:
    rec_src: "!ML EBS"
    load_dts: current_timestamp()
    brand: '!TMLC'
hashed_columns:
    item_category_b_hk: 
        - category_id
        - brand
    hdiff:
        is_hashdiff: true
        columns:
        - category_id
        - segment1
        - segment2
        - segment3
        - segment4
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}

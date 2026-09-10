{%- set yaml_metadata -%}

source_model: 'base_item_categories__ml_ebs_v1'
derived_columns:
    load_dts: current_timestamp()
hashed_columns:
    item_categories_hk: 
        - inventory_item_id
        - organization_id
        - category_id
        - category_set_id
        - bkcc
    item_hk: 
        - segment1
        - bkcc
    hdiff:
        is_hashdiff: true
        columns:
        - inventory_item_id
        - organization_id
        - category_id
        - category_set_id
        - last_update_date
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}

{%- set yaml_metadata -%}

source_model: 'base_plant_item__ml_ebs_v1'
derived_columns:
    load_dts: current_timestamp()   
    plant_bk: organization_code
    item_bk: segment1
    plant_item_bk:
        - item_bk
        - bkcc
        - plant_bk
        - bkcc
hashed_columns:
    plant_hk: 
        - organization_code
        - bkcc
    item_hk:
        - item_bk
        - bkcc
    plant_item_hk:
        - plant_item_bk   
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{
    automate_dv.stage(
        include_source_columns=true,
        source_model=metadata_dict["source_model"],
        derived_columns=metadata_dict["derived_columns"],
        null_columns=metadata_dict["null_columns"], 
        hashed_columns=metadata_dict["hashed_columns"],
    )
}}
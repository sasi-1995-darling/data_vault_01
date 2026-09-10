{%- set yaml_metadata -%}

source_model: 'base_systems_items__ml_ebs_v1'
derived_columns:
    load_dts: current_timestamp()
    item_id: to_char(segment1)
    item_bk: 
        - segment1
    base_material: material
hashed_columns:
    item_hk: 
        - segment1
        - bkcc
    hdiff:
        is_hashdiff: true
        columns:
            - inventory_item_id
            - organization_id
            - primary_unit_of_measure
            - planner_code
            - item_type
            - inventory_item_status_code
            - item_creation_date
            - lot_control_code
            - fixed_lot_multiplier
            - mto_rolled_up_flag
            - language
            - long_description
            - description
            - key_change
            - rto_flag
            - mfg_number
            - sourced_mto_mts   
            
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
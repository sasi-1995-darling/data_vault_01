{%- set yaml_metadata -%}

source_model: 'base_pos_lowes_store'
derived_columns:
    load_dts: current_timestamp()
    store_bk: 
        - location_id    	


hashed_columns:
    store_hk: 
        - store_bk
        - bkcc          	

    hash_diff:
        is_hashdiff: true
        columns:
        - location_desc
        - delivery_address
        - delivery_city
        - delivery_state
        - delivery_code
        - salesfloor_footage
        - district_district
        - region_id
        - region_desc
        - division_division
        - advertising_area
        - geo_id
        - geo_desc
        - forecast_zone
        - supporting_center
        - supporting_fdc
        - supporting_transload
        - pm_snapshot_date
        - file_name
        - open_date
        - _file
        - _fivetran_synced
        - _modified
        - real_date
        - _line

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

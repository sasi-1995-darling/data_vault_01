{%- set yaml_metadata -%}

source_model: 'base_pos_homedepot_store'
derived_columns:
    load_dts: current_timestamp()
    store_bk: 
        - d_store_nbr     	


hashed_columns:
    store_hk: 
        - store_bk
        - bkcc
    
    hash_diff:
        is_hashdiff: true
        columns:
        - 'state_territory_code'
        - 'd_all_thd'
        - 'd_buying_office'
        - 'd_city'
        - 'd_country'
        - 'd_district'
        - 'd_division'
        - 'd_lob'
        - 'd_latitude'
        - 'd_longitude'
        - 'd_market'
        - 'd_postal_code'
        - 'd_region'
        - 'd_store'
        - 'd_store_address'
        - 'd_store_name'
        - 'd_time_zone'
        - 'home_depot_account'
        - 'run_date'

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

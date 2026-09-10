{%- set yaml_metadata -%}

source_model: 'base_pos_customer_location__ferguson_extract'
derived_columns:
    load_dts: current_timestamp()
    customer: "!FERGUSON"
    location_bk: to_char(location_id)
    name: location_name
    city: location_city
    state: location_state
    zip: location_zip
hashed_columns:
    customer_location_hk: 
        - location_bk
        - customer
    hash_diff:
        is_hashdiff: true
        columns:
            - location_bk
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

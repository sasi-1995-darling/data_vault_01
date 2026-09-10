{%- set yaml_metadata -%}

source_model: 'base_pos_customer_location__lowes'
derived_columns:
    load_dts: current_timestamp()
    customer: "!LOWES"
    location_bk: to_char(location_id)
    name: location_desc
    city: delivery_city
    state: delivery_state
    zip: delivery_code
hashed_columns:
    customer_location_hk: 
        - location_bk
        - customer
    hash_diff:
        is_hashdiff: true
        columns:
            - name
            - city
            - state
            - zip
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

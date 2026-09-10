{%- set yaml_metadata -%}

source_model:
    'base_pos_customer_sales__lowes'
derived_columns:
    location_bk: location_id
    load_dts: current_timestamp()
    customer: "!LOWES"
hashed_columns:
    customer_sales_hk:
        - item_id
        - location_id
        - end_date
        - brand
        - rec_src
    customer_location_hk:
        - location_bk
        - customer

    hash_diff:
        is_hashdiff: true
        columns:
            - item_name
            - location_name
            - start_date
            - ty_sales
            - ty_sales_units
            - ty_fulfilled_internet_sales
            - ty_fulfilled_internet_units
            - ty_available_inventory_sales
            - ty_available_inventory_units
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

{%- set yaml_metadata -%}

source_model: 'base_pos_moen_hofr__ferguson_extract'
derived_columns:
    load_dts: current_timestamp()
    customer: "!FERGUSON"
hashed_columns:
    product_customer_hk:
        - _file
        - _line
    sell_location_id_hk: 
        - sell_location_id
        - customer
    ship_location_id_hk:
        - ship_location_id
        - customer
    hash_diff:
        is_hashdiff: true
        columns:
            - _file
            - _fivetran_synced
            - year_month
            - date
            - transaction_type
            - order_channel
            - build_com_order
            - customer_group
            - fei_product_code
            - product_dest_zip
            - shipped_qty
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

{%- set yaml_metadata -%}

source_model: 'base_pos_pos__hd_askuity'
derived_columns:
    load_dts: current_timestamp()
    customer: '!HOME_DEPOT'
    location_bk: to_char(d_store_nbr)
    sales_units: ceil(sales_units)
    rec_src: '!HD_ASKUITY'
hashed_columns:
    product_customer_hk: 
        - day
        - sku_nbr
        - location_bk
        - merch_vendor
        - manuf_part_number
        - fulfillment_channel
        - home_depot_account
        - sku_status
    product_inventory_hk: 
        - day
        - sku_nbr
        - location_bk
        - merch_vendor
        - manuf_part_number
        - home_depot_account
    customer_location_hk:
        - location_bk
        - customer
    hash_diff:
        is_hashdiff: true
        columns:
            - day
            - sku_nbr
            - location_bk
            - merch_vendor
            - manuf_part_number
            - fulfillment_channel
            - home_depot_account
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

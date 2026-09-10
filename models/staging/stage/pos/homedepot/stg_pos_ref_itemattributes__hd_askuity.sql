{%- set yaml_metadata -%}

source_model: 'base_pos_ref_itemattributes__hd_askuity'
derived_columns:
    load_dts: current_timestamp()
    brand: home_depot_account
hashed_columns:
    customer_sku_hk:
        - bkcc
        - sku_nbr
    item_hk:
        - manuf_part_number
        - bkcc
    hash_diff:
        is_hashdiff: true
        columns:
            - sku_nbr
            - manuf_part_number
            - run_date
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

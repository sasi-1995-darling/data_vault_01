{%- set yaml_metadata -%}

source_model: 'base_price_availability_history__profitero_edp'
derived_columns:
    rec_src: "!PROFITERO"
    load_dts: current_timestamp()
hashed_columns:
    ref_id: 
        - date
        - customer_product_id
        - product_id
        - retailer_id
        - source
        - first_party_won_buy_box
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
{%- set yaml_metadata -%}

source_model: stg_price_availability_history__profitero_edp
src_pk: ref_id
src_extra_columns: 
    - date
    - customer_product_id
    - product_id
    - retailer_id
    - regular_price
    - promotion_price
    - first_party_won_buy_box
    - source
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.ref_table(src_pk=metadata_dict["src_pk"],
                   src_extra_columns=metadata_dict["src_extra_columns"], 
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}

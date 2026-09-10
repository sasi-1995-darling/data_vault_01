{%- set yaml_metadata -%}

source_model: 'base_linkconsumer_product_review__delighted_edp'
derived_columns:
    load_dts: current_timestamp()
    rec_src: "!DELIGHTED"
hashed_columns:
    link_consumer_product_review_hk:
        - link_product_consumer_review
    consumer_hk:
        - person_email
    product_hk:
        - product_name
    review_hk:
        - review_id
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

{%- set yaml_metadata -%}

source_model: 'base_linkreview_sentiment__delighted_edp'
derived_columns:
    load_dts: current_timestamp()
    rec_src: "!DELIGHTED"
hashed_columns:
    link_review_sentiment_hk:
        - link_review_sentiment
    review_hk:
        - review_id
    sentiment_hk:
        - category_label
        - subcategory_label
        - tag
    hdiff:
        is_hashdiff: true
        columns:
            - link_review_sentiment
            - review_id
            - category_label
            - subcategory_label
            - tag
            - sentiment_text
            - subcategory_sentence
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

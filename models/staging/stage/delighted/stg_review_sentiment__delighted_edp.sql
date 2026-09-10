{%- set yaml_metadata -%}

source_model: 'base_review_sentiment__delighted_edp'
derived_columns:
    load_dts: current_timestamp()
    rec_src: "!DELIGHTED"
    sentiment_bk:
        - category_label
        - subcategory_label
        - tag 
hashed_columns:
    sentiment_hk:
        - category_label
        - subcategory_label
        - tag 
    hdiff:
        is_hashdiff: true
        columns:
            - created_at
            - ukey
            - review_source
            - review_header
            - review_text
            - sentiment
            - subcategory_sentence
            - category_label
            - subcategory_label
            - tag 

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
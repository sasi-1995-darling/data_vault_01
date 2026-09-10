{%- set yaml_metadata -%}

source_model: 'base_review__appbot_api'
derived_columns:
    load_dts: current_timestamp()
    rec_src: "!APPBOT"
hashed_columns:
    review_hk:
        - id
    hdiff:
        is_hashdiff: true
        columns:
            - customer_product_id
            - app_store_id
            - id
            - author
            - star_rating
            - text
            - summary
            - published_at
            - published_at_datetime
            - version
            - country
            - country_id
            - country_code
            - translated_subject
            - translated_body
            - manufacturer_comment_text
            - manufacturer_comment_datekey
            - topics
            - topic_ids
            - store_id
            - device
            - device_friendly_name
            - os_version
            - os_version_friendly_name
            - sentiment
            - detected_language
            - detected_language_id
            - permalink_url
            - reply_url
            - internal_url

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

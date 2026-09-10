{%- set yaml_metadata -%}

source_model: 'base_rating__appbot_api'
derived_columns:
    load_dts: current_timestamp()
    rec_src: "!APPBOT"
hashed_columns:
    rating_hk:
        - app_id
        - created_at
        - country
        - version
    hdiff:
        is_hashdiff: true
        columns:
            - app_id
            - created_at
            - country
            - country_id
            - country_code
            - cumulative_1_star
            - cumulative_2_star
            - cumulative_3_star
            - cumulative_4_star
            - cumulative_5_star
            - cumulative_reviews
            - cumulative_star_rating
            - version

{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

--
{{
    automate_dv.stage(
        include_source_columns=true,
        source_model=metadata_dict["source_model"],
        derived_columns=metadata_dict["derived_columns"],
        hashed_columns=metadata_dict["hashed_columns"],
    )
}}

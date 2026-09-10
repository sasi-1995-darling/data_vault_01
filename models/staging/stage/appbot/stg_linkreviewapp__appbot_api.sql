{%- set yaml_metadata -%}

source_model: 'base_linkreviewapp__appbot_api'
derived_columns:
    load_dts: current_timestamp()
    rec_src: "!APPBOT"
hashed_columns:
    link_review_applist_details_hk:
        - link_review_applist
    review_hk:
        - review_id
    application_hk:
        - application_id


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

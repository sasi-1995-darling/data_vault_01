{%- set yaml_metadata -%}

source_model: 'base_application__appbot_api'
derived_columns:
    load_dts: current_timestamp()
    rec_src: "!APPBOT"
hashed_columns:
    application_hk:
        - id
    hdiff:
        is_hashdiff: true
        columns:
            - id
            - identifier
            - app_name
            - store
            - store_id
            - icon
            - authenticated
            - translation_supported

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
--
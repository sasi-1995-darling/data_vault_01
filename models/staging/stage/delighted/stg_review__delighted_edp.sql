{%- set yaml_metadata -%}

source_model: 'base_review__delighted_edp'
derived_columns:
    load_dts: current_timestamp()
    rec_src: "!DELIGHTED"
    review_id_bk:
        - id
hashed_columns:
    review_hk:
        - id
    hdiff:
        is_hashdiff: true
        columns:
            - id
            - person_id
            - comment
            - permalink
            - created_at
            - updated_at
            - _fivetran_synced
            - properties_delighted_browser
            - properties_delighted_device_type
            - properties_delighted_operating_system
            - survey_type
            - score
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

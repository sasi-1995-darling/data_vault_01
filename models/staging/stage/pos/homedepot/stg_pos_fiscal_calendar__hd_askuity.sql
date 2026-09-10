{%- set yaml_metadata -%}

source_model: 'base_pos_calendar__hd_askuity'
derived_columns:
    load_dts: current_timestamp()
    rec_src: '!HOME_DEPOT'
hashed_columns:
    hdiff:
        is_hashdiff: true
        columns:
            - THD_cal_year
            - date
            - THD_cal_day
            - THD_cal_week
            - THD_cal_month
            - THD_cal_quarter
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

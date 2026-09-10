{%- set yaml_metadata -%}

source_model: 'base_date__date_spine'
derived_columns:
    load_dts: LOAD_DTS
    rec_src: REC_SRC
    date_bk: date_bk::Integer
hashed_columns:
    hdiff:
        is_hashdiff: true
        columns:
            - date_actual
            - day_name
            - month_actual
            - year_actual
            - quarter_actual
            - day_of_week
            - first_day_of_week
            - week_of_year
            - day_of_month
            - day_of_quarter
            - day_of_year
            - month_name
            - first_day_of_month
            - last_day_of_month
            - first_day_of_year
            - last_day_of_year
            - first_day_of_quarter
            - last_day_of_quarter
            - last_day_of_week
            - quarter_name
            - holiday_desc
            - is_holiday
            - snapshot_date_fpa
            - snapshot_date_billings
            - days_in_month_count
            - days_until_last_day_of_month
            - current_date_actual
            - current_first_day_of_month
            - current_day_of_month
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
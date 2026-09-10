{{ config(materialized='table') }}

{%- set yaml_metadata -%}
source_model: 'stg_date__date_spine'
src_pk: 'date_bk'
src_extra_columns: 
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
    - hdiff
src_ldts: 'load_dts'
src_source: 'rec_src'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.ref_table(src_pk=metadata_dict["src_pk"],
                   src_extra_columns=metadata_dict["src_extra_columns"], 
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}
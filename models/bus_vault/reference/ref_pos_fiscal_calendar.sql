{{
    config(
        materialized='ephemeral'
    )
}}

{%- set yaml_metadata -%}

source_model: stg_pos_fiscal_calendar
src_pk: datekey
src_extra_columns: 
    - date
    - fbin_cal_day
    - fbin_cal_week
    - fbin_cal_month
    - fbin_cal_quarter
    - fbin_cal_year
    - fbin_cal_quarter_yyyyqq
    - fbin_cal_month_yyyymm
    - fbin_cal_week_yyyyww
    - fbin_working_day_flag
    - fiscal_455_cal_day
    - fiscal_455_cal_week
    - fiscal_455_cal_month
    - fiscal_455_cal_quarter
    - fiscal_455_cal_year
    - fiscal_445_cal_quarter_yyyyqq
    - fiscal_445_cal_month_yyyymm
    - fiscal_445_cal_week_yyyyww
    - fiscal_455_working_day_flag
    - lowes_cal_day
    - lowes_cal_week
    - lowes_cal_month
    - lowes_cal_year
    - lowes_cal_quarter
    - lowes_445_cal_quarter_yyyyqq
    - lowes_445_cal_month_yyyymm
    - lowes_445_cal_week_yyyyww
    - lowes_working_day_flag
    - home_depot_cal_week
    - home_depot_cal_month
    - home_depot_cal_year
    - home_depot_cal_quarter
    - home_depot_cal_quarter_yyyyqq
    - home_depot_cal_month_yyyymm
    - home_depot_cal_week_yyyyww
    - home_depot_working_day_flag
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.ref_table(src_pk=metadata_dict["src_pk"],
                   src_extra_columns=metadata_dict["src_extra_columns"], 
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}

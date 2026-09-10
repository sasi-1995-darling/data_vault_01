{{
    config(
        alias='dim_date_fiscal_445'+ ('_ship' if target.schema not in ['dev', 'qa', 'prod'] else '')
    )
}}

select
    cast(date_bk as VARCHAR(100)) as date_bk
    , date
    , fiscal_445_cal_day
    , fiscal_445_cal_week
    , fiscal_445_cal_month
    , fiscal_445_cal_quarter
    , fiscal_445_cal_year
    , fiscal_445_cal_quarter_yyyyqq
    , fiscal_445_cal_month_yyyymm
    , fiscal_445_cal_week_yyyyww
    , cast(fiscal_445_working_day_flag as VARCHAR(100)) as fiscal_445_working_day_flag
    , is_completed_fiscal_month
    , is_completed_fiscal_week
    , fiscal_last_week_flag
    , fiscal_last_4_weeks_flag
    , fiscal_last_13_weeks_flag
    , fiscal_last_month_flag
    , fiscal_last_3_months_flag
    , month_name
    , month_name_abbr
    , epoch_day
    , epoch_week
    , epoch_month
    , weeks_in_month
    , month_number_leading_zero
    , fiscal_day_of_year
    , fiscal_ytd_flag
    , fiscal_rolling_52_week_flag
    , fiscal_last_quarter_flag
    , fiscal_last_12_months_flag
    , fiscal_qtd_flag

from {{ ref('dim_date_fiscal_445') }}

with 

cte_date as (

    select * from {{ source('gold_reference', 'dim_date_columnar') }}

),

cte_date_col as (

    select
        datekey,
        date,
        fbin_cal_day,
        fbin_cal_week,
        fbin_cal_month,
        fbin_cal_quarter,
        fbin_cal_year,
        fbin_cal_quarter_yyyyqq,
        fbin_cal_month_yyyymm,
        fbin_cal_week_yyyyww,
        fbin_working_day_flag,
        fiscal_455_cal_day,
        fiscal_455_cal_week,
        fiscal_455_cal_month,
        fiscal_455_cal_quarter,
        fiscal_455_cal_year,
        fiscal_445_cal_quarter_yyyyqq,
        fiscal_445_cal_month_yyyymm,
        fiscal_445_cal_week_yyyyww,
        fiscal_455_working_day_flag,
        lowes_cal_day,
        lowes_cal_week,
        lowes_cal_month,
        lowes_cal_year,
        lowes_cal_quarter,
        lowes_445_cal_quarter_yyyyqq,
        lowes_445_cal_month_yyyymm,
        lowes_445_cal_week_yyyyww,
        lowes_working_day_flag,
        home_depot_cal_week,
        home_depot_cal_month,
        home_depot_cal_year,
        home_depot_cal_quarter,
        home_depot_cal_quarter_yyyyqq,
        home_depot_cal_month_yyyymm,
        home_depot_cal_week_yyyyww,
        home_depot_working_day_flag

    from cte_date

)

select * from cte_date_col
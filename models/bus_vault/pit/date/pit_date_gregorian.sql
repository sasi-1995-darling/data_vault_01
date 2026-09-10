with cte_sat_date_gregorian as (

    select * from {{ ref('ref_sat_date_gregorian') }}
)

, cte_sat_date_gregorian__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_date_gregorian'
        ,hk_field='date_bk') }}
)

select
hd.date_bk
, date_actual
, day_name
, month_actual
, year_actual
, quarter_actual
, day_of_week
, first_day_of_week
, week_of_year
, day_of_month
, day_of_quarter
, day_of_year
, month_name
, first_day_of_month
, last_day_of_month
, first_day_of_year
, last_day_of_year
, first_day_of_quarter
, last_day_of_quarter
, last_day_of_week
, quarter_name
, holiday_desc
, is_holiday
, snapshot_date_fpa
, snapshot_date_billings
, days_in_month_count
, days_until_last_day_of_month
, current_date_actual
, current_first_day_of_month
, current_day_of_month
 from  {{ ref('ref_hub_date') }} hd
 INNER join cte_sat_date_gregorian__latest sd
 on hd.date_bk = sd.date_bk


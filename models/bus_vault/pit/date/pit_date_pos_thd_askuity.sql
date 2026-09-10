with cte_sat_date_pos_thd_askuity as (

    select * from {{ ref('ref_sat_date__pos_thd_askuity') }}
)

, cte_sat_date_pos_thd_askuity__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_date_pos_thd_askuity'
        ,hk_field='date_bk') }}
)

select
hd.date_bk
, THD_cal_year
, date
, THD_cal_day
, THD_cal_week
, THD_cal_month
, THD_cal_quarter
 from  {{ ref('ref_hub_date') }} hd
 INNER join cte_sat_date_pos_thd_askuity__latest sd
 on hd.date_bk = sd.date_bk


with cte_sat_date_fbin as (

    select * from {{ ref('ref_sat_date_fbin') }}
)

, cte_sat_date_fbin__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_date_fbin'
        ,hk_field='date_bk') }}
)

select
hd.date_bk
, DATE
, FBIN_CAL_DAY
, FBIN_CAL_WEEK
, FBIN_CAL_MONTH
, FBIN_CAL_QUARTER
, FBIN_CAL_YEAR
, FBIN_CAL_QUARTER_YYYYQQ
, FBIN_CAL_MONTH_YYYYMM
, FBIN_CAL_WEEK_YYYYWW
, FBIN_WORKING_DAY_FLAG
 from  {{ ref('ref_hub_date') }} hd
 INNER join cte_sat_date_fbin__latest sd
 on hd.date_bk = sd.date_bk


with cte_sat_date_pos_lowes as (

    select * from {{ ref('ref_sat_date_pos_lowes') }}
)

, cte_sat_date_pos_lowes__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_date_pos_lowes'
        ,hk_field='date_bk') }}
)

select
hd.date_bk
, LOWES_CAL_DAY
, LOWES_CAL_WEEK
, LOWES_CAL_MONTH
, LOWES_CAL_YEAR
, LOWES_CAL_QUARTER
, LOWES_445_CAL_QUARTER_YYYYQQ
, LOWES_445_CAL_MONTH_YYYYMM
, LOWES_445_CAL_WEEK_YYYYWW
, LOWES_WORKING_DAY_FLAG
 from  {{ ref('ref_hub_date') }} hd
 INNER join cte_sat_date_pos_lowes__latest sd
 on hd.date_bk = sd.date_bk
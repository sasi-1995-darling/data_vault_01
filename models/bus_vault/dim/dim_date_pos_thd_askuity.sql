with
    pit_date_pos_thd_askuity as 
    (SELECT * FROM {{ ref('pit_date_pos_thd_askuity') }})

select 
	DATE_BK,
	THD_CAL_YEAR,
	DATE,
	THD_CAL_DAY,
	THD_CAL_WEEK,
	THD_CAL_MONTH,
	THD_CAL_QUARTER
from pit_date_pos_thd_askuity

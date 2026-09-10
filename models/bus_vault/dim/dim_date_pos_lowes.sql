with
    pit_date_pos_lowes as 
    (select * from {{ ref('pit_date_pos_lowes') }})

select 
	DATE_BK,
	LOWES_CAL_DAY,
	LOWES_CAL_WEEK,
	LOWES_CAL_MONTH,
	LOWES_CAL_YEAR,
	LOWES_CAL_QUARTER,
	LOWES_445_CAL_QUARTER_YYYYQQ,
	LOWES_445_CAL_MONTH_YYYYMM,
	LOWES_445_CAL_WEEK_YYYYWW,
	LOWES_WORKING_DAY_FLAG
from 
pit_date_pos_lowes
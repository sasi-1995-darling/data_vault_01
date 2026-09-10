with
    pit_date_fbin as 
    (select * from {{ ref('pit_date_fbin') }})

select 
	DATE_BK,
	DATE,
	FBIN_CAL_DAY,
	FBIN_CAL_WEEK,
	FBIN_CAL_MONTH,
	FBIN_CAL_QUARTER,
	FBIN_CAL_YEAR,
	FBIN_CAL_QUARTER_YYYYQQ,
	FBIN_CAL_MONTH_YYYYMM,
	FBIN_CAL_WEEK_YYYYWW,
	FBIN_WORKING_DAY_FLAG
from 
pit_date_fbin
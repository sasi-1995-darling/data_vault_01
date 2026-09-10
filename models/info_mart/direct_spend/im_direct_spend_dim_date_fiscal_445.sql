{{ config(alias='dim_date_fiscal_445' + ('_direct_spend' if target.name not in ['dev', 'qa', 'prod'] else '')) }}
--{{target.name}}
select 
    DATE_BK,
	DATE,
	FISCAL_445_CAL_DAY,
	FISCAL_445_CAL_WEEK,
	FISCAL_445_CAL_MONTH,
	FISCAL_445_CAL_QUARTER,
	FISCAL_445_CAL_YEAR,
	FISCAL_445_CAL_QUARTER_YYYYQQ,
	FISCAL_445_CAL_MONTH_YYYYMM,
	FISCAL_445_CAL_WEEK_YYYYWW,
	FISCAL_445_WORKING_DAY_FLAG
from {{ ref('dim_date_fiscal_445') }}
 
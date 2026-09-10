select distinct
    year1_1 as THD_cal_year
    , to_date(day1_2) as date
    , day(to_date(day1_2)) as THD_cal_day
    , to_number(right(week_nbr, 2)) as THD_cal_week
    , to_number(right(short_month, 2)) as THD_cal_month
    , to_number(right(quarter_nbr, 1)) as THD_cal_quarter
    , TO_CHAR(to_date(day1_2), 'YYYYMMDD')::int as DATE_BK
from {{ source('homedepot_pos_askuity', 'fiscal_calendar') }}

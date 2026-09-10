select
    TO_CHAR(DATE_DAY, 'YYYYMMDD')::int as DATE_BK
    ,current_timestamp() AS LOAD_DTS
    ,'Auto-generated.Script.Date_Spine' as REC_SRC
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
from {{ ref('date_spine') }} as ds

select

    date_day
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
    /* remove snowflake default fiscal cols
    , fiscal_year
    , fiscal_quarter
    , day_of_fiscal_quarter
    , day_of_fiscal_year
    , first_day_of_fiscal_quarter
    , last_day_of_fiscal_quarter
    , first_day_of_fiscal_year
    , last_day_of_fiscal_year
    , week_of_fiscal_year
    , month_of_fiscal_year
    , fiscal_quarter_name
    , fiscal_quarter_name_fy
    , fiscal_quarter_number_absolute
    , fiscal_month_name
    , fiscal_month_name_fy
    , last_month_of_fiscal_quarter
    , is_first_day_of_last_month_of_fiscal_quarter
    , last_month_of_fiscal_year
    , is_first_day_of_last_month_of_fiscal_year
    , week_of_month_normalised --calculated based on fiscal
    , day_of_fiscal_quarter_normalised
    , week_of_fiscal_quarter_normalised
    , day_of_fiscal_year_normalised
    , is_first_day_of_fiscal_quarter_week
    , current_fiscal_year
    , current_first_day_of_fiscal_year
    , current_fiscal_quarter_name_fy
    , current_first_day_of_fiscal_quarter
    , current_day_of_fiscal_quarter
    , current_day_of_fiscal_year
    , is_fiscal_month_to_date
    , is_fiscal_quarter_to_date
    , is_fiscal_year_to_date
    , fiscal_days_ago
    , fiscal_weeks_ago
    , fiscal_months_ago
    , fiscal_quarters_ago
    , fiscal_years_ago
    */
    , pos_fiscal.* exclude (datekey, date)
from {{ ref('date_spine') }} as ds
    left join {{ ref('ref_pos_fiscal_calendar') }} as pos_fiscal
        on ds.date_day = pos_fiscal.date

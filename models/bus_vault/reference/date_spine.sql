with date_spine as (

  {{ dbt_utils.date_spine(
      start_date="to_date('01/01/2009', 'mm/dd/yyyy')",
      datepart="day",
      end_date="dateadd(year, 40, current_date)"
     )
  }}

)

, calculated as (

    select
        date_day
        , date_day
            as date_actual

            , DAYNAME(
                date_day) as day_name

            , DATE_PART('month', date_day) as month_actual
            , DATE_PART('year', date_day) as year_actual
            , DATE_PART(
                quarter, date_day) as quarter_actual

            , DATE_PART(dayofweek, date_day) + 1 as day_of_week
            , case when day_name = 'Sun' then date_day
                else DATEADD('day', -1, DATE_TRUNC('week', date_day))
            end
                as first_day_of_week

                , case when day_name = 'Sun' then WEEK(date_day) + 1
                    else WEEK(date_day)
                end
                    as week_of_year_temp --remove this column

                    , case when day_name = 'Sun' and LEAD(week_of_year_temp) over (order by date_day) = '1'
                            then '1'
                        else week_of_year_temp
                    end
                        as week_of_year

                        , DATE_PART(
                            'day', date_day) as day_of_month

                        , ROW_NUMBER()
                            over (partition by year_actual, quarter_actual order by date_day)
                            as day_of_quarter
                        , ROW_NUMBER()
                            over (partition by year_actual order by date_day) as day_of_year

                        , case when month_actual < 2
                                then year_actual
                            else (year_actual + 1)
                        end as fiscal_year
                        , case when month_actual < 2 then '4'
                            when month_actual < 5 then '1'
                            when month_actual < 8 then '2'
                            when month_actual < 11 then '3'
                            else '4'
                        end
                            as fiscal_quarter

                            , ROW_NUMBER()
                                over (partition by fiscal_year, fiscal_quarter order by date_day)
                                as day_of_fiscal_quarter
                            , ROW_NUMBER()
                                over (partition by fiscal_year order by date_day) as day_of_fiscal_year

                            , TO_CHAR(
                                date_day, 'MMMM') as month_name

                            , TRUNC(date_day, 'Month') as first_day_of_month
                            , LAST_VALUE(
                                date_day)
                                over (partition by year_actual, month_actual order by date_day)
                                as last_day_of_month

                                , FIRST_VALUE(date_day)
                                    over (partition by year_actual order by date_day)
                                    as first_day_of_year
                                , LAST_VALUE(
                                    date_day) over (partition by year_actual order by date_day) as last_day_of_year

                                , FIRST_VALUE(date_day)
                                    over (
                                        partition by year_actual, quarter_actual order by date_day
                                    )
                                    as first_day_of_quarter
                                , LAST_VALUE(
                                    date_day)
                                    over (partition by year_actual, quarter_actual order by date_day)
                                    as last_day_of_quarter

                                    , FIRST_VALUE(date_day)
                                        over (
                                            partition by fiscal_year, fiscal_quarter order by date_day
                                        )
                                        as first_day_of_fiscal_quarter
                                    , LAST_VALUE(
                                        date_day)
                                        over (partition by fiscal_year, fiscal_quarter order by date_day)
                                        as last_day_of_fiscal_quarter

                                        , FIRST_VALUE(date_day)
                                            over (partition by fiscal_year order by date_day)
                                            as first_day_of_fiscal_year
                                        , LAST_VALUE(
                                            date_day)
                                            over (partition by fiscal_year order by date_day)
                                            as last_day_of_fiscal_year

                                            , DATEDIFF(
                                                'week', first_day_of_fiscal_year, date_actual
                                            )
                                            + 1
                                                as week_of_fiscal_year

                                                , case when
                                                        EXTRACT('month', date_day) = 1
                                                        then 12
                                                    else EXTRACT('month', date_day) - 1
                                                end
                                                    as month_of_fiscal_year

                                                    , LAST_VALUE(
                                                        date_day)
                                                        over (partition by first_day_of_week order by date_day)
                                                        as last_day_of_week

                                                        , (
                                                            year_actual || '-Q' || EXTRACT(quarter from date_day))
                                                            as quarter_name

                                                            , (fiscal_year || '-' || DECODE(
                                                                fiscal_quarter
                                                                , 1, 'Q1'
                                                                , 2, 'Q2'
                                                                , 3, 'Q3'
                                                                , 4, 'Q4'
                                                            )) as fiscal_quarter_name
                                                            , ('FY' || SUBSTR(fiscal_quarter_name, 3, 7)) as fiscal_quarter_name_fy
                                                            , DENSE_RANK() over (order by fiscal_quarter_name) as fiscal_quarter_number_absolute
                                                            , fiscal_year || '-' || MONTHNAME(date_day) as fiscal_month_name
                                                            , (
                                                                'FY' || SUBSTR(fiscal_month_name, 3, 8))
                                                                as fiscal_month_name_fy

                                                                , (
                                                                    case when
                                                                            MONTH(date_day) = 1
                                                                            and DAYOFMONTH(date_day) = 1
                                                                            then 'New Year''s Day'
                                                                        when
                                                                            MONTH(date_day) = 12
                                                                            and DAYOFMONTH(date_day) = 25
                                                                            then 'Christmas Day'
                                                                        when
                                                                            MONTH(date_day) = 12
                                                                            and DAYOFMONTH(date_day) = 26
                                                                            then 'Boxing Day'
                                                                    end)::VARCHAR
                                                                    as holiday_desc
                                                                , (case when holiday_desc is null then 0
                                                                    else 1
                                                                end)::BOOLEAN as is_holiday
                                                                , DATE_TRUNC('month', last_day_of_fiscal_quarter) as last_month_of_fiscal_quarter
                                                                , IFF(DATE_TRUNC('month', last_day_of_fiscal_quarter) = date_actual, true, false) as is_first_day_of_last_month_of_fiscal_quarter
                                                                , DATE_TRUNC('month', last_day_of_fiscal_year) as last_month_of_fiscal_year
                                                                , IFF(DATE_TRUNC('month', last_day_of_fiscal_year) = date_actual, true, false) as is_first_day_of_last_month_of_fiscal_year
                                                                , DATEADD('day', 7, DATEADD('month', 1, first_day_of_month)) as snapshot_date_fpa
                                                                , DATEADD('day', 4, DATEADD('month', 1, first_day_of_month)) as snapshot_date_fpa_fifth
                                                                , DATEADD('day', 44, DATEADD('month', 1, first_day_of_month)) as snapshot_date_billings
                                                                , COUNT(date_actual) over (partition by first_day_of_month)
                                                                    as days_in_month_count

                                                                    , 90
                                                                    - DATEDIFF(
                                                                        day, date_actual, last_day_of_fiscal_quarter
                                                                    )
                                                                        as day_of_fiscal_quarter_normalised
                                                                    , 12 - FLOOR((DATEDIFF(day, date_actual, last_day_of_fiscal_quarter) / 7)) as week_of_fiscal_quarter_normalised
                                                                    , case
                                                                        when week_of_fiscal_quarter_normalised
                                                                            < 5
                                                                            then week_of_fiscal_quarter_normalised
                                                                        when week_of_fiscal_quarter_normalised
                                                                            < 9
                                                                            then week_of_fiscal_quarter_normalised
                                                                                - 4
                                                                        else week_of_fiscal_quarter_normalised
                                                                            - 8
                                                                    end
                                                                        as week_of_month_normalised
                                                                    , 365 - DATEDIFF(day, date_actual, last_day_of_fiscal_year) as day_of_fiscal_year_normalised
                                                                    , case
                                                                        when (
                                                                            (
                                                                                DATEDIFF(
                                                                                    day
                                                                                    , date_actual
                                                                                    , last_day_of_fiscal_quarter
                                                                                )
                                                                                - 6
                                                                            )
                                                                            % 7
                                                                            = 0
                                                                            or date_actual
                                                                            = first_day_of_fiscal_quarter
                                                                        )
                                                                            then 1
                                                                        else 0
                                                                    end
                                                                        as is_first_day_of_fiscal_quarter_week

                                                                        , DATEDIFF(
                                                                            'day', date_day, last_day_of_month
                                                                        ) as days_until_last_day_of_month

                                                                    from date_spine

                                                                )

, current_date_information as (

                                                                    select
                                                                        fiscal_year
                                                                            as current_fiscal_year
                                                                        , first_day_of_fiscal_year as current_first_day_of_fiscal_year
                                                                        , fiscal_quarter_name_fy as current_fiscal_quarter_name_fy
                                                                        , first_day_of_month as current_first_day_of_month
                                                                        , first_day_of_fiscal_quarter as current_first_day_of_fiscal_quarter
                                                                        , date_actual
                                                                            as current_date_actual

                                                                            , day_of_month
                                                                                as current_day_of_month
                                                                            , day_of_fiscal_quarter as current_day_of_fiscal_quarter
                                                                            , day_of_fiscal_year as current_day_of_fiscal_year

                                                                        from calculated
                                                                        where CURRENT_DATE
                                                                            = date_actual

                                                                    )

, final as (

                                                                        select
                                                                            calculated.date_day
                                                                            , calculated.date_actual
                                                                            , calculated.day_name
                                                                            , calculated.month_actual
                                                                            , calculated.year_actual
                                                                            , calculated.quarter_actual
                                                                            , calculated.day_of_week
                                                                            , calculated.first_day_of_week
                                                                            , calculated.week_of_year
                                                                            , calculated.day_of_month
                                                                            , calculated.day_of_quarter
                                                                            , calculated.day_of_year
                                                                            , calculated.fiscal_year
                                                                            , calculated.fiscal_quarter
                                                                            , calculated.day_of_fiscal_quarter
                                                                            , calculated.day_of_fiscal_year
                                                                            , calculated.month_name
                                                                            , calculated.first_day_of_month
                                                                            , calculated.last_day_of_month
                                                                            , calculated.first_day_of_year
                                                                            , calculated.last_day_of_year
                                                                            , calculated.first_day_of_quarter
                                                                            , calculated.last_day_of_quarter
                                                                            , calculated.first_day_of_fiscal_quarter
                                                                            , calculated.last_day_of_fiscal_quarter
                                                                            , calculated.first_day_of_fiscal_year
                                                                            , calculated.last_day_of_fiscal_year
                                                                            , calculated.week_of_fiscal_year
                                                                            , calculated.month_of_fiscal_year
                                                                            , calculated.last_day_of_week
                                                                            , calculated.quarter_name
                                                                            , calculated.fiscal_quarter_name
                                                                            , calculated.fiscal_quarter_name_fy
                                                                            , calculated.fiscal_quarter_number_absolute
                                                                            , calculated.fiscal_month_name
                                                                            , calculated.fiscal_month_name_fy
                                                                            , calculated.holiday_desc
                                                                            , calculated.is_holiday
                                                                            , calculated.last_month_of_fiscal_quarter
                                                                            , calculated.is_first_day_of_last_month_of_fiscal_quarter
                                                                            , calculated.last_month_of_fiscal_year
                                                                            , calculated.is_first_day_of_last_month_of_fiscal_year
                                                                            , calculated.snapshot_date_fpa
                                                                            , calculated.snapshot_date_fpa_fifth
                                                                            , calculated.snapshot_date_billings
                                                                            , calculated.days_in_month_count
                                                                            , calculated.week_of_month_normalised
                                                                            , calculated.day_of_fiscal_quarter_normalised
                                                                            , calculated.week_of_fiscal_quarter_normalised
                                                                            , calculated.day_of_fiscal_year_normalised
                                                                            , calculated.is_first_day_of_fiscal_quarter_week
                                                                            , calculated.days_until_last_day_of_month
                                                                            , current_date_information.current_date_actual
                                                                            , current_date_information.current_fiscal_year
                                                                            , current_date_information.current_first_day_of_fiscal_year
                                                                            , current_date_information.current_fiscal_quarter_name_fy
                                                                            , current_date_information.current_first_day_of_month
                                                                            , current_date_information.current_first_day_of_fiscal_quarter
                                                                            , current_date_information.current_day_of_month
                                                                            , current_date_information.current_day_of_fiscal_quarter
                                                                            , current_date_information.current_day_of_fiscal_year
                                                                            , IFF(calculated.day_of_month <= current_date_information.current_day_of_month, true, false) as is_fiscal_month_to_date
                                                                            , IFF(calculated.day_of_fiscal_quarter <= current_date_information.current_day_of_fiscal_quarter, true, false) as is_fiscal_quarter_to_date
                                                                            , IFF(calculated.day_of_fiscal_year <= current_date_information.current_day_of_fiscal_year, true, false) as is_fiscal_year_to_date
                                                                            , DATEDIFF('days', calculated.date_actual, CURRENT_DATE) as fiscal_days_ago
                                                                            , DATEDIFF('week', calculated.date_actual, CURRENT_DATE) as fiscal_weeks_ago
                                                                            , DATEDIFF('months', calculated.first_day_of_month, current_date_information.current_first_day_of_month) as fiscal_months_ago
                                                                            , ROUND(DATEDIFF('months', calculated.first_day_of_fiscal_quarter, current_date_information.current_first_day_of_fiscal_quarter) / 3, 0) as fiscal_quarters_ago
                                                                            , ROUND(DATEDIFF('months', calculated.first_day_of_fiscal_year, current_date_information.current_first_day_of_fiscal_year) / 12, 0) as fiscal_years_ago

                                                                        from calculated
                                                                            cross join
                                                                                current_date_information

                                                                    )

                                                                    select *
                                                                    from final

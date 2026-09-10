with cte_sat_date_fiscal_445 as (
    select *
    from {{ ref('ref_sat_date_fiscal_445') }}
)

, cte_sat_date_fiscal_445__latest as (
    {{ generate_cte_satellite_latest(cte_name = 'cte_sat_date_fiscal_445', hk_field = 'date_bk') }}
)

, current_week as (
    select
        fiscal_445_cal_week_yyyyww as week
        , fiscal_445_cal_week as cal_week
        , fiscal_445_cal_year as year
    from cte_sat_date_fiscal_445__latest
    where date = CURRENT_DATE
)

, last_completed_week_end_date as (
    select MAX(date) as max_date
    from cte_sat_date_fiscal_445__latest
    where fiscal_445_cal_week_yyyyww = (
            select fiscal_445_cal_week_yyyyww
            from cte_sat_date_fiscal_445__latest
            where date = DATEADD(week, -1, CURRENT_DATE)
            limit 1
        )
)

, last_year_completed_week_end_date as (
    select MAX(date) as max_date
    from cte_sat_date_fiscal_445__latest
    where fiscal_445_cal_week_yyyyww = (
            select fiscal_445_cal_week_yyyyww
            from cte_sat_date_fiscal_445__latest
            where fiscal_445_cal_year = (
                    select fiscal_445_cal_year
                    from cte_sat_date_fiscal_445__latest
                    where date = CURRENT_DATE
                ) - 1
                and fiscal_445_cal_week = (
                    select fiscal_445_cal_week
                    from cte_sat_date_fiscal_445__latest
                    where date = DATEADD(week, -1, CURRENT_DATE)
                )
            limit 1
        )
)

, anchor_dates as (
    select
        -- Week flags
        (
            select fiscal_445_cal_week_yyyyww
            from cte_sat_date_fiscal_445__latest
            where date = DATEADD(week, -1, CURRENT_DATE)
            limit 1
        ) as last_week_yyyyww
        , (
            select fiscal_445_cal_week_yyyyww
            from cte_sat_date_fiscal_445__latest
            where date = DATEADD(week, -2, CURRENT_DATE)
            limit 1
        ) as two_weeks_ago_yyyyww
        , (
            select fiscal_445_cal_week_yyyyww
            from cte_sat_date_fiscal_445__latest
            where date = DATEADD(week, -1, DATEADD(year, -1, CURRENT_DATE))
            limit 1
        ) as last_year_week_yyyyww
        -- Month flags
        , (
            select fiscal_445_cal_month_yyyymm
            from cte_sat_date_fiscal_445__latest
            where date = DATEADD(month, -1, CURRENT_DATE)
            limit 1
        ) as last_month_yyyymm
        , (
            select fiscal_445_cal_month_yyyymm
            from cte_sat_date_fiscal_445__latest
            where date = DATEADD(month, -2, CURRENT_DATE)
            limit 1
        ) as two_months_ago_yyyymm
        , (
            select fiscal_445_cal_month_yyyymm
            from cte_sat_date_fiscal_445__latest
            where fiscal_445_cal_month_yyyymm = (
                    select MAX(fiscal_445_cal_month_yyyymm)
                    from cte_sat_date_fiscal_445__latest
                    where date <= DATEADD(month, -1, DATEADD(year, -1, CURRENT_DATE))
                )
            limit 1
        ) as last_year_month_yyyymm
        -- YTD
        , (
            select fiscal_445_cal_year
            from cte_sat_date_fiscal_445__latest
            where date = CURRENT_DATE
        ) as current_fiscal_year
        , (
            select fiscal_445_cal_year
            from cte_sat_date_fiscal_445__latest
            where date = DATEADD(year, -1, CURRENT_DATE)
        ) as last_fiscal_year
)

, fiscal_periods as (
    select
        fiscal_445_cal_week_yyyyww
        , fiscal_445_cal_month_yyyymm
        , date
    from cte_sat_date_fiscal_445__latest
)-- Get current fiscal quarter and year

, current_fiscal_quarter_info as (
    select
        fiscal_445_cal_quarter_yyyyqq
        , fiscal_445_cal_quarter
        , fiscal_445_cal_year
    from cte_sat_date_fiscal_445__latest
    where date = CURRENT_DATE
    limit 1
)

-- Get the max date from the last completed quarter
, last_completed_quarter_date as (
    select MAX(date) as max_date
    from cte_sat_date_fiscal_445__latest
    where fiscal_445_cal_quarter_yyyyqq < (
            select fiscal_445_cal_quarter_yyyyqq
            from current_fiscal_quarter_info
        )
)



, last_completed_quarter_year as (
    select fiscal_445_cal_year
    from cte_sat_date_fiscal_445__latest
    where date = (select max_date from last_completed_quarter_date)
    limit 1
)

-- Get the max date for two quarters ago
, two_quarters_ago_date as (
    select MAX(date) as max_date
    from cte_sat_date_fiscal_445__latest
    where fiscal_445_cal_quarter_yyyyqq < (
            select MIN(fiscal_445_cal_quarter_yyyyqq)
            from cte_sat_date_fiscal_445__latest
            where date = (select max_date from last_completed_quarter_date)
        )
)

, two_quarters_ago as (
    select
        fiscal_445_cal_quarter
        , fiscal_445_cal_year
    from cte_sat_date_fiscal_445__latest
    where date = (select max_date from two_quarters_ago_date)
    limit 1
),last_completed_quarter AS (
    SELECT fiscal_445_cal_quarter
    FROM cte_sat_date_fiscal_445__latest
    WHERE date = (SELECT max_date FROM last_completed_quarter_date)
    LIMIT 1
),

last_year_completed_quarter_date AS (
    SELECT MAX(date) AS max_date
    FROM cte_sat_date_fiscal_445__latest
    WHERE fiscal_445_cal_year = (
        SELECT fiscal_445_cal_year - 1
        FROM current_fiscal_quarter_info
    )
    AND fiscal_445_cal_quarter = (
        SELECT fiscal_445_cal_quarter
        FROM last_completed_quarter
    )
),

last_year_completed_quarter AS (
    SELECT fiscal_445_cal_quarter
    FROM cte_sat_date_fiscal_445__latest
    WHERE date = (SELECT max_date FROM last_year_completed_quarter_date)
    LIMIT 1
),

last_year_completed_quarter_year AS (
    SELECT fiscal_445_cal_year
    FROM cte_sat_date_fiscal_445__latest
    WHERE date = (SELECT max_date FROM last_year_completed_quarter_date)
    LIMIT 1
)
select
    hd.date_bk
    , sd.date
    , sd.fiscal_445_cal_day
    , sd.fiscal_445_cal_week
    , sd.fiscal_445_cal_month
    , sd.fiscal_445_cal_quarter
    , sd.fiscal_445_cal_year
    , sd.fiscal_445_cal_quarter_yyyyqq
    , sd.fiscal_445_cal_month_yyyymm
    , sd.fiscal_445_cal_week_yyyyww
    , sd.fiscal_445_working_day_flag
    , sd.fiscal_445_cal_month_yyyymm < TO_NUMBER(TO_CHAR(CURRENT_DATE, 'yyyymm')) as is_completed_fiscal_month
    , sd.fiscal_445_cal_week_yyyyww < curr.week as is_completed_fiscal_week
    -- Last Week Flag
    , case
        when sd.fiscal_445_cal_week_yyyyww = ad.last_week_yyyyww then 1
        when sd.fiscal_445_cal_week_yyyyww = ad.two_weeks_ago_yyyyww then 2
        when sd.fiscal_445_cal_week_yyyyww = ad.last_year_week_yyyyww then 3
        else 0
    end as fiscal_last_week_flag
    -- 4 Week Flag
    , case
        when sd.fiscal_445_cal_week_yyyyww in (
                select distinct fiscal_445_cal_week_yyyyww
                from fiscal_periods
                where
                    date between DATEADD(
                        week
                        , -3
                        , (
                            select max_date
                            from last_completed_week_end_date
                        )
                    ) and (
                        select max_date
                        from last_completed_week_end_date
                    )
            )
            then 1
        when sd.fiscal_445_cal_week_yyyyww in (
                select distinct fiscal_445_cal_week_yyyyww
                from fiscal_periods
                where
                    date between DATEADD(
                        week
                        , -7
                        , (
                            select max_date
                            from last_completed_week_end_date
                        )
                    ) and DATEADD(
                        week
                        , -4
                        , (
                            select max_date
                            from last_completed_week_end_date
                        )
                    )
            )
            then 2
        when sd.fiscal_445_cal_week_yyyyww in (
                select distinct fiscal_445_cal_week_yyyyww
                from fiscal_periods
                where
                    date between DATEADD(
                        week
                        , -3
                        , (
                            select max_date
                            from last_year_completed_week_end_date
                        )
                    ) and (
                        select max_date
                        from last_year_completed_week_end_date
                    )
            )
            then 3
        else 0
    end as fiscal_last_4_weeks_flag
    -- 13 Week Flag
    , case
        when sd.fiscal_445_cal_week_yyyyww in (
                select distinct fiscal_445_cal_week_yyyyww
                from fiscal_periods
                where
                    date between DATEADD(
                        week
                        , -12
                        , (
                            select max_date
                            from last_completed_week_end_date
                        )
                    ) and (
                        select max_date
                        from last_completed_week_end_date
                    )
            )
            then 1
        when sd.fiscal_445_cal_week_yyyyww in (
                select distinct fiscal_445_cal_week_yyyyww
                from fiscal_periods
                where
                    date between DATEADD(
                        week
                        , -25
                        , (
                            select max_date
                            from last_completed_week_end_date
                        )
                    ) and DATEADD(
                        week
                        , -13
                        , (
                            select max_date
                            from last_completed_week_end_date
                        )
                    )
            )
            then 2
        when sd.fiscal_445_cal_week_yyyyww in (
                select distinct fiscal_445_cal_week_yyyyww
                from fiscal_periods
                where
                    date between DATEADD(
                        week
                        , -12
                        , (
                            select max_date
                            from last_year_completed_week_end_date
                        )
                    ) and (
                        select max_date
                        from last_year_completed_week_end_date
                    )
            )
            then 3
        else 0
    end as fiscal_last_13_weeks_flag
    -- Last Month Flag
    , case
        when sd.fiscal_445_cal_month_yyyymm = ad.last_month_yyyymm then 1
        when sd.fiscal_445_cal_month_yyyymm = ad.two_months_ago_yyyymm then 2
        when sd.fiscal_445_cal_month_yyyymm = ad.last_year_month_yyyymm then 3
        else 0
    end as fiscal_last_month_flag
    -- 3 Month Flag
    , case
        -- Last 3 full months
        when sd.fiscal_445_cal_month_yyyymm in (
                select distinct fiscal_445_cal_month_yyyymm
                from fiscal_periods
                where
                    date >= DATEADD(
                        month
                        , -2
                        , DATE_TRUNC(
                            'month'
                            , (
                                select MAX(date)
                                from fiscal_periods
                                where
                                    fiscal_445_cal_month_yyyymm = ad.last_month_yyyymm
                            )
                        )
                    )
                    and date <= (
                        select MAX(date)
                        from fiscal_periods
                        where
                            fiscal_445_cal_month_yyyymm = ad.last_month_yyyymm
                    )
            )
            then 1
        -- Previous 3 full months (4-6 months ago)
        when sd.fiscal_445_cal_month_yyyymm in (
                select distinct fiscal_445_cal_month_yyyymm
                from fiscal_periods
                where
                    date >= DATEADD(
                        month
                        , -5
                        , DATE_TRUNC(
                            'month'
                            , (
                                select MAX(date)
                                from fiscal_periods
                                where
                                    fiscal_445_cal_month_yyyymm = ad.last_month_yyyymm
                            )
                        )
                    )
                    and date <= DATEADD(
                        month
                        , -3
                        , (
                            select MAX(date)
                            from fiscal_periods
                            where
                                fiscal_445_cal_month_yyyymm = ad.last_month_yyyymm
                        )
                    )
            )
            then 2
        -- Same 3-month period last year
        when sd.fiscal_445_cal_month_yyyymm in (
                select distinct fiscal_445_cal_month_yyyymm
                from fiscal_periods
                where
                    date >= DATEADD(
                        month
                        , -2
                        , DATE_TRUNC(
                            'month'
                            , (
                                select MAX(date)
                                from fiscal_periods
                                where
                                    fiscal_445_cal_month_yyyymm = ad.last_year_month_yyyymm
                            )
                        )
                    )
                    and date <= (
                        select MAX(date)
                        from fiscal_periods
                        where
                            fiscal_445_cal_month_yyyymm = ad.last_year_month_yyyymm
                    )
            )
            then 3
        else 0
    end as fiscal_last_3_months_flag
    -- Names & Epochs
    , TO_CHAR(
        DATEADD(
            month
            , fiscal_445_cal_month - 1
            , DATE_TRUNC('YEAR', sd.date)
        )
        , 'MMMM'
    ) as month_name
    , TO_CHAR(
        DATEADD(
            month
            , fiscal_445_cal_month - 1
            , DATE_TRUNC('YEAR', sd.date)
        )
        , 'MON'
    ) as month_name_abbr
    , DATEDIFF('day', MIN(sd.date) over (), sd.date) + 1 as epoch_day
    , DENSE_RANK() over (
        order by
            sd.fiscal_445_cal_week_yyyyww
    ) as epoch_week
    , DENSE_RANK() over (
        order by
            sd.fiscal_445_cal_month_yyyymm
    ) as epoch_month
    -- Weeks in 445 month
    , case sd.fiscal_445_cal_month
        when 1 then 4
        when 2 then 4
        when 3 then 5
        when 4 then 4
        when 5 then 4
        when 6 then 5
        when 7 then 4
        when 8 then 4
        when 9 then 5
        when 10 then 4
        when 11 then 4
        when 12 then 5
    end as weeks_in_month
    -- Formatting helpers
    , LPAD(TO_CHAR(sd.fiscal_445_cal_month), 2, '0') as month_number_leading_zero
    , DATEDIFF(
        day
        , FIRST_VALUE(sd.date)
            over (
                partition by sd.fiscal_445_cal_year
                order by
                    sd.date
            )
        , sd.date
    ) + 1 as fiscal_day_of_year
    -- YTD Flag
    , case
        when sd.fiscal_445_cal_year = ad.current_fiscal_year
            and sd.date <= (
                select max_date
                from last_completed_week_end_date
            )
            then 1
        when sd.fiscal_445_cal_year = ad.last_fiscal_year
            and sd.date <= (
                select max_date
                from last_year_completed_week_end_date
            )
            then 3
        else 0
    end as fiscal_ytd_flag
    -- 52-Week Rolling
    , case
        when sd.fiscal_445_cal_week_yyyyww between (
                select MIN(fiscal_445_cal_week_yyyyww)
                from
                    cte_sat_date_fiscal_445__latest
                where
                    date >= DATEADD(
                        day
                        , -363
                        /* Exactly 52 weeks worth of days */,
                        (
                            select max_date
                            from
                                last_completed_week_end_date
                        )
                    )
            )
            and (
                select fiscal_445_cal_week_yyyyww
                from cte_sat_date_fiscal_445__latest
                where
                    date = (
                        select max_date
                        from
                            last_completed_week_end_date
                    )
            ) then 1
        when sd.fiscal_445_cal_week_yyyyww between (
                select MIN(fiscal_445_cal_week_yyyyww)

                from cte_sat_date_fiscal_445__latest
                where
                    date >= DATEADD(
                        day
                        , -363
                        , (
                            select max_date
                            from
                                last_year_completed_week_end_date
                        )
                    )
            )
            and (
                select fiscal_445_cal_week_yyyyww
                from
                    cte_sat_date_fiscal_445__latest
                where
                    date = (
                        select max_date
                        from
                            last_year_completed_week_end_date
                    )
            ) then 2
        else 0
    end as fiscal_rolling_52_week_flag
    , case
        when sd.fiscal_445_cal_quarter = (select fiscal_445_cal_quarter from last_completed_quarter)
            and sd.fiscal_445_cal_year = (select fiscal_445_cal_year from last_completed_quarter_year)
            then 1
        when sd.fiscal_445_cal_quarter = (select fiscal_445_cal_quarter from two_quarters_ago)
            and sd.fiscal_445_cal_year = (select fiscal_445_cal_year from two_quarters_ago)
            then 2
        when sd.fiscal_445_cal_quarter = (select fiscal_445_cal_quarter from last_year_completed_quarter)
            and sd.fiscal_445_cal_year = (select fiscal_445_cal_year from last_year_completed_quarter_year)
            then 3
        else 0
    end as fiscal_last_quarter_flag,
    case
    -- Last 12 full months
    when sd.fiscal_445_cal_month_yyyymm in (
        select distinct fiscal_445_cal_month_yyyymm
        from fiscal_periods
        where
            date >= DATEADD(
                month,
                -11,
                DATE_TRUNC(
                    'month',
                    (
                        select MAX(date)
                        from fiscal_periods
                        where fiscal_445_cal_month_yyyymm = ad.last_month_yyyymm
                    )
                )
            )
            and date <= (
                select MAX(date)
                from fiscal_periods
                where fiscal_445_cal_month_yyyymm = ad.last_month_yyyymm
            )
    ) then 1

    -- Same 12-month period last year
    when sd.fiscal_445_cal_month_yyyymm in (
        select distinct fiscal_445_cal_month_yyyymm
        from fiscal_periods
        where
            date >= DATEADD(
                month,
                -11,
                DATE_TRUNC(
                    'month',
                    (
                        select MAX(date)
                        from fiscal_periods
                        where fiscal_445_cal_month_yyyymm = ad.last_year_month_yyyymm
                    )
                )
            )
            and date <= (
                select MAX(date)
                from fiscal_periods
                where fiscal_445_cal_month_yyyymm = ad.last_year_month_yyyymm
            )
    ) then 2

    else 0
end as fiscal_last_12_months_flag

 ,case
    --  CONDITION 1: Current week is the first week of the quarter
    when (
        select MIN(fiscal_445_cal_week_yyyyww)
        from cte_sat_date_fiscal_445__latest
        where fiscal_445_cal_quarter_yyyyqq = (
            select fiscal_445_cal_quarter_yyyyqq
            from current_fiscal_quarter_info
        )
    ) = (select week from current_week) then
        case
            -- Flag 1 → Entire previous quarter
            when sd.fiscal_445_cal_quarter = (
                select fiscal_445_cal_quarter
                from last_completed_quarter
            )
            and sd.fiscal_445_cal_year = (
                select fiscal_445_cal_year
                from last_completed_quarter_year
            ) then 1

            -- Flag 2 → Entire quarter prior to the previous quarter
            when sd.fiscal_445_cal_quarter = (
                select fiscal_445_cal_quarter
                from two_quarters_ago
            )
            and sd.fiscal_445_cal_year = (
                select fiscal_445_cal_year
                from two_quarters_ago
            ) then 2

            -- Flag 3 → Same quarter as Flag 1, but from last year
            when sd.fiscal_445_cal_quarter = (
                select fiscal_445_cal_quarter
                from last_year_completed_quarter
            )
            and sd.fiscal_445_cal_year = (
                select fiscal_445_cal_year
                from last_year_completed_quarter_year
            ) then 3
            else 0
        end

    --  CONDITION 2: Current week is NOT the first week of the quarter
    else
        case
            -- Count number of completed weeks so far in current quarter
            when sd.fiscal_445_cal_week_yyyyww in (
                select distinct fiscal_445_cal_week_yyyyww
                from cte_sat_date_fiscal_445__latest
                where
                    date between (
                        select MIN(date)
                        from cte_sat_date_fiscal_445__latest
                        where fiscal_445_cal_quarter_yyyyqq = (
                            select fiscal_445_cal_quarter_yyyyqq
                            from current_fiscal_quarter_info
                        )
                    )
                    and (
                        select max_date
                        from last_completed_week_end_date
                    )
            ) then 1

            -- Flag 2 → Same number of weeks from previous quarter
            when sd.fiscal_445_cal_week_yyyyww in (
                select distinct fiscal_445_cal_week_yyyyww
                from cte_sat_date_fiscal_445__latest
                where
                    date between (
                        select MIN(date)
                        from cte_sat_date_fiscal_445__latest
                        where fiscal_445_cal_quarter = (
                            select fiscal_445_cal_quarter
                            from last_completed_quarter
                        )
                        and fiscal_445_cal_year = (
                            select fiscal_445_cal_year
                            from last_completed_quarter_year
                        )
                    )
                    and DATEADD(
                        week,
                        (
                            select COUNT(distinct fiscal_445_cal_week_yyyyww)
                            from cte_sat_date_fiscal_445__latest
                            where
                                date between (
                                    select MIN(date)
                                    from cte_sat_date_fiscal_445__latest
                                    where fiscal_445_cal_quarter_yyyyqq = (
                                        select fiscal_445_cal_quarter_yyyyqq
                                        from current_fiscal_quarter_info
                                    )
                                )
                                and (
                                    select max_date
                                    from last_completed_week_end_date
                                )
                        ) - 1,
                        (
                            select MIN(date)
                            from cte_sat_date_fiscal_445__latest
                            where fiscal_445_cal_quarter = (
                                select fiscal_445_cal_quarter
                                from last_completed_quarter
                            )
                            and fiscal_445_cal_year = (
                                select fiscal_445_cal_year
                                from last_completed_quarter_year
                            )
                        )
                    )
            ) then 2
-- Flag 3 → Same week positions in same quarter last year
when sd.fiscal_445_cal_week_yyyyww in (
    select ly.fiscal_445_cal_week_yyyyww
    from (
        select
            ly.fiscal_445_cal_week_yyyyww,
            DENSE_RANK() over (
                partition by ly.fiscal_445_cal_quarter_yyyyqq
                order by ly.fiscal_445_cal_week_yyyyww
            ) as ly_week_num_in_qtr
        from cte_sat_date_fiscal_445__latest ly
        where
            ly.fiscal_445_cal_quarter = (
                select fiscal_445_cal_quarter
                from current_fiscal_quarter_info
            )
            and ly.fiscal_445_cal_year = (
                select fiscal_445_cal_year - 1
                from current_fiscal_quarter_info
            )
    ) ly
    where ly.ly_week_num_in_qtr <= (
        -- Count how many weeks are completed in current quarter so far
        select COUNT(distinct fiscal_445_cal_week_yyyyww)
        from cte_sat_date_fiscal_445__latest
        where date between (
            select MIN(date)
            from cte_sat_date_fiscal_445__latest
            where fiscal_445_cal_quarter_yyyyqq = (
                select fiscal_445_cal_quarter_yyyyqq
                from current_fiscal_quarter_info
            )
        )
        and (
            select max_date
            from last_completed_week_end_date
        )
    )
) then 3

  
            else 0
        end
end as fiscal_qtd_flag

from
    {{ ref('ref_hub_date') }} as hd
    inner join
        cte_sat_date_fiscal_445__latest as sd
        on hd.date_bk = sd.date_bk
    cross join
        current_week as curr
    cross join
        anchor_dates as ad

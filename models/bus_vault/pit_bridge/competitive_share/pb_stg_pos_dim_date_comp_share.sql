{{ config(materialized='table',
    transient = true) }}
-- Intentional materialization override to avoid performance bottlenecks caused by chained ephemeral models.


---- SRC LAYER ----
WITH
SRC_DIM            as ( 
    SELECT * 
    FROM {{ ref('pit_date_fiscal_445') }} as SRC 
    WHERE year(SRC.date) < year(current_date()) 
        OR (
            year(SRC.date) = year(current_date()) 
            AND SRC.fiscal_445_cal_week < (
                SELECT fiscal_445_cal_week 
                FROM {{ ref('pit_date_fiscal_445') }} 
                WHERE date = current_date()
            ) 
            AND SRC.date < current_date()
        ) 
)

/*
SRC_DIM            as ( SELECT * FROM infomart.pit_date_fiscal_445 )
*/
---- LOGIC LAYER ----

, LOGIC_DIM as (
    SELECT
        max(date) over(partition by FISCAL_445_CAL_WEEK_YYYYWW order by date desc) as                                   TRANSACTION_DATE
      , to_char(transaction_date, 'YYYYMMDD')                        as                                TRANSACTION_DATEKEY
      , DATE
      , to_char(date, 'YYYYMMDD')                                    as                                       DATE_DATEKEY
      , FISCAL_445_CAL_WEEK_YYYYWW
    FROM SRC_DIM
)
---- RENAME LAYER ----

, RENAME_DIM as (
    SELECT
        TRANSACTION_DATE
      , TRANSACTION_DATEKEY
      , DATE
      , DATE_DATEKEY
      , FISCAL_445_CAL_WEEK_YYYYWW
    FROM LOGIC_DIM
)
---- FILTER LAYER ----

, FILTER_DIM as (
    SELECT *
    FROM RENAME_DIM
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_DIM
)

---- FINAL LAYER ----
SELECT
          TRANSACTION_DATE
        , TRANSACTION_DATEKEY
        , DATE
        , DATE_DATEKEY
        , FISCAL_445_CAL_WEEK_YYYYWW
FROM JOIN_RESULT

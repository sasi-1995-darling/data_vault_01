{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HT             as ( SELECT BKCC, REC_SRC, TRANSACTION_BK, TRANSACTION_HK FROM {{ ref('hub_transaction') }} as SRC  ),
SRC_SBT            as ( SELECT AMOUNT, AVAILABLE_ON, CREATED, DESCRIPTION, FEE, NET, STATUS, TRANSACTION_HK, TYPE FROM {{ ref('sat_balance_transaction__flo_sense') }} as SRC 
                        qualify 1= row_number() over(partition by TRANSACTION_HK order by LOAD_DTS DESC) )

/*
SRC_HT             as ( SELECT * FROM raw_vault.HUB_TRANSACTION )
SRC_SBT            as ( SELECT * FROM raw_vault.SAT_BALANCE_TRANSACTION__FLO_SENSE )
*/
---- LOGIC LAYER ----

, LOGIC_HT as (
    SELECT
        TRANSACTION_HK
      , TRANSACTION_BK
      , BKCC
      , REC_SRC
    FROM SRC_HT
)

, LOGIC_SBT as (
    SELECT
        TRANSACTION_HK                                               as                                 SBT_TRANSACTION_HK
      , AMOUNT                                                       as                                       AMOUNT_CENTS
      , FEE                                                          as                                          FEE_CENTS
      , NET                                                          as                                          NET_CENTS
      , AVAILABLE_ON                                                 as                                    AVAILABLE_ON_TS
      , CREATED                                                      as                                         CREATED_TS
      , DESCRIPTION
      , STATUS
      , TYPE
      , ROUND(AMOUNT/100,2)                                          as                                         AMOUNT_USD
      , ROUND(FEE/100,2)                                             as                                            FEE_USD
      , ROUND(NET/100,2)                                             as                                            NET_USD
      , CASE
            WHEN LOWER(STATUS) IN ('available','pending')
            AND LOWER(TYPE)   IN ('charge','adjustment')
        THEN 1 ELSE 0 END                                            as                                    IS_ARR_ELIGIBLE
      , DATE_TRUNC('month', CREATED)                                 as                                        MONTH_START
      , year(CREATED)                                                as                                           YEAR_NUM
      , month(CREATED)                                               as                                          MONTH_NUM
    FROM SRC_SBT
)
---- RENAME LAYER ----

, RENAME_HT as (
    SELECT
        TRANSACTION_HK
      , TRANSACTION_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_HT
)

, RENAME_SBT as (
    SELECT
        SBT_TRANSACTION_HK
      , AMOUNT_CENTS
      , FEE_CENTS
      , NET_CENTS
      , AVAILABLE_ON_TS
      , CREATED_TS
      , DESCRIPTION
      , STATUS
      , TYPE
      , AMOUNT_USD
      , FEE_USD
      , NET_USD
      , IS_ARR_ELIGIBLE
      , MONTH_START
      , YEAR_NUM
      , MONTH_NUM
    FROM LOGIC_SBT
)
---- FILTER LAYER ----

, FILTER_HT as (
    SELECT *
    FROM RENAME_HT
)

, FILTER_SBT as (
    SELECT *
    FROM RENAME_SBT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HT
    INNER JOIN FILTER_SBT
        ON TRANSACTION_HK = SBT_TRANSACTION_HK
)

---- FINAL LAYER ----
SELECT
          TRANSACTION_HK
        , TRANSACTION_BK
        , BKCC
        , REC_SRC
        , AMOUNT_CENTS
        , FEE_CENTS
        , NET_CENTS
        , AVAILABLE_ON_TS
        , CREATED_TS
        , DESCRIPTION
        , STATUS
        , TYPE
        , AMOUNT_USD
        , FEE_USD
        , NET_USD
        , IS_ARR_ELIGIBLE
        , MONTH_START
        , YEAR_NUM
        , MONTH_NUM
FROM JOIN_RESULT

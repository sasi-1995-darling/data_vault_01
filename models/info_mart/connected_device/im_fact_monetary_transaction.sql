{{ config(alias='fact_monetary_transaction') }}
---- SRC LAYER ----
WITH
SRC_FMT            as ( SELECT AMOUNT_CENTS, AMOUNT_USD, AVAILABLE_ON_TS, BKCC, CREATED_TS, DESCRIPTION, FEE_CENTS, FEE_USD, IS_ARR_ELIGIBLE, MONTH_NUM, MONTH_START, NET_CENTS, NET_USD, REC_SRC, STATUS, TRANSACTION_BK, TYPE, YEAR_NUM FROM {{ ref('fact_monetary_transaction') }} as SRC  )

/*
SRC_FMT            as ( SELECT * FROM BUS_VAULT.FACT_MONETARY_TRANSACTION )
*/
---- LOGIC LAYER ----

, LOGIC_FMT as (
    SELECT
        TRANSACTION_BK
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
    FROM SRC_FMT
)
---- RENAME LAYER ----

, RENAME_FMT as (
    SELECT
        TRANSACTION_BK
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
    FROM LOGIC_FMT
)
---- FILTER LAYER ----

, FILTER_FMT as (
    SELECT *
    FROM RENAME_FMT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_FMT
)

---- FINAL LAYER ----
SELECT
          TRANSACTION_BK
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

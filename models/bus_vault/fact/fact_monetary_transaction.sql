---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT AMOUNT_CENTS, AMOUNT_USD, AVAILABLE_ON_TS, BKCC, CREATED_TS, DESCRIPTION, FEE_CENTS, FEE_USD, IS_ARR_ELIGIBLE, MONTH_NUM, MONTH_START, NET_CENTS, NET_USD, REC_SRC, STATUS, TRANSACTION_BK, TYPE, YEAR_NUM FROM {{ ref('pb_monetary_transaction') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.PB_MONETARY_TRANSACTION )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
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
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
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
    FROM LOGIC_PB
)
---- FILTER LAYER ----

, FILTER_PB as (
    SELECT *
    FROM RENAME_PB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PB
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

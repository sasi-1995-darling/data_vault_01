---- SRC LAYER ----
WITH
SRC_PBBT           as ( SELECT AMOUNT_CENTS, AMOUNT_USD, AVAILABLE_ON_TS, BKCC, CREATED_TS, DESCRIPTION, FEE_CENTS, FEE_USD, IS_ARR_ELIGIBLE, MONTH_NUM, MONTH_START, NET_CENTS, NET_USD, REC_SRC, STATUS, TRANSACTION_BK, TRANSACTION_HK, TYPE, YEAR_NUM FROM {{ ref('pb_stg_balance_transaction') }} as SRC  )

/*
SRC_PBBT           as ( SELECT * FROM BUS_VAULT.PB_STG_BALANCE_TRANSACTION )
*/
---- LOGIC LAYER ----

, LOGIC_PBBT as (
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
    FROM SRC_PBBT
)
---- RENAME LAYER ----

, RENAME_PBBT as (
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
    FROM LOGIC_PBBT
)
---- FILTER LAYER ----

, FILTER_PBBT as (
    SELECT *
    FROM RENAME_PBBT
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PBBT
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , TRANSACTION_HK
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

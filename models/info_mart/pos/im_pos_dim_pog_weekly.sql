{{ config(alias='dim_pog_weekly') }}
---- SRC LAYER ----
WITH
SRC_DPOG           as ( SELECT * FROM {{ ref('dim_pog_weekly') }} as SRC  )

/*
SRC_DPOG           as ( SELECT * FROM BUS_VAULT.DIM_POG_WEEKLY )
*/
---- LOGIC LAYER ----

, LOGIC_DPOG as (
    SELECT
        STORE_KEY
      , STORE_ID
      , ITEM_KEY
      , ITEM_NUMBER
      , SKU
      , TRANSACTION_DATEKEY
      , REPORTING_CUSTOMER
      , BRAND
      , ACTIVE_SKU_FLAG
      , STOCKED_STORE_FLAG
      , FISCAL_445_WEEK_START_DATE__YYYYMMDD
      , FISCAL_445_WEEK_END_DATE__YYYYMMDD
      , BKCC
      , REC_SRC
    FROM SRC_DPOG
)
---- RENAME LAYER ----

, RENAME_DPOG as (
    SELECT
        STORE_KEY 
      , STORE_ID 
      , ITEM_KEY 
      , ITEM_NUMBER 
      , SKU
      , TRANSACTION_DATEKEY 
      , REPORTING_CUSTOMER 
      , BRAND 
      , ACTIVE_SKU_FLAG 
      , STOCKED_STORE_FLAG 
      , FISCAL_445_WEEK_START_DATE__YYYYMMDD 
      , FISCAL_445_WEEK_END_DATE__YYYYMMDD 
      , BKCC 
      , REC_SRC
    FROM LOGIC_DPOG
)
---- FILTER LAYER ----

, FILTER_DPOG as (
    SELECT *
    FROM RENAME_DPOG
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_DPOG
)

---- FINAL LAYER ----
SELECT
          STORE_KEY 
        , STORE_ID 
        , ITEM_KEY 
        , ITEM_NUMBER 
        , SKU
        , TRANSACTION_DATEKEY 
        , REPORTING_CUSTOMER 
        , BRAND 
        , ACTIVE_SKU_FLAG 
        , STOCKED_STORE_FLAG 
        , FISCAL_445_WEEK_START_DATE__YYYYMMDD 
        , FISCAL_445_WEEK_END_DATE__YYYYMMDD 
        , BKCC 
        , REC_SRC
FROM JOIN_RESULT

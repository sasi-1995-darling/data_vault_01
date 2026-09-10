---- SRC LAYER ----
WITH
SRC_PPG            as ( SELECT * FROM {{ ref('pit_pog_weekly') }} as SRC  )

/*
SRC_PPG            as ( SELECT * FROM BUS_VAULT.pit_pog_weekly )
*/
---- LOGIC LAYER ----

, LOGIC_PPG as (
    SELECT
        STORE_KEY
      , STORE_ID
      , ITEM_KEY
      , ITEM_NUMBER
      , SKU --added sku to facilitate better alignment with join to FACT_POS_WEEKLY in downstream infomart
      , TRANSACTION_DATEKEY
      , REPORTING_CUSTOMER
      , BRAND
      , ACTIVE_SKU_FLAG
      , STOCKED_STORE_FLAG
      , FISCAL_445_WEEK_START_DATE__YYYYMMDD
      , FISCAL_445_WEEK_END_DATE__YYYYMMDD
      , BKCC
      , REC_SRC
    FROM SRC_PPG
)
---- RENAME LAYER ----

, RENAME_PPG as (
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
    FROM LOGIC_PPG
)
---- FILTER LAYER ----

, FILTER_PPG as (
    SELECT *
    FROM RENAME_PPG
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PPG
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

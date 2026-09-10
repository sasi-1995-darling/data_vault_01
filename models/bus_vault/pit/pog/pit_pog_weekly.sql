---- SRC LAYER ----
WITH
SRC_src_hd         as ( SELECT ACTIVE_SKU_FLAG, BKCC, BRAND, FISCAL_445_WEEK_END_DATE__YYYYMMDD, FISCAL_445_WEEK_START_DATE__YYYYMMDD, ITEM_KEY, ITEM_NUMBER, REC_SRC, REPORTING_CUSTOMER, SKU, STOCKED_STORE_FLAG, STORE_ID, STORE_KEY, TRANSACTION_DATEKEY FROM {{ ref('stg_pit_pog_weekly_moen_homedepot') }} as SRC  ),
SRC_src_l          as ( SELECT ACTIVE_SKU_FLAG, BKCC, BRAND, FISCAL_445_WEEK_END_DATE__YYYYMMDD, FISCAL_445_WEEK_START_DATE__YYYYMMDD, ITEM_KEY, ITEM_NUMBER, REC_SRC, REPORTING_CUSTOMER, SKU, STOCKED_STORE_FLAG, STORE_ID, STORE_KEY, TRANSACTION_DATEKEY FROM {{ ref('stg_pit_pog_weekly_moen_lowes') }} as SRC 
                        where transaction_datekey < 20250913
                        /*cut-off date for manually-loaded Lowes POG data*/ ),
SRC_src_lapi       as ( SELECT ACTIVE_SKU_FLAG, BKCC, BRAND, FISCAL_445_WEEK_END_DATE__YYYYMMDD, FISCAL_445_WEEK_START_DATE__YYYYMMDD, ITEM_KEY, ITEM_NUMBER, REC_SRC, REPORTING_CUSTOMER, SKU, STOCKED_STORE_FLAG, STORE_ID, STORE_KEY, TRANSACTION_DATEKEY FROM {{ ref('stg_pit_pog_weekly_moen_lowes_api') }} as SRC 
                        where transaction_datekey >= 20250913
                        /*start date for API-loaded Lowes POG data*/ )

/*
SRC_src_hd         as ( SELECT * FROM bus_vault.stg_pit_pog_weekly_moen_homedepot )
SRC_src_l          as ( SELECT * FROM bus_vault.stg_pit_pog_weekly_moen_lowes )
SRC_src_lapi       as ( SELECT * FROM bus_vault.stg_pit_pog_weekly_moen_lowes_api )
*/
---- LOGIC LAYER ----

, LOGIC_src_hd as (
    SELECT
        REPORTING_CUSTOMER
      , BRAND
      , ITEM_KEY
      , ITEM_NUMBER
      , SKU
      , TRANSACTION_DATEKEY
      , STORE_KEY
      , STORE_ID
      , ACTIVE_SKU_FLAG
      , STOCKED_STORE_FLAG
      , FISCAL_445_WEEK_START_DATE__YYYYMMDD
      , FISCAL_445_WEEK_END_DATE__YYYYMMDD
      , BKCC
      , REC_SRC
    FROM SRC_src_hd
)

, LOGIC_src_l as (
    SELECT
        REPORTING_CUSTOMER
      , BRAND
      , ITEM_KEY
      , ITEM_NUMBER
      , SKU
      , TRANSACTION_DATEKEY
      , STORE_KEY
      , STORE_ID
      , ACTIVE_SKU_FLAG
      , STOCKED_STORE_FLAG
      , FISCAL_445_WEEK_START_DATE__YYYYMMDD
      , FISCAL_445_WEEK_END_DATE__YYYYMMDD
      , BKCC
      , REC_SRC
    FROM SRC_src_l
)

, LOGIC_src_lapi as (
    SELECT
        REPORTING_CUSTOMER
      , BRAND
      , ITEM_KEY
      , ITEM_NUMBER
      , SKU
      , TRANSACTION_DATEKEY
      , STORE_KEY
      , STORE_ID
      , ACTIVE_SKU_FLAG
      , STOCKED_STORE_FLAG
      , FISCAL_445_WEEK_START_DATE__YYYYMMDD
      , FISCAL_445_WEEK_END_DATE__YYYYMMDD
      , BKCC
      , REC_SRC
    FROM SRC_src_lapi
)
---- RENAME LAYER ----

, RENAME_src_hd as (
    SELECT
        REPORTING_CUSTOMER
      , BRAND
      , ITEM_KEY
      , ITEM_NUMBER
      , SKU
      , TRANSACTION_DATEKEY
      , STORE_KEY
      , STORE_ID
      , ACTIVE_SKU_FLAG
      , STOCKED_STORE_FLAG
      , FISCAL_445_WEEK_START_DATE__YYYYMMDD
      , FISCAL_445_WEEK_END_DATE__YYYYMMDD
      , BKCC
      , REC_SRC
    FROM LOGIC_src_hd
)

, RENAME_src_l as (
    SELECT
        REPORTING_CUSTOMER
      , BRAND
      , ITEM_KEY
      , ITEM_NUMBER
      , SKU
      , TRANSACTION_DATEKEY
      , STORE_KEY
      , STORE_ID
      , ACTIVE_SKU_FLAG
      , STOCKED_STORE_FLAG
      , FISCAL_445_WEEK_START_DATE__YYYYMMDD
      , FISCAL_445_WEEK_END_DATE__YYYYMMDD
      , BKCC
      , REC_SRC
    FROM LOGIC_src_l
)

, RENAME_src_lapi as (
    SELECT
        REPORTING_CUSTOMER
      , BRAND
      , ITEM_KEY
      , ITEM_NUMBER
      , SKU
      , TRANSACTION_DATEKEY
      , STORE_KEY
      , STORE_ID
      , ACTIVE_SKU_FLAG
      , STOCKED_STORE_FLAG
      , FISCAL_445_WEEK_START_DATE__YYYYMMDD
      , FISCAL_445_WEEK_END_DATE__YYYYMMDD
      , BKCC
      , REC_SRC
    FROM LOGIC_src_lapi
)
---- FILTER LAYER ----

, FILTER_src_hd as (
    SELECT *
    FROM RENAME_src_hd
)

, FILTER_src_l as (
    SELECT *
    FROM RENAME_src_l
)

, FILTER_src_lapi as (
    SELECT *
    FROM RENAME_src_lapi
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_src_hd
    UNION ALL
    SELECT * FROM FILTER_src_l
    UNION ALL
    SELECT * FROM FILTER_src_lapi
)

---- FINAL LAYER ----
SELECT
          RANDOM()                                                     as SEQ_ID
        ,  'PIT_POG_WEEKLY'                                            as PIT_REC_SRC
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PIT_LOAD_DTS
        , REPORTING_CUSTOMER
        , BRAND
        , ITEM_KEY
        , ITEM_NUMBER
        , SKU::varchar as SKU   --added manual varchar formatting to resolve datatype mismatch bug with join to FACT_POS_WEEKLY in REP_POS_WEEKLY infomart
        , TRANSACTION_DATEKEY
        , STORE_KEY
        , STORE_ID
        , ACTIVE_SKU_FLAG
        , STOCKED_STORE_FLAG
        , FISCAL_445_WEEK_START_DATE__YYYYMMDD
        , FISCAL_445_WEEK_END_DATE__YYYYMMDD
        , BKCC
        , REC_SRC
FROM JOIN_RESULT

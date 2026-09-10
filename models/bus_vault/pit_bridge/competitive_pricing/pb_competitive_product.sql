{{ config(materialized='table') }}
---- SRC LAYER ----
WITH
SRC_PCP            as ( SELECT COMPETITIVE_PRODUCT_HK, COMPETITIVE_PRODUCT_BK, RETAILER_HK, RETAILER_BK, RANKING_PRODUCT_ID, RPC, EAN, UPC, MODEL, URL, SOURCE, SAT_REC_SRC, REC_SRC, BKCC FROM {{ ref('pb_stg_competitive_product__profitero') }} as SRC  ),
SRC_PCPS           as ( SELECT COMPETITIVE_PRODUCT_HK, COMPETITIVE_PRODUCT_BK, RETAILER_HK, RETAILER_BK, RANKING_PRODUCT_ID, RPC, EAN, UPC, MODEL, URL, SOURCE, SAT_REC_SRC, REC_SRC, BKCC FROM {{ ref('pb_stg_competitive_product__profitero_share') }} as SRC  )

/*
SRC_PCP            as ( SELECT * FROM bus_vault.PB_STG_COMPETITIVE_PRODUCT__PROFITERO )
SRC_PCPS           as ( SELECT * FROM bus_vault.PB_STG_COMPETITIVE_PRODUCT__PROFITERO_SHARE )
*/
---- LOGIC LAYER ----

, LOGIC_PCP as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , RETAILER_HK
      , RETAILER_BK
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , SOURCE
      , SAT_REC_SRC
      , REC_SRC
      , BKCC
    FROM SRC_PCP
)

, LOGIC_PCPS as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , RETAILER_HK
      , RETAILER_BK
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , SOURCE
      , SAT_REC_SRC
      , REC_SRC
      , BKCC
    FROM SRC_PCPS
)
---- RENAME LAYER ----

, RENAME_PCP as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , RETAILER_HK
      , RETAILER_BK
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , SOURCE
      , SAT_REC_SRC
      , REC_SRC
      , BKCC
    FROM LOGIC_PCP
)

, RENAME_PCPS as (
    SELECT
        COMPETITIVE_PRODUCT_HK
      , COMPETITIVE_PRODUCT_BK
      , RETAILER_HK
      , RETAILER_BK
      , RANKING_PRODUCT_ID
      , RPC
      , EAN
      , UPC
      , MODEL
      , URL
      , SOURCE
      , SAT_REC_SRC
      , REC_SRC
      , BKCC
    FROM LOGIC_PCPS
)
---- FILTER LAYER ----

, FILTER_PCP as (
    SELECT *
    FROM RENAME_PCP
)

, FILTER_PCPS as (
    SELECT *
    FROM RENAME_PCPS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PCP
    UNION ALL
    SELECT * FROM FILTER_PCPS
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , COMPETITIVE_PRODUCT_HK
        , COMPETITIVE_PRODUCT_BK
        , RETAILER_HK
        , RETAILER_BK
        , RANKING_PRODUCT_ID
        , RPC
        , EAN
        , UPC
        , MODEL
        , URL
        , SOURCE
        , SAT_REC_SRC
        , REC_SRC
        , BKCC
FROM JOIN_RESULT

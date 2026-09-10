{{ config(alias='dim_competitive_product') }}
---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT * FROM {{ ref('dim_competitive_product') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.PB_COMPETITIVE_PRODUCT )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
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
      , REC_SRC
      , BKCC
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
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
      , REC_SRC
      , BKCC
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
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
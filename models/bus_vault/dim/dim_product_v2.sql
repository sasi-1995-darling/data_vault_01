---- SRC LAYER ----
WITH
SRC_PP             as ( SELECT * FROM {{ ref('pit_product_v2') }} as SRC  )

/*
SRC_PP             as ( SELECT * FROM bus_vault.pit_product_v2 )
*/
---- LOGIC LAYER ----

, LOGIC_PP as (
    SELECT
        PRODUCT_BK
      , PRODUCT_NAME
      , MODEL
      , BKCC
      , REC_SRC
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , BRAND_ID
    FROM SRC_PP
)
---- RENAME LAYER ----

, RENAME_PP as (
    SELECT
        PRODUCT_BK
      , PRODUCT_NAME
      , MODEL
      , BKCC
      , REC_SRC
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
      , CUSTOMER_PRODUCT_ID
      , LEVEL_1
      , LEVEL_2
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
      , BRAND_ID
    FROM LOGIC_PP
)
---- FILTER LAYER ----

, FILTER_PP as (
    SELECT *
    FROM RENAME_PP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PP
)

---- FINAL LAYER ----
SELECT
          PRODUCT_BK
        , PRODUCT_NAME
        , MODEL
        , BKCC
        , REC_SRC
        , RPC
        , EAN
        , UPC
        , MAP_PRICE
        , SENTIMENT_SRC
        , SRC_ID
        , ROOM_AREA
        , CONNECTED_PRODUCTS_CLASS
        , FIRE_RESISTANT_ATTR
        , SMART_ATTR
        , CUSTOMER_PRODUCT_ID
        , LEVEL_1
        , LEVEL_2
        , CONNECTED_FLAG
        , PRODUCT_FAMILY
        , BRAND_ID
FROM JOIN_RESULT
{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HP             as ( SELECT * FROM {{ ref('hub_product_v2') }} as SRC  ),
SRC_SPDY           as ( SELECT * FROM {{ ref('sat_product__delighted_yale') }} as SRC 
                        qualify 1= row_number() over(partition by PRODUCT_HK order by PSA_LOAD_dTS DESC) ),
SRC_CPY            as ( SELECT * FROM {{ ref('ref_connected_products_classification_for_sentiment_yale_combined') }} as SRC 
                        qualify 1= row_number() over(partition by MODEL order by PSA_LOAD_dTS DESC) )

/*
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PRODUCT_V2 )
, SRC_SPDY           as ( SELECT * FROM raw_vault.SAT_PRODUCT__DELIGHTED_YALE )
, SRC_CPY            as ( SELECT * FROM Bus_vault.REF_CONNECTED_PRODUCTS_CLASSIFICATION_FOR_SENTIMENT_YALE_COMBINED )
*/
---- LOGIC LAYER ----

, LOGIC_HP as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , PRODUCT_BK                                                   as                                              MODEL
      , BKCC
      , REC_SRC
      , to_varchar(PRODUCT_BK)                                       as                                             SRC_ID
      , ''                                                           as                                FIRE_RESISTANT_ATTR
      , to_varchar(PRODUCT_BK)                                       as                                CUSTOMER_PRODUCT_ID
    FROM SRC_HP
)

, LOGIC_SPDY as (
    SELECT
        PRODUCT_HK                                                   as                                     SPD_PRODUCT_HK
      , COALESCE(PROPERTIES_PRODUCT_NAME, '')                        as                                       PRODUCT_NAME
      , '0'                                                          as                                           BRAND_ID
      , ''                                                           as                                                RPC
      , ''                                                           as                                                EAN
      , ''                                                           as                                                UPC
      , '0'                                                          as                                          MAP_PRICE
      , 'DELIGHTED'                                                  as                                      SENTIMENT_SRC
      , 'FALSE'                                                      as                                         SMART_ATTR
    FROM SRC_SPDY
)

, LOGIC_CPY as (
    SELECT
        PRODUCT_AREA                                                 as                                          ROOM_AREA
      , PRODUCT_CATEGORY                                             as                           CONNECTED_PRODUCTS_CLASS
      , CONNECTED_FLAG                                               as                                  RC_CONNECTED_FLAG
      , PRODUCT_FAMILY                                               as                                 CPY_PRODUCT_FAMILY
      , MODEL                                                        as                                          CPY_MODEL
    FROM SRC_CPY
)
---- RENAME LAYER ----

, RENAME_HP as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , SRC_ID
      , FIRE_RESISTANT_ATTR
      , CUSTOMER_PRODUCT_ID
    FROM LOGIC_HP
)

, RENAME_SPDY as (
    SELECT
        SPD_PRODUCT_HK
      , PRODUCT_NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SMART_ATTR
    FROM LOGIC_SPDY
)

, RENAME_CPY as (
    SELECT
        ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , RC_CONNECTED_FLAG
      , CPY_PRODUCT_FAMILY
      , CPY_MODEL
    FROM LOGIC_CPY
)
---- FILTER LAYER ----

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_SPDY as (
    SELECT *
    FROM RENAME_SPDY
)

, FILTER_CPY as (
    SELECT *
    FROM RENAME_CPY
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HP
    INNER JOIN FILTER_SPDY
        ON FILTER_HP.PRODUCT_HK = SPD_PRODUCT_HK
    LEFT JOIN FILTER_CPY
        ON PRODUCT_BK = CPY_MODEL
)

---- FINAL LAYER ----
SELECT
          PRODUCT_HK
        , PRODUCT_BK
        , MODEL
        , BKCC
        , REC_SRC
        , PRODUCT_NAME
        , BRAND_ID
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
        , COALESCE(ROOM_AREA, '')                                      as LEVEL_1
        , COALESCE(CONNECTED_PRODUCTS_CLASS,'')                        as LEVEL_2
        , coalesce(RC_CONNECTED_FLAG, 'N')                             as CONNECTED_FLAG
        , coalesce(CPY_PRODUCT_FAMILY,'')                              as PRODUCT_FAMILY
FROM JOIN_RESULT

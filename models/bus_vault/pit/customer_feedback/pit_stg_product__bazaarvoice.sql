{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HP             as ( SELECT * FROM {{ ref('hub_product_v2') }} as SRC  ),
SRC_SPBV           as ( SELECT * FROM {{ ref('sat_product__bazaarvoice') }} as SRC 
                        qualify 1= row_number() over(partition by PRODUCT_HK order by PSA_LOAD_dTS DESC) ),
SRC_CPY            as ( SELECT * FROM {{ ref('ref_connected_products_classification_for_sentiment_moen_physical') }} as SRC 
                        qualify 1= row_number() over(partition by BASE_MATERIAL_NUMBER order by PSA_LOAD_dTS DESC) )

/*
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PRODUCT_V2 )
, SRC_SPBV           as ( SELECT * FROM raw_vault.SAT_PRODUCT__BAZAARVOICE )
, SRC_CPY            as ( SELECT * FROM Bus_vault.ref_connected_products_classification_for_sentiment_moen_physical )
*/
---- LOGIC LAYER ----

, LOGIC_HP as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , REC_SRC
      , ''                                                           as                                FIRE_RESISTANT_ATTR
    FROM SRC_HP
)

, LOGIC_SPBV as (
    SELECT
        MODEL_NUMBERS[0]::STRING                                     as                                              MODEL
      , PRODUCT_HK                                                   as                                    SPBV_PRODUCT_HK
      , NAME                                                         as                                       PRODUCT_NAME
      , '0'                                                          as                                           BRAND_ID
      , ''                                                           as                                                RPC
      , ''                                                           as                                                EAN
      , ''                                                           as                                                UPC
      , '0'                                                          as                                          MAP_PRICE
      , 'BAZAARVOICE'                                                as                                      SENTIMENT_SRC
      , to_varchar(id)                                               as                                             SRC_ID
      , 'FALSE'                                                      as                                         SMART_ATTR
      , to_varchar(ID)                                               as                                CUSTOMER_PRODUCT_ID
    FROM SRC_SPBV
)

, LOGIC_CPY as (
    SELECT
        ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , CONNECTED_FLAG                                               as                                  RC_CONNECTED_FLAG
      , BASE_MATERIAL_NUMBER                                         as                           CPY_BASE_MATERIAL_NUMBER
    FROM SRC_CPY
)
---- RENAME LAYER ----

, RENAME_HP as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , REC_SRC
      , FIRE_RESISTANT_ATTR
    FROM LOGIC_HP
)

, RENAME_SPBV as (
    SELECT
        MODEL
      , SPBV_PRODUCT_HK
      , PRODUCT_NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SRC_ID
      , SMART_ATTR
      , CUSTOMER_PRODUCT_ID
    FROM LOGIC_SPBV
)

, RENAME_CPY as (
    SELECT
        ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , RC_CONNECTED_FLAG
      , CPY_BASE_MATERIAL_NUMBER
    FROM LOGIC_CPY
)
---- FILTER LAYER ----

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_SPBV as (
    SELECT *
    FROM RENAME_SPBV
)

, FILTER_CPY as (
    SELECT *
    FROM RENAME_CPY
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HP
    INNER JOIN FILTER_SPBV
        ON FILTER_HP.PRODUCT_HK = SPBV_PRODUCT_HK
    LEFT JOIN FILTER_CPY
        ON PRODUCT_BK = CPY_BASE_MATERIAL_NUMBER
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
        , RC_CONNECTED_FLAG
        , FIRE_RESISTANT_ATTR
        , SMART_ATTR
        , CUSTOMER_PRODUCT_ID
        , COALESCE(ROOM_AREA, '')                                      as LEVEL_1
        , COALESCE(CONNECTED_PRODUCTS_CLASS,'')                        as LEVEL_2
        , coalesce(RC_CONNECTED_FLAG, 'N')                             as CONNECTED_FLAG
FROM JOIN_RESULT

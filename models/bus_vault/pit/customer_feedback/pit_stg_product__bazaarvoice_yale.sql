{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HP             as ( SELECT * FROM {{ ref('hub_product_v2') }} as SRC  ),
SRC_SPBVY          as ( SELECT * FROM {{ ref('sat_product__bazaarvoice_yale') }} as SRC 
                        qualify 1= row_number() over(partition by PRODUCT_HK order by PSA_LOAD_dTS DESC) ),
SRC_CPBY           as ( SELECT * FROM {{ ref('ref_connected_products_classification_for_sentiment_yale_combined') }} as SRC 
                        qualify 1= row_number() over(partition by MODEL order by PSA_LOAD_dTS DESC) )

/*
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PRODUCT_V2 )
, SRC_SPBVY          as ( SELECT * FROM raw_vault.SAT_PRODUCT__BAZAARVOICE_YALE )
, SRC_CPBY           as ( SELECT * FROM Bus_vault.ref_connected_products_classification_for_sentiment_yale_combined )
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

, LOGIC_SPBVY as (
    SELECT
        UPPER(COALESCE(FAMILY_IDS[0],MODEL_NUMBERS[0],ID))           as                                              MODEL
      , PRODUCT_HK                                                   as                                   SPBVY_PRODUCT_HK
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
    FROM SRC_SPBVY
)

, LOGIC_CPBY as (
    SELECT
        PRODUCT_AREA                                                 as                                          ROOM_AREA
      , PRODUCT_CATEGORY                                             as                           CONNECTED_PRODUCTS_CLASS
      , CONNECTED_FLAG                                               as                                  RC_CONNECTED_FLAG
      , PRODUCT_FAMILY                                               as                                CPBY_PRODUCT_FAMILY
      , MODEL                                                        as                                         CPBY_MODEL
    FROM SRC_CPBY
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

, RENAME_SPBVY as (
    SELECT
        MODEL
      , SPBVY_PRODUCT_HK
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
    FROM LOGIC_SPBVY
)

, RENAME_CPBY as (
    SELECT
        ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , RC_CONNECTED_FLAG
      , CPBY_PRODUCT_FAMILY
      , CPBY_MODEL
    FROM LOGIC_CPBY
)
---- FILTER LAYER ----

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_SPBVY as (
    SELECT *
    FROM RENAME_SPBVY
)

, FILTER_CPBY as (
    SELECT *
    FROM RENAME_CPBY
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HP
    INNER JOIN FILTER_SPBVY
        ON FILTER_HP.PRODUCT_HK = SPBVY_PRODUCT_HK
    LEFT JOIN FILTER_CPBY
        ON MODEL = CPBY_MODEL
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
        , coalesce(CPBY_PRODUCT_FAMILY,'')                             as PRODUCT_FAMILY
FROM JOIN_RESULT

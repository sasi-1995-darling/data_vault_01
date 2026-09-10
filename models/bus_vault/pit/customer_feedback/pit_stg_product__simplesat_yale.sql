{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HP             as ( SELECT * FROM {{ ref('hub_product_v2') }} as SRC  
                        WHERE REC_SRC = 'US.SIMPLESAT_YALE.RESPONSE' ),
SRC_SRD            as ( SELECT PRODUCT_HK, PRODUCT_BK FROM {{ ref('msat_response_details__simplesat_yale') }} as SRC 
                        qualify 1= row_number() over(partition by PRODUCT_HK order by PSA_LOAD_dTS DESC) )

/*
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PRODUCT_V2 )
, SRC_SRD            as ( SELECT * FROM raw_vault.MSAT_RESPONSE_DETAILS__SIMPLESAT_YALE )
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

, LOGIC_SRD as (
    SELECT
        PRODUCT_HK
      , ''                                                           as                                       PRODUCT_NAME
      , '0'                                                          as                                           BRAND_ID
      , ''                                                           as                                                RPC
      , ''                                                           as                                                EAN
      , ''                                                           as                                                UPC
      , '0'                                                          as                                          MAP_PRICE
      , 'SIMPLESAT'                                                  as                                      SENTIMENT_SRC
      , 'FALSE'                                                      as                                         SMART_ATTR
      , ''                                                           as                                          ROOM_AREA
      , ''                                                           as                           CONNECTED_PRODUCTS_CLASS
      , 'N'                                                          as                                     CONNECTED_FLAG
      , ''                                                           as                                     PRODUCT_FAMILY
    FROM SRC_SRD
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

, RENAME_SRD as (
    SELECT
        PRODUCT_HK                                                   as                                     SRD_PRODUCT_HK
      , PRODUCT_NAME
      , BRAND_ID
      , RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , SMART_ATTR
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , CONNECTED_FLAG
      , PRODUCT_FAMILY
    FROM LOGIC_SRD
)
---- FILTER LAYER ----

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_SRD as (
    SELECT *
    FROM RENAME_SRD
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT 
        FILTER_HP.PRODUCT_HK
      , FILTER_HP.PRODUCT_BK
      , FILTER_HP.MODEL
      , FILTER_HP.BKCC
      , FILTER_HP.REC_SRC
      , FILTER_HP.SRC_ID
      , FILTER_HP.FIRE_RESISTANT_ATTR
      , FILTER_HP.CUSTOMER_PRODUCT_ID
      , FILTER_SRD.PRODUCT_NAME
      , FILTER_SRD.BRAND_ID
      , FILTER_SRD.RPC
      , FILTER_SRD.EAN
      , FILTER_SRD.UPC
      , FILTER_SRD.MAP_PRICE
      , FILTER_SRD.SENTIMENT_SRC
      , FILTER_SRD.SMART_ATTR
      , FILTER_SRD.ROOM_AREA
      , FILTER_SRD.CONNECTED_PRODUCTS_CLASS
      , FILTER_SRD.CONNECTED_FLAG
      , FILTER_SRD.PRODUCT_FAMILY
    FROM FILTER_HP
    INNER JOIN FILTER_SRD
        ON FILTER_HP.PRODUCT_HK = SRD_PRODUCT_HK
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
        , ROOM_AREA                                                      as LEVEL_1
        , CONNECTED_PRODUCTS_CLASS                                       as LEVEL_2
        , CONNECTED_FLAG
        , PRODUCT_FAMILY
FROM JOIN_RESULT

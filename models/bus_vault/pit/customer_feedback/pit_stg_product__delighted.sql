{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HP             as ( SELECT * FROM {{ ref('hub_product_v2') }} as SRC  ),
SRC_SPD            as ( SELECT * FROM {{ ref('sat_product__delighted') }} as SRC 
                        qualify 1= row_number() over(partition by PRODUCT_HK order by PSA_LOAD_dTS DESC) )

/*
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PRODUCT_V2 )
, SRC_SPD            as ( SELECT * FROM raw_vault.SAT_PRODUCT__DELIGHTED )
*/
---- LOGIC LAYER ----

, LOGIC_HP as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , PRODUCT_BK                                                   as                                              MODEL
      , BKCC
      , REC_SRC
      , 'Y'                                                          as                                  RC_CONNECTED_FLAG
      , ''                                                           as                                FIRE_RESISTANT_ATTR
    FROM SRC_HP
)

, LOGIC_SPD as (
    SELECT
        PRODUCT_HK                                                   as                                     SPD_PRODUCT_HK
      , PRODUCT_DESC                                                 as                                       PRODUCT_NAME
      , '0'                                                          as                                           BRAND_ID
      , ''                                                           as                                                RPC
      , ''                                                           as                                                EAN
      , ''                                                           as                                                UPC
      , '0'                                                          as                                          MAP_PRICE
      , 'DELIGHTED'                                                  as                                      SENTIMENT_SRC
      , to_varchar(id)                                               as                                             SRC_ID
      , PRODUCT_DESC                                                 as                                          ROOM_AREA
      , PRODUCT_DESC                                                 as                           CONNECTED_PRODUCTS_CLASS
      , 'FALSE'                                                      as                                         SMART_ATTR
      , to_varchar(ID)                                               as                                CUSTOMER_PRODUCT_ID
    FROM SRC_SPD
)
---- RENAME LAYER ----

, RENAME_HP as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , MODEL
      , BKCC
      , REC_SRC
      , RC_CONNECTED_FLAG
      , FIRE_RESISTANT_ATTR
    FROM LOGIC_HP
)

, RENAME_SPD as (
    SELECT
        SPD_PRODUCT_HK
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
      , SMART_ATTR
      , CUSTOMER_PRODUCT_ID
    FROM LOGIC_SPD
)
---- FILTER LAYER ----

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_SPD as (
    SELECT *
    FROM RENAME_SPD
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HP
    INNER JOIN FILTER_SPD
        ON FILTER_HP.PRODUCT_HK = SPD_PRODUCT_HK
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

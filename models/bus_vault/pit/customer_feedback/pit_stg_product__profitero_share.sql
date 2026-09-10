{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HP             as ( SELECT BKCC, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('hub_product_v2') }} as SRC  ),
SRC_CPP            as ( SELECT DIM_BRAND_KEY, EAN, MAP_PRICE, ACCOUNT_PRODUCT_NAME, PRODUCT_HK, PRODUCT_MODEL, PROVIDED_RPC, UPC, UPDATED_AT FROM {{ ref('sat_customer_product__profitero_share') }} as SRC 
                        qualify 1= row_number() over(partition by PRODUCT_HK order by UPDATED_AT DESC) ),
SRC_RC             as ( SELECT CONNECTED_FLAG, CONNECTED_PRODUCTS_CLASS, PRODUCT_FAMILY, ROOM_AREA, SRC_ID FROM {{ ref('ref_connected_products_class') }} as SRC  ),
SRC_DC             as ( SELECT CUSTOMER_PRODUCT_ID, FIRE_RESISTANT_ATTR, LEVEL_1, LEVEL_2, SMART_ATTR FROM {{ ref('ref_dim_categories') }} as SRC  )

/*
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PRODUCT_V2 )
SRC_CPP            as ( SELECT * FROM raw_vault.SAT_CUSTOMER_PRODUCT__PROFITERO_SHARE )
SRC_RC             as ( SELECT * FROM bus_vault.ref_connected_products_class )
SRC_DC             as ( SELECT * FROM bus_vault.ref_dim_categories )
*/
---- LOGIC LAYER ----

, LOGIC_HP as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , REC_SRC
    FROM SRC_HP
)

, LOGIC_CPP as (
    SELECT
        PRODUCT_HK                                                   as                                     CPP_PRODUCT_HK
      , ACCOUNT_PRODUCT_NAME                                                         as                                       PRODUCT_NAME
      , DIM_BRAND_KEY                                                as                                           BRAND_ID
      , PROVIDED_RPC
      , EAN
      , UPC
      , MAP_PRICE
      , 'PROFITERO'                                                  as                                      SENTIMENT_SRC
      , PRODUCT_MODEL
    FROM SRC_CPP
)

, LOGIC_RC as (
    SELECT
        SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , CONNECTED_FLAG                                               as                                  RC_CONNECTED_FLAG
      , PRODUCT_FAMILY                                               as                                  RC_PRODUCT_FAMILY
    FROM SRC_RC
)

, LOGIC_DC as (
    SELECT
        TO_VARCHAR(CUSTOMER_PRODUCT_ID)                              as                             DC_CUSTOMER_PRODUCT_ID
      , LEVEL_1                                                      as                                         DC_LEVEL_1
      , LEVEL_2                                                      as                                         DC_LEVEL_2
      , CUSTOMER_PRODUCT_ID
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
    FROM SRC_DC
)
---- RENAME LAYER ----

, RENAME_HP as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_HP
)

, RENAME_CPP as (
    SELECT
        CPP_PRODUCT_HK
      , PRODUCT_NAME
      , BRAND_ID
      , PROVIDED_RPC
      , EAN
      , UPC
      , MAP_PRICE
      , SENTIMENT_SRC
      , PRODUCT_MODEL
    FROM LOGIC_CPP
)

, RENAME_RC as (
    SELECT
        SRC_ID
      , ROOM_AREA
      , CONNECTED_PRODUCTS_CLASS
      , RC_CONNECTED_FLAG
      , RC_PRODUCT_FAMILY
    FROM LOGIC_RC
)

, RENAME_DC as (
    SELECT
        DC_CUSTOMER_PRODUCT_ID
      , DC_LEVEL_1
      , DC_LEVEL_2
      , CUSTOMER_PRODUCT_ID
      , FIRE_RESISTANT_ATTR
      , SMART_ATTR
    FROM LOGIC_DC
)
---- FILTER LAYER ----

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_CPP as (
    SELECT *
    FROM RENAME_CPP
)

, FILTER_RC as (
    SELECT *
    FROM RENAME_RC
)

, FILTER_DC as (
    SELECT *
    FROM RENAME_DC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HP
    INNER JOIN FILTER_CPP
        ON FILTER_HP.PRODUCT_HK = CPP_PRODUCT_HK
    LEFT JOIN FILTER_RC
        ON PRODUCT_BK = SRC_ID
    LEFT JOIN FILTER_DC
        ON PRODUCT_BK = DC_CUSTOMER_PRODUCT_ID
)

---- FINAL LAYER ----
SELECT
          PRODUCT_HK
        , PRODUCT_BK
        , regexp_replace(PRODUCT_MODEL,'[^[:ascii:]]')                 as MODEL
        , BKCC
        , REC_SRC
        , PRODUCT_NAME
        , BRAND_ID
        , PROVIDED_RPC as RPC
        , EAN
        , UPC
        , MAP_PRICE
        , SENTIMENT_SRC
        , SRC_ID
        , ROOM_AREA
        , CONNECTED_PRODUCTS_CLASS
        , RC_CONNECTED_FLAG
        , COALESCE(FIRE_RESISTANT_ATTR, '')                            as FIRE_RESISTANT_ATTR
        , COALESCE(SMART_ATTR, 'FALSE')                                as SMART_ATTR
        , COALESCE(DC_CUSTOMER_PRODUCT_ID, PRODUCT_BK)                 as CUSTOMER_PRODUCT_ID
        , COALESCE(ROOM_AREA, DC_LEVEL_1,'')                           as LEVEL_1
        , COALESCE(CONNECTED_PRODUCTS_CLASS,DC_LEVEL_2,'')             as LEVEL_2
        , coalesce(RC_CONNECTED_FLAG, 'N')                             as CONNECTED_FLAG
        , COALESCE(RC_PRODUCT_FAMILY,'')                               as PRODUCT_FAMILY
FROM JOIN_RESULT

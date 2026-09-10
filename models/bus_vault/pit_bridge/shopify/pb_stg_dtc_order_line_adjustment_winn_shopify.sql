{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_lool           as ( SELECT ORDER_HEADER_HK, ORDER_LINE_HK, ORDER_ORDER_LINE_HK, REC_SRC FROM {{ ref('lnk_order_order_line') }} as SRC  ),
SRC_hoh            as ( SELECT BKCC, ORDER_HEADER_BK, ORDER_HEADER_HK FROM {{ ref('hub_order_header') }} as SRC 
                        WHERE ORDER_HEADER_BK <> 'MS1037'
                        /*Filtered out a test order entered by the Shopify team to test the production deployment to resolve JIRA ticket GPGDS-9665*/ ),
SRC_hol            as ( SELECT BKCC, ORDER_LINE_BK, ORDER_LINE_HK FROM {{ ref('hub_order_line') }} as SRC  ),
SRC_sola           as ( SELECT AMOUNT, ID, ORDER_HEADER_HK, REC_SRC, _FIVETRAN_SYNCED FROM {{ ref('sat_order_header_adjustment__winn_shopify') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ORDER_HEADER_HK, ID ORDER BY LOAD_DTS DESC) ),
SRC_lsol           as ( SELECT ID, INDEX, ORDER_ID, ORDER_ORDER_LINE_HK, PRICE, PRODUCT_ID, SKU, VARIANT_ID FROM {{ ref('lsat_order_order_line__winn_shopify') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ORDER_ORDER_LINE_HK ORDER BY LOAD_DTS DESC) ),
SRC_itm            as ( SELECT BASE_MATERIAL, BASE_MATERIAL_KEY, ITEM_HK, ITEM_NUMBER FROM {{ ref('pb_items_by_plant') }} as SRC 
                        WHERE BKCC = 'Hiding_Tiger'
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ITEM_HK ORDER BY SNAPSHOT_DTS DESC) )

/*
SRC_lool           as ( SELECT * FROM raw_vault.lnk_order_order_line )
SRC_hoh            as ( SELECT * FROM raw_vault.hub_order_header )
SRC_hol            as ( SELECT * FROM raw_vault.hub_order_line )
SRC_sola           as ( SELECT * FROM raw_vault.sat_order_header_adjustment__winn_shopify )
SRC_lsol           as ( SELECT * FROM raw_vault.lsat_order_order_line__winn_shopify )
SRC_itm            as ( SELECT * FROM bus_vault.pb_items_by_plant )
*/
---- LOGIC LAYER ----

, LOGIC_lool as (
    SELECT
        ORDER_ORDER_LINE_HK
      , ORDER_HEADER_HK
      , ORDER_LINE_HK
      , REC_SRC
    FROM SRC_lool
)

, LOGIC_hoh as (
    SELECT
        ORDER_HEADER_BK
      , BKCC
      , ORDER_HEADER_HK                                              as                                HOH_ORDER_HEADER_HK
    FROM SRC_hoh
)

, LOGIC_hol as (
    SELECT
        ORDER_LINE_BK
      , ORDER_LINE_HK                                                as                                  HOL_ORDER_LINE_HK
      , BKCC                                                         as                                           HOL_BKCC
    FROM SRC_hol
)

, LOGIC_sola as (
    SELECT
        ID                                                           as                                      ADJUSTMENT_ID
      , ORDER_HEADER_HK                                              as                               SOLA_ORDER_HEADER_HK
      , AMOUNT                                                       as                                        SOLA_AMOUNT
      , _FIVETRAN_SYNCED                                             as                               SOLA_FIVETRAN_SYNCED
      , REC_SRC                                                      as                                       SOLA_REC_SRC
    FROM SRC_sola
)

, LOGIC_lsol as (
    SELECT
        ORDER_ID
      , ID                                                           as                                      ORDER_LINE_ID
      , INDEX                                                        as                                  ORDER_LINE_NUMBER
      , PRODUCT_ID                                                   as                                                SKU
      , VARIANT_ID
      , PRICE
      , SKU                                                          as                                           LSOL_SKU
      , ORDER_ORDER_LINE_HK                                          as                           LSOL_ORDER_ORDER_LINE_HK
    FROM SRC_lsol
)

, LOGIC_itm as (
    SELECT
        BASE_MATERIAL_KEY
      , BASE_MATERIAL
      , ITEM_HK
      , ITEM_NUMBER                                                  as                                    ITM_ITEM_NUMBER
    FROM SRC_itm
)
---- RENAME LAYER ----

, RENAME_lool as (
    SELECT
        ORDER_ORDER_LINE_HK
      , ORDER_HEADER_HK
      , ORDER_LINE_HK
      , REC_SRC
    FROM LOGIC_lool
)

, RENAME_hoh as (
    SELECT
        ORDER_HEADER_BK
      , BKCC
      , HOH_ORDER_HEADER_HK
    FROM LOGIC_hoh
)

, RENAME_lsol as (
    SELECT
        ORDER_ID
      , ORDER_LINE_ID
      , ORDER_LINE_NUMBER
      , SKU
      , VARIANT_ID
      , PRICE
      , LSOL_SKU
      , LSOL_ORDER_ORDER_LINE_HK
    FROM LOGIC_lsol
)

, RENAME_hol as (
    SELECT
        ORDER_LINE_BK
      , HOL_ORDER_LINE_HK
      , HOL_BKCC
    FROM LOGIC_hol
)

, RENAME_sola as (
    SELECT
        ADJUSTMENT_ID
      , SOLA_ORDER_HEADER_HK
      , SOLA_AMOUNT
      , SOLA_FIVETRAN_SYNCED
      , SOLA_REC_SRC
    FROM LOGIC_sola
)

, RENAME_itm as (
    SELECT
        BASE_MATERIAL_KEY
      , BASE_MATERIAL
      , ITEM_HK
      , ITM_ITEM_NUMBER
    FROM LOGIC_itm
)
---- FILTER LAYER ----

, FILTER_lool as (
    SELECT *
    FROM RENAME_lool
)

, FILTER_hoh as (
    SELECT *
    FROM RENAME_hoh
)

, FILTER_hol as (
    SELECT *
    FROM RENAME_hol
)

, FILTER_sola as (
    SELECT *
    FROM RENAME_sola
    WHERE  SOLA_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED' /* This filter is to exclude the ghost records */
)

, FILTER_lsol as (
    SELECT *
    FROM RENAME_lsol
)

, FILTER_itm as (
    SELECT *
    FROM RENAME_itm
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_lool
    INNER JOIN FILTER_hoh
        ON FILTER_lool.ORDER_HEADER_HK = HOH_ORDER_HEADER_HK and BKCC = 'Screeching_Bat'
    INNER JOIN FILTER_hol
        ON FILTER_lool.ORDER_LINE_HK = HOL_ORDER_LINE_HK and HOL_BKCC = 'Screeching_Bat'
    INNER JOIN FILTER_sola
        ON HOH_ORDER_HEADER_HK = SOLA_ORDER_HEADER_HK
    LEFT JOIN FILTER_lsol
        ON FILTER_lool.ORDER_ORDER_LINE_HK = LSOL_ORDER_ORDER_LINE_HK
    LEFT JOIN FILTER_itm
        ON UPPER(LSOL_SKU) = UPPER(ITM_ITEM_NUMBER)
)

---- FINAL LAYER ----
SELECT
          ORDER_ORDER_LINE_HK
        , ORDER_HEADER_HK
        , ORDER_HEADER_BK
        , ORDER_ID
        , ORDER_LINE_HK
        , ORDER_LINE_BK
        , ORDER_LINE_ID
        , ORDER_LINE_NUMBER
        , NULL                                                         as REFUND_LINE_RECORD_ID
        , ADJUSTMENT_ID
        , BASE_MATERIAL_KEY
        , BASE_MATERIAL
        , ITEM_HK
        , COALESCE(ITM_ITEM_NUMBER, LSOL_SKU)                          as ITEM_NUMBER
        , SKU
        , VARIANT_ID
        , PRICE
        , ( SOLA_AMOUNT / FIRST_VALUE(ORDER_LINE_NUMBER) OVER (PARTITION BY ORDER_ID ORDER BY ORDER_LINE_NUMBER DESC) ) as LINE_DOLLARS
        , 0                                                            as LINE_QUANTITY
        , TO_CHAR( SOLA_FIVETRAN_SYNCED, 'YYYYMMDD' )::NUMBER          as CREATED_DATE_KEY
        , 'ADJUSTMENT'                                                 as ORIGIN
        , 'SHOPIFY MOEN'                                               as STORE
        , REC_SRC
        , BKCC
FROM JOIN_RESULT

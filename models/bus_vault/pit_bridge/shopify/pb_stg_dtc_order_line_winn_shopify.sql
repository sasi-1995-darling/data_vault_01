{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_lool           as ( SELECT ORDER_HEADER_HK, ORDER_LINE_HK, ORDER_ORDER_LINE_HK, REC_SRC FROM {{ ref('lnk_order_order_line') }} as SRC  ),
SRC_hoh            as ( SELECT BKCC, ORDER_HEADER_BK, ORDER_HEADER_HK FROM {{ ref('hub_order_header') }} as SRC 
                        WHERE ORDER_HEADER_BK <> 'MS1037'
                        /*Filtered out a test order entered by the Shopify team to test the production deployment to resolve JIRA ticket GPGDS-9665*/ ),
SRC_hol            as ( SELECT BKCC, ORDER_LINE_BK, ORDER_LINE_HK FROM {{ ref('hub_order_line') }} as SRC  ),
SRC_lsol           as ( SELECT ID, INDEX, ORDER_ID, ORDER_ORDER_LINE_HK, PRE_TAX_PRICE, PRICE, PRODUCT_ID, QUANTITY, REC_SRC, SKU, VARIANT_ID, _FIVETRAN_SYNCED FROM {{ ref('lsat_order_order_line__winn_shopify') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ORDER_ORDER_LINE_HK ORDER BY LOAD_DTS DESC) ),
SRC_itm            as ( SELECT BASE_MATERIAL, BASE_MATERIAL_KEY, ITEM_HK, ITEM_NUMBER FROM {{ ref('pb_items_by_plant') }} as SRC 
                        WHERE BKCC = 'Hiding_Tiger'
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ITEM_HK ORDER BY SNAPSHOT_DTS DESC) )

/*
SRC_lool           as ( SELECT * FROM raw_vault.lnk_order_order_line )
SRC_hoh            as ( SELECT * FROM raw_vault.hub_order_header )
SRC_hol            as ( SELECT * FROM raw_vault.hub_order_line )
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

, LOGIC_lsol as (
    SELECT
        ORDER_ID
      , ID                                                           as                                      ORDER_LINE_ID
      , INDEX                                                        as                                  ORDER_LINE_NUMBER
      , PRODUCT_ID                                                   as                                                SKU
      , VARIANT_ID
      , PRICE
      , PRE_TAX_PRICE                                                as                                       LINE_DOLLARS
      , QUANTITY                                                     as                                      LINE_QUANTITY
      , SKU                                                          as                                           LSOL_SKU
      , ORDER_ORDER_LINE_HK                                          as                           LSOL_ORDER_ORDER_LINE_HK
      , _FIVETRAN_SYNCED                                             as                               LSOL_FIVETRAN_SYNCED
      , REC_SRC                                                      as                                       LSOL_REC_SRC
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
      , LINE_DOLLARS
      , LINE_QUANTITY
      , LSOL_SKU
      , LSOL_ORDER_ORDER_LINE_HK
      , LSOL_FIVETRAN_SYNCED
      , LSOL_REC_SRC
    FROM LOGIC_lsol
)

, RENAME_hol as (
    SELECT
        ORDER_LINE_BK
      , HOL_ORDER_LINE_HK
      , HOL_BKCC
    FROM LOGIC_hol
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

, FILTER_lsol as (
    SELECT *
    FROM RENAME_lsol
    WHERE LSOL_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED' /* This filter is to exclude the ghost records */
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
    INNER JOIN FILTER_lsol
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
        , NULL                                                         as ADJUSTMENT_ID
        , BASE_MATERIAL_KEY
        , BASE_MATERIAL
        , ITEM_HK
        , COALESCE(ITM_ITEM_NUMBER, LSOL_SKU)                          as ITEM_NUMBER
        , SKU
        , VARIANT_ID
        , PRICE
        , LINE_DOLLARS
        , LINE_QUANTITY
        , TO_CHAR( LSOL_FIVETRAN_SYNCED, 'YYYYMMDD' )::NUMBER          as CREATED_DATE_KEY
        , 'ORDER'                                                      as ORIGIN
        , 'SHOPIFY MOEN'                                               as STORE
        , REC_SRC
        , BKCC
FROM JOIN_RESULT

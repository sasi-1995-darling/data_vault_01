---- SRC LAYER ----
WITH
SRC_OLWS           as ( SELECT ADJUSTMENT_ID, BASE_MATERIAL, BASE_MATERIAL_KEY, BKCC, CREATED_DATE_KEY, ITEM_HK, ITEM_NUMBER, LINE_DOLLARS, 
                        LINE_QUANTITY, ORDER_HEADER_BK, ORDER_HEADER_HK, ORDER_ID, ORDER_LINE_BK, ORDER_LINE_HK, ORDER_LINE_ID, ORDER_LINE_NUMBER, 
                        ORIGIN, PRICE, REC_SRC, REFUND_LINE_RECORD_ID, SKU, STORE, VARIANT_ID 
                        FROM {{ ref('pb_stg_dtc_order_line_winn_shopify') }} as SRC  ),
SRC_OLRWS          as ( SELECT ADJUSTMENT_ID, BASE_MATERIAL, BASE_MATERIAL_KEY, BKCC, CREATED_DATE_KEY, ITEM_HK, ITEM_NUMBER, LINE_DOLLARS, 
                        LINE_QUANTITY, ORDER_HEADER_BK, ORDER_HEADER_HK, ORDER_ID, ORDER_LINE_BK, ORDER_LINE_HK, ORDER_LINE_ID, ORDER_LINE_NUMBER, 
                        ORIGIN, PRICE, REC_SRC, REFUND_LINE_RECORD_ID, SKU, STORE, VARIANT_ID 
                        FROM {{ ref('pb_stg_dtc_order_line_refund_winn_shopify') }} as SRC  ),
SRC_OLAWS          as ( SELECT ADJUSTMENT_ID, BASE_MATERIAL, BASE_MATERIAL_KEY, BKCC, CREATED_DATE_KEY, ITEM_HK, ITEM_NUMBER, LINE_DOLLARS, 
                        LINE_QUANTITY, ORDER_HEADER_BK, ORDER_HEADER_HK, ORDER_ID, ORDER_LINE_BK, ORDER_LINE_HK, ORDER_LINE_ID, ORDER_LINE_NUMBER, 
                        ORIGIN, PRICE, REC_SRC, REFUND_LINE_RECORD_ID, SKU, STORE, VARIANT_ID 
                        FROM {{ ref('pb_stg_dtc_order_line_adjustment_winn_shopify') }} as SRC  )

/*
SRC_OLWS           as ( SELECT * FROM bus_vault.PB_STG_DTC_ORDER_LINE_WINN_SHOPIFY )
SRC_OLRWS          as ( SELECT * FROM bus_vault.PB_STG_DTC_ORDER_LINE_REFUND_WINN_SHOPIFY )
SRC_OLAWS          as ( SELECT * FROM bus_vault.PB_STG_DTC_ORDER_LINE_ADJUSTMENT_WINN_SHOPIFY )
*/
---- LOGIC LAYER ----

, LOGIC_OLWS as (
    SELECT
        ORDER_HEADER_HK                                              as                                   ORDER_HEADER_KEY
      , ORDER_HEADER_BK
      , ORDER_ID
      , ORDER_LINE_HK                                                as                                     ORDER_LINE_KEY
      , ORDER_LINE_BK
      , ORDER_LINE_ID
      , ORDER_LINE_NUMBER
      , REFUND_LINE_RECORD_ID
      , ADJUSTMENT_ID
      , BASE_MATERIAL_KEY
      , BASE_MATERIAL
      , ITEM_HK                                                      as                                           ITEM_KEY
      , ITEM_NUMBER
      , SKU
      , VARIANT_ID
      , PRICE
      , LINE_DOLLARS
      , LINE_QUANTITY
      , CREATED_DATE_KEY
      , ORIGIN
      , STORE
      , REC_SRC
      , BKCC
    FROM SRC_OLWS
)

, LOGIC_OLRWS as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , ORDER_ID
      , ORDER_LINE_HK
      , ORDER_LINE_BK
      , ORDER_LINE_ID
      , ORDER_LINE_NUMBER
      , REFUND_LINE_RECORD_ID
      , ADJUSTMENT_ID
      , BASE_MATERIAL_KEY
      , BASE_MATERIAL
      , ITEM_HK
      , ITEM_NUMBER
      , SKU
      , VARIANT_ID
      , PRICE
      , LINE_DOLLARS
      , LINE_QUANTITY
      , CREATED_DATE_KEY
      , ORIGIN
      , STORE
      , REC_SRC
      , BKCC
    FROM SRC_OLRWS
)

, LOGIC_OLAWS as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , ORDER_ID
      , ORDER_LINE_HK
      , ORDER_LINE_BK
      , ORDER_LINE_ID
      , ORDER_LINE_NUMBER
      , REFUND_LINE_RECORD_ID
      , ADJUSTMENT_ID
      , BASE_MATERIAL_KEY
      , BASE_MATERIAL
      , ITEM_HK
      , ITEM_NUMBER
      , SKU
      , VARIANT_ID
      , PRICE
      , LINE_DOLLARS
      , LINE_QUANTITY
      , CREATED_DATE_KEY
      , ORIGIN
      , STORE
      , REC_SRC
      , BKCC
    FROM SRC_OLAWS
)
---- RENAME LAYER ----

, RENAME_OLWS as (
    SELECT
        ORDER_HEADER_KEY
      , ORDER_HEADER_BK
      , ORDER_ID
      , ORDER_LINE_KEY
      , ORDER_LINE_BK
      , ORDER_LINE_ID
      , ORDER_LINE_NUMBER
      , REFUND_LINE_RECORD_ID
      , ADJUSTMENT_ID
      , BASE_MATERIAL_KEY
      , BASE_MATERIAL
      , ITEM_KEY
      , ITEM_NUMBER
      , SKU
      , VARIANT_ID
      , PRICE
      , LINE_DOLLARS
      , LINE_QUANTITY
      , CREATED_DATE_KEY
      , ORIGIN
      , STORE
      , REC_SRC
      , BKCC
    FROM LOGIC_OLWS
)

, RENAME_OLRWS as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , ORDER_ID
      , ORDER_LINE_HK
      , ORDER_LINE_BK
      , ORDER_LINE_ID
      , ORDER_LINE_NUMBER
      , REFUND_LINE_RECORD_ID
      , ADJUSTMENT_ID
      , BASE_MATERIAL_KEY
      , BASE_MATERIAL
      , ITEM_HK
      , ITEM_NUMBER
      , SKU
      , VARIANT_ID
      , PRICE
      , LINE_DOLLARS
      , LINE_QUANTITY
      , CREATED_DATE_KEY
      , ORIGIN
      , STORE
      , REC_SRC
      , BKCC
    FROM LOGIC_OLRWS
)

, RENAME_OLAWS as (
    SELECT
        ORDER_HEADER_HK
      , ORDER_HEADER_BK
      , ORDER_ID
      , ORDER_LINE_HK
      , ORDER_LINE_BK
      , ORDER_LINE_ID
      , ORDER_LINE_NUMBER
      , REFUND_LINE_RECORD_ID
      , ADJUSTMENT_ID
      , BASE_MATERIAL_KEY
      , BASE_MATERIAL
      , ITEM_HK
      , ITEM_NUMBER
      , SKU
      , VARIANT_ID
      , PRICE
      , LINE_DOLLARS
      , LINE_QUANTITY
      , CREATED_DATE_KEY
      , ORIGIN
      , STORE
      , REC_SRC
      , BKCC
    FROM LOGIC_OLAWS
)
---- FILTER LAYER ----

, FILTER_OLWS as (
    SELECT *
    FROM RENAME_OLWS
)

, FILTER_OLRWS as (
    SELECT *
    FROM RENAME_OLRWS
)

, FILTER_OLAWS as (
    SELECT *
    FROM RENAME_OLAWS
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_OLWS
    UNION ALL
    SELECT * FROM FILTER_OLRWS
    UNION ALL
    SELECT * FROM FILTER_OLAWS
)

---- FINAL LAYER ----
SELECT
          RANDOM()                                                     as SEQ_ID
        , 'PB_DTC_ORDER_LINE'                                          as PB_REC_SRC
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , ORDER_HEADER_KEY
        , ORDER_HEADER_BK
        , ORDER_ID
        , ORDER_LINE_KEY
        , ORDER_LINE_BK
        , ORDER_LINE_ID
        , ORDER_LINE_NUMBER
        , REFUND_LINE_RECORD_ID
        , ADJUSTMENT_ID
        , BASE_MATERIAL_KEY
        , BASE_MATERIAL
        , ITEM_KEY
        , ITEM_NUMBER
        , SKU
        , VARIANT_ID
        , PRICE
        , LINE_DOLLARS
        , LINE_QUANTITY
        , CREATED_DATE_KEY
        , ORIGIN
        , STORE
        , REC_SRC
        , BKCC
FROM JOIN_RESULT

{{ config(alias='fact_dtc_order_line') }}
---- SRC LAYER ----
WITH
SRC_fact_ordln     as ( SELECT ADJUSTMENT_ID, BASE_MATERIAL, BASE_MATERIAL_KEY, CREATED_DATE_KEY, ITEM_KEY, ITEM_NUMBER, LINE_DOLLARS, LINE_QUANTITY, 
                        ORDER_HEADER_BK, ORDER_HEADER_KEY, ORDER_ID, ORDER_LINE_BK, ORDER_LINE_ID, ORDER_LINE_KEY, ORDER_LINE_NUMBER, ORIGIN, PRICE, 
                        REFUND_LINE_RECORD_ID, SKU, STORE, VARIANT_ID FROM {{ ref('fact_dtc_order_line') }} as SRC  )

/*
SRC_fact_ordln     as ( SELECT * FROM bus_vault.fact_dtc_order_line )
*/
---- LOGIC LAYER ----

, LOGIC_fact_ordln as (
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
    FROM SRC_fact_ordln
)
---- RENAME LAYER ----

, RENAME_fact_ordln as (
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
    FROM LOGIC_fact_ordln
)
---- FILTER LAYER ----

, FILTER_fact_ordln as (
    SELECT *
    FROM RENAME_fact_ordln
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_fact_ordln
)

---- FINAL LAYER ----
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
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_OHWS           as ( SELECT ADJUSTMENT, BILLING_CITY, BILLING_COUNTRY, BILLING_STATE, BILLING_ZIP, BKCC, CANCELLED_DATE__YYYYMMDD, CONSUMER_BK, 
                        CONSUMER_HK, CREATED_DATE_KEY, CUSTOMER_BK, CUSTOMER_HK, CUSTOMER_ID, DISCOUNTS, FINANCIAL_STATUS, FULFILLMENT_STATUS, 
                        ORDER_DOLLARS, ORDER_HEADER_BK, ORDER_HEADER_HK, ORDER_ID, ORDER_SUBTOTAL_DOLLARS, ORDER_TAX, REC_SRC, SHIPPING, 
                        SHIPPING_CITY, SHIPPING_COUNTRY, SHIPPING_STATE, SHIPPING_ZIP, STORE, UPDATED_DATE__YYYYMMDD 
                        FROM {{ ref('pb_stg_dtc_order_header_winn_shopify') }} as SRC  )

/*
SRC_OHWS           as ( SELECT * FROM bus_vault.PB_STG_DTC_ORDER_HEADER_WINN_SHOPIFY )
*/
---- LOGIC LAYER ----

, LOGIC_OHWS as (
    SELECT
        ORDER_HEADER_HK                                              as                                   ORDER_HEADER_KEY
      , ORDER_HEADER_BK
      , ORDER_ID
      , CUSTOMER_HK                                                  as                                       CUSTOMER_KEY
      , CUSTOMER_BK
      , CUSTOMER_ID
      , CONSUMER_HK                                                  as                                       CONSUMER_KEY
      , CONSUMER_BK
      , FINANCIAL_STATUS
      , FULFILLMENT_STATUS
      , ORDER_DOLLARS
      , ORDER_SUBTOTAL_DOLLARS
      , ORDER_TAX
      , SHIPPING
      , DISCOUNTS
      , ADJUSTMENT
      , SHIPPING_CITY
      , SHIPPING_STATE
      , SHIPPING_COUNTRY
      , SHIPPING_ZIP
      , BILLING_CITY
      , BILLING_STATE
      , BILLING_COUNTRY
      , BILLING_ZIP
      , CREATED_DATE_KEY
      , UPDATED_DATE__YYYYMMDD
      , CANCELLED_DATE__YYYYMMDD
      , STORE
      , REC_SRC
      , BKCC
    FROM SRC_OHWS
)
---- RENAME LAYER ----

, RENAME_OHWS as (
    SELECT
        ORDER_HEADER_KEY
      , ORDER_HEADER_BK
      , ORDER_ID
      , CUSTOMER_KEY
      , CUSTOMER_BK
      , CUSTOMER_ID
      , CONSUMER_KEY
      , CONSUMER_BK
      , FINANCIAL_STATUS
      , FULFILLMENT_STATUS
      , ORDER_DOLLARS
      , ORDER_SUBTOTAL_DOLLARS
      , ORDER_TAX
      , SHIPPING
      , DISCOUNTS
      , ADJUSTMENT
      , SHIPPING_CITY
      , SHIPPING_STATE
      , SHIPPING_COUNTRY
      , SHIPPING_ZIP
      , BILLING_CITY
      , BILLING_STATE
      , BILLING_COUNTRY
      , BILLING_ZIP
      , CREATED_DATE_KEY
      , UPDATED_DATE__YYYYMMDD
      , CANCELLED_DATE__YYYYMMDD
      , STORE
      , REC_SRC
      , BKCC
    FROM LOGIC_OHWS
)
---- FILTER LAYER ----

, FILTER_OHWS as (
    SELECT *
    FROM RENAME_OHWS
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_OHWS
)

---- FINAL LAYER ----
SELECT
          RANDOM()                                                     as SEQ_ID
        ,  'PB_DTC_ORDER_HEADER'                                       as PB_REC_SRC
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , ORDER_HEADER_KEY
        , ORDER_HEADER_BK
        , ORDER_ID
        , CUSTOMER_KEY
        , CUSTOMER_BK
        , CUSTOMER_ID
        , CONSUMER_KEY
        , CONSUMER_BK
        , FINANCIAL_STATUS
        , FULFILLMENT_STATUS
        , ORDER_DOLLARS
        , ORDER_SUBTOTAL_DOLLARS
        , ORDER_TAX
        , SHIPPING
        , DISCOUNTS
        , ADJUSTMENT
        , SHIPPING_CITY
        , SHIPPING_STATE
        , SHIPPING_COUNTRY
        , SHIPPING_ZIP
        , BILLING_CITY
        , BILLING_STATE
        , BILLING_COUNTRY
        , BILLING_ZIP
        , CREATED_DATE_KEY
        , UPDATED_DATE__YYYYMMDD
        , CANCELLED_DATE__YYYYMMDD
        , STORE
        , REC_SRC
        , BKCC
FROM JOIN_RESULT

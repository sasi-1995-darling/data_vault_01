---- SRC LAYER ----
WITH
SRC_PIT            as ( SELECT 
                            SOURCE
                          , SALES_ORDER_LINE_HK
                          , SALES_ORDER_LINE_BK
                          , SALES_ORDER_NUMBER
                          , SALES_ORDER_LINE_NUMBER
                          , SALES_ORDER_CREATION_DATE_KEY
                          , SALES_ORDER_DELIVERY_IND
                          , CUSTOMER_BK
                          , ITEM_BK
                          , SALES_ORDER_ITEM_DESC
                          , SALES_ORDER_DOCUMENT_TYPE
                          , SALES_ORDER_LINE_RETURN_IND
                          , QUANTITY
                          , NET_PRICE
                          , NET_VALUE
                          , RETURN_REASON_CODE
                          , PLANT
                          , SALES_ORDER_ITEM_CATEGORY
                          , REJECTION_REASON
                          , CUMULATIVE_ORDER_QUANTITY
                          , CUMULATIVE_REQUIRED_QUANTITY
                          , CUMULATIVE_CONFIRMED_QUANTITY
                          , DELIVERY_PRIORITY
                          , MINIMUM_DELIVERY_QUANTITY
                          , LAST_CHANGE_DATE_LINE__YYYYMMDD
                          , REQUIREMENTS_TYPE
                          , BUSINESS_AREA
                          , MAX_NUMBER_OF_PARTIAL_DELIVERIES
                          , PRICING_GROUP
                          , CUSTOMER_MATERIAL_NUMBER
                          , SALES_DEAL
                          , SUBSCRIPTION_SOURCE                               
                          , SUBSCRIPTION_ID
                          , REC_SRC
                          , BKCC
                          , IS_DELETED
                        FROM {{ ref('pit_order_line') }} as SRC  )

/*
SRC_PIT              as ( SELECT * FROM RAW_VAULT.PIT_ORDER_LINE )
*/
---- LOGIC LAYER ----

, LOGIC_PIT as (
    SELECT
        SOURCE
      , SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_LINE_NUMBER
      , SALES_ORDER_CREATION_DATE_KEY
      , SALES_ORDER_DELIVERY_IND
      , CUSTOMER_BK
      , ITEM_BK
      , SALES_ORDER_ITEM_DESC
      , SALES_ORDER_DOCUMENT_TYPE
      , SALES_ORDER_LINE_RETURN_IND
      , QUANTITY
      , NET_PRICE
      , NET_VALUE
      , RETURN_REASON_CODE
      , PLANT
      , SALES_ORDER_ITEM_CATEGORY
      , REJECTION_REASON
      , CUMULATIVE_ORDER_QUANTITY
      , CUMULATIVE_REQUIRED_QUANTITY
      , CUMULATIVE_CONFIRMED_QUANTITY
      , DELIVERY_PRIORITY
      , MINIMUM_DELIVERY_QUANTITY
      , LAST_CHANGE_DATE_LINE__YYYYMMDD
      , REQUIREMENTS_TYPE
      , BUSINESS_AREA
      , MAX_NUMBER_OF_PARTIAL_DELIVERIES
      , PRICING_GROUP
      , CUSTOMER_MATERIAL_NUMBER
      , SALES_DEAL
      , SUBSCRIPTION_SOURCE                               
      , SUBSCRIPTION_ID
      , REC_SRC
      , BKCC
      , IS_DELETED
    FROM SRC_PIT
)
---- RENAME LAYER ----

, RENAME_PIT as (
    SELECT
        SOURCE
      , SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_LINE_NUMBER
      , SALES_ORDER_CREATION_DATE_KEY
      , SALES_ORDER_DELIVERY_IND
      , CUSTOMER_BK
      , ITEM_BK
      , SALES_ORDER_ITEM_DESC
      , SALES_ORDER_DOCUMENT_TYPE
      , SALES_ORDER_LINE_RETURN_IND
      , QUANTITY
      , NET_PRICE
      , NET_VALUE
      , RETURN_REASON_CODE
      , PLANT
      , SALES_ORDER_ITEM_CATEGORY
      , REJECTION_REASON
      , CUMULATIVE_ORDER_QUANTITY
      , CUMULATIVE_REQUIRED_QUANTITY
      , CUMULATIVE_CONFIRMED_QUANTITY
      , DELIVERY_PRIORITY
      , MINIMUM_DELIVERY_QUANTITY
      , LAST_CHANGE_DATE_LINE__YYYYMMDD
      , REQUIREMENTS_TYPE
      , BUSINESS_AREA
      , MAX_NUMBER_OF_PARTIAL_DELIVERIES
      , PRICING_GROUP
      , CUSTOMER_MATERIAL_NUMBER
      , SALES_DEAL
      , SUBSCRIPTION_SOURCE                               
      , SUBSCRIPTION_ID
      , REC_SRC
      , BKCC
      , IS_DELETED
    FROM LOGIC_PIT
)
---- FILTER LAYER ----

, FILTER_PIT as (
    SELECT *
    FROM RENAME_PIT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PIT
)

---- FINAL LAYER ----
SELECT
        SOURCE
      , SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_LINE_NUMBER
      , SALES_ORDER_CREATION_DATE_KEY
      , SALES_ORDER_DELIVERY_IND
      , CUSTOMER_BK
      , ITEM_BK
      , SALES_ORDER_ITEM_DESC
      , SALES_ORDER_DOCUMENT_TYPE
      , SALES_ORDER_LINE_RETURN_IND
      , QUANTITY
      , NET_PRICE
      , NET_VALUE
      , RETURN_REASON_CODE
      , PLANT
      , SALES_ORDER_ITEM_CATEGORY
      , REJECTION_REASON
      , CUMULATIVE_ORDER_QUANTITY
      , CUMULATIVE_REQUIRED_QUANTITY
      , CUMULATIVE_CONFIRMED_QUANTITY
      , DELIVERY_PRIORITY
      , MINIMUM_DELIVERY_QUANTITY
      , LAST_CHANGE_DATE_LINE__YYYYMMDD
      , REQUIREMENTS_TYPE
      , BUSINESS_AREA
      , MAX_NUMBER_OF_PARTIAL_DELIVERIES
      , PRICING_GROUP
      , CUSTOMER_MATERIAL_NUMBER
      , SALES_DEAL
      , SUBSCRIPTION_SOURCE                               
      , SUBSCRIPTION_ID
      , REC_SRC
      , BKCC
      , IS_DELETED
FROM JOIN_RESULT
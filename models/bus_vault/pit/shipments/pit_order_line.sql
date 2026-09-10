---- SRC LAYER ----
WITH
SRC_winn           as ( SELECT 
                            SOURCE
                          , SALES_ORDER_LINE_HK
                          , SALES_ORDER_LINE_BK
                          , SALES_ORDER_NUMBER
                          , SALES_ORDER_LINE_NUMBER
                          , PARTNER_FUNCTION
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
                        FROM {{ ref('stg_pit_order_line__winn_sap') }} as SRC  ),

SRC_ml             as ( SELECT 
                            SOURCE
                          , SALES_ORDER_LINE_HK
                          , SALES_ORDER_LINE_BK
                          , SALES_ORDER_NUMBER
                          , SALES_ORDER_LINE_NUMBER
                          , PARTNER_FUNCTION
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
                          , NULL AS SUBSCRIPTION_SOURCE
                          , NULL AS SUBSCRIPTION_ID
                          , REC_SRC
                          , BKCC
                          , IS_DELETED
                        FROM {{ ref('stg_pit_order_line__ml_ebs') }} as SRC  )



---- LOGIC LAYER ----

, LOGIC_winn as (
    SELECT
        SOURCE
      , SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_LINE_NUMBER
      , PARTNER_FUNCTION
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
    FROM SRC_winn
)

, LOGIC_ml as (
    SELECT
        SOURCE
      , SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_LINE_NUMBER
      , PARTNER_FUNCTION
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
    FROM SRC_ml
)


---- RENAME LAYER ----

, RENAME_winn as (
    SELECT
        SOURCE
      , SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_LINE_NUMBER
      , PARTNER_FUNCTION
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
    FROM LOGIC_winn
)

, RENAME_ml as (
    SELECT
        SOURCE
      , SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_LINE_NUMBER
      , PARTNER_FUNCTION
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
    FROM LOGIC_ml
)


---- FILTER LAYER ----

, FILTER_winn as (
    SELECT *
    FROM RENAME_winn
)

, FILTER_ml as (
    SELECT *
    FROM RENAME_ml
)



---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_winn
    UNION ALL
    SELECT * FROM FILTER_ml
    
)

---- FINAL LAYER ----
SELECT
      'PIT_ORDER_LINE'                                                as PIT_REC_SRC
      , CURRENT_DATE                                                   as SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())                   as PIT_LOAD_DTS
      , SOURCE
      , SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_LINE_NUMBER
      , PARTNER_FUNCTION
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
QUALIFY (ROW_NUMBER() OVER(PARTITION BY SALES_ORDER_LINE_HK, SALES_ORDER_NUMBER ORDER BY SOURCE)) = 1

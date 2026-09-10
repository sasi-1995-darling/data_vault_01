---- SRC LAYER ----
WITH
SRC_WINN           as ( SELECT 
                            SOURCE
                          , SALES_ORDER_HEADER_HK
                          , SALES_ORDER_HEADER_BK
                          , SALES_ORDER_NUMBER
                          , SALES_ORDER_DOCUMENT_TYPE
                          , SALES_ORDER_DOCUMENT_CATEGORY
                          , CUSTOMER_BK
                          , SALES_ORDER_CREATION_DATE_KEY
                          , DIVISION
                          , DISTRIBUTION_CHANNEL
                          , SALES_ORGANIZATION
                          , SALES_ORDER_CURRENCY
                          , CUSTOMER_PURCHASE_ORDER_TYPE
                          , CREATED_BY
                          , DOCUMENT_DATE_KEY
                          , SALES_DOCUMENT_REASON
                          , NET_VALUE
                          , DOCUMENT_CONDITION_RECORD
                          , REQUESTED_DELIVERY_DATE__YYYYMMDD
                          , LAST_CHANGE_DATE__YYYYMMDD
                          , KEY_ACCOUNT
                          , GROUP_KEY_ACCOUNT
                          , BUYING_GROUP
                          , REQUESTED_SHIP_DATE__YYYYMMDD
                          , ORDER_CATEGORY
                          , SHIPPING_CONDITION
                          , CUSTOMER_PO_NUMBER
                          , CUSTOMER_PO_DATE__YYYYMMDD
                          , CUSTOMER_LEAD_DAYS
                          , CUSTOMER_SHIP_EARLY_FLAG
                          , NOTIFICATION_NUMBER
                          , MATERIAL_AVAILABILITY_DATE__YYYYMMDD
                          , REC_SRC
                          , BKCC
                          , IS_DELETED
                        FROM {{ ref('stg_pit_order_header__winn_sap') }} ),

SRC_ML             as ( SELECT 
                            SOURCE
                          , SALES_ORDER_HEADER_HK
                          , SALES_ORDER_HEADER_BK
                          , SALES_ORDER_NUMBER
                          , SALES_ORDER_DOCUMENT_TYPE
                          , SALES_ORDER_DOCUMENT_CATEGORY
                          , CUSTOMER_BK
                          , SALES_ORDER_CREATION_DATE_KEY
                          , DIVISION
                          , DISTRIBUTION_CHANNEL
                          , SALES_ORGANIZATION
                          , SALES_ORDER_CURRENCY
                          , CUSTOMER_PURCHASE_ORDER_TYPE
                          , CREATED_BY
                          , DOCUMENT_DATE_KEY
                          , SALES_DOCUMENT_REASON
                          , NET_VALUE
                          , DOCUMENT_CONDITION_RECORD
                          , REQUESTED_DELIVERY_DATE__YYYYMMDD
                          , LAST_CHANGE_DATE__YYYYMMDD
                          , KEY_ACCOUNT
                          , GROUP_KEY_ACCOUNT
                          , BUYING_GROUP
                          , REQUESTED_SHIP_DATE__YYYYMMDD
                          , ORDER_CATEGORY
                          , SHIPPING_CONDITION
                          , CUSTOMER_PO_NUMBER
                          , CUSTOMER_PO_DATE__YYYYMMDD
                          , CUSTOMER_LEAD_DAYS
                          , CUSTOMER_SHIP_EARLY_FLAG
                          , NOTIFICATION_NUMBER
                          , MATERIAL_AVAILABILITY_DATE__YYYYMMDD
                          , REC_SRC
                          , BKCC
                          , IS_DELETED
                        FROM {{ ref('stg_pit_order_header__ml_ebs') }} )

/*
SRC_WINN           as ( SELECT * FROM BUS_VAULT.STG_PIT_ORDER_HEADER__WINN_SAP ),
SRC_ML             as ( SELECT * FROM BUS_VAULT.STG_PIT_ORDER_HEADER__ML_EBS )
*/

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM SRC_WINN
    UNION ALL
    SELECT * FROM SRC_ML
)

---- FINAL LAYER ----
SELECT
        ROW_NUMBER() OVER (ORDER BY 1)                               as SEQ_ID
      , 'PIT_ORDER_HEADER'                                           as PIT_REC_SRC
      , CURRENT_DATE                                                 as SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())                 as PIT_LOAD_DTS
      , SOURCE
      , SALES_ORDER_HEADER_HK
      , SALES_ORDER_HEADER_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_DOCUMENT_TYPE
      , SALES_ORDER_DOCUMENT_CATEGORY
      , CUSTOMER_BK
      , SALES_ORDER_CREATION_DATE_KEY
      , DIVISION
      , DISTRIBUTION_CHANNEL
      , SALES_ORGANIZATION
      , SALES_ORDER_CURRENCY
      , CUSTOMER_PURCHASE_ORDER_TYPE
      , CREATED_BY
      , DOCUMENT_DATE_KEY
      , SALES_DOCUMENT_REASON
      , NET_VALUE
      , DOCUMENT_CONDITION_RECORD
      , REQUESTED_DELIVERY_DATE__YYYYMMDD
      , LAST_CHANGE_DATE__YYYYMMDD
      , KEY_ACCOUNT
      , GROUP_KEY_ACCOUNT
      , BUYING_GROUP
      , REQUESTED_SHIP_DATE__YYYYMMDD
      , ORDER_CATEGORY
      , SHIPPING_CONDITION
      , CUSTOMER_PO_NUMBER
      , CUSTOMER_PO_DATE__YYYYMMDD
      , CUSTOMER_LEAD_DAYS
      , CUSTOMER_SHIP_EARLY_FLAG
      , NOTIFICATION_NUMBER
      , MATERIAL_AVAILABILITY_DATE__YYYYMMDD
      , REC_SRC
      , BKCC
      , IS_DELETED
FROM JOIN_RESULT
---- SRC LAYER ----
WITH
SRC_PIT            as ( SELECT 
                            SEQ_ID
                          , PIT_REC_SRC
                          , SNAPSHOTDATE
                          , PIT_LOAD_DTS
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
                        FROM {{ ref('pit_order_header') }} )

/*
SRC_PIT            as ( SELECT * FROM BUS_VAULT.PIT_ORDER_HEADER )
*/

---- LOGIC LAYER ----
, LOGIC_PIT as (
    SELECT *
    FROM SRC_PIT
)

---- RENAME LAYER ----
, RENAME_PIT as (
    SELECT *
    FROM LOGIC_PIT
)

---- FILTER LAYER ----
, FILTER_PIT as (
    SELECT *
    FROM RENAME_PIT
    WHERE 
      /* Data quality filter for specific Oracle EBS sources */
        NOT (
          REC_SRC IN (
              'USWIOC.ORCL.EBSPRD.OE_ORDER_LINES_ALL', 
              'USWIOC.ORCL.EBSPRD.ORDER_HEADERS'
          )
          AND (
              SALES_ORDER_NUMBER IS NULL 
              OR SALES_ORDER_CREATION_DATE_KEY IS NULL 
              OR SALES_ORDER_CREATION_DATE_KEY = 0
          )
      )
      /* Exclude specific problematic record sources */
      AND REC_SRC NOT IN (
          'USAZET.SNOWFLAKE.FBIN.DERIVED',
          'USWIOC.ORCL.EBSPRD.CUSTOMER_TRX_LINES_ALL'
      )
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PIT
)

---- FINAL LAYER ----
SELECT
        SALES_ORDER_HEADER_HK
      , SALES_ORDER_HEADER_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_DOCUMENT_TYPE
      , SALES_ORDER_DOCUMENT_CATEGORY
      , SALES_ORDER_CREATION_DATE_KEY
      , DIVISION
      , DISTRIBUTION_CHANNEL
      , SALES_ORGANIZATION
      , SALES_ORDER_CURRENCY
      , CUSTOMER_PURCHASE_ORDER_TYPE
      , CREATED_BY
      , CUSTOMER_BK
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
      , BKCC
      , REC_SRC
      , IS_DELETED
FROM JOIN_RESULT
WHERE NOT (
    CUSTOMER_BK IS NULL
    AND SALES_ORDER_NUMBER IS NOT NULL
    AND SALES_ORDER_NUMBER != ''
)
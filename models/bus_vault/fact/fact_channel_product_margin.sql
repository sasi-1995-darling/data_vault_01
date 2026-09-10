---- SRC LAYER ----
WITH
SRC_pb as ( 
    SELECT 
         SEQ_ID
        ,CHANNEL_PRODUCT_MARGIN_LHK
        ,ASIN
        ,REPORT_END_DATE__YYYYMMDD
        ,NET_PURE_PRODUCT_MARGIN
        ,ITEM_HK
        ,ITEM_BK
        ,STORE_HK
        ,STORE_BK
        ,IS_DELETED
        ,BKCC
        ,REC_SRC
    FROM {{ ref('pb_channel_product_margin') }} 
)

/*
SRC_pb             as ( SELECT * FROM BUS_VAULT.pb_channel_product_margin )
*/

---- LOGIC LAYER ----

, LOGIC_pb as (
    SELECT
         SEQ_ID
        ,CHANNEL_PRODUCT_MARGIN_LHK
        ,ASIN
        ,REPORT_END_DATE__YYYYMMDD
        ,NET_PURE_PRODUCT_MARGIN
        ,ITEM_HK
        ,ITEM_BK
        ,STORE_HK
        ,STORE_BK
        ,IS_DELETED
        ,BKCC
        ,REC_SRC
    FROM SRC_pb
)

---- RENAME LAYER ----

, RENAME_pb as ( 
    SELECT 
         SEQ_ID
        ,CHANNEL_PRODUCT_MARGIN_LHK
        ,ASIN
        ,REPORT_END_DATE__YYYYMMDD
        ,NET_PURE_PRODUCT_MARGIN
        ,ITEM_HK
        ,ITEM_BK
        ,STORE_HK
        ,STORE_BK
        ,IS_DELETED
        ,BKCC
        ,REC_SRC
    FROM LOGIC_pb 
)

---- FILTER LAYER ----

, FILTER_pb as (
    SELECT *
    FROM RENAME_pb
)

---- JOIN LAYER ----

, JOIN_RESULT as (
    SELECT *
    FROM FILTER_pb
)

---- FINAL LAYER ----

SELECT
         SEQ_ID
        ,CHANNEL_PRODUCT_MARGIN_LHK
        ,ASIN
        ,REPORT_END_DATE__YYYYMMDD
        ,NET_PURE_PRODUCT_MARGIN
        ,ITEM_HK
        ,ITEM_BK
        ,STORE_HK
        ,STORE_BK
        ,IS_DELETED
        ,BKCC
        ,REC_SRC 
FROM JOIN_RESULT
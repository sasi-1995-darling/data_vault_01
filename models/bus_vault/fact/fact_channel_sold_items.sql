---- SRC LAYER ----
WITH
SRC_pb as ( 
    SELECT 
          SEQ_ID
        , CHANNEL_SOLD_ITEM_LHK
        , ASIN
        , START_DATE__YYYYMMDD
        , REPORT_DATE__YYYYMMDD
        , CUSTOMER_RETURNS
        , ORDERED_REVENUE_AMT
        , SHIPPED_COGS_AMT
        , SHIPPED_REVENUE
        , ORDERED_UNITS
        , SHIPPED_UNITS
        , ITEM_HK
        , ITEM_BK
        , STORE_HK
        , STORE_BK
        , IS_DELETED
        , BKCC
        , REC_SRC
    FROM {{ ref('pb_channel_sold_items') }} 
)

/*
SRC_pb             as ( SELECT * FROM BUS_VAULT.pb_channel_sold_items )
*/

---- LOGIC LAYER ----

, LOGIC_pb as (
    SELECT
          SEQ_ID
        , CHANNEL_SOLD_ITEM_LHK
        , ASIN
        , START_DATE__YYYYMMDD
        , REPORT_DATE__YYYYMMDD
        , CUSTOMER_RETURNS
        , ORDERED_REVENUE_AMT
        , SHIPPED_COGS_AMT
        , SHIPPED_REVENUE
        , ORDERED_UNITS
        , SHIPPED_UNITS
        , ITEM_HK
        , ITEM_BK
        , STORE_HK
        , STORE_BK
        , IS_DELETED
        , BKCC
        , REC_SRC
    FROM SRC_pb
)

---- RENAME LAYER ----

, RENAME_pb as ( 
    SELECT 
          SEQ_ID
        , CHANNEL_SOLD_ITEM_LHK
        , ASIN
        , START_DATE__YYYYMMDD
        , REPORT_DATE__YYYYMMDD
        , CUSTOMER_RETURNS
        , ORDERED_REVENUE_AMT
        , SHIPPED_COGS_AMT
        , SHIPPED_REVENUE
        , ORDERED_UNITS
        , SHIPPED_UNITS
        , ITEM_HK
        , ITEM_BK
        , STORE_HK
        , STORE_BK
        , IS_DELETED
        , BKCC
        , REC_SRC
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
        , CHANNEL_SOLD_ITEM_LHK
        , ASIN
        , START_DATE__YYYYMMDD
        , REPORT_DATE__YYYYMMDD
        , CUSTOMER_RETURNS
        , ORDERED_REVENUE_AMT
        , SHIPPED_COGS_AMT
        , SHIPPED_REVENUE
        , ORDERED_UNITS
        , SHIPPED_UNITS
        , ITEM_HK
        , ITEM_BK
        , STORE_HK
        , STORE_BK
        , IS_DELETED
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
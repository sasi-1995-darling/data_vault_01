{{
  config(
    materialized = 'table'
  )
}}

---- SRC LAYER ----
WITH
SRC_COPA           as ( SELECT * FROM {{ ref('pb_copa') }} as SRC ),
SRC_LNK_COPA       as ( SELECT * FROM {{ ref('lnk_copa_sales') }} as SRC ),
SRC_ORDER_LINE     as ( SELECT * FROM {{ ref('pit_order_line') }} as SRC ),
SRC_ORDER_HEADER   as ( SELECT * FROM {{ ref('pit_order_header') }} as SRC )
/*
SRC_COPA           as ( SELECT * FROM BUS_VAULT.PB_COPA )
SRC_LNK_COPA       as ( SELECT * FROM RAW_VAULT.LNK_COPA_SALES )
SRC_ORDER_LINE     as ( SELECT * FROM BUS_VAULT.PIT_ORDER_LINE )
SRC_ORDER_HEADER   as ( SELECT * FROM BUS_VAULT.PIT_ORDER_HEADER )
*/
---- LOGIC LAYER ----
, LOGIC_PERIOD_SPINE as (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 as PERIOD_OFFSET
    FROM TABLE(GENERATOR(ROWCOUNT => 12))
)
, LOGIC_COPA as (
    SELECT
        LNK_COPA_SALES_HK
      , KAUFN
      , KDPOS
      , PRODUCT_NUMBER
      , TRY_TO_NUMBER(BILLING_DATE__YYYYMMDD)    as BILLING_DATE_KEY
      , FISCAL_MONTH__YYYYMM
      , VVNET
      , VVGRS
      , VVGBP
      , VVQTY
      , VVCST
      , BILLING_TYPE
      , REC_SRC
      , BKCC
    FROM SRC_COPA
    WHERE RECORD_TYPE = 'F'
)
, LOGIC_LNK_COPA as (
    SELECT
        LNK_COPA_SALES_HK
      , ORDER_LINE_HK
    FROM SRC_LNK_COPA
)
, LOGIC_ORDER_LINE as (
    SELECT
        SOURCE
      , SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_LINE_NUMBER
      , SALES_ORDER_CREATION_DATE_KEY
      , TRY_TO_DATE(SALES_ORDER_CREATION_DATE_KEY::VARCHAR, 'YYYYMMDD')
                                                 as SUBSCRIPTION_START_DATE
      , CUSTOMER_BK
      , ITEM_BK
      , SALES_ORDER_ITEM_DESC
      , SALES_ORDER_DOCUMENT_TYPE
      , QUANTITY
      , NET_PRICE
      , NET_VALUE
      , SUBSCRIPTION_SOURCE
      , SUBSCRIPTION_ID
      , REC_SRC
      , BKCC
      , IS_DELETED
    FROM SRC_ORDER_LINE
)
, LOGIC_ORDER_HEADER as (
    SELECT
        SALES_ORDER_HEADER_HK
      , SALES_ORDER_HEADER_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_DOCUMENT_TYPE
      , CUSTOMER_BK
      , SALES_ORDER_CREATION_DATE_KEY
      , SALES_ORGANIZATION
      , DISTRIBUTION_CHANNEL
      , DIVISION
      , SALES_ORDER_CURRENCY
      , REC_SRC
      , BKCC
      , IS_DELETED
    FROM SRC_ORDER_HEADER
)
---- RENAME LAYER ----
, RENAME_COPA as (
    SELECT
        LNK_COPA_SALES_HK
      , KAUFN                                    as BILLING_ORDER_NUMBER
      , KDPOS                                    as BILLING_LINE_ITEM
      , PRODUCT_NUMBER
      , BILLING_DATE_KEY
      , FISCAL_MONTH__YYYYMM
      , VVNET                                    as NET_SALES_REVENUE
      , VVGRS                                    as COST_OF_GOODS_SOLD
      , VVGBP                                    as GROSS_PRICE
      , VVQTY                                    as ORDER_QUANTITY
      , VVCST                                    as STANDARD_COST
      , BILLING_TYPE
      , REC_SRC                                  as COPA_REC_SRC
      , BKCC                                     as COPA_BKCC
    FROM LOGIC_COPA
)
, RENAME_ORDER_LINE as (
    SELECT
        SOURCE
      , SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_LINE_NUMBER
      , SALES_ORDER_CREATION_DATE_KEY
      , SUBSCRIPTION_START_DATE
      , CUSTOMER_BK
      , ITEM_BK
      , SALES_ORDER_ITEM_DESC
      , SALES_ORDER_DOCUMENT_TYPE
      , QUANTITY
      , NET_PRICE
      , NET_VALUE
      , SUBSCRIPTION_SOURCE
      , SUBSCRIPTION_ID
      , REC_SRC
      , BKCC
      , IS_DELETED
    FROM LOGIC_ORDER_LINE
)
, RENAME_ORDER_HEADER as (
    SELECT
        SALES_ORDER_HEADER_HK
      , SALES_ORDER_HEADER_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_DOCUMENT_TYPE
      , CUSTOMER_BK
      , SALES_ORDER_CREATION_DATE_KEY
      , SALES_ORGANIZATION
      , DISTRIBUTION_CHANNEL
      , DIVISION
      , SALES_ORDER_CURRENCY
      , REC_SRC
      , BKCC
      , IS_DELETED
    FROM LOGIC_ORDER_HEADER
)
---- FILTER LAYER ----
, FILTER_COPA as (
    SELECT *
    FROM RENAME_COPA
    WHERE BILLING_ORDER_NUMBER IS NOT NULL
      AND BILLING_ORDER_NUMBER != ''
      AND BILLING_DATE_KEY IS NOT NULL
)
, FILTER_ORDER_LINE as (
    SELECT *
    FROM RENAME_ORDER_LINE
    WHERE IS_DELETED = 'N'
)
, FILTER_ORDER_HEADER as (
    SELECT *
    FROM RENAME_ORDER_HEADER
    WHERE IS_DELETED = 'N'
      AND REC_SRC NOT IN ('USAZET.SNOWFLAKE.FBIN.DERIVED', 'USWIOC.ORCL.EBSPRD.CUSTOMER_TRX_LINES_ALL')
      AND NOT (
            REC_SRC IN ('USWIOC.ORCL.EBSPRD.OE_ORDER_LINES_ALL', 'USWIOC.ORCL.EBSPRD.ORDER_HEADERS')
            AND (SALES_ORDER_NUMBER IS NULL OR SALES_ORDER_CREATION_DATE_KEY IS NULL OR SALES_ORDER_CREATION_DATE_KEY = 0)
      )
      AND NOT (CUSTOMER_BK IS NULL AND SALES_ORDER_NUMBER IS NOT NULL AND SALES_ORDER_NUMBER != '')
)
---- JOIN LAYER ----
/*  Subscription lines: order lines with a subscription ID, joined to header */
, JOIN_SUBSCRIPTIONS as (
    SELECT
        ol.SALES_ORDER_LINE_HK
      , ol.SALES_ORDER_LINE_BK
      , ol.SALES_ORDER_NUMBER
      , ol.SALES_ORDER_LINE_NUMBER
      , ol.SALES_ORDER_CREATION_DATE_KEY
      , oh.CUSTOMER_BK
      , ol.ITEM_BK
      , ol.SALES_ORDER_ITEM_DESC
      , ol.QUANTITY
      , ol.NET_VALUE
      , ol.SUBSCRIPTION_SOURCE
      , ol.SUBSCRIPTION_ID
      , ol.SUBSCRIPTION_START_DATE
      , oh.SALES_ORDER_HEADER_HK
      , oh.SALES_ORDER_DOCUMENT_TYPE
      , oh.SALES_ORGANIZATION
      , oh.DISTRIBUTION_CHANNEL
      , oh.DIVISION
      , oh.SALES_ORDER_CURRENCY
      , ol.REC_SRC
      , ol.BKCC
    FROM FILTER_ORDER_LINE  ol
    INNER JOIN FILTER_ORDER_HEADER  oh
        ON  ol.SALES_ORDER_NUMBER = oh.SALES_ORDER_NUMBER
        AND ol.BKCC = oh.BKCC
    WHERE ol.SUBSCRIPTION_ID IS NOT NULL
      AND ol.SUBSCRIPTION_ID != ''
      AND ol.ITEM_BK NOT IN ('900-011-CNL', '900-012-CNL')
)
/*  Expand each subscription into up to 12 monthly rows.
    COPA joined via the COPA sales link key (through LOGIC_LNK_COPA /
    lnk_copa_sales_hk) to preserve the intended grain and prevent
    many-to-many fan-out.
    Period spine anchored on SUBSCRIPTION_START_DATE.
    VVNET from COPA is always the full annual contract amount;
    SUM(NET_SALES_REVENUE) / 12 prorates to monthly recurring share. */
, JOIN_RESULT as (
    SELECT
        sub.SALES_ORDER_LINE_HK
      , sub.SALES_ORDER_LINE_BK
      , sub.SALES_ORDER_HEADER_HK
      , sub.SALES_ORDER_NUMBER
      , sub.SALES_ORDER_LINE_NUMBER
      , TRY_TO_NUMBER(sub.SALES_ORDER_CREATION_DATE_KEY)                          as SUBSCRIPTION_START_DATE_KEY
      , sub.CUSTOMER_BK
      , sub.ITEM_BK
      , sub.SALES_ORDER_ITEM_DESC
      , sub.SUBSCRIPTION_SOURCE
      , sub.SUBSCRIPTION_ID
      , sub.SUBSCRIPTION_START_DATE
      , sub.SALES_ORDER_DOCUMENT_TYPE
      , sub.SALES_ORGANIZATION
      , sub.DISTRIBUTION_CHANNEL
      , sub.DIVISION
      , sub.SALES_ORDER_CURRENCY
      , sub.REC_SRC
      , sub.BKCC
      , copa.BILLING_DATE_KEY
      , copa.NET_SALES_REVENUE
      , copa.COST_OF_GOODS_SOLD
      , copa.GROSS_PRICE
      , copa.ORDER_QUANTITY
      , copa.STANDARD_COST
      , copa.PRODUCT_NUMBER
      , copa.FISCAL_MONTH__YYYYMM
      , copa.BILLING_TYPE
      , copa.COPA_REC_SRC
      , ps.PERIOD_OFFSET + 1                                                    as PERIOD_NUMBER
      , DATEADD('MONTH', ps.PERIOD_OFFSET, sub.SUBSCRIPTION_START_DATE)          as REVENUE_MONTH
      , TRY_TO_NUMBER(TO_CHAR(DATEADD('MONTH', ps.PERIOD_OFFSET, sub.SUBSCRIPTION_START_DATE), 'YYYYMMDD'))
                                                                                 as REVENUE_MONTH_DATE_KEY
      , LAST_DAY(DATEADD('MONTH', ps.PERIOD_OFFSET, sub.SUBSCRIPTION_START_DATE))
                                                                                 as REVENUE_MONTH_END
      , TRY_TO_NUMBER(TO_CHAR(LAST_DAY(DATEADD('MONTH', ps.PERIOD_OFFSET, sub.SUBSCRIPTION_START_DATE)), 'YYYYMMDD'))
                                                                                  as REVENUE_MONTH_END_DATE_KEY
    FROM JOIN_SUBSCRIPTIONS  sub
    INNER JOIN LOGIC_LNK_COPA  lnk
        ON  sub.SALES_ORDER_LINE_HK = lnk.ORDER_LINE_HK
    INNER JOIN FILTER_COPA  copa
        ON  lnk.LNK_COPA_SALES_HK = copa.LNK_COPA_SALES_HK
    CROSS JOIN LOGIC_PERIOD_SPINE  ps
    WHERE sub.SUBSCRIPTION_START_DATE IS NOT NULL
)
---- FINAL LAYER ----
SELECT
        'PB_RECURRING_REVENUE'                                                   as PB_REC_SRC
      , CURRENT_DATE                                                             as SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP)                               as PB_LOAD_DTS
      , COALESCE(SALES_ORDER_LINE_BK, '')
        || '|' || COALESCE(SUBSCRIPTION_SOURCE, '')
        || '|' || COALESCE(SUBSCRIPTION_ID, '')
        || '|' || COALESCE(CUSTOMER_BK, '')
        || '|' || COALESCE(ITEM_BK, '')
        || '|' || COALESCE(TO_CHAR(BILLING_DATE_KEY), '')
        || '|' || COALESCE(TO_CHAR(FISCAL_MONTH__YYYYMM), '')
        || '|' || TO_CHAR(PERIOD_NUMBER)         as RECURRING_REVENUE_BK
      , SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
      , SALES_ORDER_HEADER_HK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_LINE_NUMBER
      , CUSTOMER_BK
      , SUBSCRIPTION_ID
      , SUBSCRIPTION_SOURCE
      , ITEM_BK
      , SALES_ORDER_ITEM_DESC
      , PRODUCT_NUMBER
      , SALES_ORDER_DOCUMENT_TYPE
      , MAX(BILLING_TYPE)                                                        as BILLING_TYPE
      , SALES_ORGANIZATION
      , DISTRIBUTION_CHANNEL
      , DIVISION
      , SALES_ORDER_CURRENCY
      , SUM(NET_SALES_REVENUE)                                                   as NET_SALES_REVENUE
      , SUM(COST_OF_GOODS_SOLD)                                                  as COST_OF_GOODS_SOLD
      , SUM(GROSS_PRICE)                                                         as GROSS_PRICE
      , SUM(ORDER_QUANTITY)                                                      as ORDER_QUANTITY
      , SUM(STANDARD_COST)                                                       as STANDARD_COST
      , SUM(NET_SALES_REVENUE) / 12                                              as RECURRING_REVENUE
      , SUBSCRIPTION_START_DATE_KEY
      , BILLING_DATE_KEY
      , REVENUE_MONTH_DATE_KEY
      , REVENUE_MONTH_END_DATE_KEY
      , PERIOD_NUMBER
      , FISCAL_MONTH__YYYYMM
      , CASE
            WHEN REVENUE_MONTH_END_DATE_KEY < TRY_TO_NUMBER(TO_CHAR(CURRENT_DATE(), 'YYYYMMDD'))
                 AND PERIOD_NUMBER = 12                      THEN 'EXPIRED'
            WHEN REVENUE_MONTH_DATE_KEY <= TRY_TO_NUMBER(TO_CHAR(CURRENT_DATE(), 'YYYYMMDD'))
                                                             THEN 'ACTIVE'
            ELSE 'FUTURE'
        END                                      as SUBSCRIPTION_STATUS
      , REC_SRC
      , BKCC
      , MAX(COPA_REC_SRC)                                                        as COPA_REC_SRC
FROM JOIN_RESULT as JR
GROUP BY
        SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
      , SALES_ORDER_HEADER_HK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_LINE_NUMBER
      , CUSTOMER_BK
      , SUBSCRIPTION_ID
      , SUBSCRIPTION_SOURCE
      , ITEM_BK
      , SALES_ORDER_ITEM_DESC
      , PRODUCT_NUMBER
      , SALES_ORDER_DOCUMENT_TYPE
      , SALES_ORGANIZATION
      , DISTRIBUTION_CHANNEL
      , DIVISION
      , SALES_ORDER_CURRENCY
      , SUBSCRIPTION_START_DATE_KEY
      , BILLING_DATE_KEY
      , REVENUE_MONTH_DATE_KEY
      , REVENUE_MONTH_END_DATE_KEY
      , PERIOD_NUMBER
      , FISCAL_MONTH__YYYYMM
      , REC_SRC
      , BKCC
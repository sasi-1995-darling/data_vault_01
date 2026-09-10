---- SRC LAYER ----
WITH
SRC_lnk as ( 
    SELECT 
          CHANNEL_SOLD_ITEM_LHK
        , ITEM_HK
        , STORE_HK
        , REC_SRC 
    FROM {{ ref('lnk_channel_sold_items') }} 
),

SRC_hub_item as ( 
    SELECT 
          ITEM_BK
        , ITEM_HK 
    FROM {{ ref('hub_item_v1') }} 
),

SRC_hub_store as ( 
    SELECT 
          STORE_BK
        , STORE_HK
        , BKCC 
    FROM {{ ref('hub_store') }} 
),

SRC_sat_vc as ( 
    SELECT 
          CHANNEL_SOLD_ITEM_LHK
        , DATEADD(DAY, -(DAYOFWEEK(TO_DATE(REPORT_START_DT))), TO_DATE(REPORT_START_DT)) AS REPORT_START_DT
        , DATEADD(DAY, 6 - DAYOFWEEK(TO_DATE(REPORT_END_DT)), TO_DATE(REPORT_END_DT))     AS REPORT_END_DT
        , ASIN
        , ORDERDED_REVENUE_AMT
        , ORDERDED_UNITS
        , SHIPPED_COGS_AMT
        , SHIPPED_REVENUE_AMT
        , SHIPPED_UNITS
        , VENDORCENTRAL_ACCOUNT
        , SHIPPED_COGS_CURRCODE
        , CUSTOMER_RETURNS 
        , PSA_DELETE_IND
        , load_dts
    FROM {{ ref('lmsat_channel_sold_items__amazon_vc') }} 
    WHERE VENDORCENTRAL_ACCOUNT IN ('Moen Inc', 'Moen Anaheim')
      AND SHIPPED_COGS_CURRCODE = 'USD'
      AND TO_DATE(REPORT_START_DT) between '2023-01-01' and '2025-02-10'
    qualify 1 = row_number() over(partition by CHANNEL_SOLD_ITEM_LHK order by load_dts DESC) 
),

SRC_sat_anaheim as ( 
    SELECT 
          CHANNEL_SOLD_ITEM_LHK
        , ASIN
        , DATEADD(DAY, -(DAYOFWEEK(START_DATE)), START_DATE) AS START_DATE
        , DATEADD(DAY, 6 - DAYOFWEEK(END_DATE), END_DATE) AS END_DATE
        , CUSTOMER_RETURNS
        , ORDERED_REVENUE_AMOUNT
        , ORDERED_UNITS
        , SHIPPED_COGS_AMOUNT
        , SHIPPED_REVENUE_AMOUNT
        , SHIPPED_UNITS
        , ORDERED_REVENUE_CURRENCY_CODE
        , SHIPPED_REVENUE_CURRENCY_CODE
        , PSA_DELETE_IND
        , load_dts
    FROM {{ ref('lmsat_channel_sold_items__amazon_moen_anaheim') }} 
    where START_DATE >= '2025-02-11' AND ORDERED_REVENUE_CURRENCY_CODE = 'USD' AND SHIPPED_REVENUE_CURRENCY_CODE = 'USD'
    qualify 1 = row_number() over(partition by CHANNEL_SOLD_ITEM_LHK order by load_dts DESC) 
),

SRC_sat_inc as ( 
    SELECT 
          CHANNEL_SOLD_ITEM_LHK
        , ASIN
        , DATEADD(DAY, -(DAYOFWEEK(START_DATE)), START_DATE) AS START_DATE
        , DATEADD(DAY, 6 - DAYOFWEEK(END_DATE), END_DATE) AS END_DATE
        , CUSTOMER_RETURNS
        , ORDERED_REVENUE_AMOUNT
        , ORDERED_UNITS
        , SHIPPED_COGS_AMOUNT
        , SHIPPED_REVENUE_AMOUNT
        , SHIPPED_UNITS
        , ORDERED_REVENUE_CURRENCY_CODE
        , SHIPPED_REVENUE_CURRENCY_CODE
        , PSA_DELETE_IND
        , load_dts
    FROM {{ ref('lmsat_channel_sold_items__amazon_moen_inc') }} 
    where START_DATE >= '2025-02-11' AND ORDERED_REVENUE_CURRENCY_CODE = 'USD' AND SHIPPED_REVENUE_CURRENCY_CODE = 'USD'
    qualify 1 = row_number() over(partition by CHANNEL_SOLD_ITEM_LHK order by load_dts DESC) 
)

---- LOGIC LAYER ----

, LOGIC_lnk as (
    SELECT
          CHANNEL_SOLD_ITEM_LHK
        , ITEM_HK
        , STORE_HK
        , REC_SRC
        , 'PB_CHANNEL_SOLD_ITEMS' as PB_REC_SRC
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP()) as PB_LOAD_DTS
    FROM SRC_lnk
)

, LOGIC_hub_item as (
    SELECT 
          ITEM_HK as hub_ITEM_HK
        , ITEM_BK 
    FROM SRC_hub_item
)

, LOGIC_hub_store as (
    SELECT 
          STORE_HK as hub_STORE_HK
        , STORE_BK
        , BKCC 
    FROM SRC_hub_store
)

, LOGIC_sat_vc as (
    SELECT
          CHANNEL_SOLD_ITEM_LHK as LNK_HK
        , ASIN
        , REPORT_START_DT as START_DATE
        , REPORT_END_DT as REPORT_DATE
        , CUSTOMER_RETURNS
        , ORDERDED_REVENUE_AMT as ORDERED_REVENUE_AMT
        , ORDERDED_UNITS as ORDERED_UNITS
        , SHIPPED_COGS_AMT as SHIPPED_COGS_AMT
        , SHIPPED_REVENUE_AMT as SHIPPED_REVENUE
        , SHIPPED_UNITS
        , PSA_DELETE_IND as DELETE_IND
    FROM SRC_sat_vc
)

, LOGIC_sat_anaheim as (
    SELECT
          CHANNEL_SOLD_ITEM_LHK as LNK_HK
        , ASIN
        , START_DATE
        , END_DATE as REPORT_DATE
        , CUSTOMER_RETURNS
        , ORDERED_REVENUE_AMOUNT as ORDERED_REVENUE_AMT
        , ORDERED_UNITS
        , SHIPPED_COGS_AMOUNT as SHIPPED_COGS_AMT
        , SHIPPED_REVENUE_AMOUNT as SHIPPED_REVENUE
        , SHIPPED_UNITS
        , PSA_DELETE_IND as DELETE_IND
    FROM SRC_sat_anaheim
)

, LOGIC_sat_inc as (
    SELECT
          CHANNEL_SOLD_ITEM_LHK as LNK_HK
        , ASIN
        , START_DATE
        , END_DATE as REPORT_DATE
        , CUSTOMER_RETURNS
        , ORDERED_REVENUE_AMOUNT as ORDERED_REVENUE_AMT
        , ORDERED_UNITS
        , SHIPPED_COGS_AMOUNT as SHIPPED_COGS_AMT
        , SHIPPED_REVENUE_AMOUNT as SHIPPED_REVENUE
        , SHIPPED_UNITS
        , PSA_DELETE_IND as DELETE_IND
    FROM SRC_sat_inc
)

---- RENAME LAYER ----

, RENAME_lnk as ( 
    SELECT 
          CHANNEL_SOLD_ITEM_LHK
        , ITEM_HK
        , STORE_HK
        , REC_SRC
        , PB_REC_SRC
        , PB_LOAD_DTS 
    FROM LOGIC_lnk 
)

, RENAME_hub_item as ( 
    SELECT 
          hub_ITEM_HK
        , ITEM_BK 
    FROM LOGIC_hub_item 
)

, RENAME_hub_store as ( 
    SELECT 
          hub_STORE_HK
        , STORE_BK
        , BKCC 
    FROM LOGIC_hub_store 
)

, RENAME_sat_vc as ( 
    SELECT 
          LNK_HK
        , ASIN
        , START_DATE
        , REPORT_DATE
        , CUSTOMER_RETURNS
        , ORDERED_REVENUE_AMT
        , ORDERED_UNITS
        , SHIPPED_COGS_AMT
        , SHIPPED_REVENUE
        , SHIPPED_UNITS
        , DELETE_IND 
    FROM LOGIC_sat_vc 
)

, RENAME_sat_anaheim as ( 
    SELECT 
          LNK_HK
        , ASIN
        , START_DATE
        , REPORT_DATE
        , CUSTOMER_RETURNS
        , ORDERED_REVENUE_AMT
        , ORDERED_UNITS
        , SHIPPED_COGS_AMT
        , SHIPPED_REVENUE
        , SHIPPED_UNITS
        , DELETE_IND 
    FROM LOGIC_sat_anaheim 
)

, RENAME_sat_inc as ( 
    SELECT 
          LNK_HK
        , ASIN
        , START_DATE
        , REPORT_DATE
        , CUSTOMER_RETURNS
        , ORDERED_REVENUE_AMT
        , ORDERED_UNITS
        , SHIPPED_COGS_AMT
        , SHIPPED_REVENUE
        , SHIPPED_UNITS
        , DELETE_IND  
    FROM LOGIC_sat_inc 
)

---- FILTER LAYER ----

, FILTER_lnk as ( SELECT * FROM RENAME_lnk )
, FILTER_hub_item as ( SELECT * FROM RENAME_hub_item )
, FILTER_hub_store as ( SELECT * FROM RENAME_hub_store )

-- Union all sources together into a single unified stream
, UNIFIED_sat as (
    SELECT * FROM RENAME_sat_vc
    UNION ALL
    SELECT * FROM RENAME_sat_anaheim
    UNION ALL
    SELECT * FROM RENAME_sat_inc
)

---- JOIN LAYER ----

, JOIN_RESULT as (
    SELECT 
          l.CHANNEL_SOLD_ITEM_LHK
        , l.ITEM_HK
        , l.STORE_HK
        , l.REC_SRC
        , l.PB_REC_SRC
        , l.PB_LOAD_DTS
        , hi.ITEM_BK
        , hs.STORE_BK
        , hs.BKCC
        , sat.ASIN
        , sat.START_DATE
        , sat.REPORT_DATE
        , sat.CUSTOMER_RETURNS
        , sat.ORDERED_REVENUE_AMT
        , sat.SHIPPED_COGS_AMT
        , sat.SHIPPED_REVENUE
        , sat.ORDERED_UNITS
        , sat.SHIPPED_UNITS
        , sat.DELETE_IND
    FROM FILTER_lnk l
    LEFT JOIN FILTER_hub_item hi  ON l.ITEM_HK = hi.hub_ITEM_HK
    LEFT JOIN FILTER_hub_store hs ON l.STORE_HK = hs.hub_STORE_HK
    LEFT JOIN UNIFIED_sat sat      ON l.CHANNEL_SOLD_ITEM_LHK = sat.LNK_HK
)

---- FINAL LAYER ----

SELECT
      row_number() over(order by 1) as SEQ_ID
    , CURRENT_DATE as SNAPSHOTDATE
    , CHANNEL_SOLD_ITEM_LHK
    , PB_REC_SRC
    , BKCC
    , REC_SRC
    , PB_LOAD_DTS
    , ASIN
    , TO_CHAR(START_DATE, 'YYYYMMDD')::INTEGER AS START_DATE__YYYYMMDD
    , TO_CHAR(REPORT_DATE, 'YYYYMMDD')::INTEGER AS REPORT_DATE__YYYYMMDD
    , CUSTOMER_RETURNS::INTEGER AS CUSTOMER_RETURNS
    , ORDERED_REVENUE_AMT
    , SHIPPED_COGS_AMT
    , SHIPPED_REVENUE
    , ORDERED_UNITS::INTEGER AS ORDERED_UNITS
    , SHIPPED_UNITS::INTEGER AS SHIPPED_UNITS
    , ITEM_HK
    , ITEM_BK
    , STORE_HK
    , STORE_BK
    , CASE 
        WHEN BKCC = 'Running_Horse' THEN DELETE_IND 
      END as IS_DELETED 
FROM JOIN_RESULT
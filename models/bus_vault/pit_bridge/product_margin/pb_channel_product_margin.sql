---- SRC LAYER ----
WITH
SRC_lnk as ( 
    SELECT 
         CHANNEL_PRODUCT_MARGIN_LHK
        ,ITEM_HK
        ,STORE_HK
        ,REC_SRC 
    FROM {{ ref('lnk_channel_product_margin') }} 
),
SRC_hub_item as ( 
    SELECT 
         ITEM_BK
        ,ITEM_HK 
    FROM {{ ref('hub_item_v1') }} 
),
SRC_hub_store as ( 
    SELECT 
         STORE_BK
        ,STORE_HK
        ,BKCC 
    FROM {{ ref('hub_store') }} 
),
SRC_sat_vc as ( 
    SELECT 
          CHANNEL_PRODUCT_MARGIN_LHK
        , ASIN
        , REPORT_END_DATE
        , NETPPM 
        , PSA_DELETE_IND
        , load_dts
    FROM {{ ref('lmsat_channel_product_margin__amazon_vc') }} 
    where report_end_date between '2023-01-01' and '2025-02-10' and vendorcentral_account = 'Moen Inc'
    qualify 1 = row_number() over(partition by CHANNEL_PRODUCT_MARGIN_LHK order by load_dts DESC) 
),
SRC_sat_anaheim as ( 
    SELECT 
          CHANNEL_PRODUCT_MARGIN_LHK
        , ASIN
        , END_DATE
        , NET_PURE_PRODUCT_MARGIN 
        , PSA_DELETE_IND
        , load_dts
    FROM {{ ref('lmsat_channel_product_margin__amazon_moen_anaheim') }} 
    where end_date >= '2025-02-11'
    qualify 1 = row_number() over(partition by CHANNEL_PRODUCT_MARGIN_LHK order by load_dts DESC) 
),
SRC_sat_inc as ( 
    SELECT 
         CHANNEL_PRODUCT_MARGIN_LHK
        , ASIN
        , END_DATE
        , NET_PURE_PRODUCT_MARGIN 
        , PSA_DELETE_IND
        , load_dts
    FROM {{ ref('lmsat_channel_product_margin__amazon_moen_inc') }} 
    where end_date >= '2025-02-11'
    qualify 1 = row_number() over(partition by CHANNEL_PRODUCT_MARGIN_LHK order by load_dts DESC) 
)

---- LOGIC LAYER ----

, LOGIC_lnk as (
    SELECT
         CHANNEL_PRODUCT_MARGIN_LHK
        ,ITEM_HK
        ,STORE_HK
        ,REC_SRC
        ,'PB_channel_product_MARGIN' as PB_REC_SRC
        ,CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP()) as PB_LOAD_DTS
    FROM SRC_lnk
)

, LOGIC_hub_item as (
    SELECT 
         ITEM_HK as hub_ITEM_HK
        ,ITEM_BK 
    FROM SRC_hub_item
)

, LOGIC_hub_store as (
    SELECT 
         STORE_HK as hub_STORE_HK
        ,STORE_BK
        ,BKCC 
    FROM SRC_hub_store
)

, LOGIC_sat_vc as (
    SELECT
         CHANNEL_PRODUCT_MARGIN_LHK as LNK_HK
        ,ASIN
        ,NETPPM as NET_PURE_PRODUCT_MARGIN
        ,report_end_date as REPORT_DATE
        ,PSA_DELETE_IND as DELETE_IND
    FROM SRC_sat_vc
)

, LOGIC_sat_anaheim as (
    SELECT
         CHANNEL_PRODUCT_MARGIN_LHK as LNK_HK
        ,ASIN
        ,NET_PURE_PRODUCT_MARGIN
        ,end_date as REPORT_DATE
        ,PSA_DELETE_IND as DELETE_IND
    FROM SRC_sat_anaheim
)

, LOGIC_sat_inc as (
    SELECT
         CHANNEL_PRODUCT_MARGIN_LHK as LNK_HK
        ,ASIN
        ,NET_PURE_PRODUCT_MARGIN
        ,end_date as REPORT_DATE
        ,PSA_DELETE_IND as DELETE_IND
    FROM SRC_sat_inc
)

---- RENAME LAYER ----

, RENAME_lnk as ( 
    SELECT 
         CHANNEL_PRODUCT_MARGIN_LHK
        ,ITEM_HK
        ,STORE_HK
        ,REC_SRC
        ,PB_REC_SRC
        ,PB_LOAD_DTS 
    FROM LOGIC_lnk 
)

, RENAME_hub_item as ( 
    SELECT 
         hub_ITEM_HK
        ,ITEM_BK 
    FROM LOGIC_hub_item 
)

, RENAME_hub_store as ( 
    SELECT 
         hub_STORE_HK
        ,STORE_BK
        ,BKCC 
    FROM LOGIC_hub_store 
)

, RENAME_sat_vc as ( 
    SELECT 
         LNK_HK
        ,ASIN
        ,NET_PURE_PRODUCT_MARGIN
        ,REPORT_DATE
        ,DELETE_IND 
    FROM LOGIC_sat_vc 
)

, RENAME_sat_anaheim as ( 
    SELECT 
         LNK_HK
        ,ASIN
        ,NET_PURE_PRODUCT_MARGIN
        ,REPORT_DATE
        ,DELETE_IND 
    FROM LOGIC_sat_anaheim 
)

, RENAME_sat_inc as ( 
    SELECT 
         LNK_HK
        ,ASIN
        ,NET_PURE_PRODUCT_MARGIN
        ,REPORT_DATE
        ,DELETE_IND  
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
         l.CHANNEL_PRODUCT_MARGIN_LHK
        ,l.ITEM_HK
        ,l.STORE_HK
        ,l.REC_SRC
        ,l.PB_REC_SRC
        ,l.PB_LOAD_DTS
        ,hi.ITEM_BK
        ,hs.STORE_BK
        ,hs.BKCC
        ,sat.ASIN
        ,sat.REPORT_DATE
        ,sat.NET_PURE_PRODUCT_MARGIN
        ,sat.DELETE_IND
    FROM FILTER_lnk l
    LEFT JOIN FILTER_hub_item hi  ON l.ITEM_HK = hi.hub_ITEM_HK
    LEFT JOIN FILTER_hub_store hs ON l.STORE_HK = hs.hub_STORE_HK
    LEFT JOIN UNIFIED_sat sat      ON l.CHANNEL_PRODUCT_MARGIN_LHK = sat.LNK_HK
)

---- FINAL LAYER ----

SELECT
      row_number() over(order by 1) as SEQ_ID
    , CURRENT_DATE as SNAPSHOTDATE
    , CHANNEL_PRODUCT_MARGIN_LHK
    , PB_REC_SRC
    , BKCC
    , REC_SRC
    , PB_LOAD_DTS
    , ASIN
    , TO_CHAR(REPORT_DATE, 'YYYYMMDD')::INTEGER AS report_end_date__YYYYMMDD
    , NET_PURE_PRODUCT_MARGIN
    , ITEM_HK
    , ITEM_BK
    , STORE_HK
    , STORE_BK
    , CASE 
        WHEN BKCC = 'Running_Horse' THEN DELETE_IND 
      END as IS_DELETED 
FROM JOIN_RESULT
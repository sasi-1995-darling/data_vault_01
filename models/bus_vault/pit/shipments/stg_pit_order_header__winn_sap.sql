{{
    config(
        materialized='ephemeral'
    )
}}
---- SRC LAYER ----
WITH
SRC_HUB            as ( SELECT 
                            ORDER_HEADER_HK
                          , ORDER_HEADER_BK
                          , REC_SRC
                          , BKCC 
                        FROM {{ ref('hub_order_header') }} ),

SRC_SAT_OH         as ( SELECT 
                            ORDER_HEADER_HK
                          , AEDAT
                          , AUART
                          , AUDAT
                          , AUGRU
                          , BSARK
                          , BSTDK
                          , BSTNK
                          , ERDAT
                          , ERNAM
                          , FMBDAT
                          , KNUMV
                          , KUNNR
                          , KVGR1
                          , KVGR2
                          , KVGR3
                          , KVGR4
                          , KVGR5
                          , NETWR
                          , PSA_DELETE_IND
                          , QMNUM
                          , SPART
                          , VBELN
                          , VBTYP
                          , VDATU
                          , VKORG
                          , VSBED
                          , VTWEG
                          , WAERK
                          , ZZORC
                          , ZZRSD
                        FROM {{ ref('sat_order_header__winn_sap') }}
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_HUB            as ( SELECT * FROM RAW_VAULT.HUB_ORDER_HEADER ),
SRC_SAT_OH         as ( SELECT * FROM RAW_VAULT.SAT_ORDER_HEADER__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_HUB as (
    SELECT
        ORDER_HEADER_HK                                                
      , ORDER_HEADER_BK                                                
      , REC_SRC
      , BKCC                             
    FROM SRC_HUB
)

, LOGIC_SAT_OH as (
    SELECT
        ORDER_HEADER_HK
      , VTWEG
      , VKORG
      , BSARK
      , COALESCE(TO_VARCHAR(TRY_TO_DATE(ERDAT, 'YYYYMMDD'), 'YYYYMMDD'), '')                                   as ERDAT
      , VBELN
      , AUART
      , VBTYP
      , KUNNR
      , SPART
      , WAERK
      , PSA_DELETE_IND
      , ERNAM
      , COALESCE(TO_VARCHAR(TRY_TO_DATE(NULLIF(NULLIF(AUDAT, ''), '00000000'), 'YYYYMMDD'), 'YYYYMMDD'), '')   as AUDAT
      , AUGRU
      , NETWR
      , KNUMV
      , COALESCE(TO_VARCHAR(TRY_TO_DATE(NULLIF(NULLIF(VDATU, ''), '00000000'), 'YYYYMMDD'), 'YYYYMMDD'), '')   as VDATU
      , COALESCE(TO_VARCHAR(TRY_TO_DATE(NULLIF(NULLIF(AEDAT, ''), '00000000'), 'YYYYMMDD'), 'YYYYMMDD'), '')   as AEDAT
      , KVGR1
      , KVGR2
      , KVGR3
      , COALESCE(TO_VARCHAR(TRY_TO_DATE(NULLIF(NULLIF(ZZRSD, ''), '00000000'), 'YYYYMMDD'), 'YYYYMMDD'), '')   as ZZRSD
      , ZZORC
      , VSBED
      , BSTNK
      , COALESCE(TO_VARCHAR(TRY_TO_DATE(NULLIF(NULLIF(BSTDK, ''), '00000000'), 'YYYYMMDD'), 'YYYYMMDD'), '')   as BSTDK
      , KVGR4
      , KVGR5
      , QMNUM
      , COALESCE(TO_VARCHAR(TRY_TO_DATE(NULLIF(NULLIF(FMBDAT, ''), '00000000'), 'YYYYMMDD'), 'YYYYMMDD'), '')  as FMBDAT
    FROM SRC_SAT_OH
)

---- RENAME LAYER ----

, RENAME_HUB as (
    SELECT
        ORDER_HEADER_HK                                              as SALES_ORDER_HEADER_HK
      , ORDER_HEADER_BK                                              as SALES_ORDER_HEADER_BK
      , REC_SRC           
      , BKCC                                                   
    FROM LOGIC_HUB
)

, RENAME_SAT_OH as (
    SELECT
        ORDER_HEADER_HK
      , KUNNR                                                        as CUSTOMER_BK
      , VBELN                                                        as SALES_ORDER_NUMBER
      , AUART                                                        as SALES_ORDER_DOCUMENT_TYPE
      , VBTYP                                                        as SALES_ORDER_DOCUMENT_CATEGORY
      , ERDAT                                                        as SALES_ORDER_CREATION_DATE_KEY
      , WAERK                                                        as SALES_ORDER_CURRENCY
      , BSARK                                                        as CUSTOMER_PURCHASE_ORDER_TYPE
      , PSA_DELETE_IND                                               as IS_DELETED
      , SPART                                                        as DIVISION
      , VTWEG                                                        as DISTRIBUTION_CHANNEL
      , VKORG                                                        as SALES_ORGANIZATION
      , ERNAM                                                        as CREATED_BY
      , AUDAT                                                        as DOCUMENT_DATE_KEY
      , AUGRU                                                        as SALES_DOCUMENT_REASON
      , NETWR                                                        as NET_VALUE
      , KNUMV                                                        as DOCUMENT_CONDITION_RECORD
      , VDATU                                                        as REQUESTED_DELIVERY_DATE__YYYYMMDD
      , AEDAT                                                        as LAST_CHANGE_DATE__YYYYMMDD
      , KVGR1                                                        as KEY_ACCOUNT
      , KVGR2                                                        as GROUP_KEY_ACCOUNT
      , KVGR3                                                        as BUYING_GROUP
      , ZZRSD                                                        as REQUESTED_SHIP_DATE__YYYYMMDD
      , ZZORC                                                        as ORDER_CATEGORY
      , VSBED                                                        as SHIPPING_CONDITION
      , BSTNK                                                        as CUSTOMER_PO_NUMBER
      , BSTDK                                                        as CUSTOMER_PO_DATE__YYYYMMDD
      , KVGR4                                                        as CUSTOMER_LEAD_DAYS
      , KVGR5                                                        as CUSTOMER_SHIP_EARLY_FLAG
      , QMNUM                                                        as NOTIFICATION_NUMBER
      , FMBDAT                                                       as MATERIAL_AVAILABILITY_DATE__YYYYMMDD
    FROM LOGIC_SAT_OH
)

---- FILTER LAYER ----

, FILTER_HUB as (
    SELECT *
    FROM RENAME_HUB
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'
)

, FILTER_SAT_OH as (
    SELECT *
    FROM RENAME_SAT_OH
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT 
        FILTER_HUB.SALES_ORDER_HEADER_HK
      , FILTER_HUB.SALES_ORDER_HEADER_BK
      , FILTER_HUB.REC_SRC
      , FILTER_HUB.BKCC
      , FILTER_SAT_OH.CUSTOMER_BK
      , FILTER_SAT_OH.SALES_ORDER_NUMBER
      , FILTER_SAT_OH.SALES_ORDER_DOCUMENT_TYPE
      , FILTER_SAT_OH.SALES_ORDER_DOCUMENT_CATEGORY
      , FILTER_SAT_OH.SALES_ORDER_CREATION_DATE_KEY
      , FILTER_SAT_OH.SALES_ORDER_CURRENCY
      , FILTER_SAT_OH.CUSTOMER_PURCHASE_ORDER_TYPE
      , FILTER_SAT_OH.IS_DELETED
      , FILTER_SAT_OH.DIVISION
      , FILTER_SAT_OH.DISTRIBUTION_CHANNEL
      , FILTER_SAT_OH.SALES_ORGANIZATION
      , FILTER_SAT_OH.CREATED_BY
      , FILTER_SAT_OH.DOCUMENT_DATE_KEY
      , FILTER_SAT_OH.SALES_DOCUMENT_REASON
      , FILTER_SAT_OH.NET_VALUE
      , FILTER_SAT_OH.DOCUMENT_CONDITION_RECORD
      , FILTER_SAT_OH.REQUESTED_DELIVERY_DATE__YYYYMMDD
      , FILTER_SAT_OH.LAST_CHANGE_DATE__YYYYMMDD
      , FILTER_SAT_OH.KEY_ACCOUNT
      , FILTER_SAT_OH.GROUP_KEY_ACCOUNT
      , FILTER_SAT_OH.BUYING_GROUP
      , FILTER_SAT_OH.REQUESTED_SHIP_DATE__YYYYMMDD
      , FILTER_SAT_OH.ORDER_CATEGORY
      , FILTER_SAT_OH.SHIPPING_CONDITION
      , FILTER_SAT_OH.CUSTOMER_PO_NUMBER
      , FILTER_SAT_OH.CUSTOMER_PO_DATE__YYYYMMDD
      , FILTER_SAT_OH.CUSTOMER_LEAD_DAYS
      , FILTER_SAT_OH.CUSTOMER_SHIP_EARLY_FLAG
      , FILTER_SAT_OH.NOTIFICATION_NUMBER
      , FILTER_SAT_OH.MATERIAL_AVAILABILITY_DATE__YYYYMMDD
    FROM FILTER_HUB
    INNER JOIN FILTER_SAT_OH
        ON FILTER_HUB.SALES_ORDER_HEADER_HK = FILTER_SAT_OH.ORDER_HEADER_HK
)

---- FINAL LAYER ----
SELECT
        'MOEN'                                                       as SOURCE
      , SALES_ORDER_HEADER_HK
      , SALES_ORDER_HEADER_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_DOCUMENT_TYPE
      , SALES_ORDER_DOCUMENT_CATEGORY
      , CUSTOMER_BK
      , (NULLIF(SALES_ORDER_CREATION_DATE_KEY, ''))::INTEGER         as SALES_ORDER_CREATION_DATE_KEY
      , DIVISION
      , DISTRIBUTION_CHANNEL
      , SALES_ORGANIZATION
      , SALES_ORDER_CURRENCY
      , CUSTOMER_PURCHASE_ORDER_TYPE
      , CREATED_BY
      , (NULLIF(DOCUMENT_DATE_KEY, ''))::INTEGER                     as DOCUMENT_DATE_KEY
      , SALES_DOCUMENT_REASON
      , NET_VALUE
      , DOCUMENT_CONDITION_RECORD
      , (NULLIF(REQUESTED_DELIVERY_DATE__YYYYMMDD, ''))::INTEGER     as REQUESTED_DELIVERY_DATE__YYYYMMDD
      , (NULLIF(LAST_CHANGE_DATE__YYYYMMDD, ''))::INTEGER            as LAST_CHANGE_DATE__YYYYMMDD
      , KEY_ACCOUNT
      , GROUP_KEY_ACCOUNT
      , BUYING_GROUP
      , (NULLIF(REQUESTED_SHIP_DATE__YYYYMMDD, ''))::INTEGER         as REQUESTED_SHIP_DATE__YYYYMMDD
      , ORDER_CATEGORY
      , SHIPPING_CONDITION
      , CUSTOMER_PO_NUMBER
      , (NULLIF(CUSTOMER_PO_DATE__YYYYMMDD, ''))::INTEGER            as CUSTOMER_PO_DATE__YYYYMMDD
      , CUSTOMER_LEAD_DAYS
      , CUSTOMER_SHIP_EARLY_FLAG
      , NOTIFICATION_NUMBER
      , (NULLIF(MATERIAL_AVAILABILITY_DATE__YYYYMMDD, ''))::INTEGER  as MATERIAL_AVAILABILITY_DATE__YYYYMMDD
      , REC_SRC
      , BKCC
      , IS_DELETED
FROM JOIN_RESULT
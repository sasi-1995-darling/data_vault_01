{{
    config(
        materialized='ephemeral'
    )
}}
---- SRC LAYER ----
WITH
SRC_HUB            as ( SELECT ORDER_LINE_HK, ORDER_LINE_BK, REC_SRC, BKCC FROM {{ ref('hub_order_line') }} as SRC
                        WHERE BKCC = 'Hiding_Tiger' AND REC_SRC = 'USOHNO.SAP.ECCPRD.Z_VBAP'),
SRC_SAT_OL         as ( SELECT ORDER_LINE_HK, MSR_RET_REASON, VBELN, POSNR, PARVW, KUNNR, ERDAT, FIXMG, MATNR, ARKTX, SHKZG, ZMENG, NETPR, NETWR, WERKS, PSTYV, ABGRU, KWMENG, LSMENG, KBMENG, LPRIO, LFMNG, AEDAT, BEDAE, GSBER, ANTLF, KONDM, KDMAT, KNUMA_AG, ZZLPSBSRC, ZZLPSFRID, PSA_DELETE_IND
                        FROM {{ ref('sat_order_line__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY ORDER_LINE_HK ORDER BY LOAD_DTS DESC) ),
SRC_SAT_OLS        as ( SELECT ORDER_LINE_HK, VBELN, POSNR, PSA_DELETE_IND  FROM {{ ref('sat_order_line_status__winn_sap') }} as SRC
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY ORDER_LINE_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_HUB            as ( SELECT * FROM RAW_VAULT.LNK_SALES_ORDER_ITEM ),
SRC_SAT_OL         as ( SELECT * FROM RAW_VAULT.SAT_ORDER_LINE__WINN_SAP ),
SRC_SAT_OLS        as ( SELECT * FROM RAW_VAULT.SAT_ORDER_LINE_STATUS__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_HUB as (
    SELECT
        ORDER_LINE_HK                                                
      , ORDER_LINE_BK                                                
      , REC_SRC
      , BKCC                             
    FROM SRC_HUB
)

, LOGIC_SAT_OL as (
    SELECT
        ORDER_LINE_HK
      , MSR_RET_REASON                                               
      , VBELN
      , POSNR
      , PARVW
      , KUNNR
      , CAST(ERDAT AS INTEGER)                                       as ERDAT
      , FIXMG                                    
      , MATNR
      , ARKTX
      , SHKZG
      , ZMENG
      , NETPR
      , NETWR
      , WERKS
      , PSTYV
      , ABGRU
      , KWMENG
      , LSMENG
      , KBMENG
      , LPRIO
      , LFMNG
      , CAST(AEDAT AS INTEGER)                                       as AEDAT                    
      , BEDAE
      , GSBER
      , ANTLF
      , KONDM
      , KDMAT
      , KNUMA_AG
      , ZZLPSBSRC
      , ZZLPSFRID
      , PSA_DELETE_IND                                                                                     
    FROM SRC_SAT_OL
)

,  LOGIC_SAT_OLS as (
    SELECT   
        ORDER_LINE_HK                                         
      , VBELN
      , POSNR
      , PSA_DELETE_IND                                           
    FROM SRC_SAT_OLS
)
---- RENAME LAYER ----

, RENAME_HUB as (
    SELECT
        ORDER_LINE_HK                                                as SALES_ORDER_LINE_HK
      , ORDER_LINE_BK                                                as SALES_ORDER_LINE_BK
      , REC_SRC           
      , BKCC                                                   
    FROM LOGIC_HUB
)

, RENAME_SAT_OL as (
    SELECT
        ORDER_LINE_HK
      , MSR_RET_REASON                                    as RETURN_REASON_CODE
      , VBELN                                             as SALES_ORDER_NUMBER
      , POSNR                                             as SALES_ORDER_LINE_NUMBER
      , PARVW                                             as PARTNER_FUNCTION
      , KUNNR                                             as CUSTOMER_BK
      , ERDAT                                             as CREATION_DATE__YYYYMMDD
      , FIXMG                                             as SALES_ORDER_DELIVERY_IND
      , MATNR                                             as ITEM_BK
      , ARKTX                                             as SALES_ORDER_ITEM_DESC
      , SHKZG                                             as SALES_ORDER_LINE_RETURN_IND
      , ZMENG                                             as QUANTITY
      , NETPR                                             as NET_PRICE
      , NETWR                                             as NET_VALUE
      , WERKS                                             as PLANT
      , PSTYV                                             as SALES_ORDER_ITEM_CATEGORY
      , ABGRU                                             as REJECTION_REASON
      , KWMENG                                            as CUMULATIVE_ORDER_QUANTITY
      , LSMENG                                            as CUMULATIVE_REQUIRED_QUANTITY
      , KBMENG                                            as CUMULATIVE_CONFIRMED_QUANTITY
      , LPRIO                                             as DELIVERY_PRIORITY
      , LFMNG                                             as MINIMUM_DELIVERY_QUANTITY
      , AEDAT                                             as LAST_CHANGE_DATE_LINE__YYYYMMDD                   
      , BEDAE                                             as REQUIREMENTS_TYPE
      , GSBER                                             as BUSINESS_AREA
      , ANTLF                                             as MAX_NUMBER_OF_PARTIAL_DELIVERIES
      , KONDM                                             as PRICING_GROUP
      , KDMAT                                             as CUSTOMER_MATERIAL_NUMBER
      , KNUMA_AG                                          as SALES_DEAL
      , ZZLPSBSRC                                         as SUBSCRIPTION_SOURCE
      , ZZLPSFRID                                         as SUBSCRIPTION_ID
      , PSA_DELETE_IND                                    as OL_PSA_DELETE_IND
    FROM LOGIC_SAT_OL
)

, RENAME_SAT_OLS as (
    SELECT     
        ORDER_LINE_HK
      , VBELN                                                        as OLS_VBELN
      , POSNR                                                        as OLS_POSNR
      , PSA_DELETE_IND                                               as OLS_PSA_DELETE_IND
    FROM LOGIC_SAT_OLS
)
---- FILTER LAYER ----

, FILTER_HUB as (
    SELECT *
    FROM RENAME_HUB
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'       /*This filter is to exclude the ghost records*/
)

, FILTER_SAT_OL as (
    SELECT *
    FROM RENAME_SAT_OL
)

, FILTER_SAT_OLS as (
    SELECT *
    FROM RENAME_SAT_OLS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HUB
    INNER JOIN FILTER_SAT_OL
        ON FILTER_HUB.SALES_ORDER_LINE_HK = FILTER_SAT_OL.ORDER_LINE_HK
    LEFT JOIN FILTER_SAT_OLS
        ON FILTER_HUB.SALES_ORDER_LINE_HK = FILTER_SAT_OLS.ORDER_LINE_HK
)

---- FINAL LAYER ----
SELECT
        'MOEN'                                                                     as SOURCE
      , SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_LINE_NUMBER
      , PARTNER_FUNCTION
      , CREATION_DATE__YYYYMMDD                                                    as SALES_ORDER_CREATION_DATE_KEY
      , SALES_ORDER_DELIVERY_IND
      , CUSTOMER_BK
      , ITEM_BK
      , SALES_ORDER_ITEM_DESC
      , NULL                                                                       as SALES_ORDER_DOCUMENT_TYPE  
      , CASE WHEN SALES_ORDER_LINE_RETURN_IND = 'X' THEN 'Y' ELSE 'N' END          as SALES_ORDER_LINE_RETURN_IND
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
      , CASE BKCC WHEN 'Hiding_Tiger' THEN COALESCE(OL_PSA_DELETE_IND, '')
        END                                                                        as IS_DELETED                
FROM JOIN_RESULT
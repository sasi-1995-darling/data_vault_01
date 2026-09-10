{{
    config(
        materialized='ephemeral'
    )
}}
---- SRC LAYER ----
WITH
SRC_HUB            as ( SELECT ORDER_LINE_HK, ORDER_LINE_BK, REC_SRC, BKCC FROM {{ ref('hub_order_line') }} as SRC),
SRC_SAT_OLA        as ( SELECT SALES_DOCUMENT_TYPE_CODE, HEADER_ID, ORDER_LINE_HK, LINE_ID, ORDERED_QUANTITY, ORDERED_ITEM_ID, CUSTOMER_ITEM_NET_PRICE, CREATION_DATE, SOLD_TO_ORG_ID, RETURN_REASON_CODE, PSA_DELETE_IND
                        FROM {{ ref('sat_order_lines_all__ml_ebs') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY ORDER_LINE_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_HUB            as ( SELECT * FROM RAW_VAULT.LNK_SALES_ORDER_ITEM ),
SRC_SAT_OLA        as ( SELECT * FROM RAW_VAULT.SAT_ORDER_LINES_ALL__ML_EBS )
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

, LOGIC_SAT_OLA as (
    SELECT
        CAST(SALES_DOCUMENT_TYPE_CODE AS VARCHAR)                    as SALES_DOCUMENT_TYPE_CODE
      , CAST(HEADER_ID AS VARCHAR)                                   as SALES_ORDER_NUMBER  
      , ORDER_LINE_HK
      , CAST(LINE_ID AS VARCHAR)                                     as LINE_ID 
      , ORDERED_QUANTITY 
      , CAST(ORDERED_ITEM_ID AS VARCHAR)                             as ORDERED_ITEM_ID
      , CUSTOMER_ITEM_NET_PRICE
      , CAST(TO_CHAR(CREATION_DATE, 'YYYYMMDD') AS INTEGER)          as CREATION_DATE
      , CAST(SOLD_TO_ORG_ID AS VARCHAR)                              as SOLD_TO_ORG_ID 
      , RETURN_REASON_CODE
      , PSA_DELETE_IND
    FROM SRC_SAT_OLA
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

, RENAME_SAT_OLA as (
    SELECT
        SALES_DOCUMENT_TYPE_CODE                                     as SALES_ORDER_DOCUMENT_TYPE
      , SALES_ORDER_NUMBER  
      , ORDER_LINE_HK
      , LINE_ID                                                      as SALES_ORDER_LINE_NUMBER 
      , ORDERED_QUANTITY                                             as QUANTITY                             
      , ORDERED_ITEM_ID                                              as ITEM_BK
      , CUSTOMER_ITEM_NET_PRICE                                      as NET_PRICE
      , CREATION_DATE                                                as SALES_ORDER_CREATION_DATE_KEY                                         
      , SOLD_TO_ORG_ID                                               as CUSTOMER_BK
      , RETURN_REASON_CODE 
      , PSA_DELETE_IND                              
    FROM LOGIC_SAT_OLA
)
---- FILTER LAYER ----

, FILTER_HUB as (
    SELECT *
    FROM RENAME_HUB
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'       /*This filter is to exclude the ghost records*/
)

, FILTER_SAT_OLA as (
    SELECT *
    FROM RENAME_SAT_OLA
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HUB
    INNER JOIN FILTER_SAT_OLA
        ON FILTER_HUB.SALES_ORDER_LINE_HK = FILTER_SAT_OLA.ORDER_LINE_HK
)

---- FINAL LAYER ----
SELECT
        'MASTER LOCK'                                                as SOURCE
      , SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_LINE_NUMBER
      , NULL                                                         as PARTNER_FUNCTION
      , SALES_ORDER_CREATION_DATE_KEY
      , NULL                                                         as SALES_ORDER_DELIVERY_IND
      , CUSTOMER_BK
      , ITEM_BK
      , NULL                                                         as SALES_ORDER_ITEM_DESC
      , SALES_ORDER_DOCUMENT_TYPE  
      , NULL                                                         as SALES_ORDER_LINE_RETURN_IND
      , QUANTITY
      , NET_PRICE
      , NULL                                                         as NET_VALUE
      , RETURN_REASON_CODE 
      , NULL                                                         as PLANT
      , NULL                                                         as SALES_ORDER_ITEM_CATEGORY
      , NULL                                                         as REJECTION_REASON
      , NULL                                                         as CUMULATIVE_ORDER_QUANTITY
      , NULL                                                         as CUMULATIVE_REQUIRED_QUANTITY
      , NULL                                                         as CUMULATIVE_CONFIRMED_QUANTITY
      , NULL                                                         as DELIVERY_PRIORITY
      , NULL                                                         as MINIMUM_DELIVERY_QUANTITY
      , NULL                                                         as LAST_CHANGE_DATE_LINE__YYYYMMDD
      , NULL                                                         as REQUIREMENTS_TYPE
      , NULL                                                         as BUSINESS_AREA
      , NULL                                                         as MAX_NUMBER_OF_PARTIAL_DELIVERIES
      , NULL                                                         as PRICING_GROUP
      , NULL                                                         as CUSTOMER_MATERIAL_NUMBER
      , NULL                                                         as SALES_DEAL
      , REC_SRC
      , BKCC     
      , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND
        END                                                          as IS_DELETED                     
FROM JOIN_RESULT
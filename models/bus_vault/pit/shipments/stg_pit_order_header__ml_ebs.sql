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
                          , CONVERSION_TYPE_CODE
                          , CREATION_DATE
                          , ORDER_NUMBER
                          , ORG_ID
                          , SALES_DOCUMENT_TYPE_CODE
                          , _FIVETRAN_DELETED
                        FROM {{ ref('sat_order_header__ml_ebs') }}
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY ORDER_HEADER_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_HUB            as ( SELECT * FROM RAW_VAULT.HUB_ORDER_HEADER ),
SRC_SAT_OH         as ( SELECT * FROM RAW_VAULT.SAT_ORDER_HEADER__ML_EBS )
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
      , ORG_ID::TEXT                                                 as ORG_ID
      , SALES_DOCUMENT_TYPE_CODE::TEXT                               as SALES_DOCUMENT_TYPE_CODE
      , COALESCE(TO_VARCHAR(DATE(CREATION_DATE), 'YYYYMMDD'), '')    as CREATION_DATE
      , ORDER_NUMBER::TEXT                                           as ORDER_NUMBER
      , CONVERSION_TYPE_CODE::TEXT                                   as CONVERSION_TYPE_CODE
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as _FIVETRAN_DELETED
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
      , ORG_ID                                                       as CUSTOMER_BK
      , ORDER_NUMBER                                                 as SALES_ORDER_NUMBER
      , SALES_DOCUMENT_TYPE_CODE                                     as SALES_ORDER_DOCUMENT_TYPE
      , CREATION_DATE                                                as SALES_ORDER_CREATION_DATE_KEY
      , CONVERSION_TYPE_CODE                                         as SALES_ORDER_CURRENCY
      , _FIVETRAN_DELETED                                            as IS_DELETED
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
      , FILTER_SAT_OH.SALES_ORDER_CREATION_DATE_KEY
      , FILTER_SAT_OH.SALES_ORDER_CURRENCY
      , FILTER_SAT_OH.IS_DELETED
    FROM FILTER_HUB
    INNER JOIN FILTER_SAT_OH
        ON FILTER_HUB.SALES_ORDER_HEADER_HK = FILTER_SAT_OH.ORDER_HEADER_HK
)

---- FINAL LAYER ----
SELECT
        'MASTER LOCK'                                                as SOURCE
      , SALES_ORDER_HEADER_HK
      , SALES_ORDER_HEADER_BK
      , SALES_ORDER_NUMBER
      , SALES_ORDER_DOCUMENT_TYPE
      , NULL                                                         as SALES_ORDER_DOCUMENT_CATEGORY
      , CUSTOMER_BK
      , (NULLIF(SALES_ORDER_CREATION_DATE_KEY, ''))::INTEGER         as SALES_ORDER_CREATION_DATE_KEY
      , NULL                                                         as DIVISION
      , NULL                                                         as DISTRIBUTION_CHANNEL
      , NULL                                                         as SALES_ORGANIZATION
      , SALES_ORDER_CURRENCY
      , NULL                                                         as CUSTOMER_PURCHASE_ORDER_TYPE
      , NULL                                                         as CREATED_BY
      , NULL                                                         as DOCUMENT_DATE_KEY
      , NULL                                                         as SALES_DOCUMENT_REASON
      , NULL                                                         as NET_VALUE
      , NULL                                                         as DOCUMENT_CONDITION_RECORD
      , NULL                                                         as REQUESTED_DELIVERY_DATE__YYYYMMDD
      , NULL                                                         as LAST_CHANGE_DATE__YYYYMMDD
      , NULL                                                         as KEY_ACCOUNT
      , NULL                                                         as GROUP_KEY_ACCOUNT
      , NULL                                                         as BUYING_GROUP
      , NULL                                                         as REQUESTED_SHIP_DATE__YYYYMMDD
      , NULL                                                         as ORDER_CATEGORY
      , NULL                                                         as SHIPPING_CONDITION
      , NULL                                                         as CUSTOMER_PO_NUMBER
      , NULL                                                         as CUSTOMER_PO_DATE__YYYYMMDD
      , NULL                                                         as CUSTOMER_LEAD_DAYS
      , NULL                                                         as CUSTOMER_SHIP_EARLY_FLAG
      , NULL                                                         as NOTIFICATION_NUMBER
      , NULL                                                         as MATERIAL_AVAILABILITY_DATE__YYYYMMDD
      , REC_SRC
      , BKCC
      , IS_DELETED
FROM JOIN_RESULT
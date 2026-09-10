---- SRC LAYER ----
WITH
SRC_COPA           as ( SELECT LNK_COPA_SALES_HK, FISCAL_MONTH__YYYYMM, PRODUCT_NUMBER, SENDER_COST_CENTER, COST_ELEMENT, SALES_ORGANIZATION, COMPANY_CODE, DISTRIBUTION_CHANNEL, VVQTY, VVCST, ORDER_REASON, FISCAL_YEAR__YYYY, ITEM_CATEGORY, SALES_DOCUMENT_TYPE, CUSTOMER, REC_SRC, BKCC
                        FROM {{ ref('pb_copa') }} as SRC  
                        WHERE ORDER_REASON IN ('500', '502', '505')
                        AND DEAL_TYPE = 'NCH'
                        AND COMPANY_CODE IN ('MCAN', 'MINC', 'MMEX') ),
SRC_TVAUT          as ( SELECT AUGRU, BEZEI FROM {{ ref('ref_sat_order_reason__winn_sap') }} as SRC 
                        WHERE SPRAS = 'E' ),        
SRC_MAKT           as ( SELECT ITEM_ID, MATERIAL_DESC FROM {{ ref('ref_item_description__moen_sap') }} as SRC
                        WHERE language = 'E'
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ITEM_ID ORDER BY MATERIAL_DESC) ),
SRC_MARA           as ( SELECT ITEM_ID, BASE_MATERIAL FROM {{ ref('ref_item_master__moen_sap') }} as SRC
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ITEM_ID ORDER BY BASE_MATERIAL) ),
SRC_GL_MAP         as ( SELECT SAKN1, SAKN2, VKORG, VTWEG, ZZPSTYV, ZZAUGRU, ZZAUART, ZZKUNAG, MATNR 
                        FROM {{ ref('ref_sap_order_account_mapping') }} as SRC
                        WHERE (SAKN1 <> 'Other' OR SAKN2 <> 'Other')
                        AND (CASE
                                WHEN TRIM(COALESCE(SAKN1, SAKN2)) REGEXP '^[0-9]+$'
                                THEN CAST(TRIM(COALESCE(SAKN1, SAKN2)) AS INTEGER) > 56000
                                ELSE FALSE 
                            END) ),
SRC_SKAT           as ( SELECT GL_ACCOUNT_NUMBER, GL_ACCOUNT_LONG_TEXT FROM {{ ref('ref_gl_account_texts__winn_sap') }} as SRC
                        WHERE LANGUAGE_KEY = 'E' AND CHART_OF_ACCOUNTS = 'MCHT')

/*
SRC_COPA           as ( SELECT * FROM BUS_VAULT.PB_COPA ),
SRC_TVAUT          as ( SELECT * FROM BUS_VAULT.REF_SAT_ORDER_REASON__WINN_SAP ),
SRC_MAKT           as ( SELECT * FROM BUS_VAULT.REF_ITEM_DESCRIPTION__MOEN_SAP ),
SRC_MARA           as ( SELECT * FROM BUS_VAULT.REF_ITEM_MASTER__MOEN_SAP ),
SRC_GL_MAP         as ( SELECT * FROM BUS_VAULT.REF_SAP_ORDER_ACCOUNT_MAPPING ),
SRC_SKAT           as ( SELECT * FROM BUS_VAULT.REF_GL_ACCOUNT_TEXTS__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_COPA as (
    SELECT
        LNK_COPA_SALES_HK
      , FISCAL_MONTH__YYYYMM
      , PRODUCT_NUMBER
      , SENDER_COST_CENTER
      , COST_ELEMENT
      , SALES_ORGANIZATION
      , COMPANY_CODE
      , DISTRIBUTION_CHANNEL
      , VVQTY
      , VVCST
      , ORDER_REASON
      , FISCAL_YEAR__YYYY
      , ITEM_CATEGORY
      , SALES_DOCUMENT_TYPE
      , CUSTOMER
      , REC_SRC
      , BKCC
    FROM SRC_COPA
)

, LOGIC_TVAUT as (
    SELECT
        AUGRU
      , BEZEI
    FROM SRC_TVAUT
)

, LOGIC_MAKT as (
    SELECT
        ITEM_ID
      , MATERIAL_DESC
    FROM SRC_MAKT
)

, LOGIC_MARA as (
    SELECT
        ITEM_ID
      , BASE_MATERIAL
    FROM SRC_MARA
)

, LOGIC_GL_MAP as (
    SELECT
        CASE
            WHEN SAKN1 <> '0000560000' AND SAKN1 <> '0000140255' AND SAKN1 IS NOT NULL THEN SAKN1
            WHEN SAKN2 <> '0000560000' AND SAKN2 <> '0000140255' AND SAKN2 IS NOT NULL THEN SAKN2
            ELSE NULL 
        END                                                          as                                   GL_ACCOUNT_VALUE
      , VKORG
      , VTWEG
      , ZZPSTYV
      , ZZAUGRU
      , ZZAUART
      , ZZKUNAG
      , MATNR
      , CONCAT_WS('|', VKORG, VTWEG, ZZPSTYV, ZZAUGRU, ZZAUART, ZZKUNAG, MATNR) as                                GL_KEY_1
      , CONCAT_WS('|', VKORG, VTWEG, ZZPSTYV, ZZAUGRU, ZZAUART, ZZKUNAG) as                                       GL_KEY_2
      , CONCAT_WS('|', VKORG, VTWEG, ZZPSTYV, ZZAUGRU, ZZAUART)      as                                           GL_KEY_3
    FROM SRC_GL_MAP
)

, LOGIC_SKAT as (
    SELECT
        GL_ACCOUNT_NUMBER
      , GL_ACCOUNT_LONG_TEXT
    FROM SRC_SKAT
)
---- RENAME LAYER ----

, RENAME_COPA as (
    SELECT
        LNK_COPA_SALES_HK
      , FISCAL_MONTH__YYYYMM
      , PRODUCT_NUMBER
      , SENDER_COST_CENTER
      , COST_ELEMENT
      , SALES_ORGANIZATION
      , COMPANY_CODE
      , DISTRIBUTION_CHANNEL                                          as                         DISTRIBUTION_CHANNEL_CODE
      , VVQTY                                                         as                                    SALES_QUANTITY
      , VVCST                                                         as                                     STANDARD_COST
      , ORDER_REASON
      , FISCAL_YEAR__YYYY
      , ITEM_CATEGORY
      , SALES_DOCUMENT_TYPE
      , CUSTOMER
      , REC_SRC
      , BKCC
    FROM LOGIC_COPA
)

, RENAME_TVAUT as (
    SELECT
        AUGRU                                                        as                                       ORDER_REASON      
      , BEZEI                                                        as                           ORDER_REASON_DESCRIPTION
    FROM LOGIC_TVAUT
)

, RENAME_MAKT as (
    SELECT
        ITEM_ID                                                      as                                    MATERIAL_NUMBER
      , MATERIAL_DESC                                                as                               MATERIAL_DESCRIPTION
    FROM LOGIC_MAKT
)

, RENAME_MARA as (
    SELECT
        ITEM_ID                                                      as                                    MATERIAL_NUMBER
      , BASE_MATERIAL                                                as                                  FORECAST_MATERIAL
    FROM LOGIC_MARA
)

, RENAME_GL_MAP as (
    SELECT
        GL_ACCOUNT_VALUE
      , VKORG
      , VTWEG
      , ZZPSTYV
      , ZZAUGRU
      , ZZAUART
      , ZZKUNAG
      , MATNR
      , GL_KEY_1
      , GL_KEY_2
      , GL_KEY_3
    FROM LOGIC_GL_MAP
)

, RENAME_SKAT as (
    SELECT
        GL_ACCOUNT_NUMBER
      , GL_ACCOUNT_LONG_TEXT
    FROM LOGIC_SKAT
)
---- FILTER LAYER ----

, FILTER_COPA as (
    SELECT *
    FROM RENAME_COPA
)

, FILTER_TVAUT as (
    SELECT *
    FROM RENAME_TVAUT
)

, FILTER_MAKT as (
    SELECT *
    FROM RENAME_MAKT
)

, FILTER_MARA as (
    SELECT *
    FROM RENAME_MARA
)

, FILTER_GL_MAP as (
    SELECT *
    FROM RENAME_GL_MAP
)

, FILTER_SKAT as (
    SELECT *
    FROM RENAME_SKAT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_COPA COPA
    LEFT JOIN FILTER_TVAUT TVAUT
        ON COPA.ORDER_REASON = TVAUT.ORDER_REASON
    LEFT JOIN FILTER_MAKT MAKT
        ON COPA.PRODUCT_NUMBER = MAKT.MATERIAL_NUMBER
    LEFT JOIN FILTER_MARA MARA 
        ON COPA.PRODUCT_NUMBER = MARA.MATERIAL_NUMBER
    LEFT JOIN FILTER_GL_MAP GL_MAP 
        ON CONCAT_WS('|',
            TRIM(COPA.SALES_ORGANIZATION),
            TRIM(COPA.DISTRIBUTION_CHANNEL_CODE),
            TRIM(COALESCE(COPA.ORDER_REASON, '')),
            TRIM(COALESCE(COPA.SALES_DOCUMENT_TYPE, '')),
            TRIM(COPA.CUSTOMER),
            TRIM(COPA.PRODUCT_NUMBER)
           ) = TRIM(GL_MAP.GL_KEY_1)
        OR CONCAT_WS('|',
            TRIM(COPA.SALES_ORGANIZATION),
            TRIM(COPA.DISTRIBUTION_CHANNEL_CODE),
            TRIM(COPA.ITEM_CATEGORY),
            TRIM(COALESCE(COPA.ORDER_REASON, '')),
            TRIM(COALESCE(COPA.SALES_DOCUMENT_TYPE, '')),
            TRIM(COPA.CUSTOMER)
           ) = TRIM(GL_MAP.GL_KEY_2)
        OR CONCAT_WS('|',
            TRIM(COPA.SALES_ORGANIZATION),
            TRIM(COPA.DISTRIBUTION_CHANNEL_CODE),
            TRIM(COPA.ITEM_CATEGORY),
            TRIM(COALESCE(COPA.ORDER_REASON, '')),
            TRIM(COALESCE(COPA.SALES_DOCUMENT_TYPE, ''))
           ) = TRIM(GL_MAP.GL_KEY_3)
    LEFT JOIN FILTER_SKAT SKAT 
        ON COALESCE(GL_MAP.GL_ACCOUNT_VALUE, 'ERROR') = SKAT.GL_ACCOUNT_NUMBER
)

---- FINAL LAYER ----
SELECT
        LNK_COPA_SALES_HK
      , REC_SRC
      , BKCC
      , FISCAL_YEAR__YYYY
      , FISCAL_MONTH__YYYYMM
      , FORECAST_MATERIAL
      , PRODUCT_NUMBER                                              as                          MATERIAL_KEY
      , MATERIAL_DESCRIPTION
      , SENDER_COST_CENTER
      , CASE
            WHEN LEFT(COALESCE(GL_ACCOUNT_VALUE, 'ERROR'), 4) = '0000'
            THEN SUBSTR(COALESCE(GL_ACCOUNT_VALUE, 'ERROR'), 5)
            ELSE COALESCE(GL_ACCOUNT_VALUE, 'ERROR')
        END as _GLACCOUNTCOPA
      , GL_ACCOUNT_LONG_TEXT
      , COALESCE(ORDER_REASON_DESCRIPTION, 'No Order Reason')       as              ORDER_REASON_DESCRIPTION
      , SALES_ORGANIZATION
      , COMPANY_CODE
      , DISTRIBUTION_CHANNEL_CODE
      , SUM(SALES_QUANTITY)                                         as                       NO_CHARGE_UNITS
      , SUM(STANDARD_COST)                                          as                         WARRANTY_COST
FROM JOIN_RESULT
GROUP BY ALL
{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_locc           as ( SELECT CONSUMER_HK, CUSTOMER_HK, LNK_ORDER_CUSTOMER_CONSUMER_HK, ORDER_HEADER_HK, REC_SRC 
                        FROM {{ ref('lnk_order_customer_consumer') }} as SRC  ),
SRC_hoh            as ( SELECT BKCC, ORDER_HEADER_BK, ORDER_HEADER_HK FROM {{ ref('hub_order_header') }} as SRC 
                        WHERE ORDER_HEADER_BK <> 'MS1037'
                        /*Filtered out a test order entered by the Shopify team to test the production deployment to resolve JIRA ticket GPGDS-9665*/ ),
SRC_hct            as ( SELECT BKCC, CUSTOMER_BK, CUSTOMER_HK FROM {{ ref('hub_customer_v1') }} as SRC  ),
SRC_hcn            as ( SELECT BKCC, CONSUMER_BK, CONSUMER_HK FROM {{ ref('hub_consumer') }} as SRC  ),
SRC_lsocc          as ( SELECT BILLING_ADDRESS_CITY, BILLING_ADDRESS_COUNTRY_CODE, BILLING_ADDRESS_PROVINCE_CODE, BILLING_ADDRESS_ZIP, CANCELLED_AT, 
                        CREATED_AT, CURRENT_SUBTOTAL_PRICE, CURRENT_TOTAL_DISCOUNTS, CURRENT_TOTAL_PRICE, CURRENT_TOTAL_TAX, CUSTOMER_ID, FINANCIAL_STATUS, 
                        FULFILLMENT_STATUS, ID, LNK_ORDER_CUSTOMER_CONSUMER_HK, REC_SRC, SHIPPING_ADDRESS_CITY, SHIPPING_ADDRESS_COUNTRY_CODE, 
                        SHIPPING_ADDRESS_PROVINCE_CODE, SHIPPING_ADDRESS_ZIP, TOTAL_SHIPPING_PRICE_SET, UPDATED_AT 
                        FROM {{ ref('lsat_order_customer_consumer__winn_shopify') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY LNK_ORDER_CUSTOMER_CONSUMER_HK ORDER BY LOAD_DTS DESC) ),
SRC_soha           as ( SELECT AMOUNT, ORDER_HEADER_HK FROM {{ ref('sat_order_header_adjustment__winn_shopify') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ORDER_HEADER_HK, ID ORDER BY LOAD_DTS DESC) )

/*
SRC_locc           as ( SELECT * FROM raw_vault.lnk_order_customer_consumer )
SRC_hoh            as ( SELECT * FROM raw_vault.hub_order_header )
SRC_hct            as ( SELECT * FROM raw_vault.hub_customer_v1 )
SRC_hcn            as ( SELECT * FROM raw_vault.hub_consumer )
SRC_lsocc          as ( SELECT * FROM raw_vault.lsat_order_customer_consumer__winn_shopify )
SRC_soha           as ( SELECT * FROM raw_vault.sat_order_header_adjustment__winn_shopify )
*/
---- LOGIC LAYER ----

, LOGIC_locc as (
    SELECT
        LNK_ORDER_CUSTOMER_CONSUMER_HK
      , ORDER_HEADER_HK
      , CUSTOMER_HK
      , CONSUMER_HK
      , REC_SRC
    FROM SRC_locc
)

, LOGIC_hoh as (
    SELECT
        ORDER_HEADER_BK
      , BKCC
      , ORDER_HEADER_HK                                              as                                HOH_ORDER_HEADER_HK
    FROM SRC_hoh
)

, LOGIC_hct as (
    SELECT
        CUSTOMER_BK
      , CUSTOMER_HK                                                  as                                    HCT_CUSTOMER_HK
      , BKCC                                                         as                                           HCT_BKCC
    FROM SRC_hct
)

, LOGIC_hcn as (
    SELECT
        CONSUMER_BK
      , CONSUMER_HK                                                  as                                    HCN_CONSUMER_HK
      , BKCC                                                         as                                           HCN_BKCC
    FROM SRC_hcn
)

, LOGIC_lsocc as (
    SELECT
        ID                                                           as                                           ORDER_ID
      , CUSTOMER_ID
      , FINANCIAL_STATUS
      , FULFILLMENT_STATUS
      , CURRENT_TOTAL_PRICE                                          as                                      ORDER_DOLLARS
      , CURRENT_SUBTOTAL_PRICE                                       as                             ORDER_SUBTOTAL_DOLLARS
      , CURRENT_TOTAL_TAX                                            as                                          ORDER_TAX
      , CURRENT_TOTAL_DISCOUNTS                                      as                                          DISCOUNTS
      , SHIPPING_ADDRESS_CITY                                        as                                      SHIPPING_CITY
      , SHIPPING_ADDRESS_PROVINCE_CODE                               as                                     SHIPPING_STATE
      , SHIPPING_ADDRESS_COUNTRY_CODE                                as                                   SHIPPING_COUNTRY
      , SHIPPING_ADDRESS_ZIP                                         as                                       SHIPPING_ZIP
      , BILLING_ADDRESS_CITY                                         as                                       BILLING_CITY
      , BILLING_ADDRESS_PROVINCE_CODE                                as                                      BILLING_STATE
      , BILLING_ADDRESS_COUNTRY_CODE                                 as                                    BILLING_COUNTRY
      , BILLING_ADDRESS_ZIP                                          as                                        BILLING_ZIP
      , LNK_ORDER_CUSTOMER_CONSUMER_HK                               as               LSOCC_LNK_ORDER_CUSTOMER_CONSUMER_HK
      , TOTAL_SHIPPING_PRICE_SET
      , CREATED_AT
      , UPDATED_AT
      , CANCELLED_AT
      , REC_SRC                                                      as                                      LSOCC_REC_SRC
    FROM SRC_lsocc
)

, LOGIC_soha as (
    SELECT
        ORDER_HEADER_HK                                              as                               SOHA_ORDER_HEADER_HK
      , AMOUNT                                                       as                                        SOHA_AMOUNT
    FROM SRC_soha
)
---- RENAME LAYER ----

, RENAME_locc as (
    SELECT
        LNK_ORDER_CUSTOMER_CONSUMER_HK
      , ORDER_HEADER_HK
      , CUSTOMER_HK
      , CONSUMER_HK
      , REC_SRC
    FROM LOGIC_locc
)

, RENAME_hoh as (
    SELECT
        ORDER_HEADER_BK
      , BKCC
      , HOH_ORDER_HEADER_HK
    FROM LOGIC_hoh
)

, RENAME_lsocc as (
    SELECT
        ORDER_ID
      , CUSTOMER_ID
      , FINANCIAL_STATUS
      , FULFILLMENT_STATUS
      , ORDER_DOLLARS
      , ORDER_SUBTOTAL_DOLLARS
      , ORDER_TAX
      , DISCOUNTS
      , SHIPPING_CITY
      , SHIPPING_STATE
      , SHIPPING_COUNTRY
      , SHIPPING_ZIP
      , BILLING_CITY
      , BILLING_STATE
      , BILLING_COUNTRY
      , BILLING_ZIP
      , LSOCC_LNK_ORDER_CUSTOMER_CONSUMER_HK
      , TOTAL_SHIPPING_PRICE_SET
      , CREATED_AT
      , UPDATED_AT
      , CANCELLED_AT
      , LSOCC_REC_SRC
    FROM LOGIC_lsocc
)

, RENAME_hct as (
    SELECT
        CUSTOMER_BK
      , HCT_CUSTOMER_HK
      , HCT_BKCC
    FROM LOGIC_hct
)

, RENAME_hcn as (
    SELECT
        CONSUMER_BK
      , HCN_CONSUMER_HK
      , HCN_BKCC
    FROM LOGIC_hcn
)

, RENAME_soha as (
    SELECT
        SOHA_ORDER_HEADER_HK
      , SOHA_AMOUNT
    FROM LOGIC_soha
)
---- FILTER LAYER ----

, FILTER_locc as (
    SELECT *
    FROM RENAME_locc
)

, FILTER_hoh as (
    SELECT *
    FROM RENAME_hoh
)

, FILTER_hct as (
    SELECT *
    FROM RENAME_hct
)

, FILTER_hcn as (
    SELECT *
    FROM RENAME_hcn
)

, FILTER_lsocc as (
    SELECT *
    FROM RENAME_lsocc
    WHERE LSOCC_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED' 
/* This filter is to exclude the ghost records */
    QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ORDER_ID,CUSTOMER_ID ORDER BY UPDATED_AT DESC) 
/* The qualifier is implemented to prevent multiple lnk_hks for same order|customer combo due to consumer_bk(email) typos/dq issues. */
)

, FILTER_soha as (
    SELECT *
    FROM RENAME_soha
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_locc
    INNER JOIN FILTER_hoh
        ON FILTER_locc.ORDER_HEADER_HK = HOH_ORDER_HEADER_HK AND BKCC = 'Screeching_Bat'
    INNER JOIN FILTER_hct
        ON FILTER_locc.CUSTOMER_HK = HCT_CUSTOMER_HK AND HCT_BKCC = 'Screeching_Bat'
    INNER JOIN FILTER_hcn
        ON FILTER_locc.CONSUMER_HK = HCN_CONSUMER_HK AND HCN_BKCC = 'Screeching_Bat'
    INNER JOIN FILTER_lsocc
        ON FILTER_locc.LNK_ORDER_CUSTOMER_CONSUMER_HK = LSOCC_LNK_ORDER_CUSTOMER_CONSUMER_HK
    LEFT JOIN FILTER_soha
        ON FILTER_locc.ORDER_HEADER_HK = SOHA_ORDER_HEADER_HK
)

---- FINAL LAYER ----
SELECT
          LNK_ORDER_CUSTOMER_CONSUMER_HK
        , ORDER_HEADER_HK
        , ORDER_HEADER_BK
        , ORDER_ID
        , CUSTOMER_HK
        , CUSTOMER_BK
        , CUSTOMER_ID
        , CONSUMER_HK
        , CONSUMER_BK
        , FINANCIAL_STATUS
        , FULFILLMENT_STATUS
        , ORDER_DOLLARS
        , ORDER_SUBTOTAL_DOLLARS
        , ORDER_TAX
        , TOTAL_SHIPPING_PRICE_SET:presentment_money:amount::NUMBER(8,2) as SHIPPING
        , DISCOUNTS
        , SUM(SOHA_AMOUNT)                                             as ADJUSTMENT
        , SHIPPING_CITY
        , SHIPPING_STATE
        , SHIPPING_COUNTRY
        , SHIPPING_ZIP
        , BILLING_CITY
        , BILLING_STATE
        , BILLING_COUNTRY
        , BILLING_ZIP
        , TO_CHAR(CREATED_AT, 'YYYYMMDD')::NUMBER                      as CREATED_DATE_KEY
        , TO_CHAR(UPDATED_AT, 'YYYYMMDD')::NUMBER                      as UPDATED_DATE__YYYYMMDD
        , TO_CHAR(CANCELLED_AT, 'YYYYMMDD')::NUMBER                    as CANCELLED_DATE__YYYYMMDD
        , 'SHOPIFY MOEN'                                               as STORE
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
GROUP BY ALL
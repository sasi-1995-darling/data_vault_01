---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_sales_invoice') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_sales_invoice__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY SALES_INVOICE_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_SALES_INVOICE )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_SALES_INVOICE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_SALES_INVOICE'                                          as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , SALES_INVOICE_HK
      , SALES_INVOICE_BK
      , BKCC
      , REC_SRC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        SALES_INVOICE_HK                                             as                          SAT_WINN_SALES_INVOICE_HK
      , FKART                                                        as                                       BILLING_TYPE
      , FKTYP                                                        as                                   BILLING_CATEGORY
      , VBTYP                                                        as                                  DOCUMENT_CATEGORY
      , WAERK                                                        as                                  DOCUMENT_CURRENCY
      , VKORG                                                        as                                 SALES_ORGANIZATION
      , VTWEG                                                        as                               DISTRIBUTION_CHANNEL
      , VSBED                                                        as                                SHIPPING_CONDITIONS
      , GJAHR                                                        as                                        FISCAL_YEAR
      , POPER                                                        as                                     POSTING_PERIOD
      , KONDA                                                        as                               CUSTOMER_PRICE_GROUP
      , KDGRP                                                        as                                     CUSTOMER_GROUP
      , BZIRK                                                        as                                     SALES_DISTRICT
      , EXPKZ                                                        as                                   EXPORT_INDICATOR
      , VALTG                                                        as                              ADDITIONAL_VALUE_DAYS
      , CAST(VALDT AS INTEGER)                                       as                          FIXED_VALUE_DATE_YYYYMMDD
      , LAND1                                                        as                                DESTINATION_COUNTRY
      , REGIO                                                        as                                             REGION
      , BUKRS                                                        as                                       COMPANY_CODE
      , TAXK1                                                        as                               TAX_CLASSIFICATION_1
      , TAXK2                                                        as                               TAX_CLASSIFICATION_2
      , TAXK3                                                        as                               TAX_CLASSIFICATION_3
      , TAXK4                                                        as                               TAX_CLASSIFICATION_4
      , TAXK5                                                        as                               TAX_CLASSIFICATION_5
      , TAXK6                                                        as                               TAX_CLASSIFICATION_6
      , TAXK7                                                        as                               TAX_CLASSIFICATION_7
      , TAXK8                                                        as                               TAX_CLASSIFICATION_8
      , TAXK9                                                        as                               TAX_CLASSIFICATION_9
      , ERZET                                                        as                                         ENTRY_TIME
      , CAST(ERDAT AS INTEGER)                                       as                    INVOICE_CREATION_DATE__YYYYMMDD
      , KUNRG                                                        as                                              PAYER
      , KUNAG                                                        as                                      PARTY_SOLD_TO
      , MABER                                                        as                                       DUNNING_AREA
      , STWAE                                                        as                                STATISTICS_CURRENCY
      , CAST(AEDAT AS INTEGER)                                       as                       INVOICE_UPDATE_DATE__YYYYMMDD
      , FKART_RL                                                     as                                  INVOICE_LIST_TYPE
      , KURST                                                        as                                 EXCHANGE_RATE_TYPE
      , MANSP                                                        as                                      DUNNING_BLOCK
      , KKBER                                                        as                                CREDIT_CONTROL_AREA
      , ZUONR                                                        as                                  ASSIGNMENT_NUMBER
      , LOGSYS                                                       as                                     LOGICAL_SYSTEM
      , CAST(KURRF_DAT AS INTEGER)                                   as                          TRANSLATION_DATE__YYYYMMDD
      , KIDNO                                                        as                                  PAYMENT_REFERENCE
      , ZTERM                                                        as                                      PAYMENT_TERMS
      , NETWR                                                        as                                          NET_VALUE
      , STCEG                                                        as                            VAT_REGISTRATION_NUMBER
      , SPART                                                        as                                           DIVISION
      , LANDTX                                                       as                              TAX_DEPARTURE_COUNTRY
      , MWSBK                                                        as                                         TAX_AMOUNT
      , PSA_DELETE_IND
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , SALES_INVOICE_HK
      , SALES_INVOICE_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        SAT_WINN_SALES_INVOICE_HK
      , BILLING_TYPE
      , BILLING_CATEGORY
      , DOCUMENT_CATEGORY
      , DOCUMENT_CURRENCY
      , SALES_ORGANIZATION
      , DISTRIBUTION_CHANNEL
      , SHIPPING_CONDITIONS
      , FISCAL_YEAR
      , POSTING_PERIOD
      , CUSTOMER_PRICE_GROUP
      , CUSTOMER_GROUP
      , SALES_DISTRICT
      , EXPORT_INDICATOR
      , ADDITIONAL_VALUE_DAYS
      , FIXED_VALUE_DATE_YYYYMMDD
      , DESTINATION_COUNTRY
      , REGION
      , COMPANY_CODE
      , TAX_CLASSIFICATION_1
      , TAX_CLASSIFICATION_2
      , TAX_CLASSIFICATION_3
      , TAX_CLASSIFICATION_4
      , TAX_CLASSIFICATION_5
      , TAX_CLASSIFICATION_6
      , TAX_CLASSIFICATION_7
      , TAX_CLASSIFICATION_8
      , TAX_CLASSIFICATION_9
      , ENTRY_TIME
      , INVOICE_CREATION_DATE__YYYYMMDD
      , PAYER
      , PARTY_SOLD_TO
      , DUNNING_AREA
      , STATISTICS_CURRENCY
      , INVOICE_UPDATE_DATE__YYYYMMDD
      , INVOICE_LIST_TYPE
      , EXCHANGE_RATE_TYPE
      , DUNNING_BLOCK
      , CREDIT_CONTROL_AREA
      , ASSIGNMENT_NUMBER
      , LOGICAL_SYSTEM
      , TRANSLATION_DATE__YYYYMMDD
      , PAYMENT_REFERENCE
      , PAYMENT_TERMS
      , NET_VALUE
      , VAT_REGISTRATION_NUMBER
      , DIVISION
      , TAX_DEPARTURE_COUNTRY
      , TAX_AMOUNT
      , PSA_DELETE_IND
    FROM LOGIC_SAT_WINN
)
---- FILTER LAYER ----

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_H
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_H.SALES_INVOICE_HK = FILTER_SAT_WINN.SAT_WINN_SALES_INVOICE_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , SALES_INVOICE_HK
        , SALES_INVOICE_BK
        , BKCC
        , REC_SRC
        , BILLING_TYPE
        , BILLING_CATEGORY
        , DOCUMENT_CATEGORY
        , DOCUMENT_CURRENCY
        , SALES_ORGANIZATION
        , DISTRIBUTION_CHANNEL
        , SHIPPING_CONDITIONS
        , FISCAL_YEAR
        , POSTING_PERIOD
        , CUSTOMER_PRICE_GROUP
        , CUSTOMER_GROUP
        , SALES_DISTRICT
        , EXPORT_INDICATOR
        , ADDITIONAL_VALUE_DAYS
        , FIXED_VALUE_DATE_YYYYMMDD
        , DESTINATION_COUNTRY
        , REGION
        , COMPANY_CODE
        , TAX_CLASSIFICATION_1
        , TAX_CLASSIFICATION_2
        , TAX_CLASSIFICATION_3
        , TAX_CLASSIFICATION_4
        , TAX_CLASSIFICATION_5
        , TAX_CLASSIFICATION_6
        , TAX_CLASSIFICATION_7
        , TAX_CLASSIFICATION_8
        , TAX_CLASSIFICATION_9
        , ENTRY_TIME
        , INVOICE_CREATION_DATE__YYYYMMDD
        , PAYER
        , PARTY_SOLD_TO
        , DUNNING_AREA
        , STATISTICS_CURRENCY
        , INVOICE_UPDATE_DATE__YYYYMMDD
        , INVOICE_LIST_TYPE
        , EXCHANGE_RATE_TYPE
        , DUNNING_BLOCK
        , CREDIT_CONTROL_AREA
        , ASSIGNMENT_NUMBER
        , LOGICAL_SYSTEM
        , TRANSLATION_DATE__YYYYMMDD
        , PAYMENT_REFERENCE
        , PAYMENT_TERMS
        , NET_VALUE
        , VAT_REGISTRATION_NUMBER
        , DIVISION
        , TAX_DEPARTURE_COUNTRY
        , TAX_AMOUNT
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED
FROM JOIN_RESULT

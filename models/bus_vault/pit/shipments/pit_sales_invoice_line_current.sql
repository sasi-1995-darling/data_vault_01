---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_sales_invoice_line') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_sales_invoice_line__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY SALES_INVOICE_LINE_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_SALES_INVOICE_LINE )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_SALES_INVOICE_LINE )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_SALES_INVOICE_LINE'                                     as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , SALES_INVOICE_LINE_HK
      , SALES_INVOICE_LINE_BK
      , BKCC
      , REC_SRC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        SALES_INVOICE_LINE_HK                                        as                     SAT_WINN_SALES_INVOICE_LINE_HK
      , MEINS                                                        as                                           BASE_UNIT_OF_MEASURE
      , SMENG                                                        as                                     SCALE_BASE_UNIT_OF_MEASURE
      , FKLMG                                                        as                                    SKU_BILLING_QTY
      , LMENG                                                        as                                    MATERIAL_REFERENCE_SKU_QTY
      , FKIMG                                                        as                                 ACTUAL_INVOICE_QTY
      , VRKME                                                        as                                         SALES_UNIT
      , NTGEW                                                        as                                         NET_WEIGHT
      , BRGEW                                                        as                                       GROSS_WEIGHT
      , GEWEI                                                        as                                        WEIGHT_UNIT
      , VOLUM                                                        as                                           VOLUME
      , VOLEH                                                        as                                        VOLUME_UNIT
      , GSBER                                                        as                                      BUSINESS_AREA
      , PRSDT                                                        as                               PRICE_DATE_EXCHANGE_RATE
      , COALESCE(CAST(FBUDA AS INTEGER), 19000101)                   as                    SERVICE_RENDERED_DATE__YYYYMMDD
      , KURSK                                                        as                                 EXC_RATE_PRICE_DET
      , NETWR                                                        as                                      CURRENCY_AMOUNT_1
      , POSNV                                                        as                                          ORIGINAL_ITEM
      , VGBEL                                                        as                                      REFERENCE_DOCUMENT
      , VGPOS                                                        as                                        ITEM_NUM_REFERENCE
      , VGTYP                                                        as                                      DOCUMENT_CATEGORY_SDDOCUMENT
      , AUBEL                                                        as                                          SALES_DOCUMENT
      , AUPOS                                                        as                                     SALES_DOCUMENT_ITEM
      , AUREF                                                        as                                 SALES_DOCUMENT_FROM_REFERENCE
      , MATNR                                                        as                                        MATERIAL_NUM
      , ARKTX                                                        as                           SHORT_TXT_SALES_ORDER_ITEM
      , PMATN                                                        as                                      PRICE_REFERENCE_MATERIAL
      , CHARG                                                        as                                          BATCH_NUM
      , MATKL                                                        as                                       MATERIAL_GROUP
      , PSTYV                                                        as                               SALES_DOCUMENT_ITEM_CATEGORY
      , POSAR                                                        as                                          ITEM_TYPE
      , VSTEL                                                        as                                         SHIP_POINT
      , SPART                                                        as                                         DIVISION
      , POSPA                                                        as                                ITEM_NUM_PART_SEGMENT
      , WERKS                                                        as                                              PLANT
      , ALAND                                                        as                                     DEPART_COUNTRY
      , WKREG                                                        as                                          PLANT_REGION
      , WKCOU                                                        as                                      PLANT_COUNTRY
      , WKCTY                                                        as                                         PLANT_CITY
      , TAXM1                                                        as                        TAX_CLASSIFICATION_MATERIAL
      , TAXM2                                                        as                       TAX_CLASSIFICATION_MATERIAL2
      , TAXM3                                                        as                       TAX_CLASSIFICATION_MATERIAL3
      , TAXM4                                                        as                       TAX_CLASSIFICATION_MATERIAL4
      , TAXM5                                                        as                       TAX_CLASSIFICATION_MATERIAL5
      , TAXM6                                                        as                       TAX_CLASSIFICATION_MATERIAL6
      , TAXM7                                                        as                       TAX_CLASSIFICATION_MATERIAL7
      , TAXM8                                                        as                       TAX_CLASSIFICATION_MATERIAL8
      , TAXM9                                                        as                       TAX_CLASSIFICATION_MATERIAL9
      , SKFBP                                                        as                                      CURRENCY_AMOUNT_2
      , KONDM                                                        as                             MATERIAL_PRICING_GROUP 
      , KOSTL                                                        as                                        COST_CENTER
      , BONUS                                                        as                                VOLUME_REBATE_GROUP
      , LGORT                                                        as                                   STORAGE_LOCATION
      , WAVWR                                                        as                                      COST_DOCUMENT_CURRENCY
      , CMPRE                                                        as                                  ITEM_CREDIT_PRICE
      , AUTYP                                                        as                                     SD_DOCUMENT_CATEGORY
      , PROVG                                                        as                                           COMMISSION_GROUP
      , VKGRP                                                      as                                          SALES_GROUP
      , VKBUR                                                        as                                          SALES_OFFICE
      , SPARA                                                        as                                      ORDER_HEAD_DIV
      , SHKZG                                                        as                                           RETURN_ITEM
      , PRCTR                                                        as                                        PROFIT_CENTER
      , KVGR1                                                        as                                        CUSTOMER_GROUP1
      , KVGR2                                                        as                                        CUSTOMER_GROUP2
      , KVGR3                                                        as                                        CUSTOMER_GROUP3
      , KVGR4                                                        as                                        CUSTOMER_GROUP4
      , KVGR5                                                        as                                        CUSTOMER_GROUP5
      , MVGR1                                                        as                                       MATERIAL_GROUP1
      , MVGR2                                                        as                                       MATERIAL_GROUP2
      , MVGR3                                                        as                                       MATERIAL_GROUP3
      , MVGR4                                                        as                                       MATERIAL_GROUP4
      , MVGR5                                                        as                                       MATERIAL_GROUP5
      , MATWA                                                        as                                        MATERIAL_ENTERED
      , PAOBJNR                                                      as                                        PROFIT_SEGMENT_NUM
      , BZIRK_AUFT                                                   as                                 SALES_DISTRICT_SALES_ORDER
      , KDGRP_AUFT                                                   as                                   CUSTOMER_GROUP_SALES_ORDER
      , KONDA_AUFT                                                   as                                  PRICE_GROUP_SALES_ORDER
      , LLAND_AUFT                                                   as                                 COUNTRY_DESTINATION_SALES_ORDER
      , MPROK                                                        as                              STATUS_MAN_PRICE_CHANGE
      , PLTYP_AUFT                                                   as                            PRICE_LIST_TYPE_SALES_ORDER
      , REGIO_AUFT                                                   as                                        REGION_SALES_ORDER
      , VKORG_AUFT                                                   as                                  SALES_ORG_SALES_ORDER
      , VTWEG_AUFT                                                   as                                DISTRIBUTION_CHAN_SALES_ORDER
      , KNUMA_PI                                                     as                                              PROMOTION
      , KNUMA_AG                                                     as                                         SALES_DEAL
      , MSR_REFUND_CODE                                              as                                       RETURN_REFUND_CODE
      , MSR_RET_REASON                                               as                                         RETURN_REASON
      , DISPUTE_CASE                                                 as                                       DISPUTE_CASE
      , DPNRB                                                        as                       ACCOUNTING_DOCUMENT_TRANSACTION_SEQUENCE_NUM
      , CAST(ERDAT AS INTEGER)                                       as                           INVOICE_CREATION_DATE__YYYYMMDD
      , PSA_DELETE_IND
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , SALES_INVOICE_LINE_HK
      , SALES_INVOICE_LINE_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        SAT_WINN_SALES_INVOICE_LINE_HK
      , BASE_UNIT_OF_MEASURE
      , SCALE_BASE_UNIT_OF_MEASURE
      , SKU_BILLING_QTY
      , MATERIAL_REFERENCE_SKU_QTY
      , ACTUAL_INVOICE_QTY
      , SALES_UNIT
      , NET_WEIGHT
      , GROSS_WEIGHT
      , WEIGHT_UNIT
      , VOLUME  
      , VOLUME_UNIT
      , BUSINESS_AREA
      , PRICE_DATE_EXCHANGE_RATE 
      , SERVICE_RENDERED_DATE__YYYYMMDD
      , EXC_RATE_PRICE_DET
      , CURRENCY_AMOUNT_1
      , ORIGINAL_ITEM
      , REFERENCE_DOCUMENT
      , ITEM_NUM_REFERENCE
      , DOCUMENT_CATEGORY_SDDOCUMENT
      , SALES_DOCUMENT
      , SALES_DOCUMENT_ITEM
      , SALES_DOCUMENT_FROM_REFERENCE
      , MATERIAL_NUM
      , SHORT_TXT_SALES_ORDER_ITEM
      , PRICE_REFERENCE_MATERIAL
      , BATCH_NUM
      , MATERIAL_GROUP
      , SALES_DOCUMENT_ITEM_CATEGORY
      , ITEM_TYPE
      , SHIP_POINT
      , DIVISION  
      , ITEM_NUM_PART_SEGMENT
      , PLANT
      , DEPART_COUNTRY
      , PLANT_REGION
      , PLANT_COUNTRY
      , PLANT_CITY
      , TAX_CLASSIFICATION_MATERIAL
      , TAX_CLASSIFICATION_MATERIAL2
      , TAX_CLASSIFICATION_MATERIAL3
      , TAX_CLASSIFICATION_MATERIAL4
      , TAX_CLASSIFICATION_MATERIAL5
      , TAX_CLASSIFICATION_MATERIAL6
      , TAX_CLASSIFICATION_MATERIAL7
      , TAX_CLASSIFICATION_MATERIAL8
      , TAX_CLASSIFICATION_MATERIAL9
      , CURRENCY_AMOUNT_2
      , MATERIAL_PRICING_GROUP
      , COST_CENTER
      , VOLUME_REBATE_GROUP
      , STORAGE_LOCATION
      , COST_DOCUMENT_CURRENCY
      , ITEM_CREDIT_PRICE
      , SD_DOCUMENT_CATEGORY
      , COMMISSION_GROUP
      , SALES_GROUP
      , SALES_OFFICE
      , ORDER_HEAD_DIV
      , RETURN_ITEM
      , PROFIT_CENTER
      , CUSTOMER_GROUP1
      , CUSTOMER_GROUP2
      , CUSTOMER_GROUP3
      , CUSTOMER_GROUP4
      , CUSTOMER_GROUP5
      , MATERIAL_GROUP1
      , MATERIAL_GROUP2
      , MATERIAL_GROUP3
      , MATERIAL_GROUP4
      , MATERIAL_GROUP5      
      , MATERIAL_ENTERED
      , PROFIT_SEGMENT_NUM
      , SALES_DISTRICT_SALES_ORDER
      , CUSTOMER_GROUP_SALES_ORDER
      , PRICE_GROUP_SALES_ORDER
      , COUNTRY_DESTINATION_SALES_ORDER
      , STATUS_MAN_PRICE_CHANGE
      , PRICE_LIST_TYPE_SALES_ORDER
      , REGION_SALES_ORDER
      , SALES_ORG_SALES_ORDER
      , DISTRIBUTION_CHAN_SALES_ORDER
      , PROMOTION
      , SALES_DEAL
      , RETURN_REFUND_CODE
      , RETURN_REASON
      , DISPUTE_CASE
      , ACCOUNTING_DOCUMENT_TRANSACTION_SEQUENCE_NUM
      , INVOICE_CREATION_DATE__YYYYMMDD
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
        ON FILTER_H.SALES_INVOICE_LINE_HK = SAT_WINN_SALES_INVOICE_LINE_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , SALES_INVOICE_LINE_HK
        , SALES_INVOICE_LINE_BK
        , BKCC
        , REC_SRC
        , BASE_UNIT_OF_MEASURE
        , SCALE_BASE_UNIT_OF_MEASURE
        , SKU_BILLING_QTY
        , MATERIAL_REFERENCE_SKU_QTY
        , ACTUAL_INVOICE_QTY
        , SALES_UNIT
        , NET_WEIGHT
        , GROSS_WEIGHT
        , WEIGHT_UNIT
        , VOLUME  
        , VOLUME_UNIT
        , BUSINESS_AREA
        , PRICE_DATE_EXCHANGE_RATE 
        , SERVICE_RENDERED_DATE__YYYYMMDD
        , EXC_RATE_PRICE_DET
        , CURRENCY_AMOUNT_1
        , ORIGINAL_ITEM
        , REFERENCE_DOCUMENT
        , ITEM_NUM_REFERENCE
        , DOCUMENT_CATEGORY_SDDOCUMENT
        , SALES_DOCUMENT
        , SALES_DOCUMENT_ITEM
        , SALES_DOCUMENT_FROM_REFERENCE
        , MATERIAL_NUM
        , SHORT_TXT_SALES_ORDER_ITEM
        , PRICE_REFERENCE_MATERIAL
        , BATCH_NUM
        , MATERIAL_GROUP
        , SALES_DOCUMENT_ITEM_CATEGORY
        , ITEM_TYPE
        , SHIP_POINT
        , DIVISION  
        , ITEM_NUM_PART_SEGMENT
        , PLANT
        , DEPART_COUNTRY
        , PLANT_REGION
        , PLANT_COUNTRY
        , PLANT_CITY
        , TAX_CLASSIFICATION_MATERIAL
        , TAX_CLASSIFICATION_MATERIAL2
        , TAX_CLASSIFICATION_MATERIAL3
        , TAX_CLASSIFICATION_MATERIAL4
        , TAX_CLASSIFICATION_MATERIAL5
        , TAX_CLASSIFICATION_MATERIAL6
        , TAX_CLASSIFICATION_MATERIAL7
        , TAX_CLASSIFICATION_MATERIAL8
        , TAX_CLASSIFICATION_MATERIAL9
        , CURRENCY_AMOUNT_2
        , MATERIAL_PRICING_GROUP
        , COST_CENTER
        , VOLUME_REBATE_GROUP
        , STORAGE_LOCATION
        , COST_DOCUMENT_CURRENCY
        , ITEM_CREDIT_PRICE
        , SD_DOCUMENT_CATEGORY
        , COMMISSION_GROUP
        , SALES_GROUP
        , SALES_OFFICE
        , ORDER_HEAD_DIV
        , RETURN_ITEM
        , PROFIT_CENTER
        , CUSTOMER_GROUP1
        , CUSTOMER_GROUP2
        , CUSTOMER_GROUP3
        , CUSTOMER_GROUP4
        , CUSTOMER_GROUP5
        , MATERIAL_GROUP1
        , MATERIAL_GROUP2
        , MATERIAL_GROUP3
        , MATERIAL_GROUP4
        , MATERIAL_GROUP5
        , MATERIAL_ENTERED
        , PROFIT_SEGMENT_NUM
        , SALES_DISTRICT_SALES_ORDER
        , CUSTOMER_GROUP_SALES_ORDER
        , PRICE_GROUP_SALES_ORDER
        , COUNTRY_DESTINATION_SALES_ORDER
        , STATUS_MAN_PRICE_CHANGE
        , PRICE_LIST_TYPE_SALES_ORDER
        , REGION_SALES_ORDER
        , SALES_ORG_SALES_ORDER
        , DISTRIBUTION_CHAN_SALES_ORDER
        , PROMOTION
        , SALES_DEAL
        , RETURN_REFUND_CODE
        , RETURN_REASON
        , DISPUTE_CASE
        , ACCOUNTING_DOCUMENT_TRANSACTION_SEQUENCE_NUM
        , INVOICE_CREATION_DATE__YYYYMMDD
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED
FROM JOIN_RESULT

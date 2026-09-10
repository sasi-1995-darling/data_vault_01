---- SRC LAYER ----
WITH
SRC_winn           as ( SELECT AVG_INV_PRICE, BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_LEADER_NAME, CONSIGNMENT_IND, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, DOCUMENT_TYPE, DRVD_OPCO, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, HDR_BUYER_CODE, ITEM_BK, ITEM_HK, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, LOCAL_CURRENCY, MATERIAL_DOCUMENT_ITEM, MATERIAL_DOCUMENT_NUMBER, OPCO_CATEGORY, ORDER_QTY, ORDER_UNIT_PRICE, ORDER_UNIT_PRICE_USD, PAYMENT_TERMS, PLANT_BK, PLANT_HK, POSTING_DATE, PO_CREATION_DATE, PO_CURRENCY, PO_HEADER_DEL_IND, PO_HEADER_HK, PO_HEADER_ID, PO_ITEM_UOM, PO_LINE_ELIKZ, PO_LINE_NUMBER, PO_RECEIPT_UOM, PURCHASING_ORG_BK, PURCHASING_ORG_HK, PURCHASING_RECORD_BK, PURCHASING_RECORD_HK, RECEIPT_QTY, RECEIPT_SPEND, REC_SRC, SPEND_AMOUNT_LOCAL_CURRENCY, SPEND_USD, SPEND_VOLUME, SUPPLIER_BK, SUPPLIER_HK, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, TOTAL_INV_QTY, TOTAL_INV_SPEND, TOTAL_RCPT_QTY, TOTAL_RCPT_SPEND FROM {{ ref('stg_pb_global_spend__winn_sap') }} as SRC  ),
SRC_tmlc           as ( SELECT BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, DOCUMENT_TYPE, DRVD_OPCO, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, HDR_BUYER_CODE, ITEM_BK, ITEM_HK, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, LOCAL_CURRENCY, OPCO_CATEGORY, ORDER_QTY, ORDER_UNIT_PRICE, ORDER_UNIT_PRICE_USD, PAYMENT_TERMS, PLANT_BK, PLANT_HK, POSTING_DATE, PO_CREATION_DATE, PO_HEADER_DEL_IND, PO_HEADER_HK, PO_HEADER_ID, PO_ITEM_UOM, PO_LINE_NUMBER, TRANSACTION_ID, PO_NUMBER, PO_RECEIPT_UOM, PURCHASING_ORG_HK, PURCHASING_RECORD_HK, RECEIPT_QTY, RECEIPT_SPEND, REC_SRC, SUPPLIER_SITE_BK, SPEND_AMOUNT_LOCAL_CURRENCY, SPEND_USD, SPEND_VOLUME, SUPPLIER_BK, SUPPLIER_HK, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, TOTAL_RCPT_QTY, TOTAL_RCPT_SPEND FROM {{ ref('stg_pb_global_spend__ml_ebs') }} as SRC  ),
SRC_lrsn           as ( SELECT BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_CD, CATEGORY_DESC, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, DOCUMENT_TYPE, DRVD_OPCO, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, HDR_BUYER_CODE, ITEM_BK, ITEM_HK, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, LOCAL_CURRENCY, MATERIAL_DOCUMENT_ITEM, MATERIAL_DOCUMENT_NUMBER, OPCO_CATEGORY, ORDER_QTY, ORDER_UNIT_PRICE, ORDER_UNIT_PRICE_USD, PAYMENT_TERMS, PLANT_BK, PLANT_HK, POSTING_DATE, PO_CREATION_DATE, PO_CURRENCY, PO_HEADER_DEL_IND, PO_HEADER_HK, PO_HEADER_ID, PO_ITEM_UOM, PO_LINE_NUMBER, PO_NUMBER, PO_RECEIPT_UOM, PURCHASING_ORG_HK, PURCHASING_RECORD_HK, RECEIPT_QTY, RECEIPT_SPEND, REC_SRC, SPEND_AMOUNT_LOCAL_CURRENCY, SPEND_USD, SPEND_VOLUME, SUPPLIER_BK, SUPPLIER_HK, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, TOTAL_RCPT_QTY, TOTAL_RCPT_SPEND, USD_PO_ITEM_PRICE FROM {{ ref('stg_pb_global_spend__lrsn_psft') }} as SRC  ),
SRC_emtk           as ( SELECT BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, DOCUMENT_TYPE, DRVD_OPCO, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, HDR_BUYER_CODE, ITEM_BK, ITEM_HK, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, LOCAL_CURRENCY, OPCO_CATEGORY, ORDER_QTY, ORDER_UNIT_PRICE, ORDER_UNIT_PRICE_USD, PAYMENT_TERMS, PLANT_BK, PLANT_HK, POSTING_DATE, PO_CREATION_DATE, PO_HEADER_DEL_IND, PO_HEADER_HK, PO_HEADER_ID, PO_ITEM_UOM, PO_LINE_NUMBER, TRANSACTION_ID, PO_NUMBER, PO_RECEIPT_UOM, PURCHASING_ORG_HK, PURCHASING_RECORD_HK, RECEIPT_QTY, RECEIPT_SPEND, REC_SRC, SUPPLIER_SITE_BK, SPEND_AMOUNT_LOCAL_CURRENCY, SPEND_USD, SPEND_VOLUME, SUPPLIER_BK, SUPPLIER_HK, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, TOTAL_RCPT_QTY, TOTAL_RCPT_SPEND FROM {{ ref('stg_pb_global_spend__emtk_ebs') }} as SRC  ),
SRC_ttgp           as ( SELECT BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, DOCUMENT_TYPE, DRVD_OPCO, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, HDR_BUYER_CODE, ITEM_BK, ITEM_HK, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, LOCAL_CURRENCY, MATERIAL_DOCUMENT_ITEM, MATERIAL_DOCUMENT_NUMBER, OPCO_CATEGORY, ORDER_QTY, ORDER_UNIT_PRICE, ORDER_UNIT_PRICE_USD, PAYMENT_TERMS, PLANT_BK, PLANT_HK, POSTING_DATE, PO_CREATION_DATE, PO_HEADER_DEL_IND, PO_HEADER_HK, PO_HEADER_ID, PO_ITEM_UOM, PO_LINE_NUMBER, PO_RECEIPT_UOM, PURCHASING_ORG_HK, PURCHASING_RECORD_HK, RECEIPT_QTY, RECEIPT_SPEND, REC_SRC, SPEND_AMOUNT_LOCAL_CURRENCY, SPEND_USD, SPEND_VOLUME, SUPPLIER_BK, SUPPLIER_HK, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, TOTAL_RCPT_QTY, TOTAL_RCPT_SPEND FROM {{ ref('stg_pb_global_spend__tt_gp') }} as SRC  ),
SRC_tte21          as ( SELECT BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, DOCUMENT_TYPE, DRVD_OPCO, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, HDR_BUYER_CODE, ITEM_BK, ITEM_HK, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, LOCAL_CURRENCY, OPCO_CATEGORY, ORDER_QTY, ORDER_UNIT_PRICE, ORDER_UNIT_PRICE_USD, PAYMENT_TERMS, PLANT_BK, PLANT_HK, POSTING_DATE, PO_CREATION_DATE, PO_HEADER_DEL_IND, PO_HEADER_HK, PO_HEADER_ID, PO_ITEM_UOM, PO_LINE_NUMBER, PO_RECEIPT_UOM, PURCHASING_ORG_HK, PURCHASING_RECORD_HK, RECEIPT_QTY, RECEIPT_SPEND, REC_SRC, RELEASE_NUMBER, SPEND_AMOUNT_LOCAL_CURRENCY, SPEND_USD, SPEND_VOLUME, SUPPLIER_BK, SUPPLIER_HK, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, TOTAL_RCPT_QTY, TOTAL_RCPT_SPEND FROM {{ ref('stg_pb_global_spend__tt_e21') }} as SRC  ),
SRC_fib            as ( SELECT BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, DOCUMENT_TYPE, DRVD_OPCO, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, HDR_BUYER_CODE, ITEM_BK, ITEM_HK, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, LOCAL_CURRENCY, OPCO_CATEGORY, ORDER_QTY, ORDER_UNIT_PRICE, ORDER_UNIT_PRICE_USD, PAYMENT_TERMS, PLANT_BK, PLANT_HK, POSTING_DATE, PO_CREATION_DATE, PO_HEADER_DEL_IND, PO_HEADER_HK, PO_HEADER_ID, PO_ITEM_UOM, PO_LINE_NUMBER, TRANSACTION_ID, PO_NUMBER, PO_RECEIPT_UOM, PURCHASING_ORG_HK, PURCHASING_RECORD_HK, RECEIPT_QTY, RECEIPT_SPEND, REC_SRC, SUPPLIER_SITE_BK, SPEND_AMOUNT_LOCAL_CURRENCY, SPEND_USD, SPEND_VOLUME, SUPPLIER_BK, SUPPLIER_HK, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, TOTAL_RCPT_QTY, TOTAL_RCPT_SPEND FROM {{ ref('stg_pb_global_spend__fib_ocf') }} as SRC  )

/*
SRC_winn           as ( SELECT * FROM BUS_VAULT.stg_pb_global_spend__winn_sap )
SRC_tmlc           as ( SELECT * FROM BUS_VAULT.stg_pb_global_spend__ml_ebs )
SRC_lrsn           as ( SELECT * FROM BUS_VAULT.stg_pb_global_spend__lrsn_psft )
SRC_emtk           as ( SELECT * FROM BUS_VAULT.stg_pb_global_spend__emtk_ebs )
SRC_ttgp           as ( SELECT * FROM BUS_VAULT.stg_pb_global_spend__tt_gp )
SRC_tte21          as ( SELECT * FROM BUS_VAULT.stg_pb_global_spend__tt_e21 )
SRC_fib            as ( SELECT * FROM BUS_VAULT.stg_pb_global_spend__fib_ocf )
*/
---- LOGIC LAYER ----

, LOGIC_winn as (
    SELECT
        PO_HEADER_ID
      , PO_HEADER_ID                                                 as                                          PO_NUMBER
      , PO_LINE_NUMBER
      , MATERIAL_DOCUMENT_NUMBER
      , MATERIAL_DOCUMENT_ITEM
      , null                                                         as                                     TRANSACTION_ID
      , null                                                         as                                     RELEASE_NUMBER
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , COUNTRY_OF_ORIGIN
      , POSTING_DATE
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO
      , PO_CREATION_DATE
      , null                                                         as                                        CATEGORY_CD
      , null                                                         as                                      CATEGORY_DESC
      , HDR_BUYER_CODE
      , ORDER_QTY
      , TOTAL_RCPT_QTY
      , TOTAL_RCPT_SPEND
      , TOTAL_INV_QTY
      , TOTAL_INV_SPEND
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , PO_CURRENCY
      , AVG_INV_PRICE
      , SPEND_VOLUME
      , PO_ITEM_UOM
      , ORDER_UNIT_PRICE
      , ORDER_UNIT_PRICE_USD
      , PO_RECEIPT_UOM
      , SPEND_AMOUNT_LOCAL_CURRENCY
      , PO_LINE_ELIKZ
      , LOCAL_CURRENCY
      , SPEND_USD
      , null                                                         as                                  USD_PO_ITEM_PRICE
      , OPCO_CATEGORY
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , CONSIGNMENT_IND
      , PURCHASING_ORG_BK
      , PO_HEADER_DEL_IND
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , PURCHASING_RECORD_BK
      , '-2'                                                         as                                   SUPPLIER_SITE_BK
      , PO_HEADER_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , BKCC
      , REC_SRC
      , BUSINESS_UNIT
    FROM SRC_winn
)

, LOGIC_tmlc as (
    SELECT
        PO_HEADER_ID
      , PO_NUMBER
      , PO_LINE_NUMBER
      , null                                                         as                           MATERIAL_DOCUMENT_NUMBER
      , null                                                         as                             MATERIAL_DOCUMENT_ITEM
      , TRANSACTION_ID::TEXT                                         as                                     TRANSACTION_ID
      , null                                                         as                                     RELEASE_NUMBER
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , COUNTRY_OF_ORIGIN
      , POSTING_DATE
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO
      , PO_CREATION_DATE
      , null                                                         as                                        CATEGORY_CD
      , null                                                         as                                      CATEGORY_DESC
      , HDR_BUYER_CODE
      , ORDER_QTY
      , TOTAL_RCPT_QTY
      , TOTAL_RCPT_SPEND
      , null                                                         as                                      TOTAL_INV_QTY
      , null                                                         as                                    TOTAL_INV_SPEND
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , LOCAL_CURRENCY                                               as                                        PO_CURRENCY
      , null                                                         as                                      AVG_INV_PRICE
      , SPEND_VOLUME
      , PO_ITEM_UOM
      , ORDER_UNIT_PRICE
      , ORDER_UNIT_PRICE_USD
      , PO_RECEIPT_UOM
      , SPEND_AMOUNT_LOCAL_CURRENCY
      , null                                                         as                                      PO_LINE_ELIKZ
      , LOCAL_CURRENCY
      , SPEND_USD
      , null                                                         as                                  USD_PO_ITEM_PRICE
      , OPCO_CATEGORY
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , null                                                         as                                    CONSIGNMENT_IND
      , '-2'                                                         as                                  PURCHASING_ORG_BK
      , PO_HEADER_DEL_IND
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , '-2'                                                         as                               PURCHASING_RECORD_BK
      , SUPPLIER_SITE_BK
      , PO_HEADER_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , BKCC
      , REC_SRC
      , BUSINESS_UNIT
    FROM SRC_tmlc
)

, LOGIC_lrsn as (
    SELECT
        PO_HEADER_ID
      , PO_NUMBER
      , PO_LINE_NUMBER
      , MATERIAL_DOCUMENT_NUMBER
      , MATERIAL_DOCUMENT_ITEM
      , null                                                         as                                     TRANSACTION_ID
      , null                                                         as                                     RELEASE_NUMBER
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , COUNTRY_OF_ORIGIN
      , POSTING_DATE
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO
      , PO_CREATION_DATE
      , CATEGORY_CD
      , CATEGORY_DESC
      , HDR_BUYER_CODE
      , ORDER_QTY
      , TOTAL_RCPT_QTY
      , TOTAL_RCPT_SPEND
      , null                                                         as                                      TOTAL_INV_QTY
      , null                                                         as                                    TOTAL_INV_SPEND
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , PO_CURRENCY
      , null                                                         as                                      AVG_INV_PRICE
      , SPEND_VOLUME
      , PO_ITEM_UOM
      , ORDER_UNIT_PRICE
      , ORDER_UNIT_PRICE_USD
      , PO_RECEIPT_UOM
      , SPEND_AMOUNT_LOCAL_CURRENCY
      , null                                                         as                                      PO_LINE_ELIKZ
      , LOCAL_CURRENCY
      , SPEND_USD
      , USD_PO_ITEM_PRICE
      , OPCO_CATEGORY
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , null                                                         as                                    CONSIGNMENT_IND
      , '-2'                                                         as                                  PURCHASING_ORG_BK
      , PO_HEADER_DEL_IND
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , '-2'                                                         as                               PURCHASING_RECORD_BK
      , '-2'                                                         as                                   SUPPLIER_SITE_BK
      , PO_HEADER_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , BKCC
      , REC_SRC
      , BUSINESS_UNIT
    FROM SRC_lrsn
)

, LOGIC_emtk as (
    SELECT
        PO_HEADER_ID
      , PO_NUMBER
      , PO_LINE_NUMBER
      , null                                                         as                           MATERIAL_DOCUMENT_NUMBER
      , null                                                         as                             MATERIAL_DOCUMENT_ITEM
      , TRANSACTION_ID::TEXT                                         as                                     TRANSACTION_ID
      , null                                                         as                                     RELEASE_NUMBER
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , COUNTRY_OF_ORIGIN
      , POSTING_DATE
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO
      , PO_CREATION_DATE
      , null                                                         as                                        CATEGORY_CD
      , null                                                         as                                      CATEGORY_DESC
      , HDR_BUYER_CODE
      , ORDER_QTY
      , TOTAL_RCPT_QTY
      , TOTAL_RCPT_SPEND
      , null                                                         as                                      TOTAL_INV_QTY
      , null                                                         as                                    TOTAL_INV_SPEND
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , LOCAL_CURRENCY                                               as                                        PO_CURRENCY
      , null                                                         as                                      AVG_INV_PRICE
      , SPEND_VOLUME
      , PO_ITEM_UOM
      , ORDER_UNIT_PRICE
      , ORDER_UNIT_PRICE_USD
      , PO_RECEIPT_UOM
      , SPEND_AMOUNT_LOCAL_CURRENCY
      , null                                                         as                                      PO_LINE_ELIKZ
      , LOCAL_CURRENCY
      , SPEND_USD
      , null                                                         as                                  USD_PO_ITEM_PRICE
      , OPCO_CATEGORY
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , null                                                         as                                    CONSIGNMENT_IND
      , '-2'                                                         as                                  PURCHASING_ORG_BK
      , PO_HEADER_DEL_IND
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , '-2'                                                         as                               PURCHASING_RECORD_BK
      , SUPPLIER_SITE_BK
      , PO_HEADER_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , BKCC
      , REC_SRC
      , BUSINESS_UNIT
    FROM SRC_emtk
)

, LOGIC_ttgp as (
    SELECT
        PO_HEADER_ID
      , PO_HEADER_ID                                                 as                                          PO_NUMBER
      , PO_LINE_NUMBER
      , MATERIAL_DOCUMENT_NUMBER
      , MATERIAL_DOCUMENT_ITEM
      , null                                                         as                                     TRANSACTION_ID
      , null                                                         as                                     RELEASE_NUMBER
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , COUNTRY_OF_ORIGIN
      , POSTING_DATE
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO
      , PO_CREATION_DATE
      , null                                                         as                                        CATEGORY_CD
      , null                                                         as                                      CATEGORY_DESC
      , HDR_BUYER_CODE
      , ORDER_QTY
      , TOTAL_RCPT_QTY
      , TOTAL_RCPT_SPEND
      , null                                                         as                                      TOTAL_INV_QTY
      , null                                                         as                                    TOTAL_INV_SPEND
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , LOCAL_CURRENCY                                               as                                        PO_CURRENCY
      , null                                                         as                                      AVG_INV_PRICE
      , SPEND_VOLUME
      , PO_ITEM_UOM
      , ORDER_UNIT_PRICE
      , ORDER_UNIT_PRICE_USD
      , PO_RECEIPT_UOM
      , SPEND_AMOUNT_LOCAL_CURRENCY
      , null                                                         as                                      PO_LINE_ELIKZ
      , LOCAL_CURRENCY
      , SPEND_USD
      , null                                                         as                                  USD_PO_ITEM_PRICE
      , OPCO_CATEGORY
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , null                                                         as                                    CONSIGNMENT_IND
      , '-2'                                                         as                                  PURCHASING_ORG_BK
      , PO_HEADER_DEL_IND
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , '-2'                                                         as                               PURCHASING_RECORD_BK
      , '-2'                                                         as                                   SUPPLIER_SITE_BK
      , PO_HEADER_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , BKCC
      , REC_SRC
      , BUSINESS_UNIT
    FROM SRC_ttgp
)

, LOGIC_tte21 as (
    SELECT
        PO_HEADER_ID
      , PO_HEADER_ID                                                 as                                          PO_NUMBER
      , PO_LINE_NUMBER
      , null                                                         as                           MATERIAL_DOCUMENT_NUMBER
      , null                                                         as                             MATERIAL_DOCUMENT_ITEM
      , null                                                         as                                     TRANSACTION_ID
      , RELEASE_NUMBER
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , COUNTRY_OF_ORIGIN
      , POSTING_DATE
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO
      , PO_CREATION_DATE
      , null                                                         as                                        CATEGORY_CD
      , null                                                         as                                      CATEGORY_DESC
      , HDR_BUYER_CODE
      , ORDER_QTY
      , TOTAL_RCPT_QTY
      , TOTAL_RCPT_SPEND
      , null                                                         as                                      TOTAL_INV_QTY
      , null                                                         as                                    TOTAL_INV_SPEND
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , LOCAL_CURRENCY                                               as                                        PO_CURRENCY
      , null                                                         as                                      AVG_INV_PRICE
      , SPEND_VOLUME
      , PO_ITEM_UOM
      , ORDER_UNIT_PRICE
      , ORDER_UNIT_PRICE_USD
      , PO_RECEIPT_UOM
      , SPEND_AMOUNT_LOCAL_CURRENCY
      , null                                                         as                                      PO_LINE_ELIKZ
      , LOCAL_CURRENCY
      , SPEND_USD
      , null                                                         as                                  USD_PO_ITEM_PRICE
      , OPCO_CATEGORY
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , null                                                         as                                    CONSIGNMENT_IND
      , '-2'                                                         as                                  PURCHASING_ORG_BK
      , PO_HEADER_DEL_IND
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , '-2'                                                         as                               PURCHASING_RECORD_BK
      , '-2'                                                         as                                   SUPPLIER_SITE_BK
      , PO_HEADER_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , BKCC
      , REC_SRC
      , BUSINESS_UNIT
    FROM SRC_tte21
)

, LOGIC_fib as (
    SELECT
        PO_HEADER_ID
      , PO_NUMBER
      , PO_LINE_NUMBER
      , null                                                         as                           MATERIAL_DOCUMENT_NUMBER
      , null                                                         as                             MATERIAL_DOCUMENT_ITEM
      , TRANSACTION_ID::TEXT                                         as                                     TRANSACTION_ID
      , null                                                         as                                     RELEASE_NUMBER
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , COUNTRY_OF_ORIGIN
      , POSTING_DATE
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO
      , PO_CREATION_DATE
      , null                                                         as                                        CATEGORY_CD
      , null                                                         as                                      CATEGORY_DESC
      , HDR_BUYER_CODE
      , ORDER_QTY
      , TOTAL_RCPT_QTY
      , TOTAL_RCPT_SPEND
      , null                                                         as                                      TOTAL_INV_QTY
      , null                                                         as                                    TOTAL_INV_SPEND
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , LOCAL_CURRENCY                                               as                                        PO_CURRENCY
      , null                                                         as                                      AVG_INV_PRICE
      , SPEND_VOLUME
      , PO_ITEM_UOM
      , ORDER_UNIT_PRICE
      , ORDER_UNIT_PRICE_USD
      , PO_RECEIPT_UOM
      , SPEND_AMOUNT_LOCAL_CURRENCY
      , null                                                         as                                      PO_LINE_ELIKZ
      , LOCAL_CURRENCY
      , SPEND_USD
      , null                                                         as                                  USD_PO_ITEM_PRICE
      , OPCO_CATEGORY
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , null                                                         as                                    CONSIGNMENT_IND
      , '-2'                                                         as                                  PURCHASING_ORG_BK
      , PO_HEADER_DEL_IND
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , '-2'                                                         as                               PURCHASING_RECORD_BK
      , SUPPLIER_SITE_BK
      , PO_HEADER_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , BKCC
      , REC_SRC
      , BUSINESS_UNIT
    FROM SRC_fib
)
---- RENAME LAYER ----

, RENAME_winn as (
    SELECT
        PO_HEADER_ID
      , PO_NUMBER
      , PO_LINE_NUMBER
      , MATERIAL_DOCUMENT_NUMBER
      , MATERIAL_DOCUMENT_ITEM
      , TRANSACTION_ID
      , RELEASE_NUMBER
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , COUNTRY_OF_ORIGIN
      , POSTING_DATE
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO
      , PO_CREATION_DATE
      , CATEGORY_CD
      , CATEGORY_DESC
      , HDR_BUYER_CODE
      , ORDER_QTY
      , TOTAL_RCPT_QTY
      , TOTAL_RCPT_SPEND
      , TOTAL_INV_QTY
      , TOTAL_INV_SPEND
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , PO_CURRENCY
      , AVG_INV_PRICE
      , SPEND_VOLUME
      , PO_ITEM_UOM
      , ORDER_UNIT_PRICE
      , ORDER_UNIT_PRICE_USD
      , PO_RECEIPT_UOM
      , SPEND_AMOUNT_LOCAL_CURRENCY
      , PO_LINE_ELIKZ
      , LOCAL_CURRENCY
      , SPEND_USD
      , USD_PO_ITEM_PRICE
      , OPCO_CATEGORY
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , CONSIGNMENT_IND
      , PURCHASING_ORG_BK
      , PO_HEADER_DEL_IND
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , PURCHASING_RECORD_BK
      , SUPPLIER_SITE_BK
      , PO_HEADER_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , BKCC
      , REC_SRC
      , BUSINESS_UNIT
    FROM LOGIC_winn
)

, RENAME_tmlc as (
    SELECT
        PO_HEADER_ID
      , PO_NUMBER
      , PO_LINE_NUMBER
      , MATERIAL_DOCUMENT_NUMBER
      , MATERIAL_DOCUMENT_ITEM
      , TRANSACTION_ID
      , RELEASE_NUMBER
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , COUNTRY_OF_ORIGIN
      , POSTING_DATE
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO
      , PO_CREATION_DATE
      , CATEGORY_CD
      , CATEGORY_DESC
      , HDR_BUYER_CODE
      , ORDER_QTY
      , TOTAL_RCPT_QTY
      , TOTAL_RCPT_SPEND
      , TOTAL_INV_QTY
      , TOTAL_INV_SPEND
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , PO_CURRENCY
      , AVG_INV_PRICE
      , SPEND_VOLUME
      , PO_ITEM_UOM
      , ORDER_UNIT_PRICE
      , ORDER_UNIT_PRICE_USD
      , PO_RECEIPT_UOM
      , SPEND_AMOUNT_LOCAL_CURRENCY
      , PO_LINE_ELIKZ
      , LOCAL_CURRENCY
      , SPEND_USD
      , USD_PO_ITEM_PRICE
      , OPCO_CATEGORY
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , CONSIGNMENT_IND
      , PURCHASING_ORG_BK
      , PO_HEADER_DEL_IND
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , PURCHASING_RECORD_BK
      , SUPPLIER_SITE_BK
      , PO_HEADER_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , BKCC
      , REC_SRC
      , BUSINESS_UNIT
    FROM LOGIC_tmlc
)

, RENAME_lrsn as (
    SELECT
        PO_HEADER_ID
      , PO_NUMBER
      , PO_LINE_NUMBER
      , MATERIAL_DOCUMENT_NUMBER
      , MATERIAL_DOCUMENT_ITEM
      , TRANSACTION_ID
      , RELEASE_NUMBER
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , COUNTRY_OF_ORIGIN
      , POSTING_DATE
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO
      , PO_CREATION_DATE
      , CATEGORY_CD
      , CATEGORY_DESC
      , HDR_BUYER_CODE
      , ORDER_QTY
      , TOTAL_RCPT_QTY
      , TOTAL_RCPT_SPEND
      , TOTAL_INV_QTY
      , TOTAL_INV_SPEND
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , PO_CURRENCY
      , AVG_INV_PRICE
      , SPEND_VOLUME
      , PO_ITEM_UOM
      , ORDER_UNIT_PRICE
      , ORDER_UNIT_PRICE_USD
      , PO_RECEIPT_UOM
      , SPEND_AMOUNT_LOCAL_CURRENCY
      , PO_LINE_ELIKZ
      , LOCAL_CURRENCY
      , SPEND_USD
      , USD_PO_ITEM_PRICE
      , OPCO_CATEGORY
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , CONSIGNMENT_IND
      , PURCHASING_ORG_BK
      , PO_HEADER_DEL_IND
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , PURCHASING_RECORD_BK
      , SUPPLIER_SITE_BK
      , PO_HEADER_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , BKCC
      , REC_SRC
      , BUSINESS_UNIT
    FROM LOGIC_lrsn
)

, RENAME_emtk as (
    SELECT
        PO_HEADER_ID
      , PO_NUMBER
      , PO_LINE_NUMBER
      , MATERIAL_DOCUMENT_NUMBER
      , MATERIAL_DOCUMENT_ITEM
      , TRANSACTION_ID
      , RELEASE_NUMBER
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , COUNTRY_OF_ORIGIN
      , POSTING_DATE
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO
      , PO_CREATION_DATE
      , CATEGORY_CD
      , CATEGORY_DESC
      , HDR_BUYER_CODE
      , ORDER_QTY
      , TOTAL_RCPT_QTY
      , TOTAL_RCPT_SPEND
      , TOTAL_INV_QTY
      , TOTAL_INV_SPEND
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , PO_CURRENCY
      , AVG_INV_PRICE
      , SPEND_VOLUME
      , PO_ITEM_UOM
      , ORDER_UNIT_PRICE
      , ORDER_UNIT_PRICE_USD
      , PO_RECEIPT_UOM
      , SPEND_AMOUNT_LOCAL_CURRENCY
      , PO_LINE_ELIKZ
      , LOCAL_CURRENCY
      , SPEND_USD
      , USD_PO_ITEM_PRICE
      , OPCO_CATEGORY
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , CONSIGNMENT_IND
      , PURCHASING_ORG_BK
      , PO_HEADER_DEL_IND
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , PURCHASING_RECORD_BK
      , SUPPLIER_SITE_BK
      , PO_HEADER_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , BKCC
      , REC_SRC
      , BUSINESS_UNIT
    FROM LOGIC_emtk
)

, RENAME_ttgp as (
    SELECT
        PO_HEADER_ID
      , PO_NUMBER
      , PO_LINE_NUMBER
      , MATERIAL_DOCUMENT_NUMBER
      , MATERIAL_DOCUMENT_ITEM
      , TRANSACTION_ID
      , RELEASE_NUMBER
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , COUNTRY_OF_ORIGIN
      , POSTING_DATE
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO
      , PO_CREATION_DATE
      , CATEGORY_CD
      , CATEGORY_DESC
      , HDR_BUYER_CODE
      , ORDER_QTY
      , TOTAL_RCPT_QTY
      , TOTAL_RCPT_SPEND
      , TOTAL_INV_QTY
      , TOTAL_INV_SPEND
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , PO_CURRENCY
      , AVG_INV_PRICE
      , SPEND_VOLUME
      , PO_ITEM_UOM
      , ORDER_UNIT_PRICE
      , ORDER_UNIT_PRICE_USD
      , PO_RECEIPT_UOM
      , SPEND_AMOUNT_LOCAL_CURRENCY
      , PO_LINE_ELIKZ
      , LOCAL_CURRENCY
      , SPEND_USD
      , USD_PO_ITEM_PRICE
      , OPCO_CATEGORY
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , CONSIGNMENT_IND
      , PURCHASING_ORG_BK
      , PO_HEADER_DEL_IND
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , PURCHASING_RECORD_BK
      , SUPPLIER_SITE_BK
      , PO_HEADER_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , BKCC
      , REC_SRC
      , BUSINESS_UNIT
    FROM LOGIC_ttgp
)

, RENAME_tte21 as (
    SELECT
        PO_HEADER_ID
      , PO_NUMBER
      , PO_LINE_NUMBER
      , MATERIAL_DOCUMENT_NUMBER
      , MATERIAL_DOCUMENT_ITEM
      , TRANSACTION_ID
      , RELEASE_NUMBER
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , COUNTRY_OF_ORIGIN
      , POSTING_DATE
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO
      , PO_CREATION_DATE
      , CATEGORY_CD
      , CATEGORY_DESC
      , HDR_BUYER_CODE
      , ORDER_QTY
      , TOTAL_RCPT_QTY
      , TOTAL_RCPT_SPEND
      , TOTAL_INV_QTY
      , TOTAL_INV_SPEND
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , PO_CURRENCY
      , AVG_INV_PRICE
      , SPEND_VOLUME
      , PO_ITEM_UOM
      , ORDER_UNIT_PRICE
      , ORDER_UNIT_PRICE_USD
      , PO_RECEIPT_UOM
      , SPEND_AMOUNT_LOCAL_CURRENCY
      , PO_LINE_ELIKZ
      , LOCAL_CURRENCY
      , SPEND_USD
      , USD_PO_ITEM_PRICE
      , OPCO_CATEGORY
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , CONSIGNMENT_IND
      , PURCHASING_ORG_BK
      , PO_HEADER_DEL_IND
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , PURCHASING_RECORD_BK
      , SUPPLIER_SITE_BK
      , PO_HEADER_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , BKCC
      , REC_SRC
      , BUSINESS_UNIT
    FROM LOGIC_tte21
)

, RENAME_fib as (
    SELECT
        PO_HEADER_ID
      , PO_NUMBER
      , PO_LINE_NUMBER
      , MATERIAL_DOCUMENT_NUMBER
      , MATERIAL_DOCUMENT_ITEM
      , TRANSACTION_ID
      , RELEASE_NUMBER
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , COUNTRY_OF_ORIGIN
      , POSTING_DATE
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO
      , PO_CREATION_DATE
      , CATEGORY_CD
      , CATEGORY_DESC
      , HDR_BUYER_CODE
      , ORDER_QTY
      , TOTAL_RCPT_QTY
      , TOTAL_RCPT_SPEND
      , TOTAL_INV_QTY
      , TOTAL_INV_SPEND
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , PO_CURRENCY
      , AVG_INV_PRICE
      , SPEND_VOLUME
      , PO_ITEM_UOM
      , ORDER_UNIT_PRICE
      , ORDER_UNIT_PRICE_USD
      , PO_RECEIPT_UOM
      , SPEND_AMOUNT_LOCAL_CURRENCY
      , PO_LINE_ELIKZ
      , LOCAL_CURRENCY
      , SPEND_USD
      , USD_PO_ITEM_PRICE
      , OPCO_CATEGORY
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , CONSIGNMENT_IND
      , PURCHASING_ORG_BK
      , PO_HEADER_DEL_IND
      , SUPPLIER_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , PURCHASING_RECORD_BK
      , SUPPLIER_SITE_BK
      , PO_HEADER_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , BKCC
      , REC_SRC
      , BUSINESS_UNIT
    FROM LOGIC_fib
)
---- FILTER LAYER ----

, FILTER_winn as (
    SELECT *
    FROM RENAME_winn
)

, FILTER_tmlc as (
    SELECT *
    FROM RENAME_tmlc
)

, FILTER_lrsn as (
    SELECT *
    FROM RENAME_lrsn
)

, FILTER_emtk as (
    SELECT *
    FROM RENAME_emtk
)

, FILTER_ttgp as (
    SELECT *
    FROM RENAME_ttgp
)

, FILTER_tte21 as (
    SELECT *
    FROM RENAME_tte21
)

, FILTER_fib as (
    SELECT *
    FROM RENAME_fib
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_winn
    UNION ALL
    SELECT * FROM FILTER_tmlc
    UNION ALL
    SELECT * FROM FILTER_lrsn
    UNION ALL
    SELECT * FROM FILTER_emtk
    UNION ALL
    SELECT * FROM FILTER_ttgp
    UNION ALL
    SELECT * FROM FILTER_tte21
    UNION ALL
    SELECT * FROM FILTER_fib
)

---- FINAL LAYER ----
SELECT
          ROW_NUMBER() OVER(ORDER BY 1)                                as SEQ_ID
        , CURRENT_TIMESTAMP                                            as SNAPSHOT_DTS
        ,  CASE
              WHEN NULLIF(TRIM(ITEM_BK), '') IS NOT NULL
                   AND (UPPER(CATEGORY_CD) NOT IN ('BILLET', 'CHEMICALS', 'DIES', 'PAINT', 'PACKAGING', 'S100', 'S200', '9990', '9999') OR CATEGORY_CD IS NULL) -- The OR CATEGORY_CD IS NULL clause means the category exclusion list is never applied to winn, tmlc, emtk, ttgp, tte21, or fib. Because Only lrsn (PeopleSoft) passes through a real CATEGORY_CD and the other 6 sources hardcode it to null. so make sure this filter is correct.
                   AND (PLANT_BK IS NULL OR UPPER(PLANT_BK) NOT IN ('DROPSHIP', 'MERCHANDISE')) 
              THEN 'DIRECT'
              ELSE 'INDIRECT'
          END as SPEND_TYPE_FLAG
        , PO_HEADER_ID
        , PO_NUMBER
        , PO_LINE_NUMBER
        , MATERIAL_DOCUMENT_NUMBER
        , MATERIAL_DOCUMENT_ITEM
        , TRANSACTION_ID
        , RELEASE_NUMBER
        , SUPPLIER_NUMBER_PARENT
        , SUPPLIER_NAME_PARENT
        , SUPPLIER_NUMBER_CHILD
        , SUPPLIER_NAME_CHILD
        , PAYMENT_TERMS
        , DOCUMENT_TYPE
        , COUNTRY_OF_ORIGIN
        , POSTING_DATE
        , CAL_YEAR
        , CAL_MONTH
        , DRVD_OPCO
        , PO_CREATION_DATE
        , CATEGORY_CD
        , CATEGORY_DESC
        , HDR_BUYER_CODE
        , ORDER_QTY
        , TOTAL_RCPT_QTY
        , TOTAL_RCPT_SPEND
        , TOTAL_INV_QTY
        , TOTAL_INV_SPEND
        , RECEIPT_QTY
        , RECEIPT_SPEND
        , PO_CURRENCY
        , AVG_INV_PRICE
        , SPEND_VOLUME
        , PO_ITEM_UOM
        , ORDER_UNIT_PRICE
        , ORDER_UNIT_PRICE_USD
        , PO_RECEIPT_UOM
        , SPEND_AMOUNT_LOCAL_CURRENCY
        , PO_LINE_ELIKZ
        , LOCAL_CURRENCY
        , SPEND_USD
        , USD_PO_ITEM_PRICE
        , OPCO_CATEGORY
        , DIRECTOR_NAME
        , CATEGORY_LEADER_NAME
        , FBIN_CATEGORY_I
        , FBIN_CATEGORY_II
        , FBIN_CATEGORY_III
        , CONSIGNMENT_IND
        , PURCHASING_ORG_BK
        , PO_HEADER_DEL_IND
        , SUPPLIER_BK
        , ITEM_BK
        , PLANT_BK
        , LEGAL_ENTITY_BK
        , PURCHASING_RECORD_BK
        , SUPPLIER_SITE_BK
        , PO_HEADER_HK
        , ITEM_HK
        , SUPPLIER_HK
        , PLANT_HK
        , LEGAL_ENTITY_HK
        , PURCHASING_RECORD_HK
        , PURCHASING_ORG_HK
        , BKCC
        , REC_SRC
        , BUSINESS_UNIT
FROM JOIN_RESULT
/* Keeping last 10 years of historical data */
where (TO_CHAR(PO_CREATION_DATE, 'YYYYMMDD')::INTEGER >= 20150101)

---- SRC LAYER ----
WITH
SRC_pb             as ( SELECT BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_CD, CATEGORY_DESC, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, DOCUMENT_TYPE, DRVD_OPCO, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, ITEM_BK, ITEM_HK, PAYMENT_TERMS, PLANT_BK, PLANT_HK, POSTING_DATE, PO_HEADER_DEL_IND, PO_ITEM_UOM, RECEIPT_QTY, RECEIPT_SPEND, REC_SRC, SPEND_TYPE_FLAG, SPEND_USD, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT FROM {{ ref('pb_global_spend_detail') }} as SRC  )

/*
SRC_pb             as ( SELECT * FROM BUS_VAULT.pb_global_spend_detail )
*/
---- LOGIC LAYER ----

, LOGIC_pb as (
    SELECT
        SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , CATEGORY_CD
      , CATEGORY_DESC
      , DOCUMENT_TYPE
      , CONCAT_WS('|', COALESCE(DRVD_OPCO, ''), COALESCE(ITEM_BK, '')) as                                          OPCO_ITEM
      , COUNTRY_OF_ORIGIN
      , CAL_YEAR
      , CAL_MONTH
      , DRVD_OPCO                                                    as                                               OPCO
      , TO_CHAR(POSTING_DATE, 'YYYYMMDD')::INTEGER                   as                                   POSTING_DATE_KEY
      , PO_ITEM_UOM                                                  as                                                UOM
      , BUSINESS_UNIT
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , ITEM_BK
      , PLANT_BK
      , TO_CHAR(POSTING_DATE, 'YYYYMMDD')::INTEGER                   as                             POSTING_DATE__YYYYMMDD
      , ITEM_HK
      , PLANT_HK
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , SPEND_USD
      , BKCC
      , REC_SRC
      , POSTING_DATE
      , PO_HEADER_DEL_IND
      , SPEND_TYPE_FLAG
    FROM SRC_pb
)
---- RENAME LAYER ----

, RENAME_pb as (
    SELECT
        SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , CATEGORY_CD
      , CATEGORY_DESC
      , DOCUMENT_TYPE
      , OPCO_ITEM
      , COUNTRY_OF_ORIGIN
      , CAL_YEAR
      , CAL_MONTH
      , OPCO
      , POSTING_DATE_KEY
      , UOM
      , BUSINESS_UNIT
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , ITEM_BK
      , PLANT_BK
      , POSTING_DATE__YYYYMMDD
      , ITEM_HK
      , PLANT_HK
      , RECEIPT_QTY
      , RECEIPT_SPEND
      , SPEND_USD
      , BKCC
      , REC_SRC
      , POSTING_DATE
      , PO_HEADER_DEL_IND
      , SPEND_TYPE_FLAG
    FROM LOGIC_pb
)
---- FILTER LAYER ----

, FILTER_pb as (
    SELECT *
    FROM RENAME_pb
    WHERE PO_HEADER_DEL_IND ='N' 
    /* This filter is to Exclude the Indirect spend */
    and SPEND_TYPE_FLAG = 'DIRECT'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_pb
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_NUMBER_PARENT
        , SUPPLIER_NAME_PARENT
        , SUPPLIER_NUMBER_CHILD
        , SUPPLIER_NAME_CHILD
        , PAYMENT_TERMS
        , CATEGORY_CD
        , CATEGORY_DESC
        , DOCUMENT_TYPE
        , OPCO_ITEM
        , COUNTRY_OF_ORIGIN
        , CAL_YEAR
        , CAL_MONTH
        , OPCO
        , POSTING_DATE_KEY
        , UOM
        , SUM(RECEIPT_QTY)                                             as RECEIPT_QTY
        , SUM(RECEIPT_SPEND)                                           as RECEIPT_SPEND
        , SUM(SPEND_USD)                                               as SPEND_USD
        , BUSINESS_UNIT
        , DIRECTOR_NAME
        , CATEGORY_LEADER_NAME
        , FBIN_CATEGORY_I
        , FBIN_CATEGORY_II
        , FBIN_CATEGORY_III
        , ITEM_BK
        , PLANT_BK
        , POSTING_DATE__YYYYMMDD
        , ITEM_HK
        , PLANT_HK
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
GROUP BY ALL
/* Descriptive Attributes are also now part of the fact */
---- SRC LAYER ----
WITH
SRC_pb             as ( SELECT BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, DOCUMENT_TYPE, DRVD_OPCO, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, ITEM_BK, ITEM_HK, LEGAL_ENTITY_BK, NET_PRICE, OPCO_CATEGORY, OPCO_ITEM, ORDER_QTY, PAYMENT_TERMS, PLANT_BK, PO_ITEM_UOM, RECEIVED_QTY, REC_SRC, SCHEDULE_LINE_DELIVERY_DATE, SCHEDULE_LINE_DELIVERY_DATE_BK, SOURCE, SPEND, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, VOLUME FROM {{ ref('pb_open_po_lines_spend') }} as SRC  )

/*
SRC_pb             as ( SELECT * FROM BUS_VAULT.pb_open_po_lines_spend )
*/
---- LOGIC LAYER ----

, LOGIC_pb as (
    SELECT
        SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , OPCO_ITEM
      , COUNTRY_OF_ORIGIN
      , CAL_YEAR
      , CAL_MONTH
      , TO_CHAR(SCHEDULE_LINE_DELIVERY_DATE, 'YYYYMMDD')::INTEGER    as                    SCHEDULE_LINE_DELIVERY_DATE_KEY
      , SCHEDULE_LINE_DELIVERY_DATE
      , DRVD_OPCO                                                    as                                               OPCO
      , PO_ITEM_UOM
      , BUSINESS_UNIT
      , OPCO_CATEGORY
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , SOURCE
      , TO_CHAR(SCHEDULE_LINE_DELIVERY_DATE_BK, 'YYYYMMDD')::INTEGER as              SCHEDULE_LINE_DELIVERY_DATE__YYYYMMDD
      , SCHEDULE_LINE_DELIVERY_DATE_BK
      , ITEM_HK
      , REC_SRC
      , BKCC
      , NET_PRICE
      , ORDER_QTY
      , RECEIVED_QTY
      , VOLUME
      , SPEND
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
      , DOCUMENT_TYPE
      , OPCO_ITEM
      , COUNTRY_OF_ORIGIN
      , CAL_YEAR
      , CAL_MONTH
      , SCHEDULE_LINE_DELIVERY_DATE_KEY
      , SCHEDULE_LINE_DELIVERY_DATE
      , OPCO
      , PO_ITEM_UOM
      , BUSINESS_UNIT
      , OPCO_CATEGORY
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , SOURCE
      , SCHEDULE_LINE_DELIVERY_DATE__YYYYMMDD
      , SCHEDULE_LINE_DELIVERY_DATE_BK
      , ITEM_HK
      , REC_SRC
      , BKCC
      , NET_PRICE
      , ORDER_QTY
      , RECEIVED_QTY
      , VOLUME
      , SPEND
    FROM LOGIC_pb
)
---- FILTER LAYER ----

, FILTER_pb as (
    SELECT *
    FROM RENAME_pb
    WHERE /* This filter is to Exclude the Indirect spend */ 
not NULLIF(item_bk, '') is null
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
        , DOCUMENT_TYPE
        , OPCO_ITEM
        , COUNTRY_OF_ORIGIN
        , CAL_YEAR
        , CAL_MONTH
        , SCHEDULE_LINE_DELIVERY_DATE_KEY
        , OPCO
        , PO_ITEM_UOM
        , SUM(NET_PRICE)::NUMBER(23,4)                                 as NET_PRICE
        , SUM(ORDER_QTY)::NUMBER(32,2)                                 as ORDER_QTY
        , SUM(RECEIVED_QTY)::NUMBER(32,2)                              as RECEIVED_QTY
        , SUM(VOLUME)::NUMBER(32,2)                                    as VOLUME
        , SUM(SPEND)::NUMBER(32,2)                                     as SPEND
        , BUSINESS_UNIT
        , OPCO_CATEGORY
        , CATEGORY_LEADER_NAME
        , DIRECTOR_NAME
        , FBIN_CATEGORY_I
        , FBIN_CATEGORY_II
        , FBIN_CATEGORY_III
        , ITEM_BK
        , PLANT_BK
        , LEGAL_ENTITY_BK
        , SOURCE
        , SCHEDULE_LINE_DELIVERY_DATE__YYYYMMDD
        , ITEM_HK
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
GROUP BY ALL
/* Descriptive Attributes are also now part of the fact */
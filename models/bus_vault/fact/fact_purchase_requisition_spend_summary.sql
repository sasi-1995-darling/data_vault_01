---- SRC LAYER ----
WITH
SRC_pb             as ( SELECT * FROM {{ ref('pb_purchase_requisition_spend_detail') }} as SRC  )

/*
SRC_pb             as ( SELECT * FROM BUS_VAULT.pb_purchase_requisition_spend_detail )
*/
---- LOGIC LAYER ----

, LOGIC_pb as (
    SELECT
        SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , DOCUMENT_TYPE
      , OPCO_ITEM
      , COUNTRY_OF_ORIGIN
      , OPCO
      , UOM
      , BUSINESS_UNIT
      , OPCO_CATEGORY
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , ITEM_BK
      , PLANT_BK
      , SOURCE
      , ITEM_DELIVERY_DATE_BK
      , ITEM_HK
      , PLANT_HK
      , SUPPLIER_HK
      , REC_SRC
      , BKCC
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
      , DOCUMENT_TYPE
      , OPCO_ITEM
      , COUNTRY_OF_ORIGIN
      , OPCO
      , UOM
      , BUSINESS_UNIT
      , OPCO_CATEGORY
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , ITEM_BK
      , PLANT_BK
      , SOURCE
      , ITEM_DELIVERY_DATE_BK
      , ITEM_HK
      , PLANT_HK
      , SUPPLIER_HK
      , REC_SRC
      , BKCC
      , VOLUME
      , SPEND
    FROM LOGIC_pb
)
---- FILTER LAYER ----

, FILTER_pb as (
    SELECT *
    FROM RENAME_pb
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
        , DOCUMENT_TYPE
        , OPCO_ITEM
        , COUNTRY_OF_ORIGIN
        , OPCO
        , SUM(VOLUME)::NUMBER(32,2)                                    as VOLUME
        , SUM(SPEND)::NUMBER(32,2)                                     as SPEND
        , UOM
        , BUSINESS_UNIT
        , OPCO_CATEGORY
        , CATEGORY_LEADER_NAME
        , DIRECTOR_NAME
        , FBIN_CATEGORY_I
        , FBIN_CATEGORY_II
        , FBIN_CATEGORY_III
        , ITEM_BK
        , PLANT_BK
        , SOURCE
        , ITEM_DELIVERY_DATE_BK
        , ITEM_HK
        , PLANT_HK
        , SUPPLIER_HK
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
GROUP BY ALL
/* Descriptive Attributes are also now part of the fact */
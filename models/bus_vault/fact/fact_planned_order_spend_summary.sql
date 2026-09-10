---- SRC LAYER ----
WITH
SRC_pb             as ( SELECT BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, DOCUMENT_TYPE, DRVD_OPCO, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, ITEM_BK, ITEM_HK, OPCO_CATEGORY, OPCO_ITEM, PLANNED_ORDER_FINISH_DATE, PLANNED_ORDER_FINISH_DATE_BK, PLANT_BK, PLANT_HK, REC_SRC, SOURCE, SPEND, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, UOM, VOLUME FROM {{ ref('pb_planned_order_spend_detail') }} as SRC  )

/*
SRC_pb             as ( SELECT * FROM BUS_VAULT.pb_planned_order_spend_detail )
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
      , CAL_YEAR
      , CAL_MONTH
      , PLANNED_ORDER_FINISH_DATE
      , TO_CHAR(PLANNED_ORDER_FINISH_DATE, 'YYYYMMDD')::INTEGER      as                      PLANNED_ORDER_FINISH_DATE_KEY
      , DRVD_OPCO                                                    as                                               OPCO
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
      , PLANNED_ORDER_FINISH_DATE_BK::INTEGER                        as                 PLANNED_ORDER_FINISH_DATE_YYYYMMDD
      , ITEM_HK
      , PLANT_HK
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
      , CAL_YEAR
      , CAL_MONTH
      , PLANNED_ORDER_FINISH_DATE
      , PLANNED_ORDER_FINISH_DATE_KEY
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
      , PLANNED_ORDER_FINISH_DATE_YYYYMMDD
      , ITEM_HK
      , PLANT_HK
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
        , CAL_YEAR
        , CAL_MONTH
        , PLANNED_ORDER_FINISH_DATE_KEY
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
        , PLANNED_ORDER_FINISH_DATE_YYYYMMDD
        , ITEM_HK
        , PLANT_HK
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
GROUP BY ALL
/* Descriptive Attributes are also now part of the fact */
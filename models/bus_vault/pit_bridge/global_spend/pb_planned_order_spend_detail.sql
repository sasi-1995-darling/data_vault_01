---- SRC LAYER ----
WITH
SRC_winn           as ( SELECT BASE_UOM, NET_PRICE, PRICE_PER_UNIT, SPEND, BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, DOCUMENT_TYPE, DRVD_OPCO, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, ITEM_BK, ITEM_HK, OPCO_CATEGORY, OPCO_ITEM, PLANNED_ORDER_BK, PLANNED_ORDER_FINISH_DATE, PLANNED_ORDER_FINISH_DATE_BK, PLANNED_ORDER_HK, PLANT_BK, PLANT_HK, PURCHASING_ORG_HK, PURCHASING_RECORD_HK, REC_SRC, SOURCE, SUPPLIER_HK, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, UOM, UOM_D, UOM_N, VOLUME FROM {{ ref('stg_pb_planned_order_spend__winn_sap') }} as SRC  ),
SRC_ml             as ( SELECT BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, SPEND, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, ITEM_BK, ITEM_HK, OPCO_CATEGORY, OPCO_ITEM, PLANNED_ORDER_BK, PLANNED_ORDER_FINISH_DATE, PLANNED_ORDER_FINISH_DATE_BK, PLANNED_ORDER_HK, PLANT_BK, PLANT_HK, PURCHASING_ORG_HK, PURCHASING_RECORD_HK, REC_SRC, SOURCE, SUPPLIER_HK, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, UOM, VOLUME FROM {{ ref('stg_pb_planned_order_spend__ml_ascp') }} as SRC  )

/*
SRC_winn           as ( SELECT * FROM BUS_VAULT.stg_pb_planned_order_spend__winn_sap )
SRC_ml             as ( SELECT * FROM BUS_VAULT.stg_pb_planned_order_spend__ml_ascp )
*/
---- LOGIC LAYER ----

, LOGIC_winn as (
    SELECT
        PLANNED_ORDER_HK
      , PLANNED_ORDER_BK
      , PLANNED_ORDER_FINISH_DATE
      , CAL_YEAR
      , CAL_MONTH
      , VOLUME
      , UOM
      , UOM_N
      , UOM_D
      , BASE_UOM
      , COALESCE(NET_PRICE, 0)                                       as                                          NET_PRICE
      , COALESCE(PRICE_PER_UNIT, 0)                                  as                                     PRICE_PER_UNIT
      , COALESCE(SPEND, 0)::NUMBER(32,2)                             as                                              SPEND
      , DRVD_OPCO
      , OPCO_ITEM
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , COUNTRY_OF_ORIGIN
      , OPCO_CATEGORY
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , DOCUMENT_TYPE
      , ITEM_BK
      , PLANT_BK
      , PLANNED_ORDER_FINISH_DATE_BK
      , SUPPLIER_HK
      , ITEM_HK
      , PLANT_HK
      , PURCHASING_ORG_HK
      , PURCHASING_RECORD_HK
      , REC_SRC
      , BKCC
      , SOURCE
      , BUSINESS_UNIT
    FROM SRC_winn
)

, LOGIC_ml as (
    SELECT
        PLANNED_ORDER_HK
      , PLANNED_ORDER_BK
      , PLANNED_ORDER_FINISH_DATE
      , CAL_YEAR
      , CAL_MONTH
      , VOLUME
      , UOM
      , NULL                                                         as                                              UOM_N
      , NULL                                                         as                                              UOM_D
      , NULL                                                         as                                           BASE_UOM
      , 0                                                            as                                          NET_PRICE
      , 0                                                            as                                     PRICE_PER_UNIT
      , COALESCE(SPEND, 0)::NUMBER(32,2)                             as                                              SPEND
      , OPCO_CATEGORY                                                as                                          DRVD_OPCO
      , OPCO_ITEM
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , COUNTRY_OF_ORIGIN
      , OPCO_CATEGORY
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , NULL                                                         as                                      DOCUMENT_TYPE
      , ITEM_BK
      , PLANT_BK
      , PLANNED_ORDER_FINISH_DATE_BK
      , SUPPLIER_HK
      , ITEM_HK
      , PLANT_HK
      , PURCHASING_ORG_HK
      , PURCHASING_RECORD_HK
      , REC_SRC
      , BKCC
      , SOURCE
      , BUSINESS_UNIT
    FROM SRC_ml
)
---- RENAME LAYER ----

, RENAME_winn as (
    SELECT
        PLANNED_ORDER_HK
      , PLANNED_ORDER_BK
      , PLANNED_ORDER_FINISH_DATE
      , CAL_YEAR
      , CAL_MONTH
      , VOLUME
      , UOM
      , UOM_N
      , UOM_D
      , BASE_UOM
      , NET_PRICE
      , PRICE_PER_UNIT
      , SPEND
      , DRVD_OPCO
      , OPCO_ITEM
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , COUNTRY_OF_ORIGIN
      , OPCO_CATEGORY
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , DOCUMENT_TYPE
      , ITEM_BK
      , PLANT_BK
      , PLANNED_ORDER_FINISH_DATE_BK
      , SUPPLIER_HK
      , ITEM_HK
      , PLANT_HK
      , PURCHASING_ORG_HK
      , PURCHASING_RECORD_HK
      , REC_SRC
      , BKCC
      , SOURCE
      , BUSINESS_UNIT
    FROM LOGIC_winn
)

, RENAME_ml as (
    SELECT
        PLANNED_ORDER_HK
      , PLANNED_ORDER_BK
      , PLANNED_ORDER_FINISH_DATE
      , CAL_YEAR
      , CAL_MONTH
      , VOLUME
      , UOM
      , UOM_N
      , UOM_D
      , BASE_UOM
      , NET_PRICE
      , PRICE_PER_UNIT
      , SPEND
      , DRVD_OPCO
      , OPCO_ITEM
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , COUNTRY_OF_ORIGIN
      , OPCO_CATEGORY
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , DOCUMENT_TYPE
      , ITEM_BK
      , PLANT_BK
      , PLANNED_ORDER_FINISH_DATE_BK
      , SUPPLIER_HK
      , ITEM_HK
      , PLANT_HK
      , PURCHASING_ORG_HK
      , PURCHASING_RECORD_HK
      , REC_SRC
      , BKCC
      , SOURCE
      , BUSINESS_UNIT
    FROM LOGIC_ml
)
---- FILTER LAYER ----

, FILTER_winn as (
    SELECT *
    FROM RENAME_winn
)

, FILTER_ml as (
    SELECT *
    FROM RENAME_ml
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_winn
    UNION ALL
    SELECT * FROM FILTER_ml
)

---- FINAL LAYER ----
SELECT
          ROW_NUMBER() OVER(ORDER BY 1)                                as SEQ_ID
        , CURRENT_TIMESTAMP                                            as SNAPSHOT_DTS
        , PLANNED_ORDER_HK
        , PLANNED_ORDER_BK
        , PLANNED_ORDER_FINISH_DATE
        , CAL_YEAR
        , CAL_MONTH
        , VOLUME
        , UOM
        , UOM_N
        , UOM_D
        , BASE_UOM
        , NET_PRICE
        , PRICE_PER_UNIT
        , SPEND
        , DRVD_OPCO
        , OPCO_ITEM
        , SUPPLIER_NUMBER_PARENT
        , SUPPLIER_NAME_PARENT
        , SUPPLIER_NUMBER_CHILD
        , SUPPLIER_NAME_CHILD
        , COUNTRY_OF_ORIGIN
        , OPCO_CATEGORY
        , CATEGORY_LEADER_NAME
        , DIRECTOR_NAME
        , FBIN_CATEGORY_I
        , FBIN_CATEGORY_II
        , FBIN_CATEGORY_III
        , DOCUMENT_TYPE
        , ITEM_BK
        , PLANT_BK
        , PLANNED_ORDER_FINISH_DATE_BK
        , SUPPLIER_HK
        , ITEM_HK
        , PLANT_HK
        , PURCHASING_ORG_HK
        , PURCHASING_RECORD_HK
        , REC_SRC
        , BKCC
        , SOURCE
        , BUSINESS_UNIT
FROM JOIN_RESULT

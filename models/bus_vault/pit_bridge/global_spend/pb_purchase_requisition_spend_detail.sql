---- SRC LAYER ----
WITH
SRC_winn           as ( SELECT * FROM {{ ref('stg_pb_purchase_requisition_spend__winn_sap') }} as SRC  ),
SRC_ml             as ( SELECT * FROM {{ ref('stg_pb_purchase_requisition_spend__ml_ascp') }} as SRC  )

/*
SRC_winn           as ( SELECT * FROM BUS_VAULT.stg_pb_purchase_requisition_spend__winn_sap )
, SRC_ml             as ( SELECT * FROM BUS_VAULT.stg_pb_purchase_requisition_spend__ml_ascp )
*/
---- LOGIC LAYER ----

, LOGIC_winn as (
    SELECT
        PURCHASE_REQUISITION_HK
      , PURCHASE_REQUISITION_NUMBER
      , PURCHASE_REQUISITION_ITEM_NUMBER
      , QUANTITY_BASE_UNIT
      , BASE_UOM
      , QUANTITY_PO_UNIT                                             as                                             VOLUME
      , UOM
      , UOM_N
      , UOM_D
      , COALESCE(NET_PRICE, 0)                                       as                                          NET_PRICE
      , PRICE_UNIT
      , COALESCE(PRICE_PER_PO_UNIT, 0)                               as                                  PRICE_PER_PO_UNIT
      , COALESCE(SPEND, 0)::NUMBER(32,2)                             as                                              SPEND
      , OPCO
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
      , WAERS                                                        as                                      CURRENCY_CODE
      , ITEM_BK
      , PLANT_BK
      , ITEM_DELIVERY_DATE_BK
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
        PURCHASE_REQUISITION_HK
      , PURCHASE_REQUISITION_NUMBER
      , PURCHASE_REQUISITION_ITEM_NUMBER
      , NULL                                                         as                                 QUANTITY_BASE_UNIT
      , NULL                                                         as                                           BASE_UOM
      , QUANTITY_PO_UNIT                                             as                                             VOLUME
      , UOM
      , NULL                                                         as                                              UOM_N
      , NULL                                                         as                                              UOM_D
      , COALESCE(NET_PRICE, 0)                                       as                                          NET_PRICE
      , '1'::NUMBER                                                  as                                         PRICE_UNIT
      , NULL                                                         as                                  PRICE_PER_PO_UNIT
      , COALESCE(SPEND, 0)::NUMBER(32,2)                             as                                              SPEND
      , OPCO_CATEGORY                                                as                                               OPCO
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
      , NULL                                                         as                                      CURRENCY_CODE
      , ITEM_BK
      , PLANT_BK
      , ITEM_DELIVERY_DATE_BK
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
        PURCHASE_REQUISITION_HK
      , PURCHASE_REQUISITION_NUMBER
      , PURCHASE_REQUISITION_ITEM_NUMBER
      , QUANTITY_BASE_UNIT
      , BASE_UOM
      , VOLUME
      , UOM
      , UOM_N
      , UOM_D
      , NET_PRICE
      , PRICE_UNIT
      , PRICE_PER_PO_UNIT
      , SPEND
      , OPCO
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
      , CURRENCY_CODE
      , ITEM_BK
      , PLANT_BK
      , ITEM_DELIVERY_DATE_BK
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
        PURCHASE_REQUISITION_HK
      , PURCHASE_REQUISITION_NUMBER
      , PURCHASE_REQUISITION_ITEM_NUMBER
      , QUANTITY_BASE_UNIT
      , BASE_UOM
      , VOLUME
      , UOM
      , UOM_N
      , UOM_D
      , NET_PRICE
      , PRICE_UNIT
      , PRICE_PER_PO_UNIT
      , SPEND
      , OPCO
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
      , CURRENCY_CODE
      , ITEM_BK
      , PLANT_BK
      , ITEM_DELIVERY_DATE_BK
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
        , PURCHASE_REQUISITION_HK
        , PURCHASE_REQUISITION_NUMBER
        , PURCHASE_REQUISITION_ITEM_NUMBER
        , QUANTITY_BASE_UNIT
        , BASE_UOM
        , VOLUME
        , UOM
        , UOM_N
        , UOM_D
        , NET_PRICE
        , PRICE_UNIT
        , PRICE_PER_PO_UNIT
        , SPEND
        , OPCO
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
        , CURRENCY_CODE
        , ITEM_BK
        , PLANT_BK
        , ITEM_DELIVERY_DATE_BK
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
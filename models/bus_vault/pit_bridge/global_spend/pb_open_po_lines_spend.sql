---- SRC LAYER ----
WITH
SRC_winn           as ( SELECT BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, DOCUMENT_TYPE, DRVD_OPCO, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, ITEM_BK, ITEM_DESCRIPTION, ITEM_HK, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, NETPR, OPCO_CATEGORY, OPCO_ITEM, ORDER_QTY, PAYMENT_TERMS, PLANT_BK, PO_CREATION_DATE, PO_HEADER_DEL_IND, PO_HEADER_HK, PO_HEADER_ID, PO_ITEM_HK, PO_ITEM_UOM, PO_LINE_NUMBER, PO_SCHEDULE_LINE_NUMBER, PURCHASING_ORG_HK, PURCHASING_RECORD_HK, RECEIVED_QTY, REC_SRC, SCHEDULE_LINE_DELIVERY_DATE, SOURCE, SPEND, SUPPLIER_HK, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, VOLUME FROM {{ ref('stg_pb_open_po_lines_spend__winn_sap') }} as SRC  ),
SRC_ml             as ( SELECT BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, CREATION_DATE, DIRECTOR_NAME, DOCUMENT_TYPE, DRVD_OPCO, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, ITEM_BK, ITEM_DESCRIPTION, ITEM_HK, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, OPCO_CATEGORY, OPCO_ITEM, ORDER_QTY, ORDER_NUMBER, PAYMENT_TERMS, PLANT_BK, PO_CREATION_DATE, PO_HEADER_DEL_IND, PO_HEADER_HK, PO_HEADER_ID, PO_ITEM_HK, PO_ITEM_UOM, PO_LINE_NUMBER, PO_SCHEDULE_LINE_NUMBER, PURCHASING_ORG_HK, PURCHASING_RECORD_HK, REC_SRC, SCHEDULE_LINE_DELIVERY_DATE, SCHEDULE_LINE_DELIVERY_DATE_BK, SOURCE, SPEND, STANDARD_COST, SUPPLIER_HK, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, TRANSACTION_ID, VOLUME FROM {{ ref('stg_pb_open_po_lines_spend__ml_ascp') }} as SRC  ),
SRC_lrsn           as ( SELECT BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, DOCUMENT_TYPE, DRVD_OPCO, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, ITEM_BK, ITEM_DESCRIPTION, ITEM_HK, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, NET_PRICE, OPCO_CATEGORY, OPCO_ITEM, ORDER_QTY, PAYMENT_TERMS, PLANT_BK, PO_CREATION_DATE, PO_HEADER_DEL_IND, PO_HEADER_HK, PO_HEADER_ID, PO_ITEM_HK, PO_ITEM_UOM, PO_LINE_NUMBER, PO_SCHEDULE_LINE_NUMBER, PURCHASING_ORG_HK, PURCHASING_RECORD_HK, RECEIVED_QTY, REC_SRC, SCHEDULE_LINE_DELIVERY_DATE, SCHEDULE_LINE_DELIVERY_DATE_BK, SOURCE, SPEND, SUPPLIER_HK, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, VOLUME FROM {{ ref('stg_pb_open_po_lines_spend__lrsn_psft') }} as SRC  )

/*
SRC_winn           as ( SELECT * FROM BUS_VAULT.stg_pb_open_po_lines_spend__winn_sap )
SRC_ml             as ( SELECT * FROM BUS_VAULT.stg_pb_open_po_lines_spend__ml_ascp )
SRC_lrsn           as ( SELECT * FROM BUS_VAULT.stg_pb_open_po_lines_spend__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_winn as (
    SELECT
        /*PK is derived as HK , which is a combiantion of diverse fields from ML and WINN.*/
        md5_binary(concat(PO_HEADER_ID, '||',PO_LINE_NUMBER,'||',PO_SCHEDULE_LINE_NUMBER)) as                                         OPEN_PO_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , PO_SCHEDULE_LINE_NUMBER
      , NULL                                                         as                                 PLAN_CREATION_DATE
      , NULL                                                         as                                       ORDER_NUMBER
      , NULL                                                         as                                     TRANSACTION_ID
      , SCHEDULE_LINE_DELIVERY_DATE
      , ORDER_QTY
      , RECEIVED_QTY
      , NETPR                                                        as                                          NET_PRICE
      , VOLUME
      , SPEND
      , CAL_YEAR
      , CAL_MONTH
      , BUSINESS_UNIT
      , DRVD_OPCO
      , OPCO_ITEM
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , ITEM_DESCRIPTION
      , COUNTRY_OF_ORIGIN
      , PO_CREATION_DATE
      , PO_HEADER_DEL_IND
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , OPCO_CATEGORY
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , PO_ITEM_UOM
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , SCHEDULE_LINE_DELIVERY_DATE                                  as                     SCHEDULE_LINE_DELIVERY_DATE_BK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , REC_SRC
      , BKCC
      , SOURCE
    FROM SRC_winn
)

, LOGIC_ml as (
    SELECT
        /*PK is derived as HK , which is a combiantion of diverse fields from ML and WINN.*/
        md5_binary(concat(PO_HEADER_ID, '||',PO_LINE_NUMBER,'||',TRANSACTION_ID)) as                                         OPEN_PO_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , PO_SCHEDULE_LINE_NUMBER
      , CREATION_DATE                                                as                                 PLAN_CREATION_DATE
      , ORDER_NUMBER
      , TRANSACTION_ID
      , SCHEDULE_LINE_DELIVERY_DATE
      , COALESCE( ORDER_QTY,0)                                       as                                          ORDER_QTY
      , NULL                                                         as                                       RECEIVED_QTY
      , STANDARD_COST                                                as                                          NET_PRICE
      , VOLUME
      , SPEND
      , CAL_YEAR
      , CAL_MONTH
      , BUSINESS_UNIT
      , DRVD_OPCO
      , OPCO_ITEM
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , ITEM_DESCRIPTION
      , COUNTRY_OF_ORIGIN
      , PO_CREATION_DATE
      , PO_HEADER_DEL_IND
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , OPCO_CATEGORY
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , PO_ITEM_UOM
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , SCHEDULE_LINE_DELIVERY_DATE_BK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , REC_SRC
      , BKCC
      , SOURCE
    FROM SRC_ml
)

, LOGIC_lrsn as (
    SELECT
        /*PK is derived as HK , which is a combiantion of diverse fields from ML and WINN.*/
        md5_binary(concat(PO_HEADER_ID, '||',PO_LINE_NUMBER,'||',PO_SCHEDULE_LINE_NUMBER)) as                                         OPEN_PO_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , PO_SCHEDULE_LINE_NUMBER
      , NULL                                                         as                                 PLAN_CREATION_DATE
      , NULL                                                         as                                       ORDER_NUMBER
      , NULL                                                         as                                     TRANSACTION_ID
      , SCHEDULE_LINE_DELIVERY_DATE
      , COALESCE( ORDER_QTY,0)                                       as                                          ORDER_QTY
      , COALESCE( RECEIVED_QTY,0)                                    as                                       RECEIVED_QTY
      , NET_PRICE
      , VOLUME
      , SPEND
      , CAL_YEAR
      , CAL_MONTH
      , BUSINESS_UNIT
      , DRVD_OPCO
      , OPCO_ITEM
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , ITEM_DESCRIPTION
      , COUNTRY_OF_ORIGIN
      , PO_CREATION_DATE
      , PO_HEADER_DEL_IND
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , OPCO_CATEGORY
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , PO_ITEM_UOM
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , SCHEDULE_LINE_DELIVERY_DATE_BK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , REC_SRC
      , BKCC
      , SOURCE
    FROM SRC_lrsn
)
---- RENAME LAYER ----

, RENAME_winn as (
    SELECT
        OPEN_PO_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , PO_SCHEDULE_LINE_NUMBER
      , PLAN_CREATION_DATE
      , ORDER_NUMBER
      , TRANSACTION_ID
      , SCHEDULE_LINE_DELIVERY_DATE
      , ORDER_QTY
      , RECEIVED_QTY
      , NET_PRICE
      , VOLUME
      , SPEND
      , CAL_YEAR
      , CAL_MONTH
      , BUSINESS_UNIT
      , DRVD_OPCO
      , OPCO_ITEM
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , ITEM_DESCRIPTION
      , COUNTRY_OF_ORIGIN
      , PO_CREATION_DATE
      , PO_HEADER_DEL_IND
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , OPCO_CATEGORY
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , PO_ITEM_UOM
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , SCHEDULE_LINE_DELIVERY_DATE_BK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , REC_SRC
      , BKCC
      , SOURCE
    FROM LOGIC_winn
)

, RENAME_ml as (
    SELECT
        OPEN_PO_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , PO_SCHEDULE_LINE_NUMBER
      , PLAN_CREATION_DATE
      , ORDER_NUMBER
      , TRANSACTION_ID
      , SCHEDULE_LINE_DELIVERY_DATE
      , ORDER_QTY
      , RECEIVED_QTY
      , NET_PRICE
      , VOLUME
      , SPEND
      , CAL_YEAR
      , CAL_MONTH
      , BUSINESS_UNIT
      , DRVD_OPCO
      , OPCO_ITEM
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , ITEM_DESCRIPTION
      , COUNTRY_OF_ORIGIN
      , PO_CREATION_DATE
      , PO_HEADER_DEL_IND
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , OPCO_CATEGORY
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , PO_ITEM_UOM
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , SCHEDULE_LINE_DELIVERY_DATE_BK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , REC_SRC
      , BKCC
      , SOURCE
    FROM LOGIC_ml
)

, RENAME_lrsn as (
    SELECT
        OPEN_PO_HK
      , PO_HEADER_ID
      , PO_LINE_NUMBER
      , PO_SCHEDULE_LINE_NUMBER
      , PLAN_CREATION_DATE
      , ORDER_NUMBER
      , TRANSACTION_ID
      , SCHEDULE_LINE_DELIVERY_DATE
      , ORDER_QTY
      , RECEIVED_QTY
      , NET_PRICE
      , VOLUME
      , SPEND
      , CAL_YEAR
      , CAL_MONTH
      , BUSINESS_UNIT
      , DRVD_OPCO
      , OPCO_ITEM
      , SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , ITEM_DESCRIPTION
      , COUNTRY_OF_ORIGIN
      , PO_CREATION_DATE
      , PO_HEADER_DEL_IND
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , OPCO_CATEGORY
      , CATEGORY_LEADER_NAME
      , DIRECTOR_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , PO_ITEM_UOM
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , SCHEDULE_LINE_DELIVERY_DATE_BK
      , PO_HEADER_HK
      , PO_ITEM_HK
      , ITEM_HK
      , SUPPLIER_HK
      , LEGAL_ENTITY_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , REC_SRC
      , BKCC
      , SOURCE
    FROM LOGIC_lrsn
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

, FILTER_lrsn as (
    SELECT *
    FROM RENAME_lrsn
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_winn
    UNION ALL
    SELECT * FROM FILTER_ml
    UNION ALL
    SELECT * FROM FILTER_lrsn
)

---- FINAL LAYER ----
SELECT
          OPEN_PO_HK
        , ROW_NUMBER() OVER(ORDER BY 1)                                as SEQ_ID
        , CURRENT_TIMESTAMP                                            as SNAPSHOT_DTS
        , PO_HEADER_ID
        , PO_LINE_NUMBER
        , PO_SCHEDULE_LINE_NUMBER
        , PLAN_CREATION_DATE
        , ORDER_NUMBER
        , TRANSACTION_ID
        , SCHEDULE_LINE_DELIVERY_DATE
        , ORDER_QTY
        , RECEIVED_QTY
        , NET_PRICE
        , VOLUME
        , SPEND
        , CAL_YEAR
        , CAL_MONTH
        , BUSINESS_UNIT
        , DRVD_OPCO
        , OPCO_ITEM
        , SUPPLIER_NUMBER_PARENT
        , SUPPLIER_NAME_PARENT
        , SUPPLIER_NUMBER_CHILD
        , SUPPLIER_NAME_CHILD
        , ITEM_DESCRIPTION
        , COUNTRY_OF_ORIGIN
        , PO_CREATION_DATE
        , PO_HEADER_DEL_IND
        , PAYMENT_TERMS
        , DOCUMENT_TYPE
        , OPCO_CATEGORY
        , CATEGORY_LEADER_NAME
        , DIRECTOR_NAME
        , FBIN_CATEGORY_I
        , FBIN_CATEGORY_II
        , FBIN_CATEGORY_III
        , PO_ITEM_UOM
        , ITEM_BK
        , PLANT_BK
        , LEGAL_ENTITY_BK
        , SCHEDULE_LINE_DELIVERY_DATE_BK
        , PO_HEADER_HK
        , PO_ITEM_HK
        , ITEM_HK
        , SUPPLIER_HK
        , LEGAL_ENTITY_HK
        , PURCHASING_RECORD_HK
        , PURCHASING_ORG_HK
        , REC_SRC
        , BKCC
        , SOURCE
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_lnk_inv        as ( SELECT  CUSTOMER_HK, DELIVERY_LINE_HK, GOODS_MOVEMENT_ITEM_DOCUMENT_HK, GOODS_STORAGE_LOCATION_HK, ITEM_HK, ORDER_LINE_HK, PLANT_HK, PO_ITEM_HK, PRODUCTION_ORDER_HK, REC_SRC, SUPPLIER_HK, UOM_HK, lnk_GOODS_movement_hk, CUSTOMER_SHIP_LOCATION_HK  FROM {{ ref('lnk_goods_movement') }} as SRC  ),
SRC_lmsat_inv      as ( SELECT KZVBR ,KZZUG ,KZBEW ,SOBKZ, BNBTR, BUDAT_MKPF, BWART, CPUTM_MKPF, DMBTR, LBKUM, LNK_GOODS_MOVEMENT_HK, MENGE, SALK3, SHKZG, TCODE2_MKPF, VGART_MKPF, WAERS, XBLNR_MKPF FROM {{ ref('lmsat_goods_movement__winn_sap') }} as SRC 
                        WHERE  TRIM(COALESCE(BWART, '')) <> '' -- filtering cases without Movement Type
                        qualify 1= row_number() over(partition by LNK_GOODS_MOVEMENT_HK order by load_dts DESC) ),
SRC_hub_plant      as ( SELECT PLANT_BK, PLANT_HK, BKCC FROM {{ ref('hub_plant_v1') }} as SRC  ),
SRC_hub_item       as ( SELECT ITEM_BK, ITEM_HK FROM {{ ref('hub_item_v1') }} as SRC  ),
SRC_hub_cust       as ( SELECT CUSTOMER_BK, CUSTOMER_HK FROM {{ ref('hub_customer_v1') }} as SRC  ),
SRC_hub_gm       as ( SELECT GOODS_MOVEMENT_ITEM_DOCUMENT_BK, GOODS_MOVEMENT_ITEM_DOCUMENT_HK FROM {{ ref('hub_goods_movement_item_document') }} as SRC  ),
SRC_hub_u          as ( SELECT UOM_BK, UOM_HK FROM {{ ref('hub_uom') }} as SRC  ),
SRC_hub_ol         as ( SELECT ORDER_LINE_BK, ORDER_LINE_HK FROM {{ ref('hub_order_line') }} as SRC  ),
SRC_hub_po         as ( SELECT  PO_ITEM_HK, PO_LINE_NUMBER FROM {{ ref('hub_po_item') }} as SRC  ),
SRC_hub_prod       as ( SELECT PRODUCTION_ORDER_BK, PRODUCTION_ORDER_HK FROM {{ ref('hub_production_order') }} as SRC  ),
SRC_hub_del        as ( SELECT DELIVERY_LINE_ITEM_BK, DELIVERY_LINE_HK FROM {{ ref('hub_delivery_line') }} as SRC  ),
SRC_hub_sup        as ( SELECT SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('hub_supplier_v2') }} as SRC  ),
SRC_hub_in         as ( SELECT GOODS_STORAGE_LOCATION_BK, GOODS_STORAGE_LOCATION_HK FROM {{ ref('hub_storage_location') }} as SRC  ),
SRC_pit_sl         as ( SELECT GOODS_STORAGE_LOCATION_HK, STORAGE_LOCATION_DESCRIPTION_TEXT FROM {{ ref('pit_storage_location') }} as SRC  ) 
/*
SRC_lnk_inv        as ( SELECT * FROM RAW_VAULT.lnk_goods_movement )
SRC_lmsat_inv      as ( SELECT * FROM RAW_VAULT.lmsat_goods_movement__winn_sap )
SRC_hub_plant      as ( SELECT * FROM RAW_VAULT.hub_plant_v1 )
SRC_hub_item       as ( SELECT * FROM RAW_VAULT.hub_item_v1 )
SRC_hub_cust       as ( SELECT * FROM RAW_VAULT.hub_customer_v1 )
SRC_hub_u          as ( SELECT * FROM RAW_VAULT.hub_uom )
SRC_hub_ol         as ( SELECT * FROM RAW_VAULT.hub_order_line )
SRC_hub_po         as ( SELECT * FROM RAW_VAULT.hub_po_item )
SRC_hub_prod       as ( SELECT * FROM RAW_VAULT.hub_production_order )
SRC_hub_del        as ( SELECT * FROM RAW_VAULT.hub_delivery_line )
SRC_hub_sup        as ( SELECT * FROM RAW_VAULT.hub_supplier_v2 )
SRC_hub_in         as ( SELECT * FROM RAW_VAULT.hub_storage_location )
SRC_pit_sl         as ( SELECT * FROM RAW_VAULT.pit_storage_location )
*/

---- LOGIC LAYER ----

, LOGIC_lnk_inv as (
    SELECT
        GOODS_MOVEMENT_ITEM_DOCUMENT_HK
                                , lnk_GOODS_movement_hk
                                , PLANT_HK
                                , GOODS_STORAGE_LOCATION_HK
                                , CUSTOMER_HK
                                , UOM_HK
                                , ORDER_LINE_HK
                                , CUSTOMER_SHIP_LOCATION_HK
                                , PO_ITEM_HK
                                , PRODUCTION_ORDER_HK
                                , DELIVERY_LINE_HK
                                , SUPPLIER_HK
                                , ITEM_HK
                                , REC_SRC
    FROM SRC_lnk_inv
)

, LOGIC_lmsat_inv as (
    SELECT
        LNK_GOODS_MOVEMENT_HK                                    as                                 GOODS_MOVEMENT_KEY
      , BUDAT_MKPF::INTEGER                                                  as                    GOODS_MOVEMENT_POSTING_DATE__YYYYMMDD
      , CPUTM_MKPF                                                   as                      GOODS_MOVEMENT_POSTING_TIMESTAMP
      , XBLNR_MKPF                                                   as               GOODS_MOVEMENT_REFERENCE_DOCUMENT_ID
      , BWART                                                        as                           GOODS_MOVEMENT_TYPE_CODE
      , WAERS                                                        as                       GOODS_MOVEMENT_CURRENCY_CODE
      , VGART_MKPF                                                   as                     GOODS_MOVEMENT_EVENT_TYPE_CODE
      , TCODE2_MKPF                                                  as                    GOODS_MOVEMENT_TRANSACTION_CODE
      , SHKZG                                                        as              GOODS_MOVEMENT_DEBIT_CREDIT_INDICATOR
      , DMBTR                                                        as                       GOODS_MOVEMENT_POSTED_AMOUNT
      , BNBTR                                                        as                GOODS_MOVEMENT_DELIVERY_COST_AMOUNT
      , SALK3                                                        as   GOODS_MOVEMENT_STOCK_VALUE_BEFORE_POSTING_AMOUNT
      , LBKUM                                                        as       GOODS_MOVEMENT_STOCK_QUANTITY_BEFORE_POSTING
      , MENGE                                                        as                     GOODS_MOVEMENT_POSTED_QUANTITY
      , BUDAT_MKPF::INTEGER                                                  as                   GOODS_MOVEMENT_ENTRY_DATE__YYYYMMDD
      , CPUTM_MKPF                                                   as                     GOODS_MOVEMENT_ENTRY_TIMESTAMP      
      , KZVBR as CONSUMPTION_POSTING
      , KZZUG as RECEIPT_INDICATOR
      , KZBEW as MOVEMENT_INDICATOR
      , SOBKZ as SPECIAL_STOCK
    FROM SRC_lmsat_inv
)

, LOGIC_hub_plant as (
    SELECT
        PLANT_HK as HUB_PLANT_HK
      , PLANT_BK
      , BKCC
    FROM SRC_hub_plant
)

, LOGIC_hub_item as (
    SELECT
        ITEM_HK as HUB_ITEM_HK
      , ITEM_BK
    FROM SRC_hub_item
)

, LOGIC_hub_cust as (
    SELECT
        CUSTOMER_HK as HUB_CUSTOMER_HK
      , CUSTOMER_HK                                                  as                          HUB_CUSTOMER_SHIP_LOCATION_HK
      , CUSTOMER_BK  as CUSTOMER_SHIP_LOCATION_BK
      , CUSTOMER_BK
    FROM SRC_hub_cust
)

, LOGIC_hub_u as (
    SELECT
        UOM_HK as HUB_UOM_HK
    ,   UOM_BK
    FROM SRC_hub_u
)

, LOGIC_hub_ol as (
    SELECT
        ORDER_LINE_HK as HUB_ORDER_LINE_HK
        , ORDER_LINE_BK
    FROM SRC_hub_ol
)

, LOGIC_hub_po as (
    SELECT
        PO_ITEM_HK as HUB_PO_ITEM_HK,
        PO_LINE_NUMBER
    FROM SRC_hub_po
)

, LOGIC_hub_prod as (
    SELECT
        PRODUCTION_ORDER_HK as HUB_PRODUCTION_ORDER_HK
        , PRODUCTION_ORDER_BK
    FROM SRC_hub_prod
)

, LOGIC_hub_del as (
    SELECT
        DELIVERY_LINE_HK as HUB_DELIVERY_LINE_HK
        , DELIVERY_LINE_ITEM_BK
    FROM SRC_hub_del
)

, LOGIC_hub_sup as (
    SELECT
        SUPPLIER_HK as HUB_SUPPLIER_HK
        , SUPPLIER_BK
    FROM SRC_hub_sup
)

, LOGIC_hub_in as (
    SELECT
        GOODS_STORAGE_LOCATION_HK as HUB_GOODS_STORAGE_LOCATION_HK
        , GOODS_STORAGE_LOCATION_BK
    FROM SRC_hub_in
)


, LOGIC_pit_sl as (
    SELECT
        STORAGE_LOCATION_DESCRIPTION_TEXT
      , GOODS_STORAGE_LOCATION_HK as PIT_GOODS_STORAGE_LOCATION_HK
    FROM SRC_pit_sl
)

, LOGIC_hub_gm as (
    SELECT
        GOODS_MOVEMENT_ITEM_DOCUMENT_HK as HUB_GOODS_MOVEMENT_ITEM_DOCUMENT_HK
      , GOODS_MOVEMENT_ITEM_DOCUMENT_BK
    FROM SRC_hub_gm
)
---- RENAME LAYER ----

, RENAME_lnk_inv as (
    SELECT
        GOODS_MOVEMENT_ITEM_DOCUMENT_HK
                                , lnk_GOODS_movement_hk
                                , PLANT_HK
                                , GOODS_STORAGE_LOCATION_HK
                                , CUSTOMER_HK
                                , UOM_HK
                                , ORDER_LINE_HK
                                , CUSTOMER_SHIP_LOCATION_HK
                                , PO_ITEM_HK
                                , PRODUCTION_ORDER_HK
                                , DELIVERY_LINE_HK
                                , SUPPLIER_HK
                                , ITEM_HK
                                , REC_SRC
    FROM LOGIC_lnk_inv
)

, RENAME_pit_sl as (
    SELECT
        STORAGE_LOCATION_DESCRIPTION_TEXT
      , PIT_GOODS_STORAGE_LOCATION_HK
    FROM LOGIC_pit_sl
)

, RENAME_lmsat_inv as (
    SELECT
        GOODS_MOVEMENT_KEY
      , GOODS_MOVEMENT_POSTING_DATE__YYYYMMDD
      , GOODS_MOVEMENT_POSTING_TIMESTAMP
      , GOODS_MOVEMENT_REFERENCE_DOCUMENT_ID
      , GOODS_MOVEMENT_TYPE_CODE
      , GOODS_MOVEMENT_CURRENCY_CODE
      , GOODS_MOVEMENT_EVENT_TYPE_CODE
      , GOODS_MOVEMENT_TRANSACTION_CODE
      , GOODS_MOVEMENT_DEBIT_CREDIT_INDICATOR
      , GOODS_MOVEMENT_POSTED_AMOUNT
      , GOODS_MOVEMENT_DELIVERY_COST_AMOUNT
      , GOODS_MOVEMENT_STOCK_VALUE_BEFORE_POSTING_AMOUNT
      , GOODS_MOVEMENT_STOCK_QUANTITY_BEFORE_POSTING
      , GOODS_MOVEMENT_POSTED_QUANTITY
      , GOODS_MOVEMENT_ENTRY_DATE__YYYYMMDD
      , GOODS_MOVEMENT_ENTRY_TIMESTAMP   
      , CONSUMPTION_POSTING
      , RECEIPT_INDICATOR
      , MOVEMENT_INDICATOR
      , SPECIAL_STOCK   
    FROM LOGIC_lmsat_inv
)

, RENAME_hub_plant as (
    SELECT
        HUB_PLANT_HK
        , PLANT_BK
        , BKCC
    FROM LOGIC_hub_plant
)

, RENAME_hub_in as (
    SELECT
        HUB_GOODS_STORAGE_LOCATION_HK
       ,GOODS_STORAGE_LOCATION_BK
    FROM LOGIC_hub_in
)

, RENAME_hub_cust as (
    SELECT
        HUB_CUSTOMER_HK
      , HUB_CUSTOMER_SHIP_LOCATION_HK
      , CUSTOMER_BK
      , CUSTOMER_SHIP_LOCATION_BK
    FROM LOGIC_hub_cust
)

, RENAME_hub_u as (
    SELECT
        HUB_UOM_HK
       ,UOM_BK
    FROM LOGIC_hub_u
)

, RENAME_hub_ol as (
    SELECT
        HUB_ORDER_LINE_HK
    , ORDER_LINE_BK
    FROM LOGIC_hub_ol
)

, RENAME_hub_po as (
    SELECT
        HUB_PO_ITEM_HK,
        PO_LINE_NUMBER
    FROM LOGIC_hub_po
)

, RENAME_hub_prod as (
    SELECT
        HUB_PRODUCTION_ORDER_HK
        , PRODUCTION_ORDER_BK
    FROM LOGIC_hub_prod
)

, RENAME_hub_del as (
    SELECT
        HUB_DELIVERY_LINE_HK
       , DELIVERY_LINE_ITEM_BK
    FROM LOGIC_hub_del
)

, RENAME_hub_sup as (
    SELECT
        HUB_SUPPLIER_HK
        , SUPPLIER_BK
    FROM LOGIC_hub_sup
)

, RENAME_hub_item as (
    SELECT
        HUB_ITEM_HK
        ,ITEM_BK
    FROM LOGIC_hub_item
)

, RENAME_hub_gm as (
    SELECT
        HUB_GOODS_MOVEMENT_ITEM_DOCUMENT_HK
      , GOODS_MOVEMENT_ITEM_DOCUMENT_BK
    FROM LOGIC_hub_gm
)
---- FILTER LAYER ----

, FILTER_lnk_inv as (
    SELECT *
    FROM RENAME_lnk_inv
)

, FILTER_lmsat_inv as (
    SELECT *
    FROM RENAME_lmsat_inv
)

, FILTER_hub_plant as (
    SELECT *
    FROM RENAME_hub_plant
)

, FILTER_hub_item as (
    SELECT *
    FROM RENAME_hub_item
)

, FILTER_hub_cust as (
    SELECT *
    FROM RENAME_hub_cust
)

, FILTER_hub_u as (
    SELECT *
    FROM RENAME_hub_u
)

, FILTER_hub_ol as (
    SELECT *
    FROM RENAME_hub_ol
)

, FILTER_hub_po as (
    SELECT *
    FROM RENAME_hub_po
)

, FILTER_hub_prod as (
    SELECT *
    FROM RENAME_hub_prod
)

, FILTER_hub_del as (
    SELECT *
    FROM RENAME_hub_del
)

, FILTER_hub_sup as (
    SELECT *
    FROM RENAME_hub_sup
)

, FILTER_hub_in as (
    SELECT *
    FROM RENAME_hub_in
)


, FILTER_pit_sl as (
    SELECT *
    FROM RENAME_pit_sl
)

, FILTER_hub_gm as (
    SELECT *
    FROM RENAME_hub_gm
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_lnk_inv
    INNER JOIN FILTER_lmsat_inv
        ON FILTER_lnk_inv.LNK_GOODS_MOVEMENT_HK = FILTER_lmsat_inv.GOODS_MOVEMENT_KEY
    LEFT JOIN FILTER_hub_plant
        ON FILTER_lnk_inv.PLANT_HK = FILTER_hub_plant.HUB_PLANT_HK
    LEFT JOIN FILTER_hub_item
        ON FILTER_lnk_inv.ITEM_HK = FILTER_hub_item.HUB_ITEM_HK
    LEFT JOIN FILTER_hub_cust
        ON FILTER_lnk_inv.CUSTOMER_HK = FILTER_hub_cust.HUB_CUSTOMER_HK
    LEFT JOIN FILTER_hub_gm
        ON FILTER_lnk_inv.GOODS_MOVEMENT_ITEM_DOCUMENT_HK = FILTER_hub_gm.HUB_GOODS_MOVEMENT_ITEM_DOCUMENT_HK
    LEFT JOIN FILTER_hub_u
        ON FILTER_lnk_inv.UOM_HK = FILTER_hub_u.HUB_UOM_HK
    LEFT JOIN FILTER_hub_ol
        ON FILTER_lnk_inv.ORDER_LINE_HK = FILTER_hub_ol.HUB_ORDER_LINE_HK
    LEFT JOIN FILTER_hub_po
        ON FILTER_lnk_inv.PO_ITEM_HK = FILTER_hub_po.HUB_PO_ITEM_HK
    LEFT JOIN FILTER_hub_prod
        ON FILTER_lnk_inv.PRODUCTION_ORDER_HK = FILTER_hub_prod.HUB_PRODUCTION_ORDER_HK
    LEFT JOIN FILTER_hub_del
        ON FILTER_lnk_inv.DELIVERY_LINE_HK = FILTER_hub_del.HUB_DELIVERY_LINE_HK
    LEFT JOIN FILTER_hub_sup
        ON FILTER_lnk_inv.SUPPLIER_HK = FILTER_hub_sup.HUB_SUPPLIER_HK
    LEFT JOIN FILTER_hub_in
        ON FILTER_lnk_inv.GOODS_STORAGE_LOCATION_HK = FILTER_hub_in.HUB_GOODS_STORAGE_LOCATION_HK
    LEFT JOIN FILTER_pit_sl
        ON FILTER_lnk_inv.GOODS_STORAGE_LOCATION_HK = FILTER_pit_sl.PIT_GOODS_STORAGE_LOCATION_HK
)

---- FINAL LAYER ----
SELECT
          CURRENT_TIMESTAMP as SNAPSHOT_DTS
        , 'PB_GOODS_MOVEMENT' as PB_REC_SRC
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )  as PB_LOAD_DTS
        , REC_SRC
        , BKCC
        , STORAGE_LOCATION_DESCRIPTION_TEXT
        , GOODS_MOVEMENT_ITEM_DOCUMENT_HK
        , GOODS_MOVEMENT_ITEM_DOCUMENT_BK
        , GOODS_MOVEMENT_KEY
        , GOODS_MOVEMENT_POSTING_DATE__YYYYMMDD
        , GOODS_MOVEMENT_ENTRY_DATE__YYYYMMDD
        , GOODS_MOVEMENT_REFERENCE_DOCUMENT_ID
        , GOODS_MOVEMENT_TYPE_CODE
        , GOODS_MOVEMENT_CURRENCY_CODE
        , GOODS_MOVEMENT_EVENT_TYPE_CODE
        , GOODS_MOVEMENT_TRANSACTION_CODE
        , GOODS_MOVEMENT_DEBIT_CREDIT_INDICATOR
        , GOODS_MOVEMENT_POSTED_AMOUNT
        , GOODS_MOVEMENT_DELIVERY_COST_AMOUNT
        , GOODS_MOVEMENT_STOCK_VALUE_BEFORE_POSTING_AMOUNT
        , GOODS_MOVEMENT_STOCK_QUANTITY_BEFORE_POSTING
        , GOODS_MOVEMENT_POSTED_QUANTITY
        , GOODS_MOVEMENT_POSTING_TIMESTAMP
        , GOODS_MOVEMENT_ENTRY_TIMESTAMP        
        , PLANT_HK
        , PLANT_BK
        , GOODS_STORAGE_LOCATION_HK
        , GOODS_STORAGE_LOCATION_BK
        , CUSTOMER_HK
        , CUSTOMER_BK
        , UOM_HK
        , UOM_BK
        , ORDER_LINE_HK
        , ORDER_LINE_BK
        , CUSTOMER_SHIP_LOCATION_HK
        , CUSTOMER_SHIP_LOCATION_BK
        , PO_ITEM_HK
        , PO_LINE_NUMBER
        , PRODUCTION_ORDER_HK
        , PRODUCTION_ORDER_BK
        , DELIVERY_LINE_HK
        , DELIVERY_LINE_ITEM_BK
        , SUPPLIER_HK
        , SUPPLIER_BK
        , ITEM_HK
        , ITEM_BK  
        , CONSUMPTION_POSTING
        , RECEIPT_INDICATOR
        , MOVEMENT_INDICATOR
        , SPECIAL_STOCK      
FROM JOIN_RESULT
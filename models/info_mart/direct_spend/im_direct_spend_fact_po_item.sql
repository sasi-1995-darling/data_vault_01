{{ config(alias='fact_po_item' + ('_direct_spend' if target.name not in ['dev', 'qa', 'prod'] else '')) }}

select 
        PO_HEADER_ID
        , PO_NUMBER
        , PO_LINE_NUMBER
        , SUPPLIER_BK
        , ITEM_BK
        , LEGAL_ENTITY_BK
        , PURCHASING_RECORD_BK
        , PURCHASING_ORG_BK
        , PO_CREATION_DATE__YYYYMMDD
        , PO_ITEM_LAST_UPDATE_DATE__YYYYMMDD
        , ORDER_QUANTITY
        , ORDER_UOM
        , ORDER_UNIT_PRICE
        , PO_CURRENCY_CODE
        , ORDER_UNIT_PRICE_USD
        , NET_PRICE
        , PRICE_UNIT
        , PRICE_UOM
        , NET_VALUE
        , GROSS_VALUE
        , TOTAL_PLANNED_LEAD_DAYS
        , REQUESTED_DELIVERY_DATE_EARLIEST__YYYYMMDD
        , REQUESTED_DELIVERY_DATE_LATEST__YYYYMMDD
        , GOODS_RECEIPT_PROCESSING_DAYS
        , CONVERSION_PRICE_UOM_TO_ORDER_UOM_N
        , CONVERSION_PRICE_UOM_TO_ORDER_UOM_D
        , PO_HEADER_HK
        , ITEM_HK
        , SUPPLIER_HK
        , LEGAL_ENTITY_HK
        , PO_LINE_RECEIPT_IND_HK
        , PURCHASING_RECORD_HK
        , PURCHASING_ORG_HK
        , REC_SRC
        , PO_DATE_CHANGE_REASON
        , FREIGHT_DELAY_REASON_CODE
        , TRANSPORTATION_LEAD_DAYS
        , ORIGINAL_PROMISED_DATE__YYYYMMDD
        , PROMISE_SHIP_DATE__YYYYMMDD
        , SUPPLIER_SHIP_DATE_LATEST__YYYYMMDD
        , SUPPLIER_SHIP_DATE_EARLIEST__YYYYMMDD
        , BKCC 
from {{ ref('fact_po_item') }}

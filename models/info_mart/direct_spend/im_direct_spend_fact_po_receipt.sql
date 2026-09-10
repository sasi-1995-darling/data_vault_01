{{ config(alias='fact_po_receipt' + ('_direct_spend' if target.name not in ['dev', 'qa', 'prod'] else '')) }}

select 
PO_HEADER_ID
        , PO_LINE_NUMBER
        , TRANSACTION_ID
        , MATERIAL_DOCUMENT_NUMBER
        , MATERIAL_DOCUMENT_ITEM
        , SUPPLIER_BK
        , ITEM_BK
        , PLANT_BK
        , LEGAL_ENTITY_BK
        , PO_RECEIPT_DATE__YYYYMMDD
        , PO_RECEIPT_QUANTITY
        , PO_RECEIPT_PRICE
        , PO_RECEIPT_VALUE_LOCAL
        , PO_RECEIPT_VALUE
        , PO_HEADER_HK
        , SUPPLIER_HK
        , ITEM_HK
        , PLANT_HK
        , LEGAL_ENTITY_HK
        , PO_LINE_RECEIPT_IND_HK
        , BKCC
        , REC_SRC 
        , PROMISED_DATE_LATEST__YYYYMMDD
        , PROMISED_DATE_EARLIEST__YYYYMMDD
        , NEED_BY_DATE_LATEST__YYYYMMDD
        , NEED_BY_DATE_EARLIEST__YYYYMMDD
        , ORIGINAL_PROMISED_DATE__YYYYMMDD
from {{ ref('fact_po_receipt') }}

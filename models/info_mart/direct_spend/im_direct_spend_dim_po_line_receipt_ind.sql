{{ config(alias='dim_po_line_receipt_ind' + ('_direct_spend' if target.name not in ['dev', 'qa', 'prod'] else '')) }}

select 
    PO_LINE_RECEIPT_IND_HK
    ,  PO_LINE_DEL_IND
    , GOODS_RECEIPT_IND
    , GOODS_RECEIPT_COMPLETE_IND
    , CLOSED_STATUS
    , INVOICE_RECEIPT_IND
    , ACCOUNT_ASSIGNMENT
    , ORDER_UOM
    , PURCHASE_ORDER_PRICE_UOM
    , PO_RECEIPT_TYPE
    , PO_RECEIPT_UOM
    , MOVEMENT_TYPE
    , DEBIT_CREDIT_IND
    , LOCAL_CURRENCY
    , BKCC
    , REC_SRC
from {{ ref('dim_po_line_receipt_ind') }}

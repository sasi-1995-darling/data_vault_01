{{ config(alias='dim_po_header' + ('_direct_spend' if target.name not in ['dev', 'qa', 'prod'] else '')) }}

select 
  PO_HEADER_HK
    , PO_HEADER_BK
    , PO_NUMBER
    , PO_DOCUMENT_TYPE
    , PO_HEADER_DEL_IND
    , PO_PROCESSING_STATUS
    , PO_PAYMENT_TERMS
    , INCOTERMS_1
    , INCOTERMS_2
    , PURCHASING_ORG
    , BUYER_PLANNER_CODE
    , PO_CURRENCY
    , RELEASE_DATE /* Applicable to Therma-Tru E21 only */
    , REC_SRC
    , BKCC
from {{ ref('dim_po_header') }}

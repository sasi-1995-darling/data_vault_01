{{ config(alias='fact_purchase_requisition_spend_detail' + ('_direct_spend' if target.name not in ['dev', 'qa', 'prod'] else '')) }}

SELECT
          PURCHASE_REQUISITION_NUMBER
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
        , ITEM_BK
        , PLANT_BK
        , ITEM_DELIVERY_DATE_BK
        , PURCHASE_REQUISITION_HK
        , SUPPLIER_HK
        , ITEM_HK
        , PLANT_HK
        , PURCHASING_ORG_HK
        , PURCHASING_RECORD_HK
        , SOURCE
        , BUSINESS_UNIT
        , REC_SRC
        , BKCC
from {{ ref('fact_purchase_requisition_spend_detail') }}

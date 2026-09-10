{{ config(alias='fact_planned_order_spend_detail' + ('_direct_spend' if target.name not in ['dev', 'qa', 'prod'] else '')) }}

SELECT
          PLANNED_ORDER_BK
        , PLANNED_ORDER_FINISH_DATE_KEY
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
        , PLANNED_ORDER_FINISH_DATE_YYYYMMDD
        , PLANNED_ORDER_HK
        , SUPPLIER_HK
        , ITEM_HK
        , PLANT_HK
        , PURCHASING_ORG_HK
        , PURCHASING_RECORD_HK
        , SOURCE
        , BUSINESS_UNIT
        , REC_SRC
        , BKCC
from {{ ref('fact_planned_order_spend_detail') }}

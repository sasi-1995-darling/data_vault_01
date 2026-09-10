{{ config(alias='fact_global_direct_spend_daily_summary' + ('_global_spend' if target.name not in ['dev', 'qa', 'prod'] else '')) }}

select 
          SUPPLIER_NUMBER_PARENT
        , SUPPLIER_NAME_PARENT
        , SUPPLIER_NUMBER_CHILD
        , SUPPLIER_NAME_CHILD
        , PAYMENT_TERMS
        , DOCUMENT_TYPE
        , OPCO_ITEM
        , COUNTRY_OF_ORIGIN
        , CAL_YEAR
        , CAL_MONTH
        , OPCO
        , POSTING_DATE_KEY
        , UOM
        , RECEIPT_QTY
        , RECEIPT_SPEND
        , SPEND_USD
        , BUSINESS_UNIT
        , DIRECTOR_NAME
        , CATEGORY_LEADER_NAME
        , FBIN_CATEGORY_I
        , FBIN_CATEGORY_II
        , FBIN_CATEGORY_III
        , ITEM_BK
        , PLANT_BK
        , POSTING_DATE__YYYYMMDD
        , ITEM_HK
        , PLANT_HK
        , CATEGORY_CD
        , CATEGORY_DESC
        , BKCC
        , REC_SRC
from {{ ref('fact_global_direct_spend_daily_summary') }}

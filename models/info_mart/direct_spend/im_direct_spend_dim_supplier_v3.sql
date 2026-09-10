{{ config(alias='dim_supplier_v3' + ('_direct_spend' if target.name not in ['dev', 'qa', 'prod'] else '')) }}

SELECT
      SUPPLIER_HK
        , SUPPLIER_BK
        , MDM_SUPPLIER_BK
        , MDM_GOLDEN_RECORD
        , MDM_SUPPLIER_NAME
        , MDM_SUPPLIER_ALT_NAME
        , MDM_INDUSTRY_TYPE
        , MDM_SUPPLIER_STATUS
        , MDM_ORGANIZATION_TYPE
        , MDM_INACTIVATION_DATE__YYYYMMDD
        , MDM_SOURCE_CREATION_DATE__YYYYMMDD
        , MDM_SOURCE_LAST_UPDATE_DATE__YYYYMMDD
        , MDM_IS_DELETED
        , MDM_SOURCE_PKEY
        , SUPPLIER_NUMBER
        , SUPPLIER_NAME_1
        , SUPPLIER_NAME_2
        , SUPPLIER_ALT_NAME
        , INDUSTRY_TYPE
        , SUPPLIER_TYPE
        , SUPPLIER_STATUS
        , PARENT_SUPPLIER_KEY
        , PARENT_SUPPLIER_NAME
        , ORGANIZATION_TYPE
        , INACTIVATION_DATE__YYYYMMDD
        , SOURCE_CREATION_DATE__YYYYMMDD
        , SOURCE_LAST_UPDATE_DATE__YYYYMMDD
        , IS_DELETED
        , UNIFIED_SUPPLIER_KEY
        , UNIFIED_SUPPLIER_NAME
        , REC_SRC
        , BKCC
        , MDM_REC_SRC
        , MDM_BKCC
        , UNIFIED_REC_SRC
        , UNIFIED_BKCC
from {{ ref('dim_supplier_v3') }}

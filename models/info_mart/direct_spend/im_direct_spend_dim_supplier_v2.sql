{{ config(alias='dim_supplier_v2' + ('_direct_spend' if target.name not in ['dev', 'qa', 'prod'] else '')) }}

SELECT
    SUPPLIER_HK
    , SUPPLIER_BK
    , SUPPLIER_NAME_1
    , SUPPLIER_NAME_2
    , SUPPLIER_ALT_NAME
    , INDUSTRY_TYPE
    , SUPPLIER_TYPE
    , SUPPLIER_STATUS
    , PARENT_SUPPLIER_KEY
    , PARENT_SUPPLIER_NAME
    , ORGANIZATION_TYPE
    , SUPPLIER_NUMBER
    , INACTIVATION_DATE__YYYYMMDD
    , SOURCE_CREATION_DATE__YYYYMMDD
    , SOURCE_LAST_UPDATE_DATE__YYYYMMDD
    , IS_DELETED
    , REC_SRC
    , BKCC
from {{ ref('dim_supplier_v2') }}

{{ config(alias='dim_supplier_site_v2' + ('_direct_spend' if target.name not in ['dev', 'qa', 'prod'] else '')) }}

SELECT
        SUPPLIER_SITE_KEY
        , SUPPLIER_BK
        , MDM_SUPPLIER_BK
        , MDM_SUPPLIER_SITE_BK
        , MDM_GOLDEN_RECORD
        , MDM_ADDRESS_TYPE
        , MDM_ADDRESS_LINE_1
        , MDM_ADDRESS_LINE_2
        , MDM_CITY
        , MDM_STATE
        , MDM_POSTAL_CODE
        , MDM_COUNTRY
        , MDM_TAX_NUMBER
        , MDM_SUPPLIER_TYPE
        , MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD
        , MDM_INACTIVE_DATE__YYYYMMDD
        , MDM_SITE_STATUS
        , MDM_PHONE_NUMBER
        , MDM_FAX_NUMBER
        , MDM_PRIMARY_EMAIL_ADDRESS
        , REC_SRC
        , BKCC
        , MDM_REC_SRC
        , MDM_BKCC
from {{ ref('dim_supplier_site_v2') }}

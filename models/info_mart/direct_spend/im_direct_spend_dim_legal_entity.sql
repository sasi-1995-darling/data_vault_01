{{ config(alias='dim_legal_entity' + ('_direct_spend' if target.name not in ['dev', 'qa', 'prod'] else '')) }}

select 
    LEGAL_ENTITY_HK
    , LEGAL_ENTITY_BK
    , LEGAL_ENTITY_CODE
    , LEGAL_ENTITY_NAME
    , LEGAL_ENTITY_REGION
    , LEGAL_ENTITY_COUNTRY_CODE
    , LEGAL_ENTITY_CURRENCY_CODE
    , IS_DELETED
    , REC_SRC
    , BKCC
from {{ ref('dim_legal_entity') }}

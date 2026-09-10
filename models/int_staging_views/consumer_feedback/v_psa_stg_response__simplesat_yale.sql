---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT CREATED, CUSTOMER_COMPANY, CUSTOMER_CUSTOM_ATTRIBUTES, CUSTOMER_EMAIL, CUSTOMER_ID, CUSTOMER_NAME, CUSTOMER_TAGS, ID, IP_ADDRESS, MODIFIED, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SOURCE, SURVEY_ID, TICKET_CUSTOM_ATTRIBUTES, TICKET_EXTERNAL_ID, TICKET_ID, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('simplesat_yale', 'response') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC WHERE rec_src = 'US.SIMPLESAT_YALE.RESPONSE' )

/*
SRC_D1             as ( SELECT * FROM simplesat_yale.response )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ID                                                           as                                        RESPONSE_BK
      , ID
      , TICKET_CUSTOM_ATTRIBUTES
      , _FIVETRAN_DELETED
      , SURVEY_ID
      , _FIVETRAN_SYNCED
      , CUSTOMER_TAGS
      , CREATED
      , TICKET_EXTERNAL_ID
      , CUSTOMER_CUSTOM_ATTRIBUTES
      , SOURCE
      , IP_ADDRESS
      , TICKET_ID
      , CUSTOMER_EMAIL
      , MODIFIED
      , CUSTOMER_NAME
      , CUSTOMER_ID
      , CUSTOMER_COMPANY
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , COALESCE(NULLIF(TRIM(TICKET_CUSTOM_ATTRIBUTES:SKUNumber::VARCHAR), ''), '-1') as                                         SKU_NUMBER
    FROM SRC_D1
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_D1
    INNER JOIN SRC_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          RESPONSE_BK
        , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as LOAD_DTS
        , TICKET_CUSTOM_ATTRIBUTES
        , _FIVETRAN_DELETED
        , SURVEY_ID
        , _FIVETRAN_SYNCED
        , CUSTOMER_TAGS
        , CREATED
        , TICKET_EXTERNAL_ID
        , CUSTOMER_CUSTOM_ATTRIBUTES
        , SOURCE
        , IP_ADDRESS
        , TICKET_ID
        , CUSTOMER_EMAIL
        , MODIFIED
        , CUSTOMER_NAME
        , CUSTOMER_ID
        , CUSTOMER_COMPANY
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RESPONSE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SURVEY_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SURVEY_HK
        , SKU_NUMBER as PRODUCT_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(TICKET_CUSTOM_ATTRIBUTES:SKUNumber::VARCHAR),''), '-1')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(TICKET_CUSTOM_ATTRIBUTES::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(SURVEY_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_TAGS::text), '^^') 
            , '||', IFNULL(TRIM(CREATED::text), '^^') 
            , '||', IFNULL(TRIM(TICKET_EXTERNAL_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_CUSTOM_ATTRIBUTES::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(IP_ADDRESS::text), '^^') 
            , '||', IFNULL(TRIM(TICKET_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_EMAIL::text), '^^') 
            , '||', IFNULL(TRIM(MODIFIED::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_COMPANY::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
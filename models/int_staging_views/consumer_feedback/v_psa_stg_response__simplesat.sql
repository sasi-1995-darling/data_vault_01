---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT CREATED, CUSTOMER_COMPANY, CUSTOMER_CUSTOM_ATTRIBUTES, CUSTOMER_EMAIL, CUSTOMER_ID, CUSTOMER_NAME, CUSTOMER_TAGS, ID, IP_ADDRESS, MODIFIED, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SOURCE, SURVEY_ID, TICKET_CUSTOM_ATTRIBUTES, TICKET_EXTERNAL_ID, TICKET_ID, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('simplesat', 'response') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM simplesat.response )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ID                                                           as                                        RESPONSE_BK
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
    FROM SRC_D1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_D1 as (
    SELECT
        RESPONSE_BK
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
    FROM LOGIC_D1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_D1 as (
    SELECT *
    FROM RENAME_D1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.SIMPLESAT.RESPONSE'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D1
    INNER JOIN FILTER_A1
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
          COALESCE(NULLIF(TRIM(CAST(RESPONSE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RESPONSE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SURVEY_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SURVEY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(TICKET_CUSTOM_ATTRIBUTES::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(SURVEY_ID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_SYNCED::text), '^^') 
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
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

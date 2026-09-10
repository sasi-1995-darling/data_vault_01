---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT CREATED_AT, EMAIL, EXTERNAL_ID, FIRST_NAME, ID, LAST_NAME, PHONE, PHONE_COUNTRY_CODE, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, UPDATED_AT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('prive_moen', 'subscriber') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM PRIVE_MOEN.SUBSCRIBER )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ID                                                           as                                      SUBSCRIBER_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , UPDATED_AT
      , LAST_NAME
      , CREATED_AT
      , EXTERNAL_ID
      , FIRST_NAME
      , EMAIL
      , PHONE_COUNTRY_CODE
      , PHONE
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
        SUBSCRIBER_BK
      , LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , UPDATED_AT
      , LAST_NAME
      , CREATED_AT
      , EXTERNAL_ID
      , FIRST_NAME
      , EMAIL
      , PHONE_COUNTRY_CODE
      , PHONE
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
    WHERE rec_src = 'US.PRIVE_MOEN.SUBSCRIBER'
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
          SUBSCRIBER_BK
        , LOAD_DTS
        , ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , UPDATED_AT
        , LAST_NAME
        , CREATED_AT
        , EXTERNAL_ID
        , FIRST_NAME
        , EMAIL
        , PHONE_COUNTRY_CODE
        , PHONE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SUBSCRIBER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUBSCRIBER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(LAST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(EXTERNAL_ID::text), '^^') 
            , '||', IFNULL(TRIM(FIRST_NAME::text), '^^') 
            , '||', IFNULL(TRIM(EMAIL::text), '^^') 
            , '||', IFNULL(TRIM(PHONE_COUNTRY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PHONE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

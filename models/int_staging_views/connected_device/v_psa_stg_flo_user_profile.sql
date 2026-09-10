---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ENABLED_FEATURES, FIRSTNAME, LASTNAME, LOCALE, MIDDLENAME, PHONE_MOBILE, PREFIXNAME, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SUFFIXNAME, UNIT_SYSTEM, USER_ID, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('flo_dynamodb', 'prod_user_detail') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM flo_dynamodb.prod_user_detail )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        USER_ID                                                      as                                        FLO_USER_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , USER_ID
      , _FIVETRAN_SYNCED
      , FIRSTNAME
      , PHONE_MOBILE
      , LOCALE
      , LASTNAME
      , _FIVETRAN_DELETED
      , UNIT_SYSTEM
      , ENABLED_FEATURES
      , PREFIXNAME
      , SUFFIXNAME
      , MIDDLENAME
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
        FLO_USER_BK
      , LOAD_DTS
      , USER_ID
      , _FIVETRAN_SYNCED
      , FIRSTNAME
      , PHONE_MOBILE
      , LOCALE
      , LASTNAME
      , _FIVETRAN_DELETED
      , UNIT_SYSTEM
      , ENABLED_FEATURES
      , PREFIXNAME
      , SUFFIXNAME
      , MIDDLENAME
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
    WHERE rec_src = 'US.FLO_DYNAMODB.PROD_USER_DETAIL'
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
          FLO_USER_BK
        , LOAD_DTS
        , USER_ID
        , _FIVETRAN_SYNCED
        , FIRSTNAME
        , PHONE_MOBILE
        , LOCALE
        , LASTNAME
        , _FIVETRAN_DELETED
        , UNIT_SYSTEM
        , ENABLED_FEATURES
        , PREFIXNAME
        , SUFFIXNAME
        , MIDDLENAME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(FLO_USER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FLO_USER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(USER_ID::text), '^^') 
            , '||', IFNULL(TRIM(FIRSTNAME::text), '^^') 
            , '||', IFNULL(TRIM(PHONE_MOBILE::text), '^^') 
            , '||', IFNULL(TRIM(LOCALE::text), '^^') 
            , '||', IFNULL(TRIM(LASTNAME::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_SYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(ENABLED_FEATURES::text), '^^') 
            , '||', IFNULL(TRIM(PREFIXNAME::text), '^^') 
            , '||', IFNULL(TRIM(SUFFIXNAME::text), '^^') 
            , '||', IFNULL(TRIM(MIDDLENAME::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

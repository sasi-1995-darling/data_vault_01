---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ACCOUNT_ID, EMAIL, EMAIL_HASH, ID, IS_ACTIVE, IS_SUPER_USER, IS_SYSTEM_USER, PASSWORD, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SOURCE, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, _IS_IP_RESTRICTED FROM {{ source('flo_dynamodb', 'prod_user') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM flo_dynamodb.prod_user )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ID                                                           as                                        FLO_USER_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , ID
      , _FIVETRAN_SYNCED
      , PASSWORD
      , IS_ACTIVE
      , SOURCE
      , EMAIL
      , _FIVETRAN_DELETED
      , EMAIL_HASH
      , IS_SYSTEM_USER
      , ACCOUNT_ID
      , IS_SUPER_USER
      , _IS_IP_RESTRICTED
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
      , ID
      , _FIVETRAN_SYNCED
      , PASSWORD
      , IS_ACTIVE
      , SOURCE
      , EMAIL
      , _FIVETRAN_DELETED
      , EMAIL_HASH
      , IS_SYSTEM_USER
      , ACCOUNT_ID
      , IS_SUPER_USER
      , _IS_IP_RESTRICTED
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
    WHERE rec_src = 'US.FLO_DYNAMODB.PROD_USER'
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
        , ID
        , _FIVETRAN_SYNCED
        , PASSWORD
        , IS_ACTIVE
        , SOURCE
        , EMAIL
        , _FIVETRAN_DELETED
        , EMAIL_HASH
        , IS_SYSTEM_USER
        , ACCOUNT_ID
        , IS_SUPER_USER
        , _IS_IP_RESTRICTED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , COALESCE(EMAIL, '-1')                                        as ENGAGEMENT_USER_BK
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(FLO_USER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FLO_USER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ENGAGEMENT_USER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ENGAGEMENT_USER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(FLO_USER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ENGAGEMENT_USER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FLO_USER_ENGAGEMENT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(PASSWORD::text), '^^') 
            , '||', IFNULL(TRIM(IS_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(EMAIL::text), '^^') 
            , '||', IFNULL(TRIM(EMAIL_HASH::text), '^^') 
            , '||', IFNULL(TRIM(IS_SYSTEM_USER::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(IS_SUPER_USER::text), '^^') 
            , '||', IFNULL(TRIM(_IS_IP_RESTRICTED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
QUALIFY (ROW_NUMBER() OVER(PARTITION BY FLO_USER_BK ORDER BY LOAD_DTS desc, psa_load_dts desc ))=1
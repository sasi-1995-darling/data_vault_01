---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ACCOUNT_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, ROLES, USER_ID, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('flo_dynamodb', 'prod_user_account_role') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM flo_dynamodb.prod_user_account_role )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        USER_ID                                                      as                                        FLO_USER_BK
      , ACCOUNT_ID                                                   as                                  DEVICE_ACCOUNT_BK
      , ACCOUNT_ID
      , USER_ID
      , _FIVETRAN_SYNCED
      , ROLES
      , _FIVETRAN_DELETED
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
      , DEVICE_ACCOUNT_BK
      , ACCOUNT_ID
      , USER_ID
      , _FIVETRAN_SYNCED
      , ROLES
      , _FIVETRAN_DELETED
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
    WHERE rec_src = 'US.FLO_DYNAMODB.PROD_USER_ACCOUNT_ROLE'
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
        , DEVICE_ACCOUNT_BK
        , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as LOAD_DTS
        , ACCOUNT_ID
        , USER_ID
        , _FIVETRAN_SYNCED
        , ROLES
        , _FIVETRAN_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(FLO_USER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DEVICE_ACCOUNT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as USER_ACCOUNT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(FLO_USER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FLO_USER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DEVICE_ACCOUNT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEVICE_ACCOUNT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(USER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ROLES::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
QUALIFY (ROW_NUMBER() OVER(PARTITION BY FLO_USER_BK ORDER BY LOAD_DTS desc, psa_load_dts desc ))=1
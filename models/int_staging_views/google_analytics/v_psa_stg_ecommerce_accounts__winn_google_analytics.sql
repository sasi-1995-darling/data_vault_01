---- SRC LAYER ----
WITH
SRC_act            as ( SELECT CREATE_TIME, DISPLAY_NAME, NAME, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REGION_CODE, UPDATE_TIME, _FIVETRAN_SYNCED FROM {{ source('google_analytics_4_moen_dtc', 'accounts') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_act            as ( SELECT * FROM google_analytics_4_moen_dtc.accounts )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_act as (
    SELECT
        NAME
      , CREATE_TIME
      , UPDATE_TIME
      , DISPLAY_NAME
      , REGION_CODE
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_act
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_act as (
    SELECT
        NAME
      , CREATE_TIME
      , UPDATE_TIME
      , DISPLAY_NAME
      , REGION_CODE
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_act
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_act as (
    SELECT *
    FROM RENAME_act
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.API.GOOGLE_ANALYTICS_WINN_DTC.ACCOUNTS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_act
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          UPPER(TRIM(DISPLAY_NAME))                                    as ECOMMERCE_ACCOUNT_BK
        , NAME
        , CREATE_TIME
        , UPDATE_TIME
        , DISPLAY_NAME
        , REGION_CODE
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , CONVERT_TIMEZONE('UTC',_FIVETRAN_SYNCED)                     as LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ECOMMERCE_ACCOUNT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ECOMMERCE_ACCOUNT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(CREATE_TIME::text), '^^') 
            , '||', IFNULL(TRIM(UPDATE_TIME::text), '^^') 
            , '||', IFNULL(TRIM(DISPLAY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(REGION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

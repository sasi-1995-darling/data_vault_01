---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT AUTHENTICATED, ICON, ID, IDENTIFIER, NAME, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, STORE, STORE_ID, TRANSLATION_SUPPORTED, _FIVETRAN_SYNCED FROM {{ source('custom_fivetran_appbot_sdk', 'apps') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_C              as ( SELECT CUTOFF_DT FROM {{ ref('v_psa_stg_ref_appbot_talend_migration_cutoff_date') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM custom_fivetran_appbot_sdk.apps )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_C              as ( SELECT * FROM raw_vault.v_psa_stg_ref_appbot_talend_migration_cutoff_date )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        IDENTIFIER                                                   as                                         PRODUCT_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , ID
      , NAME
      , STORE
      , STORE_ID
      , ICON
      , AUTHENTICATED
      , TRANSLATION_SUPPORTED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , STORE                                                        as                                        RETAILER_BK
      , _FIVETRAN_SYNCED
    FROM SRC_S1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)

, LOGIC_C as (
    SELECT
        CUTOFF_DT
    FROM SRC_C
)
---- RENAME LAYER ----

, RENAME_S1 as (
    SELECT
        PRODUCT_BK
      , LOAD_DTS
      , ID
      , NAME
      , STORE
      , STORE_ID
      , ICON
      , AUTHENTICATED
      , TRANSLATION_SUPPORTED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , RETAILER_BK
      , _FIVETRAN_SYNCED
    FROM LOGIC_S1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)

, RENAME_C as (
    SELECT
        CUTOFF_DT
    FROM LOGIC_C
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.APPBOT_FT.APPLIST'
)

, FILTER_C as (
    SELECT *
    FROM RENAME_C
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
    INNER JOIN FILTER_A1
        ON '1' = '1'
    INNER JOIN FILTER_C
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PRODUCT_BK
        , LOAD_DTS
        , ID
        , NAME
        , STORE
        , STORE_ID
        , ICON
        , AUTHENTICATED
        , TRANSLATION_SUPPORTED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , RETAILER_BK
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RETAILER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(STORE::text), '^^') 
            , '||', IFNULL(TRIM(STORE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ICON::text), '^^') 
            , '||', IFNULL(TRIM(AUTHENTICATED::text), '^^') 
            , '||', IFNULL(TRIM(TRANSLATION_SUPPORTED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
WHERE TO_DATE(PSA_LOAD_DTS) > CUTOFF_DT
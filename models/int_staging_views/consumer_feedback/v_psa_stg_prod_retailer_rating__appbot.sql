---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT APP_ID, AVG, COUNTRY, COUNTRY_CODE, COUNTRY_ID, CREATED_AT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, STAR_1, STAR_2, STAR_3, STAR_4, STAR_5, TOTAL, VERSION FROM {{ source('appbot_psa', 'ratings') }} as SRC 
                        WHERE PSA_DELETE_IND = 'N' ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_C              as ( SELECT CUTOFF_DT FROM {{ ref('v_psa_stg_ref_appbot_talend_migration_cutoff_date') }} as SRC  ),
SRC_S2             as ( SELECT ID, IDENTIFIER, STORE FROM {{ source('appbot_psa', 'applist') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM appbot_psa.ratings )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_C              as ( SELECT * FROM raw_vault.v_psa_stg_ref_appbot_talend_migration_cutoff_date )
SRC_S2             as ( SELECT * FROM appbot_psa.applist )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , APP_ID
      , CREATED_AT
      , COUNTRY
      , COUNTRY_ID
      , COUNTRY_CODE
      , STAR_1
      , STAR_2
      , STAR_3
      , STAR_4
      , STAR_5
      , TOTAL
      , AVG
      , VERSION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S1
)

, LOGIC_A1 as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_A1
)

, LOGIC_C as (
    SELECT
        CUTOFF_DT
    FROM SRC_C
)

, LOGIC_S2 as (
    SELECT
        STORE                                                        as                                        RETAILER_BK
      , IDENTIFIER                                                   as                                         PRODUCT_BK
      , ID
    FROM SRC_S2
)
---- RENAME LAYER ----

, RENAME_S2 as (
    SELECT
        RETAILER_BK
      , PRODUCT_BK
      , ID
    FROM LOGIC_S2
)

, RENAME_S1 as (
    SELECT
        LOAD_DTS
      , APP_ID
      , CREATED_AT
      , COUNTRY
      , COUNTRY_ID
      , COUNTRY_CODE
      , STAR_1
      , STAR_2
      , STAR_3
      , STAR_4
      , STAR_5
      , TOTAL
      , AVG
      , VERSION
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S1
)

, RENAME_A1 as (
    SELECT
        BKCC
      , REC_SRC
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
    WHERE rec_src = 'US.APPBOT.RATINGS'
)

, FILTER_C as (
    SELECT *
    FROM RENAME_C
)

, FILTER_S2 as (
    SELECT *
    FROM RENAME_S2
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
    INNER JOIN FILTER_A1
        ON '1' = '1'
    INNER JOIN FILTER_C
        ON '1' = '1'
    LEFT JOIN FILTER_S2
        ON app_id = id
)

---- FINAL LAYER ----
SELECT
          RETAILER_BK
        , PRODUCT_BK
        , LOAD_DTS
        , APP_ID
        , CREATED_AT
        , COUNTRY
        , COUNTRY_ID
        , COUNTRY_CODE
        , STAR_1
        , STAR_2
        , STAR_3
        , STAR_4
        , STAR_5
        , TOTAL
        , CAST(AVG AS NUMBER(38,15)) AS AVG
        , VERSION
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_RETAILER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RETAILER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(APP_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_ID::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(STAR_1::text), '^^') 
            , '||', IFNULL(TRIM(STAR_2::text), '^^') 
            , '||', IFNULL(TRIM(STAR_3::text), '^^') 
            , '||', IFNULL(TRIM(STAR_4::text), '^^') 
            , '||', IFNULL(TRIM(STAR_5::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL::text), '^^') 
            , '||', IFNULL(TRIM(AVG::text), '^^') 
            , '||', IFNULL(TRIM(VERSION::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
WHERE TO_DATE(CREATED_AT) <= CUTOFF_DT
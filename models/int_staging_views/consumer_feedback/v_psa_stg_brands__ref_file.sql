---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT * FROM {{ source('reference_psa', 'ref_brand') }} as SRC  ),
SRC_A1             as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM reference_psa.ref_brand )
, SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        SYSTEM_BRAND                                                 as                                           BRAND_BK
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , BUSINESS_UNIT
      , BRAND
      , SUB_BRAND
      , COMPETITOR
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_S1 as (
    SELECT
        BRAND_BK
      , LOAD_DTS
      , BUSINESS_UNIT
      , BRAND
      , SUB_BRAND
      , COMPETITOR
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'USAZET.SNOWFLAKE.FBIN.REFERENCE.REF_BRAND_FILE'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          BRAND_BK
        , LOAD_DTS
        , BUSINESS_UNIT
        , BRAND
        , SUB_BRAND
        , COMPETITOR
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BRAND_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as BRAND_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(BUSINESS_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(BRAND::text), '^^') 
            , '||', IFNULL(TRIM(SUB_BRAND::text), '^^') 
            , '||', IFNULL(TRIM(COMPETITOR::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

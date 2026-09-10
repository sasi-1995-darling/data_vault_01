---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT BRAND_NAME, ID, METRIC, NAME, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SURVEY_TOKEN, SURVEY_TYPE, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('simplesat', 'survey') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM simplesat.survey )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ID                                                           as                                          SURVEY_BK
      , SURVEY_TOKEN
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , METRIC
      , NAME
      , BRAND_NAME
      , SURVEY_TYPE
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
        SURVEY_BK
      , SURVEY_TOKEN
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , METRIC
      , NAME
      , BRAND_NAME
      , SURVEY_TYPE
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
    WHERE rec_src = 'US.SIMPLESAT.SURVEY'
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
          SURVEY_BK
        , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as LOAD_DTS
        , SURVEY_TOKEN
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , METRIC
        , NAME
        , BRAND_NAME
        , SURVEY_TYPE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SURVEY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SURVEY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SURVEY_TOKEN::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_SYNCED::text), '^^') 
            , '||', IFNULL(TRIM(METRIC::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(BRAND_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SURVEY_TYPE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

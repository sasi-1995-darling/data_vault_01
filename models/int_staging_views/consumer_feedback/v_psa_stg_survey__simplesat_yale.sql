---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT BRAND_NAME, ID, METRIC, NAME, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SURVEY_TOKEN, SURVEY_TYPE, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('simplesat_yale', 'survey') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC WHERE rec_src = 'US.SIMPLESAT_YALE.SURVEY' )

/*
SRC_D1             as ( SELECT * FROM simplesat_yale.survey )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ID                                                           as                                          SURVEY_BK
      , ID
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

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_D1
    INNER JOIN SRC_A1
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
          COALESCE(NULLIF(TRIM(CAST(ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SURVEY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SURVEY_TOKEN::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(METRIC::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(BRAND_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SURVEY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
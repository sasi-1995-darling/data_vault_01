---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT CHOICES, ID, METRIC, ORDERS, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, RATING_SCALE, REQUIRED, SURVEY_ID, TEXT, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('simplesat_yale', 'question') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC WHERE rec_src = 'US.SIMPLESAT_YALE.QUESTION' )

/*
SRC_D1             as ( SELECT * FROM simplesat_yale.question )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ID                                                           as                                        QUESTION_BK
      , ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , METRIC
      , SURVEY_ID
      , RATING_SCALE
      , ORDERS
      , TEXT
      , CHOICES
      , REQUIRED
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
          QUESTION_BK
        , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as LOAD_DTS
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , METRIC
        , SURVEY_ID
        , RATING_SCALE
        , ORDERS
        , TEXT
        , CHOICES
        , REQUIRED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUESTION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SURVEY_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SURVEY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(METRIC::text), '^^') 
            , '||', IFNULL(TRIM(SURVEY_ID::text), '^^') 
            , '||', IFNULL(TRIM(RATING_SCALE::text), '^^') 
            , '||', IFNULL(TRIM(ORDERS::text), '^^') 
            , '||', IFNULL(TRIM(TEXT::text), '^^') 
            , '||', IFNULL(TRIM(CHOICES::text), '^^') 
            , '||', IFNULL(TRIM(REQUIRED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
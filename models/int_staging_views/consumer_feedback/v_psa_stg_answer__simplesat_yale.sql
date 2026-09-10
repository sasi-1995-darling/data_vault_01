---- SRC LAYER ----
-- Note: SIMPLESAT_YALE.ANSWER has 8 fewer columns than SIMPLESAT.ANSWER:
--   Missing: SURVEY_MODIFIED, IS_PRIMARY, SESSION, CHANNEL, RATING, ANSWER_LABEL, IP_ADDRESS, SURVEY_NAME
--   Type diff: CHOICE is NUMBER in Yale (TEXT in Moen) — cast to VARCHAR for consistency
WITH
SRC_D1             as ( SELECT CHOICE, CHOICES, CHOICE_LABEL, CREATED, FOLLOW_UP_ANSWER, FOLLOW_UP_ANSWER_CHOICES, ID, MODIFIED, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PUBLISHED_AS_TESTIMONIAL, QUESTION_ID, RESPONSE_ID, SENTIMENT, SURVEY_ID, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('simplesat_yale', 'answer') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC WHERE rec_src = 'US.SIMPLESAT_YALE.ANSWER' )

/*
SRC_D1             as ( SELECT * FROM simplesat_yale.answer )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        ID                                                           as                                          ANSWER_BK
      , ID
      , CHOICES
      , FOLLOW_UP_ANSWER_CHOICES
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , SENTIMENT
      , CREATED
      , SURVEY_ID
      , MODIFIED
      , FOLLOW_UP_ANSWER
      , RESPONSE_ID
      , CHOICE_LABEL
      , CAST(CHOICE AS VARCHAR)                                      as                                          CHOICE
      , QUESTION_ID
      , PUBLISHED_AS_TESTIMONIAL
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
          ANSWER_BK
        , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as LOAD_DTS
        , CHOICES
        , FOLLOW_UP_ANSWER_CHOICES
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , SENTIMENT
        , CREATED
        , SURVEY_ID
        , MODIFIED
        , FOLLOW_UP_ANSWER
        , RESPONSE_ID
        , CHOICE_LABEL
        , CHOICE
        , QUESTION_ID
        , PUBLISHED_AS_TESTIMONIAL
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ANSWER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SURVEY_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SURVEY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(QUESTION_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUESTION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RESPONSE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RESPONSE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SURVEY_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(QUESTION_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RESPONSE_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SURVEY_QUESTION_RESPONSE_ANSWER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CHOICES::text), '^^') 
            , '||', IFNULL(TRIM(FOLLOW_UP_ANSWER_CHOICES::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(SENTIMENT::text), '^^') 
            , '||', IFNULL(TRIM(CREATED::text), '^^') 
            , '||', IFNULL(TRIM(MODIFIED::text), '^^') 
            , '||', IFNULL(TRIM(FOLLOW_UP_ANSWER::text), '^^') 
            , '||', IFNULL(TRIM(CHOICE_LABEL::text), '^^') 
            , '||', IFNULL(TRIM(CHOICE::text), '^^') 
            , '||', IFNULL(TRIM(PUBLISHED_AS_TESTIMONIAL::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
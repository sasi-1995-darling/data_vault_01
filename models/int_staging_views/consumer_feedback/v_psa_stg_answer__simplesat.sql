---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ANSWER_LABEL, CHANNEL, CHOICE, CHOICES, CHOICE_LABEL, CREATED, FOLLOW_UP_ANSWER, FOLLOW_UP_ANSWER_CHOICES, ID, IP_ADDRESS, IS_PRIMARY, MODIFIED, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PUBLISHED_AS_TESTIMONIAL, QUESTION_ID, RATING, RESPONSE_ID, SENTIMENT, SESSION, SURVEY_ID, SURVEY_MODIFIED, SURVEY_NAME, _FIVETRAN_DELETED, _FIVETRAN_SYNCED FROM {{ source('simplesat', 'answer') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM simplesat.answer )
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
      , SURVEY_MODIFIED
      , IS_PRIMARY
      , CREATED
      , SESSION
      , CHANNEL
      , RATING
      , ANSWER_LABEL
      , IP_ADDRESS
      , SURVEY_ID
      , MODIFIED
      , SURVEY_NAME
      , FOLLOW_UP_ANSWER
      , RESPONSE_ID
      , CHOICE_LABEL
      , CHOICE
      , QUESTION_ID
      , PUBLISHED_AS_TESTIMONIAL
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
        ANSWER_BK
      , ID
      , CHOICES
      , FOLLOW_UP_ANSWER_CHOICES
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , SENTIMENT
      , SURVEY_MODIFIED
      , IS_PRIMARY
      , CREATED
      , SESSION
      , CHANNEL
      , RATING
      , ANSWER_LABEL
      , IP_ADDRESS
      , SURVEY_ID
      , MODIFIED
      , SURVEY_NAME
      , FOLLOW_UP_ANSWER
      , RESPONSE_ID
      , CHOICE_LABEL
      , CHOICE
      , QUESTION_ID
      , PUBLISHED_AS_TESTIMONIAL
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
    WHERE rec_src = 'US.SIMPLESAT.ANSWER'
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
          ANSWER_BK
        , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as LOAD_DTS
        , CHOICES
        , FOLLOW_UP_ANSWER_CHOICES
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , SENTIMENT
        , SURVEY_MODIFIED
        , IS_PRIMARY
        , CREATED
        , SESSION
        , CHANNEL
        , RATING
        , ANSWER_LABEL
        , IP_ADDRESS
        , SURVEY_ID
        , MODIFIED
        , SURVEY_NAME
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
            , '||', IFNULL(TRIM(SURVEY_MODIFIED::text), '^^') 
            , '||', IFNULL(TRIM(IS_PRIMARY::text), '^^') 
            , '||', IFNULL(TRIM(CREATED::text), '^^') 
            , '||', IFNULL(TRIM(SESSION::text), '^^') 
            , '||', IFNULL(TRIM(CHANNEL::text), '^^') 
            , '||', IFNULL(TRIM(RATING::text), '^^') 
            , '||', IFNULL(TRIM(ANSWER_LABEL::text), '^^') 
            , '||', IFNULL(TRIM(IP_ADDRESS::text), '^^') 
            , '||', IFNULL(TRIM(MODIFIED::text), '^^') 
            , '||', IFNULL(TRIM(SURVEY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(FOLLOW_UP_ANSWER::text), '^^') 
            , '||', IFNULL(TRIM(CHOICE_LABEL::text), '^^') 
            , '||', IFNULL(TRIM(CHOICE::text), '^^') 
            , '||', IFNULL(TRIM(PUBLISHED_AS_TESTIMONIAL::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

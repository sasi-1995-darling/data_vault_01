{{ config(alias='fact_survey_response') }}
---- SRC LAYER ----
WITH
SRC_FP             as ( SELECT * FROM {{ ref('fact_survey_response') }} as SRC  )

/*
SRC_FP             as ( SELECT * FROM BUS_VAULT.FACT_SURVEY_RESPONSE )
*/
---- LOGIC LAYER ----

, LOGIC_FP as (
    SELECT
        FORM_BK
      , PROJECT_BK
      , BKCC
      , REC_SRC
      , ORDINAL_POSITION
      , RESPONSE_ORDINAL
      , FIELD_ORDINAL
      , QUESTION_NAME
      , DATA_TYPE
      , RESPONSE_ID
      , ANSWER_ID
      , COMPUTED_VALUE
      , VALUE_LIST
      , DISPLAY_NAME
      , JIRA_ID
      , TICKET_ID
      , SOURCE
    FROM SRC_FP
)
---- RENAME LAYER ----

, RENAME_FP as (
    SELECT
        FORM_BK
      , PROJECT_BK
      , BKCC
      , REC_SRC
      , ORDINAL_POSITION
      , RESPONSE_ORDINAL
      , FIELD_ORDINAL
      , QUESTION_NAME
      , DATA_TYPE
      , RESPONSE_ID
      , ANSWER_ID
      , COMPUTED_VALUE
      , VALUE_LIST
      , DISPLAY_NAME
      , JIRA_ID
      , TICKET_ID
      , SOURCE
    FROM LOGIC_FP
)
---- FILTER LAYER ----

, FILTER_FP as (
    SELECT *
    FROM RENAME_FP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_FP
)

---- FINAL LAYER ----
SELECT
          FORM_BK
        , PROJECT_BK
        , BKCC
        , REC_SRC
        , ORDINAL_POSITION
        , RESPONSE_ORDINAL
        , FIELD_ORDINAL
        , QUESTION_NAME
        , DATA_TYPE
        , RESPONSE_ID
        , ANSWER_ID
        , COMPUTED_VALUE
        , VALUE_LIST
        , DISPLAY_NAME
        , JIRA_ID
        , TICKET_ID
        , SOURCE
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT * FROM {{ ref('pb_survey_response') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.PB_SURVEY_RESPONSE )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
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
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
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
    FROM LOGIC_PB
)
---- FILTER LAYER ----

, FILTER_PB as (
    SELECT *
    FROM RENAME_PB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PB
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

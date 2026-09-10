{{ config(alias='rep_survey_response') }}
---- SRC LAYER ----
WITH
SRC_FSR            as ( SELECT * FROM {{ ref('im_fact_survey_response') }} as SRC  ),
SRC_DF             as ( SELECT * FROM {{ ref('im_dim_survey_form') }} as SRC  ),
SRC_DP             as ( SELECT * FROM {{ ref('im_dim_survey_project') }} as SRC  )

/*
SRC_FSR            as ( SELECT * FROM consumer_feedback.IM_FACT_SURVEY_RESPONSE )
, SRC_DF             as ( SELECT * FROM consumer_feedback.IM_DIM_SURVEY_FORM )
, SRC_DP             as ( SELECT * FROM consumer_feedback.IM_DIM_SURVEY_PROJECT )
*/
---- LOGIC LAYER ----

, LOGIC_FSR as (
    SELECT
        FORM_BK                                                      as                                        FSR_FORM_BK
      , PROJECT_BK                                                   as                                     FSR_PROJECT_BK
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
    FROM SRC_FSR
)

, LOGIC_DF as (
    SELECT
        FORM_BK
      , FORM_TYPE
    FROM SRC_DF
)

, LOGIC_DP as (
    SELECT
        PROJECT_BK
    FROM SRC_DP
)
---- RENAME LAYER ----

, RENAME_DF as (
    SELECT
        FORM_BK
      , FORM_TYPE
    FROM LOGIC_DF
)

, RENAME_DP as (
    SELECT
        PROJECT_BK
    FROM LOGIC_DP
)

, RENAME_FSR as (
    SELECT
        FSR_FORM_BK
      , FSR_PROJECT_BK
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
    FROM LOGIC_FSR
)
---- FILTER LAYER ----

, FILTER_FSR as (
    SELECT *
    FROM RENAME_FSR
)

, FILTER_DF as (
    SELECT *
    FROM RENAME_DF
)

, FILTER_DP as (
    SELECT *
    FROM RENAME_DP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_FSR
    INNER JOIN FILTER_DF
        ON FSR_FORM_BK = FORM_BK
    INNER JOIN FILTER_DP
        ON FSR_PROJECT_BK = PROJECT_BK
)

---- FINAL LAYER ----
SELECT
          FORM_BK
        , PROJECT_BK
        , FORM_TYPE
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

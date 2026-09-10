---- SRC LAYER ----
WITH
SRC_PBRC           as ( SELECT * FROM {{ ref('pb_stg_response__centercode') }} as SRC 
                        qualify 1= row_number() over(partition by FORM_PROJECT_HK, RESPONSE_ORDINAL, FIELD_ORDINAL order by LOAD_DTS) )

/*
SRC_PBRC           as ( SELECT * FROM BUS_VAULT.PB_STG_RESPONSE__CENTERCODE )
*/
---- LOGIC LAYER ----

, LOGIC_PBRC as (
    SELECT
        FORM_PROJECT_HK
      , FORM_HK
      , PROJECT_HK
      , FORM_BK
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
    FROM SRC_PBRC
)
---- RENAME LAYER ----

, RENAME_PBRC as (
    SELECT
        FORM_PROJECT_HK
      , FORM_HK
      , PROJECT_HK
      , FORM_BK
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
    FROM LOGIC_PBRC
)
---- FILTER LAYER ----

, FILTER_PBRC as (
    SELECT *
    FROM RENAME_PBRC
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PBRC
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , FORM_PROJECT_HK
        , FORM_HK
        , PROJECT_HK
        , FORM_BK
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

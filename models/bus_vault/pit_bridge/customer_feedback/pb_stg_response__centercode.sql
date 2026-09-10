{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LFP            as ( SELECT * FROM {{ ref('lnk_form_project') }} as SRC  ),
SRC_HF             as ( SELECT * FROM {{ ref('hub_form') }} as SRC  ),
SRC_HP             as ( SELECT * FROM {{ ref('hub_project') }} as SRC  ),
SRC_LRC            as ( SELECT * FROM {{ ref('lsat_response__centercode') }} as SRC 
                        qualify 1= row_number() over(partition by FORM_PROJECT_HK, RESPONSE_ORDINAL, FIELD_ORDINAL order by LOAD_DTS DESC) ),
SRC_CC             as ( SELECT * FROM {{ ref('pb_stg_users__centercode') }} as SRC  )

/*
SRC_LFP            as ( SELECT * FROM raw_vault.LNK_FORM_PROJECT )
, SRC_HF             as ( SELECT * FROM raw_vault.HUB_FORM )
, SRC_HP             as ( SELECT * FROM raw_vault.HUB_PROJECT )
, SRC_LRC            as ( SELECT * FROM raw_vault.LSAT_RESPONSE__CENTERCODE )
, SRC_CC             as ( SELECT * FROM bus_vault.PB_STG_USERS__CENTERCODE )
*/
---- LOGIC LAYER ----

, LOGIC_LFP as (
    SELECT
        FORM_PROJECT_HK
      , FORM_HK
      , PROJECT_HK
      , ORDINAL_POSITION
      , REC_SRC
    FROM SRC_LFP
)

, LOGIC_HF as (
    SELECT
        FORM_HK                                                      as                                         HF_FORM_HK
      , FORM_BK
      , BKCC
    FROM SRC_HF
)

, LOGIC_HP as (
    SELECT
        PROJECT_HK                                                   as                                      HP_PROJECT_HK
      , PROJECT_BK
    FROM SRC_HP
)

, LOGIC_LRC as (
    SELECT
        FORM_PROJECT_HK                                              as                                LRC_FORM_PROJECT_HK
      , ORDINAL_POSITION                                             as                               LRC_ORDINAL_POSITION
      , RESPONSE_ORDINAL
      , FIELD_ORDINAL
      , QUESTION_NAME
      , DATA_TYPE
      , RESPONSE_ID
      , ANSWER_ID
      , COMPUTED_VALUE
      , VALUE_LIST
      , LOAD_DTS
    FROM SRC_LRC
)

, LOGIC_CC as (
    SELECT
        RESPONSE_ORDINAL                                             as                                CC_RESPONSE_ORDINAL
      , FORM_PROJECT_HK                                              as                                 CC_FORM_PROJECT_HK
      , DISPLAY_NAME
      , JIRA_ID
      , TICKET_ID
    FROM SRC_CC
)
---- RENAME LAYER ----

, RENAME_LFP as (
    SELECT
        FORM_PROJECT_HK
      , FORM_HK
      , PROJECT_HK
      , ORDINAL_POSITION
      , REC_SRC
    FROM LOGIC_LFP
)

, RENAME_HF as (
    SELECT
        HF_FORM_HK
      , FORM_BK
      , BKCC
    FROM LOGIC_HF
)

, RENAME_HP as (
    SELECT
        HP_PROJECT_HK
      , PROJECT_BK
    FROM LOGIC_HP
)

, RENAME_LRC as (
    SELECT
        LRC_FORM_PROJECT_HK
      , LRC_ORDINAL_POSITION
      , RESPONSE_ORDINAL
      , FIELD_ORDINAL
      , QUESTION_NAME
      , DATA_TYPE
      , RESPONSE_ID
      , ANSWER_ID
      , COMPUTED_VALUE
      , VALUE_LIST
      , LOAD_DTS
    FROM LOGIC_LRC
)

, RENAME_CC as (
    SELECT
        CC_RESPONSE_ORDINAL
      , CC_FORM_PROJECT_HK
      , DISPLAY_NAME
      , JIRA_ID
      , TICKET_ID
    FROM LOGIC_CC
)
---- FILTER LAYER ----

, FILTER_LFP as (
    SELECT *
    FROM RENAME_LFP
)

, FILTER_HF as (
    SELECT *
    FROM RENAME_HF
)

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_LRC as (
    SELECT *
    FROM RENAME_LRC
)

, FILTER_CC as (
    SELECT *
    FROM RENAME_CC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LFP
    INNER JOIN FILTER_HF
        ON FORM_HK = HF_FORM_HK
    INNER JOIN FILTER_HP
        ON PROJECT_HK = HP_PROJECT_HK
    INNER JOIN FILTER_LRC
        ON FORM_PROJECT_HK = LRC_FORM_PROJECT_HK AND ORDINAL_POSITION = LRC_ORDINAL_POSITION
    LEFT JOIN FILTER_CC
        ON FORM_PROJECT_HK = CC_FORM_PROJECT_HK AND RESPONSE_ORDINAL = CC_RESPONSE_ORDINAL
)

---- FINAL LAYER ----
SELECT
          FORM_PROJECT_HK
        , FORM_HK
        , PROJECT_HK
        , ORDINAL_POSITION
        , FORM_BK
        , PROJECT_BK
        , BKCC
        , REC_SRC
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
        , LOAD_DTS
        , 'CENTERCODE'                                                 as SOURCE
FROM JOIN_RESULT

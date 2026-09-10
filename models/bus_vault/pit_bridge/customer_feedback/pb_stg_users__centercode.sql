{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LFP            as ( SELECT * FROM {{ ref('lnk_form_project') }} as SRC  ),
SRC_HF             as ( SELECT * FROM {{ ref('hub_form') }} as SRC  ),
SRC_HP             as ( SELECT * FROM {{ ref('hub_project') }} as SRC  ),
SRC_LRC            as ( SELECT * FROM {{ ref('lsat_response__centercode') }} as SRC 
                        qualify 1= row_number() over(partition by FORM_PROJECT_HK, RESPONSE_ORDINAL, FIELD_ORDINAL order by LOAD_DTS DESC) )

/*
SRC_LFP            as ( SELECT * FROM raw_vault.LNK_FORM_PROJECT )
, SRC_HF             as ( SELECT * FROM raw_vault.HUB_FORM )
, SRC_HP             as ( SELECT * FROM raw_vault.HUB_PROJECT )
, SRC_LRC            as ( SELECT * FROM raw_vault.LSAT_RESPONSE__CENTERCODE )
*/
---- LOGIC LAYER ----

, LOGIC_LFP as (
    SELECT
        FORM_PROJECT_HK
      , FORM_HK
      , PROJECT_HK
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
      , QUESTION_NAME
      , COMPUTED_VALUE
      , RESPONSE_ORDINAL
    FROM SRC_LRC
)
---- RENAME LAYER ----

, RENAME_LFP as (
    SELECT
        FORM_PROJECT_HK
      , FORM_HK
      , PROJECT_HK
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
      , QUESTION_NAME
      , COMPUTED_VALUE
      , RESPONSE_ORDINAL
    FROM LOGIC_LRC
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

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LFP
    INNER JOIN FILTER_HF
        ON FORM_HK = HF_FORM_HK
    INNER JOIN FILTER_HP
        ON PROJECT_HK = HP_PROJECT_HK
    INNER JOIN FILTER_LRC
        ON FORM_PROJECT_HK = LRC_FORM_PROJECT_HK
)

---- FINAL LAYER ----
SELECT
          FORM_PROJECT_HK
        , FORM_HK
        , PROJECT_HK
        , FORM_BK
        , PROJECT_BK
        , BKCC
        , REC_SRC
        , MAX(CASE WHEN UPPER(QUESTION_NAME) LIKE '%DISPLAY NAME%' THEN COMPUTED_VALUE END) as DISPLAY_NAME
        , MAX(CASE WHEN UPPER(QUESTION_NAME) LIKE 'JIRA ID' THEN COMPUTED_VALUE END) as JIRA_ID
        , MAX(CASE WHEN UPPER(QUESTION_NAME) LIKE 'ID' THEN COMPUTED_VALUE END) as TICKET_ID
        , RESPONSE_ORDINAL
        , 'CENTERCODE'                                                 as SOURCE
FROM JOIN_RESULT
GROUP BY ALL
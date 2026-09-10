---- SRC LAYER ----
WITH
SRC_P              as ( SELECT 
                            GL_ACCOUNT_HK
                          , GL_ACCOUNT_NUMBER_BK
                          , CHART_OF_ACCOUNT
                          , GL_ACCOUNT_NUMBER
                          , CREATE_DATE_YYYYMMDD
                          , GL_ACCOUNT_GROUP
                          , MARKED_FOR_DELETION_IND
                          , BLOCKED_FOR_CREATION_IND
                          , BLOCKED_FOR_POSTING_IND
                          , BLOCKED_FOR_PLANNING_IND
                          , IS_DELETED
                          , BKCC
                          , REC_SRC
                        FROM {{ ref('pit_gl_account_current') }} ),

SRC_GL_TEXT        as ( SELECT 
                            CHART_OF_ACCOUNTS
                          , GL_ACCOUNT_NUMBER
                          , GL_ACCOUNT_SHORT_TEXT
                          , GL_ACCOUNT_LONG_TEXT
                        FROM {{ ref('ref_gl_account_texts__winn_sap') }}
                        WHERE LANGUAGE_KEY = 'E'  -- English
                      )

/*
SRC_P              as ( SELECT * FROM RAW_VAULT.PIT_GL_ACCOUNT_CURRENT )
*/
---- LOGIC LAYER ----

, LOGIC_P as (
    SELECT
        GL_ACCOUNT_HK
      , GL_ACCOUNT_NUMBER_BK
      , CHART_OF_ACCOUNT
      , GL_ACCOUNT_NUMBER
      , CREATE_DATE_YYYYMMDD
      , GL_ACCOUNT_GROUP
      , MARKED_FOR_DELETION_IND
      , BLOCKED_FOR_CREATION_IND
      , BLOCKED_FOR_POSTING_IND
      , BLOCKED_FOR_PLANNING_IND
      , IS_DELETED
      , BKCC
      , REC_SRC
    FROM SRC_P
)

, LOGIC_GL_TEXT as (
    SELECT
        CHART_OF_ACCOUNTS
      , GL_ACCOUNT_NUMBER
      , GL_ACCOUNT_SHORT_TEXT
      , GL_ACCOUNT_LONG_TEXT
    FROM SRC_GL_TEXT
)

---- RENAME LAYER ----

, RENAME_P as (
    SELECT
        GL_ACCOUNT_HK
      , GL_ACCOUNT_NUMBER_BK
      , CHART_OF_ACCOUNT
      , GL_ACCOUNT_NUMBER
      , CREATE_DATE_YYYYMMDD
      , GL_ACCOUNT_GROUP
      , MARKED_FOR_DELETION_IND
      , BLOCKED_FOR_CREATION_IND
      , BLOCKED_FOR_POSTING_IND
      , BLOCKED_FOR_PLANNING_IND
      , IS_DELETED
      , BKCC
      , REC_SRC
    FROM LOGIC_P
)

, RENAME_GL_TEXT as (
    SELECT
        CHART_OF_ACCOUNTS                as TEXT_CHART_OF_ACCOUNT
      , GL_ACCOUNT_NUMBER                as TEXT_GL_ACCOUNT_NUMBER
      , GL_ACCOUNT_SHORT_TEXT            as GL_ACCOUNT_SHORT_DESCRIPTION
      , GL_ACCOUNT_LONG_TEXT             as GL_ACCOUNT_DESCRIPTION
    FROM LOGIC_GL_TEXT
)

---- FILTER LAYER ----

, FILTER_P as (
    SELECT *
    FROM RENAME_P
)

, FILTER_GL_TEXT as (
    SELECT *
    FROM RENAME_GL_TEXT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT 
        FILTER_P.*
      , FILTER_GL_TEXT.GL_ACCOUNT_SHORT_DESCRIPTION
      , FILTER_GL_TEXT.GL_ACCOUNT_DESCRIPTION
    FROM FILTER_P
    LEFT JOIN FILTER_GL_TEXT
        ON FILTER_P.CHART_OF_ACCOUNT = FILTER_GL_TEXT.TEXT_CHART_OF_ACCOUNT
        AND FILTER_P.GL_ACCOUNT_NUMBER = FILTER_GL_TEXT.TEXT_GL_ACCOUNT_NUMBER
)

---- FINAL LAYER ----
SELECT
          GL_ACCOUNT_HK
        , GL_ACCOUNT_NUMBER_BK
        , CHART_OF_ACCOUNT
        , GL_ACCOUNT_NUMBER
        , COALESCE(GL_ACCOUNT_SHORT_DESCRIPTION, '')                as GL_ACCOUNT_SHORT_DESCRIPTION
        , COALESCE(GL_ACCOUNT_DESCRIPTION, '')                      as GL_ACCOUNT_DESCRIPTION
        , CREATE_DATE_YYYYMMDD
        , GL_ACCOUNT_GROUP
        , MARKED_FOR_DELETION_IND
        , BLOCKED_FOR_CREATION_IND
        , BLOCKED_FOR_POSTING_IND
        , BLOCKED_FOR_PLANNING_IND
        , IS_DELETED
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
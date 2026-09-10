---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_gl_account') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_gl_account__winn_sap') }} as SRC
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY GL_ACCOUNT_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_GL_ACCOUNT )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_GL_ACCOUNT__WINN_SAP)
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_GL_ACCOUNT'                                             as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , GL_ACCOUNT_HK
      , GL_ACCOUNT_NUMBER_BK
      , BKCC
      , REC_SRC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        GL_ACCOUNT_HK
      , KTOPL                                                        as                                   CHART_OF_ACCOUNT
      , SAKNR                                                        as                                  GL_ACCOUNT_NUMBER
      , CAST(ERDAT AS INTEGER)                                       as                               CREATE_DATE_YYYYMMDD
      , KTOKS                                                        as                                   GL_ACCOUNT_GROUP
      , XLOEV                                                        as                            MARKED_FOR_DELETION_IND
      , XSPEA                                                        as                           BLOCKED_FOR_CREATION_IND
      , XSPEB                                                        as                            BLOCKED_FOR_POSTING_IND
      , XSPEP                                                        as                           BLOCKED_FOR_PLANNING_IND
      , PSA_DELETE_IND
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , GL_ACCOUNT_HK
      , GL_ACCOUNT_NUMBER_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        GL_ACCOUNT_HK                                               as                             SAT_WINN_GL_ACCOUNT_HK
      , CHART_OF_ACCOUNT
      , GL_ACCOUNT_NUMBER
      , CREATE_DATE_YYYYMMDD
      , GL_ACCOUNT_GROUP
      , MARKED_FOR_DELETION_IND
      , BLOCKED_FOR_CREATION_IND
      , BLOCKED_FOR_POSTING_IND
      , BLOCKED_FOR_PLANNING_IND
      , PSA_DELETE_IND
    FROM LOGIC_SAT_WINN
)
---- FILTER LAYER ----

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_H
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_H.GL_ACCOUNT_HK = FILTER_SAT_WINN.SAT_WINN_GL_ACCOUNT_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , GL_ACCOUNT_HK
        , GL_ACCOUNT_NUMBER_BK
        , CHART_OF_ACCOUNT
        , GL_ACCOUNT_NUMBER
        , CREATE_DATE_YYYYMMDD
        , GL_ACCOUNT_GROUP
        , MARKED_FOR_DELETION_IND
        , BLOCKED_FOR_CREATION_IND
        , BLOCKED_FOR_POSTING_IND
        , BLOCKED_FOR_PLANNING_IND
        , BKCC
        , REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND
          END as IS_DELETED
FROM JOIN_RESULT

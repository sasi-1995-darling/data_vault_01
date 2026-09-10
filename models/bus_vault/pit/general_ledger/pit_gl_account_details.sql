{{
  config(
    materialized = 'incremental',
    unique_key='GL_ACCOUNT_DETAILS_HK',
    incremental_strategy= 'merge'
  )
}}

---- SRC LAYER ----
WITH
SRC_L              as ( SELECT * FROM {{ ref('lnk_gl_account_details') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_gl_company_code__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY GL_ACCOUNT_DETAILS_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_L              as ( SELECT * FROM RAW_VAULT.LNK_GL_ACCOUNT_DETAILS )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_GL_COMPANY_CODE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_L as (
    SELECT
        'PIT_GL_ACCOUNT_DETAILS'                                     as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , GL_ACCOUNT_HK
      , LEGAL_ENTITY_HK
      , GL_ACCOUNT_DETAILS_HK
      , REC_SRC
    FROM SRC_L
)

, LOGIC_SAT_WINN as (
    SELECT
        BUKRS                                                        as                                       COMPANY_CODE
      , SAKNR                                                        as                                  GL_ACCOUNT_NUMBER
      , CAST(ERDAT AS INTEGER)                                       as                              CREATE_DATE__YYYYMMDD
      , FDLEV                                                        as                                     PLANNING_LEVEL
      , FIPLS                                                        as                              FINANCIAL_BUDGET_ITEM
      , WAERS                                                        as                                      CURRENCY_CODE
      , XGKON                                                        as                           CASH_RECEIPT_ACCOUNT_IND
      , XINTB                                                        as                   AUTOMATICALLY_POSTED_ACCOUNT_IND
      , XKRES                                                        as                              LINE_ITEM_DISPLAY_IND
      , XLOEB                                                        as                            MARKED_FOR_DELETION_IND
      , XOPVW                                                        as                           OPEN_ITEM_MANAGEMENT_IND
      , XSPEB                                                        as                            BLOCKED_FOR_POSTING_IND
      , XSALH                                                        as                       MANAGE_IN_LOCAL_CURRENCY_IND
      , BKCC
      , GL_ACCOUNT_DETAILS_HK                                           as                        SAT_WINN_GL_ACCOUNT_DETAILS_HK
      , PSA_DELETE_IND
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_L as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , GL_ACCOUNT_HK
      , LEGAL_ENTITY_HK
      , GL_ACCOUNT_DETAILS_HK
      , REC_SRC
    FROM LOGIC_L
)

, RENAME_SAT_WINN as (
    SELECT
        COMPANY_CODE
      , GL_ACCOUNT_NUMBER
      , CREATE_DATE__YYYYMMDD
      , PLANNING_LEVEL
      , FINANCIAL_BUDGET_ITEM
      , CURRENCY_CODE
      , CASH_RECEIPT_ACCOUNT_IND
      , AUTOMATICALLY_POSTED_ACCOUNT_IND
      , LINE_ITEM_DISPLAY_IND
      , MARKED_FOR_DELETION_IND
      , OPEN_ITEM_MANAGEMENT_IND
      , BLOCKED_FOR_POSTING_IND
      , MANAGE_IN_LOCAL_CURRENCY_IND
      , BKCC
      , SAT_WINN_GL_ACCOUNT_DETAILS_HK
      , PSA_DELETE_IND
    FROM LOGIC_SAT_WINN
)
---- FILTER LAYER ----

, FILTER_L as (
    SELECT *
    FROM RENAME_L
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_L
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_L.GL_ACCOUNT_DETAILS_HK = FILTER_SAT_WINN.SAT_WINN_GL_ACCOUNT_DETAILS_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , GL_ACCOUNT_HK
        , LEGAL_ENTITY_HK
        , GL_ACCOUNT_DETAILS_HK
        , COMPANY_CODE
        , GL_ACCOUNT_NUMBER
        , CREATE_DATE__YYYYMMDD
        , PLANNING_LEVEL
        , FINANCIAL_BUDGET_ITEM
        , CURRENCY_CODE
        , CASH_RECEIPT_ACCOUNT_IND
        , AUTOMATICALLY_POSTED_ACCOUNT_IND
        , LINE_ITEM_DISPLAY_IND
        , MARKED_FOR_DELETION_IND
        , OPEN_ITEM_MANAGEMENT_IND
        , BLOCKED_FOR_POSTING_IND
        , MANAGE_IN_LOCAL_CURRENCY_IND
        , BKCC
        , REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED
FROM JOIN_RESULT
{% if is_incremental() %}
    WHERE GL_ACCOUNT_DETAILS_HK NOT IN (
        SELECT GL_ACCOUNT_DETAILS_HK 
        FROM {{ this }}
    )
    AND DATE(CREATE_DATE__YYYYMMDD) >= DATE_TRUNC('day', CURRENT_DATE() - 60)
{% endif %}

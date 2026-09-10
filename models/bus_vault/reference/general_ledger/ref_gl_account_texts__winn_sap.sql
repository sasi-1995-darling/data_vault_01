---- SRC LAYER ----
WITH
SRC_GLAT           as ( SELECT MANDT, SPRAS, KTOPL, SAKNR, MCOD1, TXT20, TXT50, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_gl_account_texts__winn_sap') }} as SRC 
                        WHERE SPRAS = 'E'
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY KTOPL, SAKNR ORDER BY LOAD_DTS desc))=1 )

/*
SRC_GLAT           as ( SELECT * FROM STAGING.V_PSA_STG_GL_ACCOUNT_TEXTS__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_GLAT as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , KTOPL                                                        as                                  CHART_OF_ACCOUNTS
      , SAKNR                                                        as                                  GL_ACCOUNT_NUMBER
      , TXT20                                                        as                              GL_ACCOUNT_SHORT_TEXT
      , TXT50                                                        as                               GL_ACCOUNT_LONG_TEXT
      , MCOD1                                                        as                                        SEARCH_TERM
      , LOAD_DTS
      , REC_SRC
    FROM SRC_GLAT
)
---- RENAME LAYER ----

, RENAME_GLAT as (
    SELECT
        CLIENT
      , LANGUAGE_KEY
      , CHART_OF_ACCOUNTS
      , GL_ACCOUNT_NUMBER
      , GL_ACCOUNT_SHORT_TEXT
      , GL_ACCOUNT_LONG_TEXT
      , SEARCH_TERM
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_GLAT
)
---- FILTER LAYER ----

, FILTER_GLAT as (
    SELECT *
    FROM RENAME_GLAT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_GLAT
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , LANGUAGE_KEY
        , CHART_OF_ACCOUNTS
        , GL_ACCOUNT_NUMBER
        , GL_ACCOUNT_SHORT_TEXT
        , GL_ACCOUNT_LONG_TEXT
        , SEARCH_TERM
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
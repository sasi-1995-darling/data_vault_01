---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_gl_header') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_gl_header__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY GENERAL_LEDGER_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_GL_HEADER )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_GL_HEADER__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_GENERAL_LEDGER'                                         as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , GENERAL_LEDGER_HK
      , COMPANY_CODE_BK
      , ACCOUNTING_DOC_NUM_BK
      , FISCAL_YEAR_BK
      , BKCC
      , REC_SRC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        GENERAL_LEDGER_HK 
      , BUKRS 
      , BELNR 
      , GJAHR 
      , BLART 
      , CAST(BLDAT as INTEGER)                                       as                            DOCUMENT_DATE__YYYYMMDD
      , CAST(BUDAT as INTEGER)                                       as                             POSTING_DATE__YYYYMMDD
      , MONAT 
      , CAST(CPUDT as INTEGER)                                       as                             DAY_OF_ENTRY__YYYYMMDD 
      , TO_TIME((CPUTM::VARCHAR), 'HH24MISS')                        as                             TIME_OF_ENTRY
      , XBLNR 
      , WAERS 
      , KURSF 
      , AWTYP 
      , AWKEY 
      , KURS2  
      , KURST 
      , CURT2 
      , KUTY2  
      , BKTXT
      , BSTAT
      , STBLG
      , CAST(STJAH as INTEGER)                                      as                 FISCAL_YEAR_REVERSAL_DOCUMENT__YYYY
      , STGRD 
      , PSA_DELETE_IND
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , GENERAL_LEDGER_HK
      , COMPANY_CODE_BK
      , ACCOUNTING_DOC_NUM_BK
      , FISCAL_YEAR_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        GENERAL_LEDGER_HK                                            as                         SAT_WINN_GENERAL_LEDGER_HK
      , BUKRS                                                        as                                       COMPANY_CODE
      , BELNR                                                        as                         ACCOUNTING_DOCUMENT_NUMBER
      , CAST(GJAHR as INTEGER)                                       as                                    ACCOUNTING_YEAR
      , BLART                                                        as                                      DOCUMENT_TYPE
      , DOCUMENT_DATE__YYYYMMDD
      , POSTING_DATE__YYYYMMDD
      , CAST(MONAT as INTEGER)                                       as                                      FISCAL_PERIOD
      , DAY_OF_ENTRY__YYYYMMDD
      , TIME_OF_ENTRY
      , XBLNR                                                        as                          REFERENCE_DOCUMENT_NUMBER
      , WAERS                                                        as                                       CURRENCY_KEY
      , KURSF                                                        as                                      EXCHANGE_RATE
      , AWTYP                                                        as                         REFERENCE_TRANSACTION_TYPE
      , AWKEY                                                        as                                      REFERENCE_KEY
      , KURS2                                                        as                         EXCHANGE_RATE_2ND_CURRENCY
      , KURST                                                        as                                 EXCHANGE_RATE_TYPE
      , CURT2                                                        as                                    CURRENCY_TYPE_2
      , KUTY2                                                        as                               EXCHANGE_RATE_TYPE_2
      , BKTXT                                                        as                               DOCUMENT_HEADER_TEXT
      , BSTAT                                                        as                                    DOCUMENT_STATUS
      , STBLG                                                        as                           REVERSAL_DOCUMENT_NUMBER
      , FISCAL_YEAR_REVERSAL_DOCUMENT__YYYY
      , STGRD                                                        as                                    REVERSAL_REASON
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
        ON FILTER_H.GENERAL_LEDGER_HK = FILTER_SAT_WINN.SAT_WINN_GENERAL_LEDGER_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , GENERAL_LEDGER_HK
        , COMPANY_CODE_BK
        , ACCOUNTING_DOC_NUM_BK
        , FISCAL_YEAR_BK
        , ACCOUNTING_YEAR
        , DOCUMENT_TYPE
        , DOCUMENT_DATE__YYYYMMDD
        , POSTING_DATE__YYYYMMDD
        , FISCAL_PERIOD
        , DAY_OF_ENTRY__YYYYMMDD
        , TIME_OF_ENTRY
        , REFERENCE_DOCUMENT_NUMBER
        , CURRENCY_KEY
        , EXCHANGE_RATE
        , REFERENCE_TRANSACTION_TYPE
        , REFERENCE_KEY
        , EXCHANGE_RATE_2ND_CURRENCY
        , EXCHANGE_RATE_TYPE
        , CURRENCY_TYPE_2
        , EXCHANGE_RATE_TYPE_2
        , DOCUMENT_HEADER_TEXT
        , DOCUMENT_STATUS
        , REVERSAL_DOCUMENT_NUMBER
        , FISCAL_YEAR_REVERSAL_DOCUMENT__YYYY
        , REVERSAL_REASON
        , BKCC
        , REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED
FROM JOIN_RESULT

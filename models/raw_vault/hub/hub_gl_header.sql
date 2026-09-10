---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_gl_header__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY GENERAL_LEDGER_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.V_PSA_STG_GL_HEADER__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        GENERAL_LEDGER_HK
      , COMPANY_CODE_BK
      , ACCOUNTING_DOC_NUM_BK
      , FISCAL_YEAR_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        GENERAL_LEDGER_HK
      , COMPANY_CODE_BK
      , ACCOUNTING_DOC_NUM_BK
      , FISCAL_YEAR_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SWINN
)
---- FILTER LAYER ----

, FILTER_SWINN as (
    SELECT *
    FROM RENAME_SWINN
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SWINN
)

---- FINAL LAYER ----
SELECT
          GENERAL_LEDGER_HK
        , COMPANY_CODE_BK
        , ACCOUNTING_DOC_NUM_BK
        , FISCAL_YEAR_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
  WHERE NOT EXISTS (
      SELECT 1 
      FROM {{ this }} existing
      WHERE existing.GENERAL_LEDGER_HK = JOIN_RESULT.GENERAL_LEDGER_HK
)
{% endif %}
{% if not is_incremental() %}
 union all
 
 SELECT MD5_BINARY(GR.VALUE) GENERAL_LEDGER_HK
 , GR.VALUE AS COMPANY_CODE_BK
 , GR.VALUE AS ACCOUNTING_DOC_NUM_BK
 , GR.VALUE AS FISCAL_YEAR_BK
 , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
 , CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS
 , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
 FROM
 TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
 {% endif %}
---- SRC LAYER ----
WITH
SRC_profit        as ( SELECT * FROM {{ ref('v_psa_stg_profit_center_line_item__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PROFIT_CENTER_POSTINGS_HK ORDER BY LOAD_DTS asc))=1 )
                        
/*
SRC_profit        as ( SELECT * FROM {{ ref('v_psa_stg_profit_center_line_item__winn_sap') }} as SRC 
*/
---- LOGIC LAYER ----

, LOGIC_profit as (
    SELECT
        PROFIT_CENTER_POSTINGS_HK
        , LEDGER_HK
        , LEGAL_ENTITY_HK
        , PROFIT_CENTER_HK
        , GL_ACCOUNT_HK
        , ACCOUNTING_FISCAL_PERIOD_HK
        , REFDOCNR
        , LOAD_DTS
        , REC_SRC
    FROM SRC_profit
)
---- RENAME LAYER ----

, RENAME_profit as (
    SELECT
        PROFIT_CENTER_POSTINGS_HK
        , LEDGER_HK
        , LEGAL_ENTITY_HK
        , PROFIT_CENTER_HK
        , GL_ACCOUNT_HK
        , ACCOUNTING_FISCAL_PERIOD_HK
        , REFDOCNR AS ENTRY_NUMBER
        , LOAD_DTS
        , REC_SRC
    FROM LOGIC_profit
)

---- FILTER LAYER ----

, FILTER_profit as (
    SELECT *
    FROM RENAME_profit
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_profit
)

---- FINAL LAYER ----
SELECT
        PROFIT_CENTER_POSTINGS_HK
        , LEDGER_HK
        , LEGAL_ENTITY_HK
        , PROFIT_CENTER_HK
        , GL_ACCOUNT_HK
        , ACCOUNTING_FISCAL_PERIOD_HK
        , ENTRY_NUMBER
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PROFIT_CENTER_POSTINGS_HK = JOIN_RESULT.PROFIT_CENTER_POSTINGS_HK
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PROFIT_CENTER_POSTINGS_HK,
MD5_BINARY(GR.VALUE) AS LEDGER_HK,
MD5_BINARY(GR.VALUE) AS LEGAL_ENTITY_HK,
MD5_BINARY(GR.VALUE) AS PROFIT_CENTER_HK,
MD5_BINARY(GR.VALUE) AS GL_ACCOUNT_HK,
MD5_BINARY(GR.VALUE) AS ACCOUNTING_FISCAL_PERIOD_HK,
GR.VALUE::text AS ENTRY_NUMBER,
CONVERT_TIMEZONE('UTC','1900-01-01') AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

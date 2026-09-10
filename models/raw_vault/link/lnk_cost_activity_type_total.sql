---- SRC LAYER ----
WITH
SRC_cosl           as ( SELECT * FROM {{ ref('v_psa_stg_cost_activity_type_total__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY COST_ACTIVITY_TYPE_TOTALS_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_cosl           as ( SELECT * FROM sap_ecc_prd.v_psa_stg_cost_activity_type_total )
*/
---- LOGIC LAYER ----

, LOGIC_cosl as (
    SELECT
        COST_ACTIVITY_TYPE_TOTALS_HK
      , OBJECT_NUMBER_HK
      , FISCAL_PERIOD_HK
      , COST_VALUE_TYPE_HK
      , COST_VERSION_HK
      , LEDGER_HK
      , COST_TRANSACTION_TYPE_HK
      , PERIOD_BLOCK_HK
      , LOAD_DTS 
      , BKCC
      , REC_SRC
    FROM SRC_cosl
)
---- RENAME LAYER ----

, RENAME_cosl as (
    SELECT
        COST_ACTIVITY_TYPE_TOTALS_HK
      , OBJECT_NUMBER_HK
      , FISCAL_PERIOD_HK
      , COST_VALUE_TYPE_HK
      , COST_VERSION_HK
      , LEDGER_HK
      , COST_TRANSACTION_TYPE_HK
      , PERIOD_BLOCK_HK
      , LOAD_DTS 
      , BKCC
      , REC_SRC
    FROM LOGIC_cosl
)
---- FILTER LAYER ----

, FILTER_cosl as (
    SELECT *
    FROM RENAME_cosl
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_cosl
)

---- FINAL LAYER ----
SELECT
          COST_ACTIVITY_TYPE_TOTALS_HK
        , OBJECT_NUMBER_HK
        , FISCAL_PERIOD_HK
        , COST_VALUE_TYPE_HK
        , COST_VERSION_HK
        , LEDGER_HK
        , COST_TRANSACTION_TYPE_HK
        , PERIOD_BLOCK_HK
        , LOAD_DTS 
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.COST_ACTIVITY_TYPE_TOTALS_HK= JOIN_RESULT.COST_ACTIVITY_TYPE_TOTALS_HK
)
{% endif %}

{% if not is_incremental() %}
union all
SELECT 
 MD5_BINARY(GR.VALUE) AS COST_ACTIVITY_TYPE_TOTALS_HK
, MD5_BINARY(GR.VALUE) AS OBJECT_NUMBER_HK
, MD5_BINARY(GR.VALUE) AS FISCAL_PERIOD_HK
, MD5_BINARY(GR.VALUE) AS COST_VALUE_TYPE_HK
, MD5_BINARY(GR.VALUE) AS COST_VERSION_HK
, MD5_BINARY(GR.VALUE) AS LEDGER_HK
, MD5_BINARY(GR.VALUE) AS COST_TRANSACTION_TYPE_HK
, MD5_BINARY(GR.VALUE) AS PERIOD_BLOCK_HK
, CONVERT_TIMEZONE('UTC','1900-01-01')  AS LOAD_DTS
, DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
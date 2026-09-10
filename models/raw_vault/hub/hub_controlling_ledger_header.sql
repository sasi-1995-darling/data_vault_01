---- SRC LAYER ----
WITH
SRC_c           as ( SELECT * FROM {{ ref('v_psa_stg_controlling_ledger_entry__winn_sap') }} as SRC
                       QUALIFY (ROW_NUMBER() OVER(PARTITION BY CONTROLLING_LEDGER_HEADER_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_c           as ( SELECT * FROM staging.V_PSA_STG_CONTROLLING_LEDGER_ENTRY__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_c as (
    SELECT
        CONTROLLING_LEDGER_HEADER_HK
      , CONTROLLING_LEDGER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_c
)
---- RENAME LAYER ----

, RENAME_c as (
    SELECT
        CONTROLLING_LEDGER_HEADER_HK
      , CONTROLLING_LEDGER_HEADER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_c
)
---- FILTER LAYER ----

, FILTER_c as (
    SELECT *
    FROM RENAME_c
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_c
)

---- FINAL LAYER ----
SELECT
          CONTROLLING_LEDGER_HEADER_HK
        , CONTROLLING_LEDGER_HEADER_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CONTROLLING_LEDGER_HEADER_HK = JOIN_RESULT.CONTROLLING_LEDGER_HEADER_HK
)
{% endif %}

{% if not is_incremental() %}
 union all
 SELECT
   MD5_BINARY(GR.VALUE) AS CONTROLLING_LEDGER_HEADER_HK
 , GR.VALUE AS CONTROLLING_LEDGER_HEADER_BK
 , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
 , CONVERT_TIMEZONE('UTC','1900-01-01') AS LOAD_DTS
 , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
 FROM
 TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
 {% endif %}
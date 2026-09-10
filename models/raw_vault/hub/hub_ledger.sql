---- SRC LAYER ----
WITH
SRC_COST         as ( SELECT * FROM {{ ref('v_psa_stg_controlling_ledger_entry__winn_sap') }} as SRC
                       QUALIFY (ROW_NUMBER() OVER(PARTITION BY LEDGER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PROFIT       as ( SELECT * FROM {{ ref('v_psa_stg_profit_center_line_item__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LEDGER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_LEDGER       as ( SELECT LEDGER_HK, LEDGER_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_ledger__winn_sap') }} as SRC
                       QUALIFY (ROW_NUMBER() OVER(PARTITION BY LEDGER_HK ORDER BY LOAD_DTS ))=1 ),
SRC_LEL       as ( SELECT LEDGER_HK, LEDGER_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_legal_entity_ledger__winn_sap') }} as SRC
                       QUALIFY (ROW_NUMBER() OVER(PARTITION BY LEDGER_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_COST         as ( SELECT * FROM staging.v_psa_stg_controlling_ledger_entry__winn_sap )
SRC_PROFIT       as ( SELECT * FROM staging.v_psa_stg_profit_center_line_item__winn_sap )
SRC_LEDGER       as ( SELECT * FROM staging.v_psa_stg_ledger__winn_sap )
SRC_LEL          as ( SELECT * FROM staging.v_psa_stg_legal_entity_ledger__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_COST as (
    SELECT
        LEDGER_HK
      , LEDGER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_COST
)

, LOGIC_PROFIT as (
    SELECT
        LEDGER_HK
      , LEDGER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PROFIT
)

, LOGIC_LEDGER as (
    SELECT
        LEDGER_HK
      , LEDGER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_LEDGER
)

, LOGIC_LEL as (
    SELECT
        LEDGER_HK
      , LEDGER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_LEL
)
---- RENAME LAYER ----

, RENAME_COST as (
    SELECT
        LEDGER_HK
      , LEDGER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_COST
)

, RENAME_PROFIT as (
    SELECT
        LEDGER_HK
      , LEDGER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PROFIT
)

, RENAME_LEDGER as (
    SELECT
        LEDGER_HK
      , LEDGER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_LEDGER
)

, RENAME_LEL as (
    SELECT
        LEDGER_HK
      , LEDGER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_LEL
)
---- FILTER LAYER ----

, FILTER_COST as (
    SELECT *
    FROM RENAME_COST
)

, FILTER_PROFIT as (
    SELECT *
    FROM RENAME_PROFIT
)

, FILTER_LEDGER as (
    SELECT *
    FROM RENAME_LEDGER
)

, FILTER_LEL as (
    SELECT *
    FROM RENAME_LEL
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_COST
    UNION ALL
    SELECT *
    FROM FILTER_PROFIT
    UNION ALL
    SELECT *
    FROM FILTER_LEDGER
    UNION ALL
    SELECT *
    FROM FILTER_LEL
)

---- FINAL LAYER ----
SELECT
          LEDGER_HK
        , LEDGER_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LEDGER_HK = JOIN_RESULT.LEDGER_HK
)
{% endif %}
QUALIFY ROW_NUMBER() OVER(PARTITION BY LEDGER_HK, BKCC ORDER BY LOAD_DTS DESC)=1
{% if not is_incremental() %}
 union all
 SELECT
   MD5_BINARY(GR.VALUE) AS LEDGER_HK
 , GR.VALUE AS LEDGER_BK
 , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
 , CONVERT_TIMEZONE('UTC','1900-01-01') AS LOAD_DTS
 , 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
 FROM
 TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
 {% endif %}
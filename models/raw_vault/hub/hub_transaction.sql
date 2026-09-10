---- SRC LAYER ----
WITH
SRC_HT             as ( SELECT BKCC, LOAD_DTS, REC_SRC, TRANSACTION_BK, TRANSACTION_HK FROM {{ ref('v_psa_stg_balance_transaction_flo_sense') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY TRANSACTION_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_HT             as ( SELECT * FROM STAGING.v_psa_stg_balance_transaction_flo_sense )
*/
---- LOGIC LAYER ----

, LOGIC_HT as (
    SELECT
        TRANSACTION_HK
      , TRANSACTION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_HT
)
---- RENAME LAYER ----

, RENAME_HT as (
    SELECT
        TRANSACTION_HK
      , TRANSACTION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_HT
)
---- FILTER LAYER ----

, FILTER_HT as (
    SELECT *
    FROM RENAME_HT
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_HT
)

---- FINAL LAYER ----
SELECT
          TRANSACTION_HK
        , TRANSACTION_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.TRANSACTION_HK = JOIN_RESULT.TRANSACTION_HK
)
{% endif %}
{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE) as  TRANSACTION_HK
, GR.VALUE  AS TRANSACTION_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
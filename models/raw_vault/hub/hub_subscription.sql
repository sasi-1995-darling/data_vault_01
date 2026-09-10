---- SRC LAYER ----
WITH
SRC_FU             as ( SELECT BKCC, LOAD_DTS, REC_SRC, SUBSCRIPTION_BK, SUBSCRIPTION_HK FROM {{ ref('v_psa_stg_subscription__winn_prive') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUBSCRIPTION_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_FU             as ( SELECT * FROM STAGING.v_psa_stg_subscription__winn_prive )
*/
---- LOGIC LAYER ----

, LOGIC_FU as (
    SELECT
        SUBSCRIPTION_HK
      , SUBSCRIPTION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_FU
)
---- RENAME LAYER ----

, RENAME_FU as (
    SELECT
        SUBSCRIPTION_HK
      , SUBSCRIPTION_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_FU
)
---- FILTER LAYER ----

, FILTER_FU as (
    SELECT *
    FROM RENAME_FU
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_FU
)

---- FINAL LAYER ----
SELECT
          SUBSCRIPTION_HK
        , SUBSCRIPTION_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SUBSCRIPTION_HK = JOIN_RESULT.SUBSCRIPTION_HK
)
{% endif %}
{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE)  as SUBSCRIPTION_HK
, GR.VALUE  AS SUBSCRIPTION_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
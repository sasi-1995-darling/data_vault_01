---- SRC LAYER ----
WITH
SRC_ALM            as ( SELECT ALARM_BK, ALARM_HK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_alarm') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ALARM_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_ALM            as ( SELECT * FROM STAGING.v_psa_stg_alarm )
*/
---- LOGIC LAYER ----

, LOGIC_ALM as (
    SELECT
        ALARM_HK
      , ALARM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ALM
)
---- RENAME LAYER ----

, RENAME_ALM as (
    SELECT
        ALARM_HK
      , ALARM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ALM
)
---- FILTER LAYER ----

, FILTER_ALM as (
    SELECT *
    FROM RENAME_ALM
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_ALM
)

---- FINAL LAYER ----
SELECT
          ALARM_HK
        , ALARM_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ALARM_HK = JOIN_RESULT.ALARM_HK
)
{% endif %}
{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE)  as ALARM_HK
, GR.VALUE  AS ALARM_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
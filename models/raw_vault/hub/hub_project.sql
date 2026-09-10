---- SRC LAYER ----
WITH
SRC_PRJ            as ( SELECT * FROM {{ ref('v_psa_stg_centercode') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PROJECT_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_PRJ            as ( SELECT * FROM STAGING.v_psa_stg_centercode )
*/
---- LOGIC LAYER ----

, LOGIC_PRJ as (
    SELECT
        PROJECT_HK
      , PROJECT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PRJ
)
---- RENAME LAYER ----

, RENAME_PRJ as (
    SELECT
        PROJECT_HK
      , PROJECT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PRJ
)
---- FILTER LAYER ----

, FILTER_PRJ as (
    SELECT *
    FROM RENAME_PRJ
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PRJ
)

---- FINAL LAYER ----
SELECT
          PROJECT_HK
        , PROJECT_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PROJECT_HK = JOIN_RESULT.PROJECT_HK
)
{% endif %}
{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE)  PROJECT_HK
, GR.VALUE  AS PROJECT_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
---- SRC LAYER ----
WITH
SRC_FD             as ( SELECT BKCC, LOAD_DTS, REC_SRC, RESPONSE_BK, RESPONSE_HK FROM {{ ref('v_psa_stg_response__simplesat') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY RESPONSE_HK ORDER BY LOAD_DTS ))=1 )

, SRC_YALE          as ( SELECT BKCC, LOAD_DTS, REC_SRC, RESPONSE_BK, RESPONSE_HK FROM {{ ref('v_psa_stg_response__simplesat_yale') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY RESPONSE_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_FD             as ( SELECT * FROM STAGING.v_psa_stg_response__simplesat )
SRC_YALE           as ( SELECT * FROM STAGING.v_psa_stg_response__simplesat_yale )
*/
---- LOGIC LAYER ----

, LOGIC_FD as (
    SELECT
        RESPONSE_HK
      , RESPONSE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_FD
)

, LOGIC_YALE as (
    SELECT
        RESPONSE_HK
      , RESPONSE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_YALE
)
---- RENAME LAYER ----

, RENAME_FD as (
    SELECT
        RESPONSE_HK
      , RESPONSE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_FD
)

, RENAME_YALE as (
    SELECT
        RESPONSE_HK
      , RESPONSE_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_YALE
)
---- FILTER LAYER ----

, FILTER_FD as (
    SELECT *
    FROM RENAME_FD
)

, FILTER_YALE as (
    SELECT *
    FROM RENAME_YALE
)
---- JOIN LAYER ----
-- Consolidate records from multiple sources with the same BKCC
, JOIN_RESULT as (
    SELECT * FROM FILTER_FD
    UNION ALL
    SELECT * FROM FILTER_YALE
)

---- FINAL LAYER ----
SELECT
          RESPONSE_HK
        , RESPONSE_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT

{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.RESPONSE_HK = JOIN_RESULT.RESPONSE_HK
)
{% endif %}
QUALIFY (ROW_NUMBER() OVER(PARTITION BY RESPONSE_HK ORDER BY LOAD_DTS))=1
{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE) AS RESPONSE_HK
, GR.VALUE::integer  AS RESPONSE_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
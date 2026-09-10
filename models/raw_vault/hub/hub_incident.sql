---- SRC LAYER ----
WITH
SRC_INC            as ( SELECT BKCC, INCIDENT_BK, INCIDENT_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_incident') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY INCIDENT_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_INC            as ( SELECT * FROM STAGING.v_psa_stg_incident )
*/
---- LOGIC LAYER ----

, LOGIC_INC as (
    SELECT
        INCIDENT_HK
      , INCIDENT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_INC
)
---- RENAME LAYER ----

, RENAME_INC as (
    SELECT
        INCIDENT_HK
      , INCIDENT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_INC
)
---- FILTER LAYER ----

, FILTER_INC as (
    SELECT *
    FROM RENAME_INC
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_INC
)

---- FINAL LAYER ----
SELECT
          INCIDENT_HK
        , INCIDENT_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.INCIDENT_HK = JOIN_RESULT.INCIDENT_HK
)
{% endif %}
{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE)  as INCIDENT_HK
, GR.VALUE  AS INCIDENT_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
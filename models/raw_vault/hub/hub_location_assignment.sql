---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT LOCATION_ASSIGNMENT_HK, LOCATION_ASSIGNMENT_BK, LOAD_DTS, BKCC, REC_SRC FROM {{ ref('v_psa_stg_location_assignment__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LOCATION_ASSIGNMENT_HK ORDER BY LOAD_DTS)) = 1 )

/*
SRC_SRC            as ( SELECT * FROM int_staging_views.v_psa_stg_location_assignment__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        LOCATION_ASSIGNMENT_HK
      , LOCATION_ASSIGNMENT_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_SRC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
)

---- FINAL LAYER ----
SELECT
          LOCATION_ASSIGNMENT_HK
        , LOCATION_ASSIGNMENT_BK
        , LOAD_DTS
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.LOCATION_ASSIGNMENT_HK = JOIN_RESULT.LOCATION_ASSIGNMENT_HK
)
{% endif %}
/* Safety dedup — matches production hub pattern */
QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY LOCATION_ASSIGNMENT_BK, BKCC ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LOCATION_ASSIGNMENT_HK,
GR.VALUE::text AS LOCATION_ASSIGNMENT_BK,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

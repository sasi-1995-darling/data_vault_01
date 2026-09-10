---- SRC LAYER ----
WITH
SRC_equi           as ( SELECT EQUIPMENT_HK, EQUIPMENT_BK, LOAD_DTS, BKCC, REC_SRC FROM {{ ref('v_psa_stg_equipment__winn_sap') }} )
, SRC_equz          as ( SELECT EQUIPMENT_HK, EQUIPMENT_BK, LOAD_DTS, BKCC, REC_SRC FROM {{ ref('v_psa_stg_equipment_location_assignment__winn_sap') }} )

/*
SRC_equi           as ( SELECT * FROM int_staging_views.v_psa_stg_equipment__winn_sap )
SRC_equz           as ( SELECT * FROM int_staging_views.v_psa_stg_equipment_location_assignment__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_equi as (
    SELECT
        EQUIPMENT_HK
      , EQUIPMENT_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_equi
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY EQUIPMENT_HK ORDER BY LOAD_DTS)) = 1
)

, LOGIC_equz as (
    SELECT
        EQUIPMENT_HK
      , EQUIPMENT_BK
      , LOAD_DTS
      , BKCC
      , REC_SRC
    FROM SRC_equz
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY EQUIPMENT_HK ORDER BY LOAD_DTS)) = 1
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM LOGIC_equi
    UNION ALL
    SELECT * FROM LOGIC_equz
)

---- FINAL LAYER ----
SELECT
          EQUIPMENT_HK
        , EQUIPMENT_BK
        , LOAD_DTS
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.EQUIPMENT_HK = JOIN_RESULT.EQUIPMENT_HK
)
{% endif %}
QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY EQUIPMENT_BK, BKCC ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS EQUIPMENT_HK,
GR.VALUE::text AS EQUIPMENT_BK,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

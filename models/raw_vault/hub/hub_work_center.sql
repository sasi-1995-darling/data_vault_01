---- SRC LAYER ----
WITH
SRC_s              as ( SELECT WORK_CENTER_HK, WORK_CENTER_BK, PLANT_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_work_center_capacity__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY WORK_CENTER_HK, PLANT_BK ORDER BY LOAD_DTS ))=1 ),
SRC_crtx           as ( SELECT WORK_CENTER_HK, WORK_CENTER_BK, PLANT_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_work_center__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY WORK_CENTER_HK,PLANT_BK ORDER BY LOAD_DTS ))=1 ),
SRC_crca           as ( SELECT WORK_CENTER_HK, WORK_CENTER_BK, PLANT_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_work_center_capacity_allocation__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY WORK_CENTER_HK,PLANT_BK ORDER BY LOAD_DTS ))=1 )                        
/*
SRC_s              as ( SELECT * FROM STAGING.V_PSA_STG_WORK_CENTER_CAPACITY__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        WORK_CENTER_HK
      , WORK_CENTER_BK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_s
)

, LOGIC_crtx as (
    SELECT
        WORK_CENTER_HK
      , WORK_CENTER_BK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_crtx
)

, LOGIC_crca as (
    SELECT
        WORK_CENTER_HK
      , WORK_CENTER_BK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_crca
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        WORK_CENTER_HK
      , WORK_CENTER_BK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_s
)

, RENAME_crtx as (
    SELECT
        WORK_CENTER_HK
      , WORK_CENTER_BK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_crtx
)

, RENAME_crca as (
    SELECT
        WORK_CENTER_HK
      , WORK_CENTER_BK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_crca
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_crtx as (
    SELECT *
    FROM RENAME_crtx
)

, FILTER_crca as (
    SELECT *
    FROM RENAME_crca
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    UNION ALL
    SELECT *
    FROM FILTER_crtx
    UNION ALL
    SELECT *
    FROM FILTER_crca 
)

---- FINAL LAYER ----
SELECT
          WORK_CENTER_HK
        , WORK_CENTER_BK
        , PLANT_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.WORK_CENTER_HK = JOIN_RESULT.WORK_CENTER_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY WORK_CENTER_HK ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS WORK_CENTER_HK,
GR.VALUE::text AS WORK_CENTER_BK,
GR.VALUE::text AS PLANT_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
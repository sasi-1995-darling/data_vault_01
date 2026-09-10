---- SRC LAYER ----
WITH
SRC_b              as ( SELECT CAPACITY_HK, LNK_PLANT_CAPACITY_HK, LOAD_DTS, PLANT_HK, REC_SRC, UOM_HK FROM {{ ref('v_psa_stg_capacity_header__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_PLANT_CAPACITY_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_b              as ( SELECT * FROM STAGING.V_PSA_STG_CAPACITY_HEADER__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        LNK_PLANT_CAPACITY_HK
      , PLANT_HK
      , UOM_HK
      , CAPACITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        LNK_PLANT_CAPACITY_HK
      , PLANT_HK
      , UOM_HK
      , CAPACITY_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_b
)

---- FINAL LAYER ----
SELECT
          LNK_PLANT_CAPACITY_HK
        , PLANT_HK
        , UOM_HK
        , CAPACITY_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_PLANT_CAPACITY_HK = JOIN_RESULT.LNK_PLANT_CAPACITY_HK 
    AND existing.CAPACITY_HK = JOIN_RESULT.CAPACITY_HK     
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_PLANT_CAPACITY_HK,
MD5_BINARY(GR.VALUE) AS PLANT_HK,
MD5_BINARY(GR.VALUE) AS UOM_HK,
MD5_BINARY(GR.VALUE) AS CAPACITY_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
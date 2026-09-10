---- SRC LAYER ----
WITH
SRC_mv            as ( SELECT * FROM {{ ref('v_psa_stg_material_valuation__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_MATERIAL_VALUATION_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_mv            as ( SELECT * FROM staging.v_psa_stg_material_valuation__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_mv as (
    SELECT
        LNK_MATERIAL_VALUATION_HK                                      
      , PLANT_HK                                
      , ITEM_HK
      , BWTAR           as          BWTAR_DC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_mv
)

---- RENAME LAYER ----

, RENAME_mv as (
    SELECT
        LNK_MATERIAL_VALUATION_HK
      , PLANT_HK
      , ITEM_HK
      , BWTAR_DC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_mv
)

---- FILTER LAYER ----

, FILTER_mv as (
    SELECT *
    FROM RENAME_mv
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_mv
)

---- FINAL LAYER ----
SELECT
        LNK_MATERIAL_VALUATION_HK                                      
    , PLANT_HK                                
    , ITEM_HK
    , BWTAR_DC
    , LOAD_DTS
    , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_MATERIAL_VALUATION_HK = JOIN_RESULT.LNK_MATERIAL_VALUATION_HK 
)
{% endif %}

{% if not is_incremental() %}
union all
SELECT 

MD5_BINARY(GR.VALUE) AS LNK_MATERIAL_VALUATION_HK
, MD5_BINARY(GR.VALUE) AS PLANT_HK 
, MD5_BINARY(GR.VALUE) AS ITEM_HK
, NULL AS BWTAR_DC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
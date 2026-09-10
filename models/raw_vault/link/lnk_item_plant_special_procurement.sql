---- SRC LAYER ----
WITH
SRC_b              as ( SELECT LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK, ITEM_HK, PLANT_HK, SOBSL, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_plant_item__moen_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK ORDER BY LOAD_DTS desc))=1 ) 

/*
SRC_b              as ( SELECT * FROM STAGING.v_psa_stg_plant_item__moen_sap )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK
      , ITEM_HK
      , PLANT_HK
      , SOBSL
      , LOAD_DTS
      , REC_SRC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK
      , ITEM_HK
      , PLANT_HK
      , SOBSL
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
          LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK
        , ITEM_HK
        , PLANT_HK
        , SOBSL
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK = JOIN_RESULT.LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_ITEM_PLANT_SPECIAL_PROCUREMENT_HK,
MD5_BINARY(GR.VALUE) AS ITEM_HK,
MD5_BINARY(GR.VALUE) AS PLANT_HK,
NULL AS SOBSL,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
---- SRC LAYER ----
WITH
SRC_bom            as ( SELECT * FROM {{ ref('v_psa_stg_bom_component_item__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_BOM_ITEM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_bom_c          as ( SELECT * FROM {{ ref('v_psa_stg_bom_components__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY LNK_BOM_ITEM_HK ORDER BY LOAD_DTS ))=1 )                        

/*
  SRC_bom            as ( SELECT * FROM STAGING.V_PSA_STG_BOM_COMPONENT_ITEM__WINN_SAP )
, SRC_bom_c          as ( SELECT * FROM staging.V_PSA_STG_BOM_COMPONENTS__ML_EBS )
*/
---- LOGIC LAYER ----

, LOGIC_bom as (
    SELECT
        LNK_BOM_ITEM_HK
      , BOM_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_bom
)

, LOGIC_bom_c as (
    SELECT
        LNK_BOM_ITEM_HK
      , BOM_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_bom_c
)
---- RENAME LAYER ----

, RENAME_bom as (
    SELECT
        LNK_BOM_ITEM_HK
      , BOM_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_bom
)

, RENAME_bom_c as (
    SELECT
        LNK_BOM_ITEM_HK
      , BOM_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_bom_c
)
---- FILTER LAYER ----

, FILTER_bom as (
    SELECT *
    FROM RENAME_bom
)

, FILTER_bom_c as (
    SELECT *
    FROM RENAME_bom_c
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_bom
    UNION ALL
    SELECT * FROM FILTER_bom_c
)

---- FINAL LAYER ----
SELECT
          LNK_BOM_ITEM_HK
        , BOM_HK
        , ITEM_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_BOM_ITEM_HK = JOIN_RESULT.LNK_BOM_ITEM_HK
)
{% endif %}
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_BOM_ITEM_HK,
MD5_BINARY(GR.VALUE) AS BOM_HK,
MD5_BINARY(GR.VALUE) AS ITEM_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
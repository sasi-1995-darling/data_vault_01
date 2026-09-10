---- SRC LAYER ----
WITH
SRC_DAS            as ( SELECT * FROM {{ ref('v_psa_stg_item_special_procurement_plant__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK ORDER BY LOAD_DTS))=1 )

/*
SRC_DAS            as ( SELECT * FROM STAGING.v_psa_stg_item_special_procurement_plant__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_DAS as (
    SELECT
        SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK
      , PLANT_HK
      , PLANT_TRANSFER_HK
      , SOBSL
      , LOAD_DTS
      , REC_SRC
    FROM SRC_DAS
)
---- RENAME LAYER ----

, RENAME_DAS as (
    SELECT
        SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK
      , PLANT_HK
      , PLANT_TRANSFER_HK
      , SOBSL
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_DAS
)
---- FILTER LAYER ----

, FILTER_DAS as (
    SELECT *
    FROM RENAME_DAS
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_DAS
)

---- FINAL LAYER ----
SELECT
          SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK
        , PLANT_HK
        , PLANT_TRANSFER_HK
        , SOBSL
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK = JOIN_RESULT.SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK
)
{% endif %}

{% if not is_incremental() %}

union all
SELECT 
 MD5_BINARY(GR.VALUE) AS SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK
, MD5_BINARY(GR.VALUE) AS PLANT_HK
, MD5_BINARY(GR.VALUE) AS PLANT_TRANSFER_HK
, GR.VALUE AS SOBSL
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
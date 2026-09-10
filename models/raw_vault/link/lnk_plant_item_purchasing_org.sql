---- SRC LAYER ---- 
WITH
SRC_SPPI          as ( SELECT * FROM {{ ref('v_psa_stg_plant_item__moen_sap') }} as SRC 
                       QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_PURCHASING_ORG_LHK ORDER BY LOAD_DTS ))=1 )                                               

/*
SRC_SPPI          as ( SELECT * FROM STAGING.v_psa_stg_plant_item__moen_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SPPI as (
    SELECT
        PLANT_ITEM_PURCHASING_ORG_LHK
      , PLANT_HK
      , ITEM_HK
	  , PURCHASING_ORG_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPPI
)

---- RENAME LAYER ----

, RENAME_SPPI as (
    SELECT
        PLANT_ITEM_PURCHASING_ORG_LHK
      , PLANT_HK
      , ITEM_HK
	  , PURCHASING_ORG_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPPI
)

---- FILTER LAYER ----

, FILTER_SPPI as (
    SELECT *
    FROM RENAME_SPPI
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SPPI
)

---- FINAL LAYER ----
SELECT
		  PLANT_ITEM_PURCHASING_ORG_LHK
	    , PLANT_HK
	    , ITEM_HK
	    , PURCHASING_ORG_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PLANT_ITEM_PURCHASING_ORG_LHK = JOIN_RESULT.PLANT_ITEM_PURCHASING_ORG_LHK
)
{% endif %}
--this is to consolidate records coming from multiple diff tables with the same bkcc
QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_PURCHASING_ORG_LHK ORDER BY LOAD_DTS))=1
{% if not is_incremental() %}
union all
SELECT 
  MD5_BINARY(GR.VALUE) as PLANT_ITEM_PURCHASING_ORG_LHK
, MD5_BINARY(GR.VALUE) as PLANT_HK
, MD5_BINARY(GR.VALUE) as ITEM_HK
, MD5_BINARY(GR.VALUE) as PURCHASING_ORG_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
---- SRC LAYER ----
WITH
SRC_DC             as ( SELECT * FROM {{ ref('v_psa_stg_dc_inventory_with_store__homedepot_ft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_DC             as ( SELECT * FROM STAGING.v_psa_stg_dc_inventory_with_store__homedepot_ft )
*/
---- LOGIC LAYER ----

, LOGIC_DC as (
    SELECT
        HOME_DEPOT_ACCOUNT
      , DAY_1
      , MANUF_PART_NUMBER
      , SKU_NBR
      , STORE_HK
      , LOAD_DTS
      , D_DC_NAME
      , D_DH_DC_NBR
      , M_DC_OH_UNITS
      , M_DC_OH_AMT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , HASHDIFF
      , REC_SRC
      , BKCC
    FROM SRC_DC
)
---- RENAME LAYER ----

, RENAME_DC as (
    SELECT
        HOME_DEPOT_ACCOUNT
      , DAY_1
      , MANUF_PART_NUMBER
      , SKU_NBR
      , STORE_HK
      , LOAD_DTS
      , D_DC_NAME
      , D_DH_DC_NBR
      , M_DC_OH_UNITS
      , M_DC_OH_AMT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , HASHDIFF
      , REC_SRC
      , BKCC
    FROM LOGIC_DC
)
---- FILTER LAYER ----

, FILTER_DC as (
    SELECT *
    FROM RENAME_DC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_DC
)

---- FINAL LAYER ----
SELECT
          HOME_DEPOT_ACCOUNT
        , DAY_1
        , MANUF_PART_NUMBER
        , SKU_NBR
        , STORE_HK
        , LOAD_DTS
        , D_DC_NAME
        , D_DH_DC_NBR
        , M_DC_OH_UNITS
        , M_DC_OH_AMT
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , HASHDIFF
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
	WHERE existing.HOME_DEPOT_ACCOUNT=JOIN_RESULT.HOME_DEPOT_ACCOUNT
    AND existing.DAY_1 = JOIN_RESULT.DAY_1 
	AND existing.MANUF_PART_NUMBER=JOIN_RESULT.MANUF_PART_NUMBER
	AND existing.STORE_HK=JOIN_RESULT.STORE_HK
	AND existing.SKU_NBR=JOIN_RESULT.SKU_NBR
	AND existing.LOAD_DTS=JOIN_RESULT.LOAD_DTS	
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	)
{% endif %}



{% if not is_incremental() %}
qualify 1=row_number() over(partition by HOME_DEPOT_ACCOUNT,DAY_1,MANUF_PART_NUMBER,SKU_NBR,STORE_HK, hashdiff order by LOAD_DTS desc)
{% endif %}
{% if not is_incremental() %}
UNION ALL
SELECT
GR.VALUE AS HOME_DEPOT_ACCOUNT,
'1900-01-01'::DATE AS DAY_1,
GR.VALUE AS MANUF_PART_NUMBER,
GR.VALUE AS SKU_NBR,
MD5_BINARY(GR.VALUE) AS STORE_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP_LTZ) AS LOAD_DTS,
GR.VALUE AS D_DC_NAME,
GR.VALUE AS D_DH_DC_NBR,
NULL AS M_DC_OH_UNITS,
NULL AS M_DC_OH_AMT,
'1900-01-01'::TIMESTAMP_LTZ AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
NULL AS PSA_DELETE_IND,
MD5_BINARY(GR.VALUE) AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
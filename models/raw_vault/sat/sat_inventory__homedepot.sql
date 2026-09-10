---- SRC LAYER ----
WITH
SRC_SIH            as ( SELECT * FROM {{ ref('v_psa_stg_inventory__homedepot') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SIH            as ( SELECT * FROM STAGING.v_psa_stg_inventory__homedepot )
*/
---- LOGIC LAYER ----

, LOGIC_SIH as (
    SELECT
        STORE_HK
      , DAY
      , MANUF_PART_NUMBER
      , SKU_NBR
      , D_STORE_NBR
      , MERCH_VENDOR
      , SKU_STATUS
      , HOME_DEPOT_ACCOUNT
      , LOAD_DTS
      , STR_OH
      , STR_OH_UNITS_DLY
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SIH
)
---- RENAME LAYER ----

, RENAME_SIH as (
    SELECT
        STORE_HK
      , DAY
      , MANUF_PART_NUMBER
      , SKU_NBR
      , D_STORE_NBR
      , MERCH_VENDOR
      , SKU_STATUS
      , HOME_DEPOT_ACCOUNT
      , LOAD_DTS
      , STR_OH
      , STR_OH_UNITS_DLY
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SIH
)
---- FILTER LAYER ----

, FILTER_SIH as (
    SELECT *
    FROM RENAME_SIH
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SIH
)

---- FINAL LAYER ----
SELECT
          STORE_HK
        , DAY
        , MANUF_PART_NUMBER
        , SKU_NBR
        , D_STORE_NBR
        , MERCH_VENDOR
        , SKU_STATUS
        , HOME_DEPOT_ACCOUNT
        , LOAD_DTS
        , STR_OH
        , STR_OH_UNITS_DLY
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.STORE_HK = JOIN_RESULT.STORE_HK 
	AND existing.DAY=JOIN_RESULT.DAY
	AND existing.MANUF_PART_NUMBER=JOIN_RESULT.MANUF_PART_NUMBER
	AND existing.SKU_NBR=JOIN_RESULT.SKU_NBR
	AND existing.D_STORE_NBR=JOIN_RESULT.D_STORE_NBR
	AND existing.MERCH_VENDOR=JOIN_RESULT.MERCH_VENDOR
	AND existing.SKU_STATUS=JOIN_RESULT.SKU_STATUS
	AND existing.HOME_DEPOT_ACCOUNT=JOIN_RESULT.HOME_DEPOT_ACCOUNT
	AND existing.LOAD_DTS=JOIN_RESULT.LOAD_DTS	
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}



{% if not is_incremental() %}
qualify 1=row_number() over(partition by store_hk, day, sku_nbr, manuf_part_number, d_store_nbr, merch_vendor, sku_status, home_depot_account, hashdiff order by psa_load_dts)
union all
SELECT MD5_BINARY(GR.VALUE::varchar) AS STORE_HK
	, GR.VALUE::varchar as DAY
	, GR.VALUE:: varchar as MANUF_PART_NUMBER
	, GR.VALUE::varchar as SKU_NBR
	, GR.VALUE::varchar as D_STORE_NBR
	, GR.VALUE::varchar as MERCH_VENDOR
	, GR.VALUE::varchar as SKU_STATUS
	, GR.VALUE::varchar as HOME_DEPOT_ACCOUNT
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, null as STR_OH
	, null as STR_OH_UNITS_DLY
	, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, null as PSA_DELETE_IND
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}				
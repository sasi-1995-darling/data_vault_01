---- SRC LAYER ----
WITH
SRC_SHD            as ( SELECT * FROM {{ ref('v_psa_stg_sales__homedepot_ft') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SHD            as ( SELECT * FROM STAGING.v_psa_stg_sales__homedepot_ft )
*/
---- LOGIC LAYER ----

, LOGIC_SHD as (
    SELECT
        STORE_HK
      , D_STORE_NBR
      , MANUF_PART_NUMBER
      , DAY
      , LOAD_DTS
      , FULFILLMENT_CHANNEL
      , MERCH_VENDOR
      , SKU_NBR
      , SKU_STATUS
      , HOME_DEPOT_ACCOUNT
      , SALES_UNITS
      , M_TY_RETURNS_SUM
      , M_TY_RETURN_UNITS_SUM
      , SALES
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SHD
)
---- RENAME LAYER ----

, RENAME_SHD as (
    SELECT
        STORE_HK
      , D_STORE_NBR
      , MANUF_PART_NUMBER
      , DAY
      , LOAD_DTS
      , FULFILLMENT_CHANNEL
      , MERCH_VENDOR
      , SKU_NBR
      , SKU_STATUS
      , HOME_DEPOT_ACCOUNT
      , SALES_UNITS
      , M_TY_RETURNS_SUM
      , M_TY_RETURN_UNITS_SUM
      , SALES
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SHD
)
---- FILTER LAYER ----

, FILTER_SHD as (
    SELECT *
    FROM RENAME_SHD
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SHD
)

---- FINAL LAYER ----
SELECT
          STORE_HK
        , D_STORE_NBR
        , MANUF_PART_NUMBER
        , DAY
        , LOAD_DTS
        , FULFILLMENT_CHANNEL
        , MERCH_VENDOR
        , SKU_NBR
        , SKU_STATUS
        , HOME_DEPOT_ACCOUNT
        , SALES_UNITS
        , M_TY_RETURNS_SUM
        , M_TY_RETURN_UNITS_SUM
        , SALES
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.STORE_HK = JOIN_RESULT.STORE_HK 
	AND existing.DAY = JOIN_RESULT.DAY
	AND existing.D_STORE_NBR = JOIN_RESULT.D_STORE_NBR 
	AND existing.MANUF_PART_NUMBER=JOIN_RESULT.MANUF_PART_NUMBER
	AND existing.LOAD_DTS=JOIN_RESULT.LOAD_DTS	
	AND existing.FULFILLMENT_CHANNEL=JOIN_RESULT.FULFILLMENT_CHANNEL
	AND existing.MERCH_VENDOR=JOIN_RESULT.MERCH_VENDOR
	AND existing.SKU_NBR = JOIN_RESULT.SKU_NBR 
	AND existing.SKU_STATUS=JOIN_RESULT.SKU_STATUS
	AND existing.HOME_DEPOT_ACCOUNT=JOIN_RESULT.HOME_DEPOT_ACCOUNT
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
 
{% if not is_incremental() %}
qualify 1=row_number() over(partition by day, store_hk,d_store_nbr,manuf_part_number,fulfillment_channel,merch_vendor,sku_nbr,sku_status,home_depot_account,hashdiff order by load_dts desc)
union all
SELECT MD5_BINARY(GR.VALUE::varchar) AS STORE_HK
	, GR.VALUE::varchar as D_STORE_NBR
	, GR.VALUE::varchar as MANUF_PART_NUMBER
	, '1900-01-01'::DATE as DAY	
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) as LOAD_DTS
	, GR.VALUE::varchar as FULFILLMENT_CHANNEL
	, GR.VALUE::varchar as MERCH_VENDOR
	, GR.VALUE::varchar as SKU_NBR
	, GR.VALUE::varchar as SKU_STATUS
	, GR.VALUE::varchar as HOME_DEPOT_ACCOUNT
	, null as SALES_UNITS
	, null as M_TY_RETURNS_SUM
	, null as M_TY_RETURN_UNITS_SUM
	, null as SALES
	, null as PSA_LOAD_DTS
	, null as PSA_RECORD_SOURCE
	, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        , DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        , ''::BINARY as HASH_DIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
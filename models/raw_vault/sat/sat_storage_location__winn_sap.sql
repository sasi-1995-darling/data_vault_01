---- SRC LAYER ----
WITH
SRC_b              as ( SELECT * FROM {{ ref('v_psa_stg_goods_movement_storage_location__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_b              as ( SELECT * FROM STAGING.V_PSA_STG_GOODS_MOVEMENT_STORAGE_LOCATION__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        GOODS_STORAGE_LOCATION_HK
      , MANDT
      , WERKS
      , LGORT
      , GLREQUEST
      , GLSOURCESYSTEM
      , LGOBE
      , XLONG
      , XBUFX
      , DISKZ
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        GOODS_STORAGE_LOCATION_HK
      , MANDT
      , WERKS
      , LGORT
      , GLREQUEST
      , GLSOURCESYSTEM
      , LGOBE
      , XLONG
      , XBUFX
      , DISKZ
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
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
        GOODS_STORAGE_LOCATION_HK
      , MANDT
      , WERKS
      , LGORT
      , GLREQUEST
      , GLSOURCESYSTEM
      , LGOBE
      , XLONG
      , XBUFX
      , DISKZ
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.GOODS_STORAGE_LOCATION_HK = JOIN_RESULT.GOODS_STORAGE_LOCATION_HK)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by GOODS_STORAGE_LOCATION_HK, HASHDIFF order by LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS GOODS_STORAGE_LOCATION_HK,
NULL AS MANDT,
'-1' AS WERKS,
GR.VALUE::text AS LGORT,
NULL AS GLREQUEST,
NULL AS GLSOURCESYSTEM,
NULL AS LGOBE,
NULL AS XLONG,
NULL AS XBUFX,
NULL AS DISKZ,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
'N' AS PSA_DELETE_IND,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
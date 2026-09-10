---- SRC LAYER ----
WITH
SRC_DT             as ( SELECT * FROM {{ ref('v_psa_stg_device_telemetry_flo_daily') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_DT             as ( SELECT * FROM staging.v_psa_stg_device_telemetry_flo_daily )
*/
---- LOGIC LAYER ----

, LOGIC_DT as (
    SELECT
        DEVICE_HK
      , LOAD_DTS
      , ID
      , AGGREGATE_DATE
      , GALLONS
      , MAX_GPM
      , MIN_PRESSURE
      , MAX_PRESSURE
      , AVG_PRESSURE
      , MIN_TEMPERATURE
      , MAX_TEMPERATURE
      , AVG_TEMPERATURE
      , RECORDS
      , FLOW_RECORDS
      , AVG_NIGHT_TEMPERATURE
      , CREATED_AT
      , UPDATED_AT
      , MEDIAN_GPS
      , P_STATIC
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_DT
)
---- RENAME LAYER ----

, RENAME_DT as (
    SELECT
        DEVICE_HK
      , LOAD_DTS
      , ID
      , AGGREGATE_DATE
      , GALLONS
      , MAX_GPM
      , MIN_PRESSURE
      , MAX_PRESSURE
      , AVG_PRESSURE
      , MIN_TEMPERATURE
      , MAX_TEMPERATURE
      , AVG_TEMPERATURE
      , RECORDS
      , FLOW_RECORDS
      , AVG_NIGHT_TEMPERATURE
      , CREATED_AT
      , UPDATED_AT
      , MEDIAN_GPS
      , P_STATIC
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_DT
)
---- FILTER LAYER ----

, FILTER_DT as (
    SELECT *
    FROM RENAME_DT
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_DT
)

---- FINAL LAYER ----
SELECT
          DEVICE_HK
        , LOAD_DTS
        , ID
        , AGGREGATE_DATE
        , GALLONS
        , MAX_GPM
        , MIN_PRESSURE
        , MAX_PRESSURE
        , AVG_PRESSURE
        , MIN_TEMPERATURE
        , MAX_TEMPERATURE
        , AVG_TEMPERATURE
        , RECORDS
        , FLOW_RECORDS
        , AVG_NIGHT_TEMPERATURE
        , CREATED_AT
        , UPDATED_AT
        , MEDIAN_GPS
        , P_STATIC
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
    WHERE existing.DEVICE_HK = JOIN_RESULT.DEVICE_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by DEVICE_HK, HASHDIFF order by LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS DEVICE_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as ID
,'1900-01-01' as AGGREGATE_DATE
,null as GALLONS
,null as MAX_GPM
,null as MIN_PRESSURE 
,null as MAX_PRESSURE
,null as AVG_PRESSURE
,null as MIN_TEMPERATURE
,null as MAX_TEMPERATURE
,null as AVG_TEMPERATURE
,null as RECORDS
,null as FLOW_RECORDS
,null as AVG_NIGHT_TEMPERATURE
,null as CREATED_AT
,null as UPDATED_AT
,null as MEDIAN_GPS
,null as P_STATIC
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND		
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}
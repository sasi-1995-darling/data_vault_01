---- SRC LAYER ----
WITH
SRC_DI             as ( SELECT * FROM {{ ref('v_psa_stg_device_inventory') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_DI             as ( SELECT * FROM staging.v_psa_stg_device_inventory )
*/
---- LOGIC LAYER ----

, LOGIC_DI as (
    SELECT
        DEVICE_HK
      , LOAD_DTS
      , ID
      , SKU
      , MFG_NUMBER
      , SERIAL_NUMBER
      , PALLET_ID
      , CYSN
      , CYPN
      , ORIG_FW_VER
      , SHEET_NUMBER
      , MANUFACTURE_DATE
      , VTECH_CARTON
      , TIN
      , NEW_SERIAL_NUMBER
      , REMARK
      , FIVETRAN_DELETED
      , FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_DI
)
---- RENAME LAYER ----

, RENAME_DI as (
    SELECT
        DEVICE_HK
      , LOAD_DTS
      , ID
      , SKU
      , MFG_NUMBER
      , SERIAL_NUMBER
      , PALLET_ID
      , CYSN
      , CYPN
      , ORIG_FW_VER
      , SHEET_NUMBER
      , MANUFACTURE_DATE
      , VTECH_CARTON
      , TIN
      , NEW_SERIAL_NUMBER
      , REMARK
      , FIVETRAN_DELETED
      , FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_DI
)
---- FILTER LAYER ----

, FILTER_DI as (
    SELECT *
    FROM RENAME_DI
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_DI
)

---- FINAL LAYER ----
SELECT
          DEVICE_HK
        , LOAD_DTS
        , ID
        , SKU
        , MFG_NUMBER
        , SERIAL_NUMBER
        , PALLET_ID
        , CYSN
        , CYPN
        , ORIG_FW_VER
        , SHEET_NUMBER
        , MANUFACTURE_DATE
        , VTECH_CARTON
        , TIN
        , NEW_SERIAL_NUMBER
        , REMARK
        , FIVETRAN_DELETED
        , FIVETRAN_SYNCED
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
,null as SKU
,null as MFG_NUMBER
,null as SERIAL_NUMBER
,null as PALLET_ID
,null as CYSN
,null as CYPN
,null as ORIG_FW_VER
,null as SHEET_NUMBER
,null as MANUFACTURE_DATE
,null as VTECH_CARTON
,null as TIN
,null as NEW_SERIAL_NUMBER
,null as REMARK
,null as FIVETRAN_DELETED
,null as FIVETRAN_SYNCED
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND		
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}
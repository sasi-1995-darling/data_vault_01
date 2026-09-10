---- SRC LAYER ----
WITH
SRC_county_zip     as ( SELECT * FROM {{ ref('v_psa_stg_county_zip__snfl_usps') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_county_zip     as ( SELECT * FROM STAGING.v_psa_stg_county_zip__snfl_usps )
*/
---- LOGIC LAYER ----

, LOGIC_county_zip as (
    SELECT
        LNK_ZIP_COUNTY_HK
      , COUNTY
      , ZIP
      , USPS_ZIP_PREF_CITY
      , USPS_ZIP_PREF_STATE
      , RES_RATIO
      , BUS_RATIO
      , OTH_RATIO
      , TOT_RATIO
      , UPDATED_ON
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_county_zip
)
---- RENAME LAYER ----

, RENAME_county_zip as (
    SELECT
        LNK_ZIP_COUNTY_HK
      , COUNTY
      , ZIP
      , USPS_ZIP_PREF_CITY
      , USPS_ZIP_PREF_STATE
      , RES_RATIO
      , BUS_RATIO
      , OTH_RATIO
      , TOT_RATIO
      , UPDATED_ON
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_county_zip
)
---- FILTER LAYER ----

, FILTER_county_zip as (
    SELECT *
    FROM RENAME_county_zip
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_county_zip
)

---- FINAL LAYER ----
SELECT
          LNK_ZIP_COUNTY_HK
        , COUNTY
        , ZIP
        , USPS_ZIP_PREF_CITY
        , USPS_ZIP_PREF_STATE
        , RES_RATIO
        , BUS_RATIO
        , OTH_RATIO
        , TOT_RATIO
        , UPDATED_ON
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_ZIP_COUNTY_HK = JOIN_RESULT.LNK_ZIP_COUNTY_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
union all
    SELECT MD5_BINARY(GR.VALUE) LNK_ZIP_COUNTY_HK
        ,GR.VALUE as COUNTY
        ,GR.VALUE as ZIP
        ,null as USPS_ZIP_PREF_CITY
        ,null as USPS_ZIP_PREF_STATE
        ,null as RES_RATIO
        ,null as BUS_RATIO
        ,null as OTH_RATIO
        ,null as TOT_RATIO
        ,'1900-01-01' as UPDATED_ON
        ,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP as LOAD_DTS
        ,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        ,DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        ,''::BINARY as HASHDIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
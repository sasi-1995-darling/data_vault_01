---- SRC LAYER ----
WITH
SRC_county         as ( SELECT * FROM {{ ref('v_psa_stg_county__snfl_usps') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_county         as ( SELECT * FROM STAGING.v_psa_stg_county__snfl_usps )
*/
---- LOGIC LAYER ----

, LOGIC_county as (
    SELECT
        COUNTY_HK
      , USPS
      , GEOID
      , ANSICODE
      , NAME
      , POP10
      , HU10
      , ALAND
      , AWATER
      , ALAND_SQMI
      , AWATER_SQMI
      , INTPTLAT
      , INTPTLONG
      , UPDATED_ON
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_county
)
---- RENAME LAYER ----

, RENAME_county as (
    SELECT
        COUNTY_HK
      , USPS
      , GEOID
      , ANSICODE
      , NAME
      , POP10
      , HU10
      , ALAND
      , AWATER
      , ALAND_SQMI
      , AWATER_SQMI
      , INTPTLAT
      , INTPTLONG
      , UPDATED_ON
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_county
)
---- FILTER LAYER ----

, FILTER_county as (
    SELECT *
    FROM RENAME_county
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_county
)

---- FINAL LAYER ----
SELECT
          COUNTY_HK
        , USPS
        , GEOID
        , ANSICODE
        , NAME
        , POP10
        , HU10
        , ALAND
        , AWATER
        , ALAND_SQMI
        , AWATER_SQMI
        , INTPTLAT
        , INTPTLONG
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
    WHERE existing.COUNTY_HK = JOIN_RESULT.COUNTY_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
union all
    SELECT MD5_BINARY(GR.VALUE) COUNTY_HK
        ,GR.VALUE as USPS
        ,GR.VALUE as GEOID
        ,null as ANSICODE
        ,null as NAME
        ,null as POP10
        ,null as HU10
        ,null as ALAND
        ,null as AWATER
        ,null as ALAND_SQMI
        ,null as AWATER_SQMI
        ,null as INTPTLAT
        ,null as INTPTLONG
        ,null as UPDATED_ON
        ,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP as LOAD_DTS
        ,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        ,DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        ,''::BINARY as HASHDIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
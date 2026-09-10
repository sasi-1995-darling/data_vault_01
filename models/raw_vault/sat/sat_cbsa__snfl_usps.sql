---- SRC LAYER ----
WITH
SRC_cbsa           as ( SELECT * FROM {{ ref('v_psa_stg_cbsa__snfl_usps') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_cbsa           as ( SELECT * FROM STAGING.v_psa_stg_cbsa__snfl_usps )
*/
---- LOGIC LAYER ----

, LOGIC_cbsa as (
    SELECT
        CBSA_HK
      , CBSA_CODE
      , METRO_DIVISION_CODE
      , CSA_CODE
      , CBSA_TITLE
      , METROPOLITAN_MICROPOLITAN_STATISTICAL_AREA
      , METROPOLITAN_DIVISION_TITLE
      , COUNTY_COUNTY_EQUIVALENT
      , STATE_NAME
      , FIPS_STATE_CODE
      , FIPS_COUNTY_CODE
      , CENTRAL_OUTLYING_COUNTY
      , UPDATED_ON
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_cbsa
)
---- RENAME LAYER ----

, RENAME_cbsa as (
    SELECT
        CBSA_HK
      , CBSA_CODE
      , METRO_DIVISION_CODE
      , CSA_CODE
      , CBSA_TITLE
      , METROPOLITAN_MICROPOLITAN_STATISTICAL_AREA
      , METROPOLITAN_DIVISION_TITLE
      , COUNTY_COUNTY_EQUIVALENT
      , STATE_NAME
      , FIPS_STATE_CODE
      , FIPS_COUNTY_CODE
      , CENTRAL_OUTLYING_COUNTY
      , UPDATED_ON
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_cbsa
)
---- FILTER LAYER ----

, FILTER_cbsa as (
    SELECT *
    FROM RENAME_cbsa
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_cbsa
)

---- FINAL LAYER ----
SELECT
          CBSA_HK
        , CBSA_CODE
        , METRO_DIVISION_CODE
        , CSA_CODE
        , CBSA_TITLE
        , METROPOLITAN_MICROPOLITAN_STATISTICAL_AREA
        , METROPOLITAN_DIVISION_TITLE
        , COUNTY_COUNTY_EQUIVALENT
        , STATE_NAME
        , FIPS_STATE_CODE
        , FIPS_COUNTY_CODE
        , CENTRAL_OUTLYING_COUNTY
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
    WHERE existing.CBSA_HK = JOIN_RESULT.CBSA_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
union all
    SELECT MD5_BINARY(GR.VALUE) CBSA_HK
        ,GR.VALUE as CBSA_CODE
        ,null as METRO_DIVISION_CODE
        ,null as CSA_CODE
        ,null as CBSA_TITLE
        ,null as METROPOLITAN_MICROPOLITAN_STATISTICAL_AREA
        ,null as METROPOLITAN_DIVISION_TITLE
        ,null as COUNTY_COUNTY_EQUIVALENT
        ,null as STATE_NAME
        ,GR.VALUE as FIPS_STATE_CODE
        ,GR.VALUE as FIPS_COUNTY_CODE
        ,null as CENTRAL_OUTLYING_COUNTY
        ,null as UPDATED_ON
        ,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP as LOAD_DTS
        ,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
        ,DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS  BKCC
        ,''::BINARY as HASHDIFF
        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
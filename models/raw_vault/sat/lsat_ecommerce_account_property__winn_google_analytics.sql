---- SRC LAYER ----
WITH
SRC_GAEP           as ( SELECT * FROM {{ ref('v_psa_stg_ecommerce_properties__winn_google_analytics') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_GAEP           as ( SELECT * FROM STAGING.v_psa_stg_ecommerce_properties__winn_google_analytics )
*/
---- LOGIC LAYER ----

, LOGIC_GAEP as (
    SELECT
        LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK
      , NAME
      , PROPERTY_TYPE
      , CREATE_TIME
      , UPDATE_TIME
      , PARENT
      , DISPLAY_NAME
      , INDUSTRY_CATEGORY
      , TIME_ZONE
      , CURRENCY_CODE
      , SERVICE_LEVEL
      , DELETE_TIME
      , EXPIRE_TIME
      , ACCOUNT
      , ACCOUNT_DISPLAY_NAME
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_GAEP
)
---- RENAME LAYER ----

, RENAME_GAEP as (
    SELECT
        LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK
      , NAME
      , PROPERTY_TYPE
      , CREATE_TIME
      , UPDATE_TIME
      , PARENT
      , DISPLAY_NAME
      , INDUSTRY_CATEGORY
      , TIME_ZONE
      , CURRENCY_CODE
      , SERVICE_LEVEL
      , DELETE_TIME
      , EXPIRE_TIME
      , ACCOUNT
      , ACCOUNT_DISPLAY_NAME
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_GAEP
)
---- FILTER LAYER ----

, FILTER_GAEP as (
    SELECT *
    FROM RENAME_GAEP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_GAEP
)

---- FINAL LAYER ----
SELECT
          LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK
        , NAME
        , PROPERTY_TYPE
        , CREATE_TIME
        , UPDATE_TIME
        , PARENT
        , DISPLAY_NAME
        , INDUSTRY_CATEGORY
        , TIME_ZONE
        , CURRENCY_CODE
        , SERVICE_LEVEL
        , DELETE_TIME
        , EXPIRE_TIME
        , ACCOUNT
        , ACCOUNT_DISPLAY_NAME
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK = JOIN_RESULT.LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK
	AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS LNK_ECOMMERCE_ACCOUNT_PROPERTY_HK,
NULL AS NAME,
NULL AS PROPERTY_TYPE,
NULL AS CREATE_TIME,
NULL AS UPDATE_TIME,
NULL AS PARENT,
GR.VALUE::text AS DISPLAY_NAME,
NULL AS INDUSTRY_CATEGORY,
NULL AS TIME_ZONE,
NULL AS CURRENCY_CODE,
NULL AS SERVICE_LEVEL,
NULL AS DELETE_TIME,
NULL AS EXPIRE_TIME,
NULL AS ACCOUNT,
GR.VALUE::text AS ACCOUNT_DISPLAY_NAME,
NULL AS _FIVETRAN_SYNCED,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

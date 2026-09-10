---- SRC LAYER ----
WITH
SRC_GAEA           as ( SELECT * FROM {{ ref('v_psa_stg_ecommerce_accounts__winn_google_analytics') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_GAEA           as ( SELECT * FROM STAGING.v_psa_stg_ecommerce_accounts__winn_google_analytics )
*/
---- LOGIC LAYER ----

, LOGIC_GAEA as (
    SELECT
        ECOMMERCE_ACCOUNT_HK
      , NAME
      , CREATE_TIME
      , UPDATE_TIME
      , DISPLAY_NAME
      , REGION_CODE
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_GAEA
)
---- RENAME LAYER ----

, RENAME_GAEA as (
    SELECT
        ECOMMERCE_ACCOUNT_HK
      , NAME
      , CREATE_TIME
      , UPDATE_TIME
      , DISPLAY_NAME
      , REGION_CODE
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_GAEA
)
---- FILTER LAYER ----

, FILTER_GAEA as (
    SELECT *
    FROM RENAME_GAEA
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_GAEA
)

---- FINAL LAYER ----
SELECT
          ECOMMERCE_ACCOUNT_HK
        , NAME
        , CREATE_TIME
        , UPDATE_TIME
        , DISPLAY_NAME
        , REGION_CODE
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
    WHERE existing.ECOMMERCE_ACCOUNT_HK = JOIN_RESULT.ECOMMERCE_ACCOUNT_HK
	AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by ECOMMERCE_ACCOUNT_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ECOMMERCE_ACCOUNT_HK,
NULL AS NAME,
NULL AS CREATE_TIME,
NULL AS UPDATE_TIME,
GR.VALUE::text AS DISPLAY_NAME,
NULL AS REGION_CODE,
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

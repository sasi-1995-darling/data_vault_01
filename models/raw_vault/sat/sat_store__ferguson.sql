---- SRC LAYER ----
WITH
SRC_SSTF           as ( SELECT * FROM {{ ref('v_psa_stg_store__ferguson') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SSTF           as ( SELECT * FROM STAGING.v_psa_stg_store__ferguson )
*/
---- LOGIC LAYER ----

, LOGIC_SSTF as (
    SELECT
        STORE_HK
      , _LINE
      , _FILE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , LEGACY_LOCATION_ID
      , BRANCH
      , ZIP
      , BRANCH_ZIP_CODE
      , STATE
      , LOCATION_CLOSE_DATE
      , COMPANY
      , DISTRICT
      , BRANCH_NAME
      , CITY
      , LEGACY_MAIN_BRANCH
      , ADDRESS_1
      , ADDRESS_2
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SSTF
)
---- RENAME LAYER ----

, RENAME_SSTF as (
    SELECT
        STORE_HK
      , _LINE
      , _FILE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , LEGACY_LOCATION_ID
      , BRANCH
      , ZIP
      , BRANCH_ZIP_CODE
      , STATE
      , LOCATION_CLOSE_DATE
      , COMPANY
      , DISTRICT
      , BRANCH_NAME
      , CITY
      , LEGACY_MAIN_BRANCH
      , ADDRESS_1
      , ADDRESS_2
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SSTF
)
---- FILTER LAYER ----

, FILTER_SSTF as (
    SELECT *
    FROM RENAME_SSTF
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SSTF
)

---- FINAL LAYER ----
SELECT
          STORE_HK
        , _LINE
        , _FILE
        , _MODIFIED
        , _FIVETRAN_SYNCED
        , LEGACY_LOCATION_ID
        , BRANCH
        , ZIP
        , BRANCH_ZIP_CODE
        , STATE
        , LOCATION_CLOSE_DATE
        , COMPANY
        , DISTRICT
        , BRANCH_NAME
        , CITY
        , LEGACY_MAIN_BRANCH
        , ADDRESS_1
        , ADDRESS_2
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
    WHERE existing.STORE_HK = JOIN_RESULT.STORE_HK
	AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by STORE_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS STORE_HK,
NULL AS _LINE,
NULL AS _FILE,
NULL AS _MODIFIED,
NULL AS _FIVETRAN_SYNCED,
NULL AS LEGACY_LOCATION_ID,
NULL AS BRANCH,
NULL AS ZIP,
NULL AS BRANCH_ZIP_CODE,
NULL AS STATE,
NULL AS LOCATION_CLOSE_DATE,
NULL AS COMPANY,
NULL AS DISTRICT,
NULL AS BRANCH_NAME,
NULL AS CITY,
NULL AS LEGACY_MAIN_BRANCH,
NULL AS ADDRESS_1,
NULL AS ADDRESS_2,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

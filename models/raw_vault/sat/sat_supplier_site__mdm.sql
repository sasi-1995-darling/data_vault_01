---- SRC LAYER ----
WITH
SRC_MDM            as ( SELECT * FROM {{ ref('v_psa_stg_supplier_site__mdm') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_MDM            as ( SELECT * FROM STAGING.v_psa_stg_supplier_site__mdm )
*/
---- LOGIC LAYER ----

, LOGIC_MDM as (
    SELECT
        SUPPLIER_SITE_HK
      , BUSINESS_ID
      , SITE_SOURCE_KEY
      , LAST_RUN_DATE
      , SITE_STATUS
      , INACTIVE_DATE
      , ADDRESS_TYPE
      , ADDRESS_LINE_1
      , ADDRESS_LINE_2
      , CITY
      , STATE
      , POSTAL_CODE
      , COUNTRY
      , TAX_NUMBER
      , SUPPLIER_TYPE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_MDM
)
---- RENAME LAYER ----

, RENAME_MDM as (
    SELECT
        SUPPLIER_SITE_HK
      , BUSINESS_ID
      , SITE_SOURCE_KEY
      , LAST_RUN_DATE
      , SITE_STATUS
      , INACTIVE_DATE
      , ADDRESS_TYPE
      , ADDRESS_LINE_1
      , ADDRESS_LINE_2
      , CITY
      , STATE
      , POSTAL_CODE
      , COUNTRY
      , TAX_NUMBER
      , SUPPLIER_TYPE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_MDM
)
---- FILTER LAYER ----

, FILTER_MDM as (
    SELECT *
    FROM RENAME_MDM
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_MDM
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_SITE_HK
        , BUSINESS_ID
        , SITE_SOURCE_KEY
        , LAST_RUN_DATE
        , SITE_STATUS
        , INACTIVE_DATE
        , ADDRESS_TYPE
        , ADDRESS_LINE_1
        , ADDRESS_LINE_2
        , CITY
        , STATE
        , POSTAL_CODE
        , COUNTRY
        , TAX_NUMBER
        , SUPPLIER_TYPE
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SUPPLIER_SITE_HK = JOIN_RESULT.SUPPLIER_SITE_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by SUPPLIER_SITE_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS SUPPLIER_SITE_HK,
GR.VALUE::text AS BUSINESS_ID,
GR.VALUE::text AS SITE_SOURCE_KEY,
NULL AS LAST_RUN_DATE,
NULL AS SITE_STATUS,
NULL AS INACTIVE_DATE,
NULL AS ADDRESS_TYPE,
NULL AS ADDRESS_LINE_1,
NULL AS ADDRESS_LINE_2,
NULL AS CITY,
NULL AS STATE,
NULL AS POSTAL_CODE,
NULL AS COUNTRY,
NULL AS TAX_NUMBER,
NULL AS SUPPLIER_TYPE,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %} 

---- SRC LAYER ----
WITH
SRC_MDM            as ( SELECT * FROM {{ ref('v_psa_stg_supplier_site_org__mdm') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_MDM            as ( SELECT * FROM STAGING.v_psa_stg_supplier_site_org__mdm )
*/
---- LOGIC LAYER ----

, LOGIC_MDM as (
    SELECT
        SUPPLIER_SITE_LEGAL_ENTITY_HK
      , PARENT_ID
      , BUSINESS_ID
      , ORGANIZATION_ID
      , LAST_RUN_DATE
      , PSA_RECORD_SOURCE
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
        SUPPLIER_SITE_LEGAL_ENTITY_HK
      , PARENT_ID
      , BUSINESS_ID
      , ORGANIZATION_ID
      , LAST_RUN_DATE
      , PSA_RECORD_SOURCE
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
          SUPPLIER_SITE_LEGAL_ENTITY_HK
        , PARENT_ID
        , BUSINESS_ID
        , ORGANIZATION_ID
        , LAST_RUN_DATE
        , PSA_RECORD_SOURCE
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
    WHERE existing.SUPPLIER_SITE_LEGAL_ENTITY_HK = JOIN_RESULT.SUPPLIER_SITE_LEGAL_ENTITY_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by SUPPLIER_SITE_LEGAL_ENTITY_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS SUPPLIER_SITE_LEGAL_ENTITY_HK,
GR.VALUE::text AS PARENT_ID,
GR.VALUE::text AS BUSINESS_ID,
GR.VALUE::text AS ORGANIZATION_ID,
NULL AS LAST_RUN_DATE,
NULL AS PSA_RECORD_SOURCE,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

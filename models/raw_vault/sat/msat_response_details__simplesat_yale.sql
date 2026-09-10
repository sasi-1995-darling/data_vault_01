---- SRC LAYER ----
WITH
SRC_FD             as ( SELECT * FROM {{ ref('v_psa_stg_response__simplesat_yale') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_FD             as ( SELECT * FROM staging.v_psa_stg_response__simplesat_yale )
*/
---- LOGIC LAYER ----

, LOGIC_FD as (
    SELECT
        RESPONSE_HK
      , LOAD_DTS
      , TICKET_CUSTOM_ATTRIBUTES
      , _FIVETRAN_DELETED
      , SURVEY_ID
      , _FIVETRAN_SYNCED
      , CUSTOMER_TAGS
      , CREATED
      , TICKET_EXTERNAL_ID
      , CUSTOMER_CUSTOM_ATTRIBUTES
      , SOURCE
      , IP_ADDRESS
      , TICKET_ID
      , CUSTOMER_EMAIL
      , MODIFIED
      , CUSTOMER_NAME
      , CUSTOMER_ID
      , CUSTOMER_COMPANY
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
      , PRODUCT_BK
      , PRODUCT_HK
    FROM SRC_FD
)
---- RENAME LAYER ----

, RENAME_FD as (
    SELECT
        RESPONSE_HK
      , LOAD_DTS
      , TICKET_CUSTOM_ATTRIBUTES
      , _FIVETRAN_DELETED
      , SURVEY_ID
      , _FIVETRAN_SYNCED
      , CUSTOMER_TAGS
      , CREATED
      , TICKET_EXTERNAL_ID
      , CUSTOMER_CUSTOM_ATTRIBUTES
      , SOURCE
      , IP_ADDRESS
      , TICKET_ID
      , CUSTOMER_EMAIL
      , MODIFIED
      , CUSTOMER_NAME
      , CUSTOMER_ID
      , CUSTOMER_COMPANY
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
      , PRODUCT_BK
      , PRODUCT_HK
    FROM LOGIC_FD
)
---- FILTER LAYER ----

, FILTER_FD as (
    SELECT *
    FROM RENAME_FD
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_FD
)

---- FINAL LAYER ----
SELECT
          RESPONSE_HK
        , LOAD_DTS
        , TICKET_CUSTOM_ATTRIBUTES
        , _FIVETRAN_DELETED
        , SURVEY_ID
        , _FIVETRAN_SYNCED
        , CUSTOMER_TAGS
        , CREATED
        , TICKET_EXTERNAL_ID
        , CUSTOMER_CUSTOM_ATTRIBUTES
        , SOURCE
        , IP_ADDRESS
        , TICKET_ID
        , CUSTOMER_EMAIL
        , MODIFIED
        , CUSTOMER_NAME
        , CUSTOMER_ID
        , CUSTOMER_COMPANY
        , PRODUCT_BK
        , PRODUCT_HK
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
    WHERE existing.RESPONSE_HK = JOIN_RESULT.RESPONSE_HK
   AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
qualify 1 = row_number() over (partition by RESPONSE_HK, HASHDIFF order by PSA_LOAD_DTS)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by RESPONSE_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS RESPONSE_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
NULL AS TICKET_CUSTOM_ATTRIBUTES,
NULL AS _FIVETRAN_DELETED,
NULL AS SURVEY_ID,
NULL AS _FIVETRAN_SYNCED,
NULL AS CUSTOMER_TAGS,
NULL AS CREATED,
NULL AS TICKET_EXTERNAL_ID,
NULL AS CUSTOMER_CUSTOM_ATTRIBUTES,
NULL AS SOURCE,
NULL AS IP_ADDRESS,
NULL AS TICKET_ID,
NULL AS CUSTOMER_EMAIL,
NULL AS MODIFIED,
NULL AS CUSTOMER_NAME,
NULL AS CUSTOMER_ID,
NULL AS CUSTOMER_COMPANY,
NULL AS PRODUCT_BK,
NULL AS PRODUCT_HK,
'1900-01-01'::timestamp AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
upper('n') AS PSA_DELETE_IND,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

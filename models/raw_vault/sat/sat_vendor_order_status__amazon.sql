---- SRC LAYER ----
WITH
SRC_s              as ( SELECT * FROM {{ ref('v_psa_stg_vendor_retail_procurement_order_status__amazon') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_s              as ( SELECT * FROM STAGING.V_PSA_STG_VENDOR_RETAIL_PROCUREMENT_ORDER_STATUS__AMAZON )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        VENDOR_ORDER_HK
      , PURCHASE_ORDER_STATUS
      , PURCHASE_ORDER_DATE
      , LAST_UPDATED_DATE
      , PURCHASE_ORDER_NUMBER
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_s
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        VENDOR_ORDER_HK
      , PURCHASE_ORDER_STATUS
      , PURCHASE_ORDER_DATE
      , LAST_UPDATED_DATE
      , PURCHASE_ORDER_NUMBER
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM LOGIC_s
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
)

---- FINAL LAYER ----
SELECT
          VENDOR_ORDER_HK
        , PURCHASE_ORDER_STATUS
        , PURCHASE_ORDER_DATE
        , LAST_UPDATED_DATE
        , PURCHASE_ORDER_NUMBER
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , HASHDIFF
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.VENDOR_ORDER_HK = JOIN_RESULT.VENDOR_ORDER_HK  AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by VENDOR_ORDER_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS VENDOR_ORDER_HK,
NULL AS PURCHASE_ORDER_STATUS,
NULL AS PURCHASE_ORDER_DATE,
NULL AS LAST_UPDATED_DATE,
GR.VALUE::text AS PURCHASE_ORDER_NUMBER,
NULL AS _FIVETRAN_SYNCED,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
'psa_record_source' AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

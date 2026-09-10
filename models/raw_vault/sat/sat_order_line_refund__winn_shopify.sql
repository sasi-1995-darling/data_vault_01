---- SRC LAYER ----
WITH
SRC_SHPORDLNRF     as ( SELECT * FROM {{ ref('v_psa_stg_dtc_order_line_refund__winn_shopify') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_SHPORDLNRF     as ( SELECT * FROM STAGING.v_psa_stg_dtc_order_line_refund__winn_shopify )
*/
---- LOGIC LAYER ----

, LOGIC_SHPORDLNRF as (
    SELECT
        ORDER_LINE_HK
      , ID
      , LOCATION_ID
      , REFUND_ID
      , RESTOCK_TYPE
      , QUANTITY
      , SUBTOTAL
      , SUBTOTAL_SET
      , TOTAL_TAX
      , TOTAL_TAX_SET
      , ORDER_LINE_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SHPORDLNRF
)
---- RENAME LAYER ----

, RENAME_SHPORDLNRF as (
    SELECT
        ORDER_LINE_HK
      , ID
      , LOCATION_ID
      , REFUND_ID
      , RESTOCK_TYPE
      , QUANTITY
      , SUBTOTAL
      , SUBTOTAL_SET
      , TOTAL_TAX
      , TOTAL_TAX_SET
      , ORDER_LINE_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SHPORDLNRF
)
---- FILTER LAYER ----

, FILTER_SHPORDLNRF as (
    SELECT *
    FROM RENAME_SHPORDLNRF
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SHPORDLNRF
)

---- FINAL LAYER ----
SELECT
          ORDER_LINE_HK
        , ID
        , LOCATION_ID
        , REFUND_ID
        , RESTOCK_TYPE
        , QUANTITY
        , SUBTOTAL
        , SUBTOTAL_SET
        , TOTAL_TAX
        , TOTAL_TAX_SET
        , ORDER_LINE_ID
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
    WHERE existing.ORDER_LINE_HK = JOIN_RESULT.ORDER_LINE_HK
	AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by ORDER_LINE_HK, ID, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ORDER_LINE_HK,
GR.VALUE::number AS ID,
NULL AS LOCATION_ID,
GR.VALUE::number AS REFUND_ID,
NULL AS RESTOCK_TYPE,
NULL AS QUANTITY,
NULL AS SUBTOTAL,
NULL AS SUBTOTAL_SET,
NULL AS TOTAL_TAX,
NULL AS TOTAL_TAX_SET,
GR.VALUE::number AS ORDER_LINE_ID,
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

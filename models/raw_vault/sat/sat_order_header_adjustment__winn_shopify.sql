---- SRC LAYER ----
WITH
SRC_SHPORDADJ      as ( SELECT * FROM {{ ref('v_psa_stg_dtc_order_adjustment__winn_shopify') }} as SRC 
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_SHPORDADJ      as ( SELECT * FROM STAGING.v_psa_stg_dtc_order_adjustment__winn_shopify )
*/
---- LOGIC LAYER ----

, LOGIC_SHPORDADJ as (
    SELECT
        ORDER_HEADER_HK
      , ID
      , ORDER_ID
      , REFUND_ID
      , AMOUNT
      , TAX_AMOUNT
      , KIND
      , REASON
      , AMOUNT_SET
      , TAX_AMOUNT_SET
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SHPORDADJ
)
---- RENAME LAYER ----

, RENAME_SHPORDADJ as (
    SELECT
        ORDER_HEADER_HK
      , ID
      , ORDER_ID
      , REFUND_ID
      , AMOUNT
      , TAX_AMOUNT
      , KIND
      , REASON
      , AMOUNT_SET
      , TAX_AMOUNT_SET
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SHPORDADJ
)
---- FILTER LAYER ----

, FILTER_SHPORDADJ as (
    SELECT *
    FROM RENAME_SHPORDADJ
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SHPORDADJ
)

---- FINAL LAYER ----
SELECT
          ORDER_HEADER_HK
        , ID
        , ORDER_ID
        , REFUND_ID
        , AMOUNT
        , TAX_AMOUNT
        , KIND
        , REASON
        , AMOUNT_SET
        , TAX_AMOUNT_SET
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
    WHERE existing.ORDER_HEADER_HK = JOIN_RESULT.ORDER_HEADER_HK
	AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by ORDER_HEADER_HK, ID, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ORDER_HEADER_HK,
GR.VALUE::number AS ID,
GR.VALUE::number AS ORDER_ID,
GR.VALUE::number AS REFUND_ID,
NULL AS AMOUNT,
NULL AS TAX_AMOUNT,
NULL AS KIND,
NULL AS REASON,
NULL AS AMOUNT_SET,
NULL AS TAX_AMOUNT_SET,
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

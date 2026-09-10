---- SRC LAYER ----
WITH
SRC_OF             as ( SELECT * FROM {{ ref('v_psa_stg_dtc_fulfillment__winn_shopify') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', -1, MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_OF             as ( SELECT * FROM staging.v_psa_stg_dtc_fulfillment__winn_shopify )
*/
---- LOGIC LAYER ----

, LOGIC_OF as (
    SELECT
        LNK_ORDER_FULFILLMENT_HK
      , LOAD_DTS
      , ID
      , ORDER_ID
      , LOCATION_ID
      , CREATED_AT
      , UPDATED_AT
      , STATUS
      , SERVICE
      , TRACKING_COMPANY
      , TRACKING_NUMBER
      , SHIPMENT_STATUS
      , TRACKING_NUMBERS
      , TRACKING_URLS
      , NAME
      , RECEIPT_AUTHORIZATION
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_OF
)
---- RENAME LAYER ----

, RENAME_OF as (
    SELECT
        LNK_ORDER_FULFILLMENT_HK
      , LOAD_DTS
      , ID
      , ORDER_ID
      , LOCATION_ID
      , CREATED_AT
      , UPDATED_AT
      , STATUS
      , SERVICE
      , TRACKING_COMPANY
      , TRACKING_NUMBER
      , SHIPMENT_STATUS
      , TRACKING_NUMBERS
      , TRACKING_URLS
      , NAME
      , RECEIPT_AUTHORIZATION
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_OF
)
---- FILTER LAYER ----

, FILTER_OF as (
    SELECT *
    FROM RENAME_OF
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_OF
)

---- FINAL LAYER ----
SELECT
          LNK_ORDER_FULFILLMENT_HK
        , LOAD_DTS
        , ID
        , ORDER_ID
        , LOCATION_ID
        , CREATED_AT
        , UPDATED_AT
        , STATUS
        , SERVICE
        , TRACKING_COMPANY
        , TRACKING_NUMBER
        , SHIPMENT_STATUS
        , TRACKING_NUMBERS
        , TRACKING_URLS
        , NAME
        , RECEIPT_AUTHORIZATION
        , _FIVETRAN_SYNCED
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
    WHERE existing.LNK_ORDER_FULFILLMENT_HK = JOIN_RESULT.LNK_ORDER_FULFILLMENT_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by LNK_ORDER_FULFILLMENT_HK, HASHDIFF order by LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS LNK_ORDER_FULFILLMENT_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as ID
,null as ORDER_ID
,null as LOCATION_ID
,null as CREATED_AT
,null as UPDATED_AT
,null as STATUS
,null as SERVICE
,null as TRACKING_COMPANY
,null as TRACKING_NUMBER
,null as SHIPMENT_STATUS
,null as TRACKING_NUMBERS
,null as TRACKING_URLS
,null as NAME
,null as RECEIPT_AUTHORIZATION
,null as _FIVETRAN_SYNCED
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}
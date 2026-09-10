---- SRC LAYER ----
WITH
SRC_OD             as ( SELECT * FROM {{ ref('v_psa_stg_dtc_order_discount__winn_shopify') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', -1, MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_OD             as ( SELECT * FROM staging.v_psa_stg_dtc_order_discount__winn_shopify )
*/
---- LOGIC LAYER ----

, LOGIC_OD as (
    SELECT
        ORDER_HEADER_HK
      , LOAD_DTS
      , ORDER_ID
      , INDEX
      , TYPE
      , TITLE
      , CODE
      , DESCRIPTION
      , VALUE
      , VALUE_TYPE
      , ALLOCATION_METHOD
      , TARGET_SELECTION
      , TARGET_TYPE
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_OD
)
---- RENAME LAYER ----

, RENAME_OD as (
    SELECT
        ORDER_HEADER_HK
      , LOAD_DTS
      , ORDER_ID
      , INDEX
      , TYPE
      , TITLE
      , CODE
      , DESCRIPTION
      , VALUE
      , VALUE_TYPE
      , ALLOCATION_METHOD
      , TARGET_SELECTION
      , TARGET_TYPE
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_OD
)
---- FILTER LAYER ----

, FILTER_OD as (
    SELECT *
    FROM RENAME_OD
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_OD
)

---- FINAL LAYER ----
SELECT
          ORDER_HEADER_HK
        , LOAD_DTS
        , ORDER_ID
        , INDEX
        , TYPE
        , TITLE
        , CODE
        , DESCRIPTION
        , VALUE
        , VALUE_TYPE
        , ALLOCATION_METHOD
        , TARGET_SELECTION
        , TARGET_TYPE
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
    WHERE existing.ORDER_HEADER_HK = JOIN_RESULT.ORDER_HEADER_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by ORDER_HEADER_HK, HASHDIFF order by LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS ORDER_HEADER_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as ORDER_ID
,CAST(GR.VALUE AS NUMBER(38,0)) as INDEX
,null as TYPE
,null as TITLE
,null as CODE
,null as DESCRIPTION
,null as VALUE
,null as VALUE_TYPE
,null as ALLOCATION_METHOD
,null as TARGET_SELECTION
,null as TARGET_TYPE
,null as _FIVETRAN_SYNCED
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,'N' as PSA_DELETE_IND
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}
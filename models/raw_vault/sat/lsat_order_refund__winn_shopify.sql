---- SRC LAYER ----
WITH
SRC_RH             as ( SELECT * FROM {{ ref('v_psa_stg_dtc_refund_header__winn_shopify') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', -1, MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_RH             as ( SELECT * FROM staging.v_psa_stg_dtc_refund_header__winn_shopify )
*/
---- LOGIC LAYER ----

, LOGIC_RH as (
    SELECT
        LNK_ORDER_REFUND_HK
      , LOAD_DTS
      , ID
      , CREATED_AT
      , PROCESSED_AT
      , NOTE
      , RESTOCK
      , USER_ID
      , ORDER_ID
      , TOTAL_DUTIES_SET
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_RH
)
---- RENAME LAYER ----

, RENAME_RH as (
    SELECT
        LNK_ORDER_REFUND_HK
      , LOAD_DTS
      , ID
      , CREATED_AT
      , PROCESSED_AT
      , NOTE
      , RESTOCK
      , USER_ID
      , ORDER_ID
      , TOTAL_DUTIES_SET
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_RH
)
---- FILTER LAYER ----

, FILTER_RH as (
    SELECT *
    FROM RENAME_RH
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_RH
)

---- FINAL LAYER ----
SELECT
          LNK_ORDER_REFUND_HK
        , LOAD_DTS
        , ID
        , CREATED_AT
        , PROCESSED_AT
        , NOTE
        , RESTOCK
        , USER_ID
        , ORDER_ID
        , TOTAL_DUTIES_SET
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
    WHERE existing.LNK_ORDER_REFUND_HK = JOIN_RESULT.LNK_ORDER_REFUND_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by LNK_ORDER_REFUND_HK, HASHDIFF order by LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS LNK_ORDER_REFUND_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as ID
,null as CREATED_AT
,null as PROCESSED_AT
,null as NOTE
,null as RESTOCK
,null as USER_ID
,null as ORDER_ID
,null as TOTAL_DUTIES_SET
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
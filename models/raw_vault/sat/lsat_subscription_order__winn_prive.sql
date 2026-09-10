---- SRC LAYER ----
WITH
SRC_OD             as ( SELECT * FROM {{ ref('v_psa_stg_subscription_order__winn_prive') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', -1, MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_OD             as ( SELECT * FROM staging.v_psa_stg_subscription_order__winn_prive )
*/
---- LOGIC LAYER ----

, LOGIC_OD as (
    SELECT
        LNK_SUBSCRIPTION_ORDER_HK
      , LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , SUBSCRIBER_ID
      , _FIVETRAN_SYNCED
      , CREATED_AT
      , EXTERNAL_ID
      , TAX
      , TYPE
      , DELIVERY_AMOUNT
      , CURRENCY_CODE
      , CHARGED_AMOUNT
      , UPDATED_AT
      , IS_SKIPPED
      , SUBSCRIPTION_CHARGED_AMOUNT
      , PURCHASE_DATE
      , STATUS
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
        LNK_SUBSCRIPTION_ORDER_HK
      , LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , SUBSCRIBER_ID
      , _FIVETRAN_SYNCED
      , CREATED_AT
      , EXTERNAL_ID
      , TAX
      , TYPE
      , DELIVERY_AMOUNT
      , CURRENCY_CODE
      , CHARGED_AMOUNT
      , UPDATED_AT
      , IS_SKIPPED
      , SUBSCRIPTION_CHARGED_AMOUNT
      , PURCHASE_DATE
      , STATUS
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
          LNK_SUBSCRIPTION_ORDER_HK
        , LOAD_DTS
        , ID
        , _FIVETRAN_DELETED
        , SUBSCRIBER_ID
        , _FIVETRAN_SYNCED
        , CREATED_AT
        , EXTERNAL_ID
        , TAX
        , TYPE
        , DELIVERY_AMOUNT
        , CURRENCY_CODE
        , CHARGED_AMOUNT
        , UPDATED_AT
        , IS_SKIPPED
        , SUBSCRIPTION_CHARGED_AMOUNT
        , PURCHASE_DATE
        , STATUS
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
    WHERE existing.LNK_SUBSCRIPTION_ORDER_HK = JOIN_RESULT.LNK_SUBSCRIPTION_ORDER_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by LNK_SUBSCRIPTION_ORDER_HK, HASHDIFF order by LOAD_DTS DESC)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS LNK_SUBSCRIPTION_ORDER_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as ID
,null as _FIVETRAN_DELETED
,null as SUBSCRIBER_ID
,null as _FIVETRAN_SYNCED
,null as CREATED_AT
,null as EXTERNAL_ID
,null as TAX
,null as TYPE
,null as DELIVERY_AMOUNT
,null as CURRENCY_CODE
,null as CHARGED_AMOUNT
,null as UPDATED_AT
,null as IS_SKIPPED
,null as SUBSCRIPTION_CHARGED_AMOUNT
,null as PURCHASE_DATE
,null as STATUS
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}
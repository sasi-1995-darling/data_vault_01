---- SRC LAYER ----
WITH
SRC_DA             as ( SELECT * FROM {{ ref('v_psa_stg_flo_device_account_subscription') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_DA             as ( SELECT * FROM staging.v_psa_stg_flo_device_account_subscription )
*/
---- LOGIC LAYER ----

, LOGIC_DA as (
    SELECT
        DEVICE_ACCOUNT_SUBSCRIPTION_HK
      , LOAD_DTS
      , ACCOUNT_ID
      , _FIVETRAN_SYNCED
      , STRIPE_CUSTOMER_ID
      , UPDATED_AT
      , CANCEL_AT_PERIOD_END
      , CANCELED_AT
      , STRIPE_SUBSCRIPTION_ID
      , CURRENT_PERIOD_END
      , PLAN_ID
      , ENDED_AT
      , CURRENT_PERIOD_START
      , LOCATION_ID
      , STATUS
      , _FIVETRAN_DELETED
      , CREATED_AT
      , SOURCE_ID
      , CANCELLATION_REASON
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_DA
)
---- RENAME LAYER ----

, RENAME_DA as (
    SELECT
        DEVICE_ACCOUNT_SUBSCRIPTION_HK
      , LOAD_DTS
      , ACCOUNT_ID
      , _FIVETRAN_SYNCED
      , STRIPE_CUSTOMER_ID
      , UPDATED_AT
      , CANCEL_AT_PERIOD_END
      , CANCELED_AT
      , STRIPE_SUBSCRIPTION_ID
      , CURRENT_PERIOD_END
      , PLAN_ID
      , ENDED_AT
      , CURRENT_PERIOD_START
      , LOCATION_ID
      , STATUS
      , _FIVETRAN_DELETED
      , CREATED_AT
      , SOURCE_ID
      , CANCELLATION_REASON
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_DA
)
---- FILTER LAYER ----

, FILTER_DA as (
    SELECT *
    FROM RENAME_DA
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_DA
)

---- FINAL LAYER ----
SELECT
          DEVICE_ACCOUNT_SUBSCRIPTION_HK
        , LOAD_DTS
        , ACCOUNT_ID
        , _FIVETRAN_SYNCED
        , STRIPE_CUSTOMER_ID
        , UPDATED_AT
        , CANCEL_AT_PERIOD_END
        , CANCELED_AT
        , STRIPE_SUBSCRIPTION_ID
        , CURRENT_PERIOD_END
        , PLAN_ID
        , ENDED_AT
        , CURRENT_PERIOD_START
        , LOCATION_ID
        , STATUS
        , _FIVETRAN_DELETED
        , CREATED_AT
        , SOURCE_ID
        , CANCELLATION_REASON
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
    WHERE existing.DEVICE_ACCOUNT_SUBSCRIPTION_HK = JOIN_RESULT.DEVICE_ACCOUNT_SUBSCRIPTION_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 

{% if not is_incremental() %}
qualify 1= row_number()over(partition by DEVICE_ACCOUNT_SUBSCRIPTION_HK, HASHDIFF order by LOAD_DTS) 
union all
SELECT
MD5_BINARY(GR.VALUE) AS DEVICE_ACCOUNT_SUBSCRIPTION_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, GR.VALUE::TEXT  as ACCOUNT_ID
, null  as _FIVETRAN_SYNCED
,null as STRIPE_CUSTOMER_ID
,null as _FIVETRAN_DELETED
,null as UPDATED_AT
,null as CANCEL_AT_PERIOD_END
,null as CANCELED_AT
,null as STRIPE_SUBSCRIPTION_ID
,null as CURRENT_PERIOD_END
,null as PLAN_ID
,null as ENDED_AT
,null as CURRENT_PERIOD_START
,null as LOCATION_ID
,null as STATUS
,null as CREATED_AT
,null as SOURCE_ID  
,null as CANCELLATION_REASON
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}
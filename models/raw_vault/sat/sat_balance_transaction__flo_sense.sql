---- SRC LAYER ----
WITH
SRC_BT             as ( SELECT * FROM {{ ref('v_psa_stg_balance_transaction_flo_sense') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_BT             as ( SELECT * FROM staging.v_psa_stg_balance_transaction_flo_sense )
*/
---- LOGIC LAYER ----

, LOGIC_BT as (
    SELECT
        TRANSACTION_HK
      , LOAD_DTS
      , CONNECTED_ACCOUNT_ID
      , AMOUNT
      , AVAILABLE_ON
      , CREATED
      , CURRENCY
      , DESCRIPTION
      , EXCHANGE_RATE
      , FEE
      , NET
      , SOURCE
      , STATUS
      , TYPE
      , REPORTING_CATEGORY
      , FIVETRAN_SYNCED
      , PAYOUT_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_BT
)
---- RENAME LAYER ----

, RENAME_BT as (
    SELECT
        TRANSACTION_HK
      , LOAD_DTS
      , CONNECTED_ACCOUNT_ID
      , AMOUNT
      , AVAILABLE_ON
      , CREATED
      , CURRENCY
      , DESCRIPTION
      , EXCHANGE_RATE
      , FEE
      , NET
      , SOURCE
      , STATUS
      , TYPE
      , REPORTING_CATEGORY
      , FIVETRAN_SYNCED
      , PAYOUT_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_BT
)
---- FILTER LAYER ----

, FILTER_BT as (
    SELECT *
    FROM RENAME_BT
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_BT
)

---- FINAL LAYER ----
SELECT
          TRANSACTION_HK
        , LOAD_DTS
        , CONNECTED_ACCOUNT_ID
        , AMOUNT
        , AVAILABLE_ON
        , CREATED
        , CURRENCY
        , DESCRIPTION
        , EXCHANGE_RATE
        , FEE
        , NET
        , SOURCE
        , STATUS
        , TYPE
        , REPORTING_CATEGORY
        , FIVETRAN_SYNCED
        , PAYOUT_ID
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
    WHERE existing.TRANSACTION_HK = JOIN_RESULT.TRANSACTION_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by TRANSACTION_HK, HASHDIFF order by LOAD_DTS) 
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS TRANSACTION_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as CONNECTED_ACCOUNT_ID
,null as AMOUNT
,null as AVAILABLE_ON
,null as CREATED
,null as CURRENCY
,null as DESCRIPTION
,null as EXCHANGE_RATE
,null as FEE
,null as NET
,null as SOURCE
,null as STATUS
,null as TYPE
,null as REPORTING_CATEGORY
,null as FIVETRAN_SYNCED
,null as PAYOUT_ID
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND		
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}
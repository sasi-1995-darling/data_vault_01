---- SRC LAYER ----
WITH
SRC_DA             as ( SELECT * FROM {{ ref('v_psa_stg_flo_device_account') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_DA             as ( SELECT * FROM staging.v_psa_stg_flo_device_account )
*/
---- LOGIC LAYER ----

, LOGIC_DA as (
    SELECT
        DEVICE_ACCOUNT_HK
      , LOAD_DTS
      , ID
      , _FIVETRAN_SYNCED
      , OWNER_USER_ID
      , _FIVETRAN_DELETED
      , GROUP_ID
      , ACCOUNT_TYPE
      , TYPE_V_2
      , ACCOUNT_NAME
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
        DEVICE_ACCOUNT_HK
      , LOAD_DTS
      , ID
      , _FIVETRAN_SYNCED
      , OWNER_USER_ID
      , _FIVETRAN_DELETED
      , GROUP_ID
      , ACCOUNT_TYPE
      , TYPE_V_2
      , ACCOUNT_NAME
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
          DEVICE_ACCOUNT_HK
        , LOAD_DTS
        , ID
        , _FIVETRAN_SYNCED
        , OWNER_USER_ID
        , _FIVETRAN_DELETED
        , GROUP_ID
        , ACCOUNT_TYPE
        , TYPE_V_2
        , ACCOUNT_NAME
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
    WHERE existing.DEVICE_ACCOUNT_HK = JOIN_RESULT.DEVICE_ACCOUNT_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 

{% if not is_incremental() %}
qualify 1= row_number()over(partition by DEVICE_ACCOUNT_HK, HASHDIFF order by LOAD_DTS) 
union all
SELECT
MD5_BINARY(GR.VALUE) AS DEVICE_ACCOUNT_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, GR.VALUE::TEXT  as ID
, null  as _FIVETRAN_SYNCED
,null as OWNER_USER_ID
,null as _FIVETRAN_DELETED
,null as GROUP_ID
,null as ACCOUNT_TYPE
,null as TYPE_V_2
,null as ACCOUNT_NAME
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}
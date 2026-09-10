---- SRC LAYER ----
WITH
SRC_OD             as ( SELECT * FROM {{ ref('v_psa_stg_subscriber__winn_prive') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', -1, MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_OD             as ( SELECT * FROM staging.v_psa_stg_subscriber__winn_prive )
*/
---- LOGIC LAYER ----

, LOGIC_OD as (
    SELECT
        SUBSCRIBER_HK
      , LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , UPDATED_AT
      , LAST_NAME
      , CREATED_AT
      , EXTERNAL_ID
      , FIRST_NAME
      , EMAIL
      , PHONE_COUNTRY_CODE
      , PHONE
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
        SUBSCRIBER_HK
      , LOAD_DTS
      , ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , UPDATED_AT
      , LAST_NAME
      , CREATED_AT
      , EXTERNAL_ID
      , FIRST_NAME
      , EMAIL
      , PHONE_COUNTRY_CODE
      , PHONE
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
          SUBSCRIBER_HK
        , LOAD_DTS
        , ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , UPDATED_AT
        , LAST_NAME
        , CREATED_AT
        , EXTERNAL_ID
        , FIRST_NAME
        , EMAIL
        , PHONE_COUNTRY_CODE
        , PHONE
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
    WHERE existing.SUBSCRIBER_HK = JOIN_RESULT.SUBSCRIBER_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by SUBSCRIBER_HK, HASHDIFF order by LOAD_DTS DESC)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS SUBSCRIBER_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as ID
,null as _FIVETRAN_DELETED
,null as _FIVETRAN_SYNCED
,null as UPDATED_AT
,null as LAST_NAME
,null as CREATED_AT
,null as EXTERNAL_ID
,null as FIRST_NAME
,null as EMAIL
,null as PHONE_COUNTRY_CODE
,null as PHONE
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}
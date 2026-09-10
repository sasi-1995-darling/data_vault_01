---- SRC LAYER ----
WITH
SRC_SML            as ( SELECT * FROM {{ ref('v_psa_stg_curr_rates__ml_ebs') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SML            as ( SELECT * FROM STAGING.v_psa_stg_curr_rates__ml_ebs )
*/
---- LOGIC LAYER ----

, LOGIC_SML as (
    SELECT
        CURR_RATES_BK
      , FROM_CURRENCY
      , TO_CURRENCY
      , CONVERSION_DATE
      , CONVERSION_TYPE
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , RATE_SOURCE_CODE
      , CONTEXT
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , ATTRIBUTE1
      , STATUS_CODE
      , ATTRIBUTE9
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , ATTRIBUTE4
      , ATTRIBUTE15
      , CREATION_DATE
      , CONVERSION_RATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_SML
)
---- RENAME LAYER ----

, RENAME_SML as (
    SELECT
        CURR_RATES_BK
      , FROM_CURRENCY
      , TO_CURRENCY
      , CONVERSION_DATE
      , CONVERSION_TYPE
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , RATE_SOURCE_CODE
      , CONTEXT
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , ATTRIBUTE1
      , STATUS_CODE
      , ATTRIBUTE9
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE8
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , ATTRIBUTE4
      , ATTRIBUTE15
      , CREATION_DATE
      , CONVERSION_RATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_SML
)
---- FILTER LAYER ----

, FILTER_SML as (
    SELECT *
    FROM RENAME_SML
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SML
)

---- FINAL LAYER ----
SELECT
          CURR_RATES_BK
        , FROM_CURRENCY
        , TO_CURRENCY
        , CONVERSION_DATE
        , CONVERSION_TYPE
        , ATTRIBUTE10
        , ATTRIBUTE14
        , ATTRIBUTE13
        , ATTRIBUTE12
        , ATTRIBUTE11
        , RATE_SOURCE_CODE
        , CONTEXT
        , CREATED_BY
        , ATTRIBUTE3
        , LAST_UPDATED_BY
        , ATTRIBUTE2
        , ATTRIBUTE1
        , STATUS_CODE
        , ATTRIBUTE9
        , LAST_UPDATE_LOGIN
        , ATTRIBUTE8
        , ATTRIBUTE7
        , ATTRIBUTE6
        , ATTRIBUTE5
        , ATTRIBUTE4
        , ATTRIBUTE15
        , CREATION_DATE
        , CONVERSION_RATE
        , LAST_UPDATE_DATE
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
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
    WHERE existing.CURR_RATES_BK = JOIN_RESULT.CURR_RATES_BK
    AND   existing.CONVERSION_TYPE = JOIN_RESULT.CONVERSION_TYPE
    AND existing.HASH_DIFF = JOIN_RESULT.HASH_DIFF
)
{% endif %} 
{% if not is_incremental() %}
union all
    SELECT GR.VALUE as CURR_RATES_BK
    , null as FROM_CURRENCY
    , null as TO_CURRENCY
    , null as CONVERSION_DATE
    , GR.VALUE as CONVERSION_TYPE
    , null as ATTRIBUTE10
    , null as ATTRIBUTE14
    , null as ATTRIBUTE13
    , null as ATTRIBUTE12
    , null as ATTRIBUTE11
    , null as RATE_SOURCE_CODE
    , null as CONTEXT
    , null as CREATED_BY
    , null as ATTRIBUTE3
    , null as LAST_UPDATED_BY
    , null as ATTRIBUTE2
    , null as ATTRIBUTE1
    , null as STATUS_CODE
    , null as ATTRIBUTE9
    , null as LAST_UPDATE_LOGIN
    , null as ATTRIBUTE8
    , null as ATTRIBUTE7
    , null as ATTRIBUTE6
    , null as ATTRIBUTE5
    , null as ATTRIBUTE4
    , null as ATTRIBUTE15
    , null as CREATION_DATE
    , null as CONVERSION_RATE
    , null as LAST_UPDATE_DATE
    , null as _FIVETRAN_DELETED
    , null as _FIVETRAN_ID
    , null as _FIVETRAN_SYNCED
    , null as PSA_LOAD_DTS
    , null as PSA_RECORD_SOURCE
    , null as PSA_DELETE_IND
	, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)::TIMESTAMP  as  LOAD_DTS
	,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
	,''::BINARY as HASH_DIFF

        FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
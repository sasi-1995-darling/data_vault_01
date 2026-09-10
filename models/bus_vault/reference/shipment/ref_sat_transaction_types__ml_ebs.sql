---- SRC LAYER ----
WITH
SRC_SML            as ( SELECT * FROM {{ ref('v_psa_stg_transaction_types__ml_ebs') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SML            as ( SELECT * FROM STAGING.v_psa_stg_transaction_types__ml_ebs )
*/
---- LOGIC LAYER ----

, LOGIC_SML as (
    SELECT
        TRANSACTION_TYPE_BK
      , TRANSACTION_TYPE_ID
      , CREATED_BY
      , LANGUAGE
      , LAST_UPDATED_BY
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_ID
      , NAME
      , DESCRIPTION
      , PROGRAM_APPLICATION_ID
      , SOURCE_LANG
      , CREATION_DATE
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
        TRANSACTION_TYPE_BK
      , TRANSACTION_TYPE_ID
      , CREATED_BY
      , LANGUAGE
      , LAST_UPDATED_BY
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_ID
      , NAME
      , DESCRIPTION
      , PROGRAM_APPLICATION_ID
      , SOURCE_LANG
      , CREATION_DATE
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
          TRANSACTION_TYPE_BK
        , TRANSACTION_TYPE_ID
        , CREATED_BY
        , LANGUAGE
        , LAST_UPDATED_BY
        , LAST_UPDATE_LOGIN
        , REQUEST_ID
        , PROGRAM_ID
        , NAME
        , DESCRIPTION
        , PROGRAM_APPLICATION_ID
        , SOURCE_LANG
        , CREATION_DATE
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
    WHERE existing.TRANSACTION_TYPE_BK = JOIN_RESULT.TRANSACTION_TYPE_ID
    AND existing.HASH_DIFF = JOIN_RESULT.HASH_DIFF
)
{% endif %} 
{% if not is_incremental() %}
union all
    SELECT GR.VALUE as TRANSACTION_TYPE_BK
, GR.VALUE::NUMBER as TRANSACTION_TYPE_ID
    , null as CREATED_BY
    , null as LANGUAGE
    , null as LAST_UPDATED_BY
    , null as LAST_UPDATE_LOGIN
    , null as REQUEST_ID
    , null as PROGRAM_ID
    , null as NAME
    , null as DESCRIPTION
    , null as PROGRAM_APPLICATION_ID
    , null as SOURCE_LANG
    , null as CREATION_DATE
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
---- SRC LAYER ----
WITH
SRC_FD             as ( SELECT * FROM {{ ref('v_psa_stg_flo_onboarding_log') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_FD             as ( SELECT * FROM staging.v_psa_stg_flo_onboarding_log )
*/
---- LOGIC LAYER ----

, LOGIC_FD as (
    SELECT
        PAIRED_DEVICE_EVENT_HK
      , LOAD_DTS
      , TO_TIMESTAMP_TZ(CREATED_AT)                                  as                                         CREATED_AT
      , ICD_ID
      , _FIVETRAN_DELETED
      , EVENT
      , _FIVETRAN_SYNCED
      , DUMMY
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_FD
)
---- RENAME LAYER ----

, RENAME_FD as (
    SELECT
        PAIRED_DEVICE_EVENT_HK
      , LOAD_DTS
      , CREATED_AT
      , ICD_ID
      , _FIVETRAN_DELETED
      , EVENT
      , _FIVETRAN_SYNCED
      , DUMMY
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_FD
)
---- FILTER LAYER ----

, FILTER_FD as (
    SELECT *
    FROM RENAME_FD
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_FD
)

---- FINAL LAYER ----
SELECT
          PAIRED_DEVICE_EVENT_HK
        , LOAD_DTS
        , CREATED_AT
        , ICD_ID
        , _FIVETRAN_DELETED
        , EVENT
        , _FIVETRAN_SYNCED
        , DUMMY
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
    WHERE existing.PAIRED_DEVICE_EVENT_HK = JOIN_RESULT.PAIRED_DEVICE_EVENT_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 

{% if not is_incremental() %}
qualify 1= row_number()over(partition by PAIRED_DEVICE_EVENT_HK, HASHDIFF order by LOAD_DTS) 
union all
SELECT
MD5_BINARY(GR.VALUE) AS PAIRED_DEVICE_EVENT_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, TO_TIMESTAMP_TZ('1900-01-01T00:00:00.000Z') as CREATED_AT
, GR.VALUE::TEXT  as ICD_ID
, FALSE  as _FIVETRAN_DELETED
, cast(GR.VALUE::TEXT as number(1,0))  as EVENT
, null  as _FIVETRAN_SYNCED
, null  as DUMMY
, null as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE
, null as PSA_DELETE_IND
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}
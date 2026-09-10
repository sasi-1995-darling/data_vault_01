---- SRC LAYER ----
WITH
SRC_CC             as ( SELECT * FROM {{ ref('v_psa_stg_centercode') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_CC             as ( SELECT * FROM staging.v_psa_stg_centercode )
*/
---- LOGIC LAYER ----

, LOGIC_CC as (
    SELECT
        FORM_PROJECT_HK
      , LOAD_DTS
      , ORDINAL_POSITION
      , RESPONSE_ORDINAL
      , FIELD_ORDINAL
      , QUESTION_NAME
      , DATA_TYPE
      , RESPONSE_ID
      , ANSWER_ID
      , COMPUTED_VALUE
      , VALUE_LIST
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_CC
)
---- RENAME LAYER ----

, RENAME_CC as (
    SELECT
        FORM_PROJECT_HK
      , LOAD_DTS
      , ORDINAL_POSITION
      , RESPONSE_ORDINAL
      , FIELD_ORDINAL
      , QUESTION_NAME
      , DATA_TYPE
      , RESPONSE_ID
      , ANSWER_ID
      , COMPUTED_VALUE
      , VALUE_LIST
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_CC
)
---- FILTER LAYER ----

, FILTER_CC as (
    SELECT *
    FROM RENAME_CC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_CC
)

---- FINAL LAYER ----
SELECT
          FORM_PROJECT_HK
        , LOAD_DTS
        , ORDINAL_POSITION
        , RESPONSE_ORDINAL
        , FIELD_ORDINAL
        , QUESTION_NAME
        , DATA_TYPE
        , RESPONSE_ID
        , ANSWER_ID
        , COMPUTED_VALUE
        , VALUE_LIST
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
    WHERE existing.FORM_PROJECT_HK = JOIN_RESULT.FORM_PROJECT_HK 
    AND existing.ORDINAL_POSITION = JOIN_RESULT.ORDINAL_POSITION
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 

{% if not is_incremental() %}
qualify 1= row_number()over(partition by FORM_PROJECT_HK, ORDINAL_POSITION, HASHDIFF order by LOAD_DTS, PSA_LOAD_DTS) 
union all
SELECT
MD5_BINARY(GR.VALUE) AS FORM_PROJECT_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, CAST(GR.VALUE AS NUMBER(38,0)) AS ORDINAL_POSITION
, CAST(GR.VALUE AS NUMBER(38,0)) AS RESPONSE_ORDINAL
, CAST(GR.VALUE AS NUMBER(38,0)) AS FIELD_ORDINAL
, null  as QUESTION_NAME
, null  as DATA_TYPE
, null  as RESPONSE_ID
, null  as ANSWER_ID
, null  as COMPUTED_VALUE
, null  as VALUE_LIST
, '1900-01-01'::TIMESTAMP_LTZ  as PSA_LOAD_DTS
, null  as PSA_RECORD_SOURCE
, null  as PSA_DELETE_IND

, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}
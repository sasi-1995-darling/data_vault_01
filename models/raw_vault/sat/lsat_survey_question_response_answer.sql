---- SRC LAYER ----
WITH
SRC_FD             as ( SELECT * FROM {{ ref('v_psa_stg_answer__simplesat') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_FD             as ( SELECT * FROM staging.v_psa_stg_answer__simplesat )
*/
---- LOGIC LAYER ----

, LOGIC_FD as (
    SELECT
        SURVEY_QUESTION_RESPONSE_ANSWER_HK
      , LOAD_DTS
      , CHOICES
      , FOLLOW_UP_ANSWER_CHOICES
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , SENTIMENT
      , SURVEY_MODIFIED
      , IS_PRIMARY
      , CREATED
      , SESSION
      , CHANNEL
      , RATING
      , ANSWER_LABEL
      , IP_ADDRESS
      , SURVEY_ID
      , MODIFIED
      , SURVEY_NAME
      , FOLLOW_UP_ANSWER
      , RESPONSE_ID
      , CHOICE_LABEL
      , CHOICE
      , QUESTION_ID
      , PUBLISHED_AS_TESTIMONIAL
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
        SURVEY_QUESTION_RESPONSE_ANSWER_HK
      , LOAD_DTS
      , CHOICES
      , FOLLOW_UP_ANSWER_CHOICES
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , SENTIMENT
      , SURVEY_MODIFIED
      , IS_PRIMARY
      , CREATED
      , SESSION
      , CHANNEL
      , RATING
      , ANSWER_LABEL
      , IP_ADDRESS
      , SURVEY_ID
      , MODIFIED
      , SURVEY_NAME
      , FOLLOW_UP_ANSWER
      , RESPONSE_ID
      , CHOICE_LABEL
      , CHOICE
      , QUESTION_ID
      , PUBLISHED_AS_TESTIMONIAL
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
    SELECT * FROM FILTER_FD
)

---- FINAL LAYER ----
SELECT
          SURVEY_QUESTION_RESPONSE_ANSWER_HK
        , LOAD_DTS
        , CHOICES
        , FOLLOW_UP_ANSWER_CHOICES
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , SENTIMENT
        , SURVEY_MODIFIED
        , IS_PRIMARY
        , CREATED
        , SESSION
        , CHANNEL
        , RATING
        , ANSWER_LABEL
        , IP_ADDRESS
        , SURVEY_ID
        , MODIFIED
        , SURVEY_NAME
        , FOLLOW_UP_ANSWER
        , RESPONSE_ID
        , CHOICE_LABEL
        , TO_VARCHAR(CHOICE) AS CHOICE
        , QUESTION_ID
        , PUBLISHED_AS_TESTIMONIAL
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
    WHERE existing.SURVEY_QUESTION_RESPONSE_ANSWER_HK = JOIN_RESULT.SURVEY_QUESTION_RESPONSE_ANSWER_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
qualify 1 = row_number() over (partition by SURVEY_QUESTION_RESPONSE_ANSWER_HK, HASHDIFF order by PSA_LOAD_DTS)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by SURVEY_QUESTION_RESPONSE_ANSWER_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS SURVEY_QUESTION_RESPONSE_ANSWER_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
NULL AS CHOICES,
NULL AS FOLLOW_UP_ANSWER_CHOICES,
NULL AS _FIVETRAN_DELETED,
NULL AS _FIVETRAN_SYNCED,
NULL AS SENTIMENT,
NULL AS SURVEY_MODIFIED,
NULL AS IS_PRIMARY,
NULL AS CREATED,
NULL AS SESSION,
NULL AS CHANNEL,
NULL AS RATING,
NULL AS ANSWER_LABEL,
NULL AS IP_ADDRESS,
GR.VALUE::integer AS SURVEY_ID,
NULL AS MODIFIED,
NULL AS SURVEY_NAME,
NULL AS FOLLOW_UP_ANSWER,
GR.VALUE::integer AS RESPONSE_ID,
NULL AS CHOICE_LABEL,
NULL AS CHOICE,
GR.VALUE::integer AS QUESTION_ID,
NULL AS PUBLISHED_AS_TESTIMONIAL,
'1900-01-01'::timestamp AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
upper('n') AS PSA_DELETE_IND,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

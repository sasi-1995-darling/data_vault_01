---- SRC LAYER ----
WITH
SRC_FD             as ( SELECT * FROM {{ ref('v_psa_stg_question_rules__simplesat_yale') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_FD             as ( SELECT * FROM staging.v_psa_stg_question_rules__simplesat_yale )
*/
---- LOGIC LAYER ----

, LOGIC_FD as (
    SELECT
        QUESTION_HK
      , LOAD_DTS
      , INDEX
      , CONDITIONS
      , QUESTION
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , ACTION
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
        QUESTION_HK
      , LOAD_DTS
      , INDEX
      , CONDITIONS
      , QUESTION
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , ACTION
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
          QUESTION_HK
        , LOAD_DTS
        , INDEX
        , CONDITIONS
        , QUESTION
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , ACTION
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
    WHERE existing.QUESTION_HK = JOIN_RESULT.QUESTION_HK
   AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
qualify 1 = row_number() over (partition by QUESTION_HK, HASHDIFF order by PSA_LOAD_DTS)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by QUESTION_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS QUESTION_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
CAST(GR.VALUE AS NUMBER(38,0)) AS INDEX,
NULL AS CONDITIONS,
NULL AS QUESTION,
NULL AS _FIVETRAN_DELETED,
NULL AS _FIVETRAN_SYNCED,
NULL AS ACTION,
'1900-01-01'::timestamp AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
upper('n') AS PSA_DELETE_IND,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

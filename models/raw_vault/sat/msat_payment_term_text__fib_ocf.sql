---- SRC LAYER ----
WITH
SRC_sfib           as ( SELECT * FROM {{ ref('v_psa_stg_payment_terms_text__fib_ocf') }} as SRC 
                         {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_sfib           as ( SELECT * FROM staging.v_psa_stg_payment_terms_text__fib_ocf )
*/
---- LOGIC LAYER ----

, LOGIC_sfib as (
    SELECT
        PAYMENT_TERM_HK
      , TERM_ID
      , LANGUAGE
      , ORA_SEED_SET_1
      , LAST_UPDATE_DATE
      , OBJECT_VERSION_NUMBER
      , SOURCE_LANG
      , DESCRIPTION
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , LAST_UPDATED_BY
      , CREATION_DATE
      , SEED_DATA_SOURCE
      , NAME
      , ORA_SEED_SET_2
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_sfib
)
---- RENAME LAYER ----

, RENAME_sfib as (
    SELECT
        PAYMENT_TERM_HK
      , TERM_ID
      , LANGUAGE
      , ORA_SEED_SET_1
      , LAST_UPDATE_DATE
      , OBJECT_VERSION_NUMBER
      , SOURCE_LANG
      , DESCRIPTION
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , LAST_UPDATED_BY
      , CREATION_DATE
      , SEED_DATA_SOURCE
      , NAME
      , ORA_SEED_SET_2
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_sfib
)
---- FILTER LAYER ----

, FILTER_sfib as (
    SELECT *
    FROM RENAME_sfib
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_sfib
)

---- FINAL LAYER ----
SELECT
          PAYMENT_TERM_HK
        , TERM_ID
        , LANGUAGE
        , ORA_SEED_SET_1
        , LAST_UPDATE_DATE
        , OBJECT_VERSION_NUMBER
        , SOURCE_LANG
        , DESCRIPTION
        , CREATED_BY
        , LAST_UPDATE_LOGIN
        , LAST_UPDATED_BY
        , CREATION_DATE
        , SEED_DATA_SOURCE
        , NAME
        , ORA_SEED_SET_2
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PAYMENT_TERM_HK = JOIN_RESULT.PAYMENT_TERM_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PAYMENT_TERM_HK, LANGUAGE, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PAYMENT_TERM_HK,
GR.VALUE::number AS TERM_ID,
GR.VALUE::text AS LANGUAGE,
NULL AS ORA_SEED_SET_1,
NULL AS LAST_UPDATE_DATE,
NULL AS OBJECT_VERSION_NUMBER,
NULL AS SOURCE_LANG,
NULL AS DESCRIPTION,
NULL AS CREATED_BY,
NULL AS LAST_UPDATE_LOGIN,
NULL AS LAST_UPDATED_BY,
NULL AS CREATION_DATE,
NULL AS SEED_DATA_SOURCE,
NULL AS NAME,
NULL AS ORA_SEED_SET_2,
NULL AS _FIVETRAN_DELETED,
NULL AS _FIVETRAN_SYNCED,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

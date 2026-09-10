---- SRC LAYER ----
WITH
SRC_sml            as ( SELECT * FROM {{ ref('v_psa_stg_payment_terms_text__ml_ebs') }} as SRC 
                         {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_sml            as ( SELECT * FROM staging.v_psa_stg_payment_terms_text__ml_ebs )
*/
---- LOGIC LAYER ----

, LOGIC_sml as (
    SELECT
        PAYMENT_TERM_HK
      , TERM_ID
      , LANGUAGE
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , RANK
      , DESCRIPTION
      , SOURCE_LANG
      , TYPE
      , END_DATE_ACTIVE
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , START_DATE_ACTIVE
      , ATTRIBUTE1
      , ATTRIBUTE9
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE8
      , ENABLED_FLAG
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , NAME
      , ATTRIBUTE4
      , DUE_CUTOFF_DAY
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE15
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_sml
)
---- RENAME LAYER ----

, RENAME_sml as (
    SELECT
        PAYMENT_TERM_HK
      , TERM_ID
      , LANGUAGE
      , ATTRIBUTE10
      , ATTRIBUTE14
      , ATTRIBUTE13
      , ATTRIBUTE12
      , ATTRIBUTE11
      , RANK
      , DESCRIPTION
      , SOURCE_LANG
      , TYPE
      , END_DATE_ACTIVE
      , CREATED_BY
      , ATTRIBUTE3
      , LAST_UPDATED_BY
      , ATTRIBUTE2
      , START_DATE_ACTIVE
      , ATTRIBUTE1
      , ATTRIBUTE9
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE8
      , ENABLED_FLAG
      , ATTRIBUTE7
      , ATTRIBUTE6
      , ATTRIBUTE5
      , NAME
      , ATTRIBUTE4
      , DUE_CUTOFF_DAY
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE15
      , CREATION_DATE
      , LAST_UPDATE_DATE
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_sml
)
---- FILTER LAYER ----

, FILTER_sml as (
    SELECT *
    FROM RENAME_sml
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_sml
)

---- FINAL LAYER ----
SELECT
          PAYMENT_TERM_HK
        , TERM_ID
        , LANGUAGE
        , ATTRIBUTE10
        , ATTRIBUTE14
        , ATTRIBUTE13
        , ATTRIBUTE12
        , ATTRIBUTE11
        , RANK
        , DESCRIPTION
        , SOURCE_LANG
        , TYPE
        , END_DATE_ACTIVE
        , CREATED_BY
        , ATTRIBUTE3
        , LAST_UPDATED_BY
        , ATTRIBUTE2
        , START_DATE_ACTIVE
        , ATTRIBUTE1
        , ATTRIBUTE9
        , LAST_UPDATE_LOGIN
        , ATTRIBUTE8
        , ENABLED_FLAG
        , ATTRIBUTE7
        , ATTRIBUTE6
        , ATTRIBUTE5
        , NAME
        , ATTRIBUTE4
        , DUE_CUTOFF_DAY
        , ATTRIBUTE_CATEGORY
        , ATTRIBUTE15
        , CREATION_DATE
        , LAST_UPDATE_DATE
        , _FIVETRAN_ID
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
NULL AS ATTRIBUTE10,
NULL AS ATTRIBUTE14,
NULL AS ATTRIBUTE13,
NULL AS ATTRIBUTE12,
NULL AS ATTRIBUTE11,
NULL AS RANK,
NULL AS DESCRIPTION,
NULL AS SOURCE_LANG,
NULL AS TYPE,
NULL AS END_DATE_ACTIVE,
NULL AS CREATED_BY,
NULL AS ATTRIBUTE3,
NULL AS LAST_UPDATED_BY,
NULL AS ATTRIBUTE2,
NULL AS START_DATE_ACTIVE,
NULL AS ATTRIBUTE1,
NULL AS ATTRIBUTE9,
NULL AS LAST_UPDATE_LOGIN,
NULL AS ATTRIBUTE8,
NULL AS ENABLED_FLAG,
NULL AS ATTRIBUTE7,
NULL AS ATTRIBUTE6,
NULL AS ATTRIBUTE5,
NULL AS NAME,
NULL AS ATTRIBUTE4,
NULL AS DUE_CUTOFF_DAY,
NULL AS ATTRIBUTE_CATEGORY,
NULL AS ATTRIBUTE15,
NULL AS CREATION_DATE,
NULL AS LAST_UPDATE_DATE,
NULL AS _FIVETRAN_ID,
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

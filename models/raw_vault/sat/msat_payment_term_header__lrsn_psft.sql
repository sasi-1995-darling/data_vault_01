---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ ref('v_psa_stg_payment_terms_header__lrsn_psft') }} as SRC 
{% if is_incremental() %}
      where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
    {% endif %} )

/*
SRC_SRC            as ( SELECT * FROM int_staging_views.v_psa_stg_payment_terms_header__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        PAYMENT_TERM_HK
      , PYMNT_TERMS_CD
      , SETID
      , PYMNT_TERMS_TYPE
      , DESCR
      , DESCRSHORT
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SRC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
)

---- FINAL LAYER ----
SELECT
          PAYMENT_TERM_HK
        , PYMNT_TERMS_CD
        , SETID
        , PYMNT_TERMS_TYPE
        , DESCR
        , DESCRSHORT
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , _FIVETRAN_SYNCED
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
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
      AND existing.SETID = JOIN_RESULT.SETID
      AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PAYMENT_TERM_HK, SETID, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PAYMENT_TERM_HK,
NULL AS PYMNT_TERMS_CD,
GR.VALUE::text AS SETID,
NULL AS PYMNT_TERMS_TYPE,
NULL AS DESCR,
NULL AS DESCRSHORT,
'N' AS PSA_DELETE_IND,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
NULL AS _FIVETRAN_SYNCED,
NULL AS _FIVETRAN_ID,
NULL AS _FIVETRAN_DELETED,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
MD5_BINARY('') AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

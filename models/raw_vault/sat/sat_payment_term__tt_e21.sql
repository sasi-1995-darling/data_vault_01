---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ ref('v_psa_stg_payment_terms__tt_e21') }} as SRC 
{% if is_incremental() %}
      where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
    {% endif %} )

/*
SRC_SRC            as ( SELECT * FROM int_staging_views.v_psa_stg_payment_terms__tt_e21 )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        PAYMENT_TERM_HK
      , TERMS_CODE
      , END_DAY3
      , DISC_PCT3
      , END_DAY2
      , DISC_DOM1
      , TERMS_DESC
      , END_DAY1
      , DISC_DOM2
      , DISC_DOM3
      , DISC_PCT2
      , DISC_PCT1
      , DISC_MO1
      , DISC_MO3
      , DISC_MO2
      , PROX_DATE
      , DISC_DAY2
      , DUE_DAY3
      , DUE_DAY2
      , DISC_PCT
      , PROX_DISC_DAY
      , NUMB_MTHS
      , BEG_DAY3
      , BEG_DAY1
      , BEG_DAY2
      , PROX_DOM2
      , DISC_DAYS
      , PROX_DOM1
      , DUE_DAYS
      , PROX_DISC
      , TERMS_TYPE
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
        , TERMS_CODE
        , END_DAY3
        , DISC_PCT3
        , END_DAY2
        , DISC_DOM1
        , TERMS_DESC
        , END_DAY1
        , DISC_DOM2
        , DISC_DOM3
        , DISC_PCT2
        , DISC_PCT1
        , DISC_MO1
        , DISC_MO3
        , DISC_MO2
        , PROX_DATE
        , DISC_DAY2
        , DUE_DAY3
        , DUE_DAY2
        , DISC_PCT
        , PROX_DISC_DAY
        , NUMB_MTHS
        , BEG_DAY3
        , BEG_DAY1
        , BEG_DAY2
        , PROX_DOM2
        , DISC_DAYS
        , PROX_DOM1
        , DUE_DAYS
        , PROX_DISC
        , TERMS_TYPE
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
      AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PAYMENT_TERM_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PAYMENT_TERM_HK,
NULL AS TERMS_CODE,
NULL AS END_DAY3,
NULL AS DISC_PCT3,
NULL AS END_DAY2,
NULL AS DISC_DOM1,
NULL AS TERMS_DESC,
NULL AS END_DAY1,
NULL AS DISC_DOM2,
NULL AS DISC_DOM3,
NULL AS DISC_PCT2,
NULL AS DISC_PCT1,
NULL AS DISC_MO1,
NULL AS DISC_MO3,
NULL AS DISC_MO2,
NULL AS PROX_DATE,
NULL AS DISC_DAY2,
NULL AS DUE_DAY3,
NULL AS DUE_DAY2,
NULL AS DISC_PCT,
NULL AS PROX_DISC_DAY,
NULL AS NUMB_MTHS,
NULL AS BEG_DAY3,
NULL AS BEG_DAY1,
NULL AS BEG_DAY2,
NULL AS PROX_DOM2,
NULL AS DISC_DAYS,
NULL AS PROX_DOM1,
NULL AS DUE_DAYS,
NULL AS PROX_DISC,
NULL AS TERMS_TYPE,
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

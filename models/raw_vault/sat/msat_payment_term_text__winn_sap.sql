---- SRC LAYER ----
WITH
SRC_swinn          as ( SELECT * FROM {{ ref('v_psa_stg_payment_terms_text__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_swinn          as ( SELECT * FROM staging.v_psa_stg_payment_terms_text__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_swinn as (
    SELECT
        PAYMENT_TERM_HK
      , ZTERM
      , SPRAS
      , ZTAGG
      , MANDT
      , GLREQUEST
      , TEXT1
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_swinn
)
---- RENAME LAYER ----

, RENAME_swinn as (
    SELECT
        PAYMENT_TERM_HK
      , ZTERM
      , SPRAS
      , ZTAGG
      , MANDT
      , GLREQUEST
      , TEXT1
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_swinn
)
---- FILTER LAYER ----

, FILTER_swinn as (
    SELECT *
    FROM RENAME_swinn
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_swinn
)

---- FINAL LAYER ----
SELECT
          PAYMENT_TERM_HK
        , ZTERM
        , SPRAS
        , ZTAGG
        , MANDT
        , GLREQUEST
        , TEXT1
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , GLCHANGETIME_DTTM
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
qualify 1 = row_number() over (partition by PAYMENT_TERM_HK, ZTAGG, SPRAS, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PAYMENT_TERM_HK,
GR.VALUE::text AS ZTERM,
GR.VALUE::text AS SPRAS,
GR.VALUE::text AS ZTAGG,
NULL AS MANDT,
NULL AS GLREQUEST,
NULL AS TEXT1,
NULL AS GLDELFLAG,
NULL AS GLSOURCESYSTEM,
NULL AS GLCHANGETIME,
NULL AS GLCHANGETIME_DTTM,
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

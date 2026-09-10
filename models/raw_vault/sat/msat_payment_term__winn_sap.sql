---- SRC LAYER ----
WITH
SRC_swinn          as ( SELECT * FROM {{ ref('v_psa_stg_payment_terms__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_swinn          as ( SELECT * FROM staging.v_psa_stg_payment_terms__ winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_swinn as (
    SELECT
        PAYMENT_TERM_HK
      , ZTERM
      , MANDT
      , ZTAGG
      , GLREQUEST
      , ZDART
      , ZFAEL
      , ZMONA
      , ZTAG1
      , ZPRZ1
      , ZTAG2
      , ZPRZ2
      , ZTAG3
      , ZSTG1
      , ZSMN1
      , ZSTG2
      , ZSMN2
      , ZSTG3
      , ZSMN3
      , XZBRV
      , ZSCHF
      , XCHPB
      , TXN08
      , ZLSCH
      , XCHPM
      , KOART
      , XSPLT
      , XSCRC
      , F_OBSOLETE
      , GLDELFLAG
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , GLSOURCESYSTEM
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
      , MANDT
      , ZTAGG
      , GLREQUEST
      , ZDART
      , ZFAEL
      , ZMONA
      , ZTAG1
      , ZPRZ1
      , ZTAG2
      , ZPRZ2
      , ZTAG3
      , ZSTG1
      , ZSMN1
      , ZSTG2
      , ZSMN2
      , ZSTG3
      , ZSMN3
      , XZBRV
      , ZSCHF
      , XCHPB
      , TXN08
      , ZLSCH
      , XCHPM
      , KOART
      , XSPLT
      , XSCRC
      , F_OBSOLETE
      , GLDELFLAG
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , GLSOURCESYSTEM
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
        , MANDT
        , ZTAGG
        , GLREQUEST
        , ZDART
        , ZFAEL
        , ZMONA
        , ZTAG1
        , ZPRZ1
        , ZTAG2
        , ZPRZ2
        , ZTAG3
        , ZSTG1
        , ZSMN1
        , ZSTG2
        , ZSMN2
        , ZSTG3
        , ZSMN3
        , XZBRV
        , ZSCHF
        , XCHPB
        , TXN08
        , ZLSCH
        , XCHPM
        , KOART
        , XSPLT
        , XSCRC
        , F_OBSOLETE
        , GLDELFLAG
        , GLCHANGETIME
        , GLCHANGETIME_DTTM
        , GLSOURCESYSTEM
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
qualify 1 = row_number() over (partition by PAYMENT_TERM_HK, ZTAGG, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PAYMENT_TERM_HK,
GR.VALUE::text AS ZTERM,
NULL AS MANDT,
GR.VALUE::text AS ZTAGG,
NULL AS GLREQUEST,
NULL AS ZDART,
NULL AS ZFAEL,
NULL AS ZMONA,
NULL AS ZTAG1,
NULL AS ZPRZ1,
NULL AS ZTAG2,
NULL AS ZPRZ2,
NULL AS ZTAG3,
NULL AS ZSTG1,
NULL AS ZSMN1,
NULL AS ZSTG2,
NULL AS ZSMN2,
NULL AS ZSTG3,
NULL AS ZSMN3,
NULL AS XZBRV,
NULL AS ZSCHF,
NULL AS XCHPB,
NULL AS TXN08,
NULL AS ZLSCH,
NULL AS XCHPM,
NULL AS KOART,
NULL AS XSPLT,
NULL AS XSCRC,
NULL AS F_OBSOLETE,
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLCHANGETIME_DTTM,
NULL AS GLSOURCESYSTEM,
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

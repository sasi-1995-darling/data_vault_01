---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ ref('v_psa_stg_payment_terms__tt_gp') }} as SRC 
{% if is_incremental() %}
      where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
    {% endif %} )

/*
SRC_SRC            as ( SELECT * FROM int_staging_views.v_psa_stg_payment_terms__tt_gp )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        PAYMENT_TERM_HK
      , PYMTRMID
      , DUETYPE
      , DUEDTDS
      , DISCTYPE
      , DISCDTDS
      , DSCLCTYP
      , DSCDLRAM
      , DSCPCTAM
      , SALPURCH
      , DISCNTCB
      , FREIGHT
      , MISC
      , TAX
      , NOTEINDX
      , CBUVATMD
      , LSTUSRED
      , MODIFDT
      , CREATDDT
      , USEGRPER
      , DEX_ROW_ID
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
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
        , PYMTRMID
        , DUETYPE
        , DUEDTDS
        , DISCTYPE
        , DISCDTDS
        , DSCLCTYP
        , DSCDLRAM
        , DSCPCTAM
        , SALPURCH
        , DISCNTCB
        , FREIGHT
        , MISC
        , TAX
        , NOTEINDX
        , CBUVATMD
        , LSTUSRED
        , MODIFDT
        , CREATDDT
        , USEGRPER
        , DEX_ROW_ID
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
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
NULL AS PYMTRMID,
NULL AS DUETYPE,
NULL AS DUEDTDS,
NULL AS DISCTYPE,
NULL AS DISCDTDS,
NULL AS DSCLCTYP,
NULL AS DSCDLRAM,
NULL AS DSCPCTAM,
NULL AS SALPURCH,
NULL AS DISCNTCB,
NULL AS FREIGHT,
NULL AS MISC,
NULL AS TAX,
NULL AS NOTEINDX,
NULL AS CBUVATMD,
NULL AS LSTUSRED,
NULL AS MODIFDT,
NULL AS CREATDDT,
NULL AS USEGRPER,
NULL AS DEX_ROW_ID,
'N' AS PSA_DELETE_IND,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'1900-01-01T00:00:00'::TIMESTAMP_NTZ AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
MD5_BINARY('') AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

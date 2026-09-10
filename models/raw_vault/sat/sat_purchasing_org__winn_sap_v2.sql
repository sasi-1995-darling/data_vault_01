---- SRC LAYER ----
WITH
SRC_porg           as ( SELECT * FROM {{ ref('v_psa_stg_purchasing_org__winn_sap_v2') }} as SRC 
                         {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_porg           as ( SELECT * FROM staging.v_psa_stg_purchasing_org__winn_sap_v2 )
*/
---- LOGIC LAYER ----

, LOGIC_porg as (
    SELECT
        PURCHASING_ORG_HK
      , EKORG
      , MANDT
      , GLREQUEST
      , EKOTX
      , BUKRS
      , TXADR
      , TXKOP
      , TXFUS
      , TXGRU
      , KALSE
      , MKALS
      , BPEFF
      , BUKRS_NTR
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_porg
)
---- RENAME LAYER ----

, RENAME_porg as (
    SELECT
        PURCHASING_ORG_HK
      , EKORG
      , MANDT
      , GLREQUEST
      , EKOTX
      , BUKRS
      , TXADR
      , TXKOP
      , TXFUS
      , TXGRU
      , KALSE
      , MKALS
      , BPEFF
      , BUKRS_NTR
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_porg
)
---- FILTER LAYER ----

, FILTER_porg as (
    SELECT *
    FROM RENAME_porg
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_porg
)

---- FINAL LAYER ----
SELECT
          PURCHASING_ORG_HK
        , EKORG
        , MANDT
        , GLREQUEST
        , EKOTX
        , BUKRS
        , TXADR
        , TXKOP
        , TXFUS
        , TXGRU
        , KALSE
        , MKALS
        , BPEFF
        , BUKRS_NTR
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PURCHASING_ORG_HK = JOIN_RESULT.PURCHASING_ORG_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PURCHASING_ORG_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PURCHASING_ORG_HK,
GR.VALUE::text AS EKORG,
NULL AS MANDT,
NULL AS GLREQUEST,
NULL AS EKOTX,
NULL AS BUKRS,
NULL AS TXADR,
NULL AS TXKOP,
NULL AS TXFUS,
NULL AS TXGRU,
NULL AS KALSE,
NULL AS MKALS,
NULL AS BPEFF,
NULL AS BUKRS_NTR,
NULL AS GLDELFLAG,
NULL AS GLSOURCESYSTEM,
NULL AS GLCHANGETIME,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

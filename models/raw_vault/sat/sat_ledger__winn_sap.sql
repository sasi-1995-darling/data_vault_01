---- SRC LAYER ----
WITH
SRC_SRC_L          as ( SELECT * FROM {{ ref('v_psa_stg_ledger__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SRC_L          as ( SELECT * FROM STAGING.v_psa_stg_ledger__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SRC_L as (
    SELECT
        LEDGER_HK
      , MANDT
      , RLDNR
      , GLREQUEST
      , GCURR
      , CLASS
      , TYP
      , TRCUR
      , LCCUR
      , RCCUR
      , OCCUR
      , QUANT
      , ATQNT
      , TAB
      , RCOPY
      , SHKZ
      , GLSIP
      , VORTRAG
      , DLDNR
      , XDLDNR
      , CURT1
      , CURT2
      , CURT3
      , V2POST
      , LCTYP
      , FIX
      , POST
      , ROLLUP
      , DEPLD
      , APPL
      , SUBAPPL
      , KOMP
      , GZLEDGER
      , EXIT
      , KLDNR
      , LOGSYS
      , VALUTYP
      , GCOMPRESS
      , SPLITMETHD
      , DATE_DET_POPER
      , GLFLEX
      , XLEADING
      , ORIENT_LEDGER
      , AVG_ROLLUP
      , XCASH_LEDGER
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SRC_L
)
---- RENAME LAYER ----

, RENAME_SRC_L as (
    SELECT
        LEDGER_HK
      , MANDT
      , RLDNR
      , GLREQUEST
      , GCURR
      , CLASS
      , TYP
      , TRCUR
      , LCCUR
      , RCCUR
      , OCCUR
      , QUANT
      , ATQNT
      , TAB
      , RCOPY
      , SHKZ
      , GLSIP
      , VORTRAG
      , DLDNR
      , XDLDNR
      , CURT1
      , CURT2
      , CURT3
      , V2POST
      , LCTYP
      , FIX
      , POST
      , ROLLUP
      , DEPLD
      , APPL
      , SUBAPPL
      , KOMP
      , GZLEDGER
      , EXIT
      , KLDNR
      , LOGSYS
      , VALUTYP
      , GCOMPRESS
      , SPLITMETHD
      , DATE_DET_POPER
      , GLFLEX
      , XLEADING
      , ORIENT_LEDGER
      , AVG_ROLLUP
      , XCASH_LEDGER
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SRC_L
)
---- FILTER LAYER ----

, FILTER_SRC_L as (
    SELECT *
    FROM RENAME_SRC_L
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SRC_L
)

---- FINAL LAYER ----
SELECT
          LEDGER_HK
        , MANDT
        , RLDNR
        , GLREQUEST
        , GCURR
        , CLASS
        , TYP
        , TRCUR
        , LCCUR
        , RCCUR
        , OCCUR
        , QUANT
        , ATQNT
        , TAB
        , RCOPY
        , SHKZ
        , GLSIP
        , VORTRAG
        , DLDNR
        , XDLDNR
        , CURT1
        , CURT2
        , CURT3
        , V2POST
        , LCTYP
        , FIX
        , POST
        , ROLLUP
        , DEPLD
        , APPL
        , SUBAPPL
        , KOMP
        , GZLEDGER
        , EXIT
        , KLDNR
        , LOGSYS
        , VALUTYP
        , GCOMPRESS
        , SPLITMETHD
        , DATE_DET_POPER
        , GLFLEX
        , XLEADING
        , ORIENT_LEDGER
        , AVG_ROLLUP
        , XCASH_LEDGER
        , GLDELFLAG
        , GLCHANGETIME
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
    WHERE existing.LEDGER_HK= JOIN_RESULT.LEDGER_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by LEDGER_HK, HASHDIFF order by PSA_LOAD_DTS)
union all
    SELECT        
    MD5_BINARY(GR.VALUE) AS LEDGER_HK
    , NULL AS MANDT
, NULL AS RLDNR
, NULL AS GLREQUEST
, NULL AS GCURR
, NULL AS CLASS
, NULL AS TYP
, NULL AS TRCUR
, NULL AS LCCUR
, NULL AS RCCUR
, NULL AS OCCUR
, NULL AS QUANT
, NULL AS ATQNT
, NULL AS TABR
, NULL AS COPY
, NULL AS SHKZ
, NULL AS GLSIP
, NULL AS VORTRAG
, NULL AS DLDNR
, NULL AS XDLDNR
, NULL AS CURT1
, NULL AS CURT2
, NULL AS CURT3
, NULL AS V2POST
, NULL AS LCTYP
, NULL AS FIXPOST
, NULL AS ROLLUP
, NULL AS DEPLD
, NULL AS APPL
, NULL AS SUBAPPL
, NULL AS KOMPG
, NULL AS ZLEDGER
, NULL AS EXIT
, NULL AS KLDNR
, NULL AS LOGSYS
, NULL AS VALUTY
, NULL AS PGCOMPRESS
, NULL AS SPLITMET
, NULL AS HDDATE_DET
, NULL AS POPER
, NULL AS GLFLEX
, NULL AS XLEADING
, NULL AS ORIENT_LEDGER
, NULL AS AVG_ROLLUP
, NULL AS XCASH_LEDGER
, NULL AS GLDELFLAG
, NULL AS GLSOURCESYSTEM
, NULL AS GLCHANGETIME
, NULL AS PSA_LOAD_DTS
, NULL AS PSA_RECORD_SOURCE
, NULL AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01')  as  LOAD_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASH_DIFF FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
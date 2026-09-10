---- SRC LAYER ----
WITH
SRC_RH             as ( SELECT * FROM {{ ref('v_psa_stg_reservation_header__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_RH             as ( SELECT * FROM STAGING.V_PSA_STG_RESERVATION_HEADER__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_RH as (
    SELECT
        RESERVATION_HK
      , MANDT
      , RSNUM
      , GLREQUEST
      , KZVER
      , XCALE
      , RSDAT
      , USNAM
      , BWART
      , WEMPF
      , KOSTL
      , PROJN
      , ANLN1
      , ANLN2
      , KUNNR
      , EBELN
      , EBELP
      , AUFNR
      , KDAUF
      , KDPOS
      , KDEIN
      , UMWRK
      , UMLGO
      , SERIE
      , KOKRS
      , PARBU
      , PARGB
      , IMKEY
      , KSTRG
      , PAOBJNR
      , PRCTR
      , PS_PSP_PNR
      , NPLNR
      , AUFPL
      , APLZL
      , VPTNR
      , FIPOS
      , ZZALTKT
      , RECID
      , FKBER
      , DABRZ
      , FISTL
      , GEBER
      , PRZNR
      , LSTAR
      , GRANT_NBR
      , BUDGET_PD
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_RH
)
---- RENAME LAYER ----

, RENAME_RH as (
    SELECT
        RESERVATION_HK
      , MANDT
      , RSNUM
      , GLREQUEST
      , KZVER
      , XCALE
      , RSDAT
      , USNAM
      , BWART
      , WEMPF
      , KOSTL
      , PROJN
      , ANLN1
      , ANLN2
      , KUNNR
      , EBELN
      , EBELP
      , AUFNR
      , KDAUF
      , KDPOS
      , KDEIN
      , UMWRK
      , UMLGO
      , SERIE
      , KOKRS
      , PARBU
      , PARGB
      , IMKEY
      , KSTRG
      , PAOBJNR
      , PRCTR
      , PS_PSP_PNR
      , NPLNR
      , AUFPL
      , APLZL
      , VPTNR
      , FIPOS
      , ZZALTKT
      , RECID
      , FKBER
      , DABRZ
      , FISTL
      , GEBER
      , PRZNR
      , LSTAR
      , GRANT_NBR
      , BUDGET_PD
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_RH
)
---- FILTER LAYER ----

, FILTER_RH as (
    SELECT *
    FROM RENAME_RH
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_RH
)

---- FINAL LAYER ----
SELECT
          RESERVATION_HK
        , MANDT
        , RSNUM
        , GLREQUEST
        , KZVER
        , XCALE
        , RSDAT
        , USNAM
        , BWART
        , WEMPF
        , KOSTL
        , PROJN
        , ANLN1
        , ANLN2
        , KUNNR
        , EBELN
        , EBELP
        , AUFNR
        , KDAUF
        , KDPOS
        , KDEIN
        , UMWRK
        , UMLGO
        , SERIE
        , KOKRS
        , PARBU
        , PARGB
        , IMKEY
        , KSTRG
        , PAOBJNR
        , PRCTR
        , PS_PSP_PNR
        , NPLNR
        , AUFPL
        , APLZL
        , VPTNR
        , FIPOS
        , ZZALTKT
        , RECID
        , FKBER
        , DABRZ
        , FISTL
        , GEBER
        , PRZNR
        , LSTAR
        , GRANT_NBR
        , BUDGET_PD
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
    WHERE existing.RESERVATION_HK = JOIN_RESULT.RESERVATION_HK  
   AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by RESERVATION_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS RESERVATION_HK,
NULL AS MANDT,
GR.VALUE::text AS RSNUM,
NULL AS GLREQUEST,
NULL AS KZVER,
NULL AS XCALE,
NULL AS RSDAT,
NULL AS USNAM,
NULL AS BWART,
NULL AS WEMPF,
NULL AS KOSTL,
NULL AS PROJN,
NULL AS ANLN1,
NULL AS ANLN2,
NULL AS KUNNR,
NULL AS EBELN,
NULL AS EBELP,
NULL AS AUFNR,
NULL AS KDAUF,
NULL AS KDPOS,
NULL AS KDEIN,
NULL AS UMWRK,
NULL AS UMLGO,
NULL AS SERIE,
NULL AS KOKRS,
NULL AS PARBU,
NULL AS PARGB,
NULL AS IMKEY,
NULL AS KSTRG,
NULL AS PAOBJNR,
NULL AS PRCTR,
NULL AS PS_PSP_PNR,
NULL AS NPLNR,
NULL AS AUFPL,
NULL AS APLZL,
NULL AS VPTNR,
NULL AS FIPOS,
NULL AS ZZALTKT,
NULL AS RECID,
NULL AS FKBER,
NULL AS DABRZ,
NULL AS FISTL,
NULL AS GEBER,
NULL AS PRZNR,
NULL AS LSTAR,
NULL AS GRANT_NBR,
NULL AS BUDGET_PD,
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

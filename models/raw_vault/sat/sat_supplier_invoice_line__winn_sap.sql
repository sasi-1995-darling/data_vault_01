---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ ref('v_psa_stg_supplier_invoice_line__winn_sap') }} as SRC 
{% if is_incremental() %}
      where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
    {% endif %} )

/*
SRC_SRC            as ( SELECT * FROM int_staging_views.v_psa_stg_supplier_invoice_line__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        SUPPLIER_INVOICE_LINE_HK
      , BELNR
      , MANDT
      , GJAHR
      , BUZEI
      , GLREQUEST
      , EBELN
      , EBELP
      , ZEKKN
      , MATNR
      , BWKEY
      , BWTAR
      , BUKRS
      , WERKS
      , WRBTR
      , SHKZG
      , MWSKZ
      , TXJCD
      , MENGE
      , BSTME
      , BPMNG
      , BPRME
      , LBKUM
      , VRKUM
      , MEINS
      , PSTYP
      , KNTTP
      , BKLAS
      , EREKZ
      , EXKBE
      , XEKBZ
      , TBTKZ
      , SPGRP
      , SPGRM
      , SPGRT
      , SPGRG
      , SPGRV
      , SPGRQ
      , SPGRS
      , SPGRC
      , SPGREXT
      , BUSTW
      , XBLNR
      , XRUEB
      , BNKAN
      , KSCHL
      , SALK3
      , VMSAL
      , XLIFO
      , LFBNR
      , LFGJA
      , LFPOS
      , MATBF
      , RBMNG
      , BPRBM
      , RBWWR
      , LFEHL
      , GRICD
      , GRIRG
      , GITYP
      , PACKNO
      , INTROW
      , SGTXT
      , XSKRL
      , KZMEK
      , MRMOK
      , STUNR
      , ZAEHK
      , STOCK_POSTING
      , STOCK_POSTING_PP
      , STOCK_POSTING_PY
      , WEREC
      , LIFNR
      , FRBNR
      , XHISTMA
      , COMPLAINT_REASON
      , RETAMT_FC
      , RETPC
      , RETDUEDT
      , XRETTAXNET
      , RE_ACCOUNT
      , ERP_CONTRACT_ID
      , ERP_CONTRACT_ITM
      , SRM_CONTRACT_ID
      , SRM_CONTRACT_ITM
      , CONT_PSTYP
      , SRVMAPKEY
      , CHARG
      , INV_ITM_ORIGIN
      , INVREL
      , XDINV
      , DIFF_AMOUNT
      , XCPRF
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , LICNO
      , ZEILE
      , SGT_SCAT
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
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
          SUPPLIER_INVOICE_LINE_HK
        , BELNR
        , MANDT
        , GJAHR
        , BUZEI
        , GLREQUEST
        , EBELN
        , EBELP
        , ZEKKN
        , MATNR
        , BWKEY
        , BWTAR
        , BUKRS
        , WERKS
        , WRBTR
        , SHKZG
        , MWSKZ
        , TXJCD
        , MENGE
        , BSTME
        , BPMNG
        , BPRME
        , LBKUM
        , VRKUM
        , MEINS
        , PSTYP
        , KNTTP
        , BKLAS
        , EREKZ
        , EXKBE
        , XEKBZ
        , TBTKZ
        , SPGRP
        , SPGRM
        , SPGRT
        , SPGRG
        , SPGRV
        , SPGRQ
        , SPGRS
        , SPGRC
        , SPGREXT
        , BUSTW
        , XBLNR
        , XRUEB
        , BNKAN
        , KSCHL
        , SALK3
        , VMSAL
        , XLIFO
        , LFBNR
        , LFGJA
        , LFPOS
        , MATBF
        , RBMNG
        , BPRBM
        , RBWWR
        , LFEHL
        , GRICD
        , GRIRG
        , GITYP
        , PACKNO
        , INTROW
        , SGTXT
        , XSKRL
        , KZMEK
        , MRMOK
        , STUNR
        , ZAEHK
        , STOCK_POSTING
        , STOCK_POSTING_PP
        , STOCK_POSTING_PY
        , WEREC
        , LIFNR
        , FRBNR
        , XHISTMA
        , COMPLAINT_REASON
        , RETAMT_FC
        , RETPC
        , RETDUEDT
        , XRETTAXNET
        , RE_ACCOUNT
        , ERP_CONTRACT_ID
        , ERP_CONTRACT_ITM
        , SRM_CONTRACT_ID
        , SRM_CONTRACT_ITM
        , CONT_PSTYP
        , SRVMAPKEY
        , CHARG
        , INV_ITM_ORIGIN
        , INVREL
        , XDINV
        , DIFF_AMOUNT
        , XCPRF
        , FSH_SEASON_YEAR
        , FSH_SEASON
        , FSH_COLLECTION
        , FSH_THEME
        , LICNO
        , ZEILE
        , SGT_SCAT
        , WRF_CHARSTC1
        , WRF_CHARSTC2
        , WRF_CHARSTC3
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
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
    WHERE existing.SUPPLIER_INVOICE_LINE_HK = JOIN_RESULT.SUPPLIER_INVOICE_LINE_HK
      AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by SUPPLIER_INVOICE_LINE_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS SUPPLIER_INVOICE_LINE_HK,
NULL AS BELNR,
NULL AS MANDT,
NULL AS GJAHR,
NULL AS BUZEI,
NULL AS GLREQUEST,
NULL AS EBELN,
NULL AS EBELP,
NULL AS ZEKKN,
NULL AS MATNR,
NULL AS BWKEY,
NULL AS BWTAR,
NULL AS BUKRS,
NULL AS WERKS,
NULL AS WRBTR,
NULL AS SHKZG,
NULL AS MWSKZ,
NULL AS TXJCD,
NULL AS MENGE,
NULL AS BSTME,
NULL AS BPMNG,
NULL AS BPRME,
NULL AS LBKUM,
NULL AS VRKUM,
NULL AS MEINS,
NULL AS PSTYP,
NULL AS KNTTP,
NULL AS BKLAS,
NULL AS EREKZ,
NULL AS EXKBE,
NULL AS XEKBZ,
NULL AS TBTKZ,
NULL AS SPGRP,
NULL AS SPGRM,
NULL AS SPGRT,
NULL AS SPGRG,
NULL AS SPGRV,
NULL AS SPGRQ,
NULL AS SPGRS,
NULL AS SPGRC,
NULL AS SPGREXT,
NULL AS BUSTW,
NULL AS XBLNR,
NULL AS XRUEB,
NULL AS BNKAN,
NULL AS KSCHL,
NULL AS SALK3,
NULL AS VMSAL,
NULL AS XLIFO,
NULL AS LFBNR,
NULL AS LFGJA,
NULL AS LFPOS,
NULL AS MATBF,
NULL AS RBMNG,
NULL AS BPRBM,
NULL AS RBWWR,
NULL AS LFEHL,
NULL AS GRICD,
NULL AS GRIRG,
NULL AS GITYP,
NULL AS PACKNO,
NULL AS INTROW,
NULL AS SGTXT,
NULL AS XSKRL,
NULL AS KZMEK,
NULL AS MRMOK,
NULL AS STUNR,
NULL AS ZAEHK,
NULL AS STOCK_POSTING,
NULL AS STOCK_POSTING_PP,
NULL AS STOCK_POSTING_PY,
NULL AS WEREC,
NULL AS LIFNR,
NULL AS FRBNR,
NULL AS XHISTMA,
NULL AS COMPLAINT_REASON,
NULL AS RETAMT_FC,
NULL AS RETPC,
NULL AS RETDUEDT,
NULL AS XRETTAXNET,
NULL AS RE_ACCOUNT,
NULL AS ERP_CONTRACT_ID,
NULL AS ERP_CONTRACT_ITM,
NULL AS SRM_CONTRACT_ID,
NULL AS SRM_CONTRACT_ITM,
NULL AS CONT_PSTYP,
NULL AS SRVMAPKEY,
NULL AS CHARG,
NULL AS INV_ITM_ORIGIN,
NULL AS INVREL,
NULL AS XDINV,
NULL AS DIFF_AMOUNT,
NULL AS XCPRF,
NULL AS FSH_SEASON_YEAR,
NULL AS FSH_SEASON,
NULL AS FSH_COLLECTION,
NULL AS FSH_THEME,
NULL AS LICNO,
NULL AS ZEILE,
NULL AS SGT_SCAT,
NULL AS WRF_CHARSTC1,
NULL AS WRF_CHARSTC2,
NULL AS WRF_CHARSTC3,
NULL AS GLDELFLAG,
NULL AS GLSOURCESYSTEM,
NULL AS GLCHANGETIME,
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

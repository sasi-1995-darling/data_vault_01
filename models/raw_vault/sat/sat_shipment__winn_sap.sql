---- SRC LAYER ----
WITH
SRC_s              as ( SELECT * FROM {{ ref('v_psa_stg_shipment__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                        WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}}){% endif %} )

/*
SRC_s              as ( SELECT * FROM STAGING.V_PSA_STG_SHIPMENT__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        SHIPMENT_HK
      , MANDT
      , TKNUM
      , GLREQUEST
      , VBTYP
      , SHTYP
      , TPLST
      , ERNAM
      , ERDAT
      , ERZET
      , AENAM
      , AEDAT
      , AEZET
      , STERM
      , ABFER
      , ABWST
      , BFART
      , VSART
      , VSAVL
      , VSANL
      , LAUFK
      , VSBED
      , ROUTE
      , SIGNI
      , EXTI1
      , EXTI2
      , TPBEZ
      , STDIS
      , DTDIS
      , UZDIS
      , STREG
      , DPREG
      , UPREG
      , DAREG
      , UAREG
      , STLBG
      , DPLBG
      , UPLBG
      , DALBG
      , UALBG
      , STLAD
      , DPLEN
      , UPLEN
      , DALEN
      , UALEN
      , STABF
      , DPABF
      , UPABF
      , DTABF
      , UZABF
      , STTBG
      , DPTBG
      , UPTBG
      , DATBG
      , UATBG
      , STTEN
      , DPTEN
      , UPTEN
      , DATEN
      , UATEN
      , STTRG
      , TDLNR
      , TERNR
      , PKSTK
      , DTMEG
      , DTMEV
      , DISTZ
      , MEDST
      , FAHZT
      , GESZT
      , MEIZT
      , STAFO
      , FBSTA
      , FBGST
      , ARSTA
      , ARGST
      , STERM_DONE
      , VSE_FRK
      , KKALSM
      , SDABW
      , FRKRL
      , GESZTD
      , FAHZTD
      , GESZTDA
      , FAHZTDA
      , ROCPY_DONE
      , HANDLE
      , TSEGFL
      , TSEGTP
      , ADD01
      , ADD02
      , ADD03
      , ADD04
      , TEXT1
      , TEXT2
      , TEXT3
      , TEXT4
      , PROLI
      , DGTLOCK
      , DGMDDAT
      , CONT_DG
      , WARZTD
      , WARZTDA
      , AULWE
      , TNDRST
      , TNDRRC
      , TNDR_TEXT
      , TNDRDAT
      , TNDRZET
      , TNDR_MAXP
      , TNDR_MAXC
      , TNDR_ACTP
      , TNDR_ACTC
      , TNDR_CARR
      , TNDR_CRNM
      , TNDR_TRKID
      , TNDR_EXPD
      , TNDR_EXPT
      , TNDR_ERPD
      , TNDR_ERPT
      , TNDR_LTPD
      , TNDR_LTPT
      , TNDR_ERDD
      , TNDR_ERDT
      , TNDR_LTDD
      , TNDR_LTDT
      , TNDR_LDLG
      , TNDR_LDLU
      , KZHULFR
      , ALLOWED_TWGT
      , VLSTK
      , VERURSYS
      , CM_IDENT
      , CM_SEQUENCE
      , EXT_FREIGHT_ORD
      , EXT_TM_SYS
      , BEV1_RPFAR1
      , BEV1_RPFAR2
      , BEV1_RPMOWA
      , BEV1_RPANHAE
      , BEV1_RPFLGNR
      , VSO_R_STATUS
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM SRC_s
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        SHIPMENT_HK
      , MANDT
      , TKNUM
      , GLREQUEST
      , VBTYP
      , SHTYP
      , TPLST
      , ERNAM
      , ERDAT
      , ERZET
      , AENAM
      , AEDAT
      , AEZET
      , STERM
      , ABFER
      , ABWST
      , BFART
      , VSART
      , VSAVL
      , VSANL
      , LAUFK
      , VSBED
      , ROUTE
      , SIGNI
      , EXTI1
      , EXTI2
      , TPBEZ
      , STDIS
      , DTDIS
      , UZDIS
      , STREG
      , DPREG
      , UPREG
      , DAREG
      , UAREG
      , STLBG
      , DPLBG
      , UPLBG
      , DALBG
      , UALBG
      , STLAD
      , DPLEN
      , UPLEN
      , DALEN
      , UALEN
      , STABF
      , DPABF
      , UPABF
      , DTABF
      , UZABF
      , STTBG
      , DPTBG
      , UPTBG
      , DATBG
      , UATBG
      , STTEN
      , DPTEN
      , UPTEN
      , DATEN
      , UATEN
      , STTRG
      , TDLNR
      , TERNR
      , PKSTK
      , DTMEG
      , DTMEV
      , DISTZ
      , MEDST
      , FAHZT
      , GESZT
      , MEIZT
      , STAFO
      , FBSTA
      , FBGST
      , ARSTA
      , ARGST
      , STERM_DONE
      , VSE_FRK
      , KKALSM
      , SDABW
      , FRKRL
      , GESZTD
      , FAHZTD
      , GESZTDA
      , FAHZTDA
      , ROCPY_DONE
      , HANDLE
      , TSEGFL
      , TSEGTP
      , ADD01
      , ADD02
      , ADD03
      , ADD04
      , TEXT1
      , TEXT2
      , TEXT3
      , TEXT4
      , PROLI
      , DGTLOCK
      , DGMDDAT
      , CONT_DG
      , WARZTD
      , WARZTDA
      , AULWE
      , TNDRST
      , TNDRRC
      , TNDR_TEXT
      , TNDRDAT
      , TNDRZET
      , TNDR_MAXP
      , TNDR_MAXC
      , TNDR_ACTP
      , TNDR_ACTC
      , TNDR_CARR
      , TNDR_CRNM
      , TNDR_TRKID
      , TNDR_EXPD
      , TNDR_EXPT
      , TNDR_ERPD
      , TNDR_ERPT
      , TNDR_LTPD
      , TNDR_LTPT
      , TNDR_ERDD
      , TNDR_ERDT
      , TNDR_LTDD
      , TNDR_LTDT
      , TNDR_LDLG
      , TNDR_LDLU
      , KZHULFR
      , ALLOWED_TWGT
      , VLSTK
      , VERURSYS
      , CM_IDENT
      , CM_SEQUENCE
      , EXT_FREIGHT_ORD
      , EXT_TM_SYS
      , BEV1_RPFAR1
      , BEV1_RPFAR2
      , BEV1_RPMOWA
      , BEV1_RPANHAE
      , BEV1_RPFLGNR
      , VSO_R_STATUS
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , HASHDIFF
      , REC_SRC
    FROM LOGIC_s
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
)

---- FINAL LAYER ----
SELECT
          SHIPMENT_HK
        , MANDT
        , TKNUM
        , GLREQUEST
        , VBTYP
        , SHTYP
        , TPLST
        , ERNAM
        , ERDAT
        , ERZET
        , AENAM
        , AEDAT
        , AEZET
        , STERM
        , ABFER
        , ABWST
        , BFART
        , VSART
        , VSAVL
        , VSANL
        , LAUFK
        , VSBED
        , ROUTE
        , SIGNI
        , EXTI1
        , EXTI2
        , TPBEZ
        , STDIS
        , DTDIS
        , UZDIS
        , STREG
        , DPREG
        , UPREG
        , DAREG
        , UAREG
        , STLBG
        , DPLBG
        , UPLBG
        , DALBG
        , UALBG
        , STLAD
        , DPLEN
        , UPLEN
        , DALEN
        , UALEN
        , STABF
        , DPABF
        , UPABF
        , DTABF
        , UZABF
        , STTBG
        , DPTBG
        , UPTBG
        , DATBG
        , UATBG
        , STTEN
        , DPTEN
        , UPTEN
        , DATEN
        , UATEN
        , STTRG
        , TDLNR
        , TERNR
        , PKSTK
        , DTMEG
        , DTMEV
        , DISTZ
        , MEDST
        , FAHZT
        , GESZT
        , MEIZT
        , STAFO
        , FBSTA
        , FBGST
        , ARSTA
        , ARGST
        , STERM_DONE
        , VSE_FRK
        , KKALSM
        , SDABW
        , FRKRL
        , GESZTD
        , FAHZTD
        , GESZTDA
        , FAHZTDA
        , ROCPY_DONE
        , HANDLE
        , TSEGFL
        , TSEGTP
        , ADD01
        , ADD02
        , ADD03
        , ADD04
        , TEXT1
        , TEXT2
        , TEXT3
        , TEXT4
        , PROLI
        , DGTLOCK
        , DGMDDAT
        , CONT_DG
        , WARZTD
        , WARZTDA
        , AULWE
        , TNDRST
        , TNDRRC
        , TNDR_TEXT
        , TNDRDAT
        , TNDRZET
        , TNDR_MAXP
        , TNDR_MAXC
        , TNDR_ACTP
        , TNDR_ACTC
        , TNDR_CARR
        , TNDR_CRNM
        , TNDR_TRKID
        , TNDR_EXPD
        , TNDR_EXPT
        , TNDR_ERPD
        , TNDR_ERPT
        , TNDR_LTPD
        , TNDR_LTPT
        , TNDR_ERDD
        , TNDR_ERDT
        , TNDR_LTDD
        , TNDR_LTDT
        , TNDR_LDLG
        , TNDR_LDLU
        , KZHULFR
        , ALLOWED_TWGT
        , VLSTK
        , VERURSYS
        , CM_IDENT
        , CM_SEQUENCE
        , EXT_FREIGHT_ORD
        , EXT_TM_SYS
        , BEV1_RPFAR1
        , BEV1_RPFAR2
        , BEV1_RPMOWA
        , BEV1_RPANHAE
        , BEV1_RPFLGNR
        , VSO_R_STATUS
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , HASHDIFF
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SHIPMENT_HK = JOIN_RESULT.SHIPMENT_HK  AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by SHIPMENT_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS SHIPMENT_HK,
NULL AS MANDT,
GR.VALUE::text AS TKNUM,
NULL AS GLREQUEST,
NULL AS VBTYP,
NULL AS SHTYP,
NULL AS TPLST,
NULL AS ERNAM,
NULL AS ERDAT,
NULL AS ERZET,
NULL AS AENAM,
NULL AS AEDAT,
NULL AS AEZET,
NULL AS STERM,
NULL AS ABFER,
NULL AS ABWST,
NULL AS BFART,
NULL AS VSART,
NULL AS VSAVL,
NULL AS VSANL,
NULL AS LAUFK,
NULL AS VSBED,
NULL AS ROUTE,
NULL AS SIGNI,
NULL AS EXTI1,
NULL AS EXTI2,
NULL AS TPBEZ,
NULL AS STDIS,
NULL AS DTDIS,
NULL AS UZDIS,
NULL AS STREG,
NULL AS DPREG,
NULL AS UPREG,
NULL AS DAREG,
NULL AS UAREG,
NULL AS STLBG,
NULL AS DPLBG,
NULL AS UPLBG,
NULL AS DALBG,
NULL AS UALBG,
NULL AS STLAD,
NULL AS DPLEN,
NULL AS UPLEN,
NULL AS DALEN,
NULL AS UALEN,
NULL AS STABF,
NULL AS DPABF,
NULL AS UPABF,
NULL AS DTABF,
NULL AS UZABF,
NULL AS STTBG,
NULL AS DPTBG,
NULL AS UPTBG,
NULL AS DATBG,
NULL AS UATBG,
NULL AS STTEN,
NULL AS DPTEN,
NULL AS UPTEN,
NULL AS DATEN,
NULL AS UATEN,
NULL AS STTRG,
NULL AS TDLNR,
NULL AS TERNR,
NULL AS PKSTK,
NULL AS DTMEG,
NULL AS DTMEV,
NULL AS DISTZ,
NULL AS MEDST,
NULL AS FAHZT,
NULL AS GESZT,
NULL AS MEIZT,
NULL AS STAFO,
NULL AS FBSTA,
NULL AS FBGST,
NULL AS ARSTA,
NULL AS ARGST,
NULL AS STERM_DONE,
NULL AS VSE_FRK,
NULL AS KKALSM,
NULL AS SDABW,
NULL AS FRKRL,
NULL AS GESZTD,
NULL AS FAHZTD,
NULL AS GESZTDA,
NULL AS FAHZTDA,
NULL AS ROCPY_DONE,
NULL AS HANDLE,
NULL AS TSEGFL,
NULL AS TSEGTP,
NULL AS ADD01,
NULL AS ADD02,
NULL AS ADD03,
NULL AS ADD04,
NULL AS TEXT1,
NULL AS TEXT2,
NULL AS TEXT3,
NULL AS TEXT4,
NULL AS PROLI,
NULL AS DGTLOCK,
NULL AS DGMDDAT,
NULL AS CONT_DG,
NULL AS WARZTD,
NULL AS WARZTDA,
NULL AS AULWE,
NULL AS TNDRST,
NULL AS TNDRRC,
NULL AS TNDR_TEXT,
NULL AS TNDRDAT,
NULL AS TNDRZET,
NULL AS TNDR_MAXP,
NULL AS TNDR_MAXC,
NULL AS TNDR_ACTP,
NULL AS TNDR_ACTC,
NULL AS TNDR_CARR,
NULL AS TNDR_CRNM,
NULL AS TNDR_TRKID,
NULL AS TNDR_EXPD,
NULL AS TNDR_EXPT,
NULL AS TNDR_ERPD,
NULL AS TNDR_ERPT,
NULL AS TNDR_LTPD,
NULL AS TNDR_LTPT,
NULL AS TNDR_ERDD,
NULL AS TNDR_ERDT,
NULL AS TNDR_LTDD,
NULL AS TNDR_LTDT,
NULL AS TNDR_LDLG,
NULL AS TNDR_LDLU,
NULL AS KZHULFR,
NULL AS ALLOWED_TWGT,
NULL AS VLSTK,
NULL AS VERURSYS,
NULL AS CM_IDENT,
NULL AS CM_SEQUENCE,
NULL AS EXT_FREIGHT_ORD,
NULL AS EXT_TM_SYS,
NULL AS BEV1_RPFAR1,
NULL AS BEV1_RPFAR2,
NULL AS BEV1_RPMOWA,
NULL AS BEV1_RPANHAE,
NULL AS BEV1_RPFLGNR,
NULL AS VSO_R_STATUS,
NULL AS GLDELFLAG,
NULL AS GLSOURCESYSTEM,
NULL AS GLCHANGETIME,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
'psa_record_source' AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
''::BINARY AS HASHDIFF,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

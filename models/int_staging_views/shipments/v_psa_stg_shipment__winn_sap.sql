---- SRC LAYER ----
WITH
SRC_a              as ( SELECT "/BEV1/RPANHAE", "/BEV1/RPFAR1", "/BEV1/RPFAR2", "/BEV1/RPFLGNR", "/BEV1/RPMOWA", "/VSO/R_STATUS", ABFER, ABWST, ADD01, ADD02, ADD03, ADD04, AEDAT, AENAM, AEZET, ALLOWED_TWGT, ARGST, ARSTA, AULWE, BFART, CM_IDENT, CM_SEQUENCE, CONT_DG, DALBG, DALEN, DAREG, DATBG, DATEN, DGMDDAT, DGTLOCK, DISTZ, DPABF, DPLBG, DPLEN, DPREG, DPTBG, DPTEN, DTABF, DTDIS, DTMEG, DTMEV, ERDAT, ERNAM, ERZET, EXTI1, EXTI2, EXT_FREIGHT_ORD, EXT_TM_SYS, FAHZT, FAHZTD, FAHZTDA, FBGST, FBSTA, FRKRL, GESZT, GESZTD, GESZTDA, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, HANDLE, KKALSM, KZHULFR, LAUFK, MANDT, MEDST, MEIZT, PKSTK, PROLI, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, ROCPY_DONE, ROUTE, SDABW, SHTYP, SIGNI, STABF, STAFO, STDIS, STERM, STERM_DONE, STLAD, STLBG, STREG, STTBG, STTEN, STTRG, TDLNR, TERNR, TEXT1, TEXT2, TEXT3, TEXT4, TKNUM, TNDRDAT, TNDRRC, TNDRST, TNDRZET, TNDR_ACTC, TNDR_ACTP, TNDR_CARR, TNDR_CRNM, TNDR_ERDD, TNDR_ERDT, TNDR_ERPD, TNDR_ERPT, TNDR_EXPD, TNDR_EXPT, TNDR_LDLG, TNDR_LDLU, TNDR_LTDD, TNDR_LTDT, TNDR_LTPD, TNDR_LTPT, TNDR_MAXC, TNDR_MAXP, TNDR_TEXT, TNDR_TRKID, TPBEZ, TPLST, TSEGFL, TSEGTP, UALBG, UALEN, UAREG, UATBG, UATEN, UPABF, UPLBG, UPLEN, UPREG, UPTBG, UPTEN, UZABF, UZDIS, VBTYP, VERURSYS, VLSTK, VSANL, VSART, VSAVL, VSBED, VSE_FRK, WARZTD, WARZTDA FROM {{ source('sap_ecc_prd', 'z_vttk') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_vttk )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MANDT
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
      , "/BEV1/RPFAR1"                                               as                                        BEV1_RPFAR1
      , "/BEV1/RPFAR2"                                               as                                        BEV1_RPFAR2
      , "/BEV1/RPMOWA"                                               as                                        BEV1_RPMOWA
      , "/BEV1/RPANHAE"                                              as                                       BEV1_RPANHAE
      , "/BEV1/RPFLGNR"                                              as                                       BEV1_RPFLGNR
      , "/VSO/R_STATUS"                                              as                                       VSO_R_STATUS
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , TKNUM                                                        as                                        SHIPMENT_BK
      , IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
            ))
        )                                                            as                                           LOAD_DTS
    FROM SRC_a
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        MANDT
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
      , SHIPMENT_BK
      , LOAD_DTS
    FROM LOGIC_a
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_VTTK'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          MANDT
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
        , REC_SRC
        , BKCC
        , SHIPMENT_BK
        , LOAD_DTS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SHIPMENT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SHIPMENT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(VBTYP::text), '^^') 
            , '||', IFNULL(TRIM(SHTYP::text), '^^') 
            , '||', IFNULL(TRIM(TPLST::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERZET::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(AEZET::text), '^^') 
            , '||', IFNULL(TRIM(STERM::text), '^^') 
            , '||', IFNULL(TRIM(ABFER::text), '^^') 
            , '||', IFNULL(TRIM(ABWST::text), '^^') 
            , '||', IFNULL(TRIM(BFART::text), '^^') 
            , '||', IFNULL(TRIM(VSART::text), '^^') 
            , '||', IFNULL(TRIM(VSAVL::text), '^^') 
            , '||', IFNULL(TRIM(VSANL::text), '^^') 
            , '||', IFNULL(TRIM(LAUFK::text), '^^') 
            , '||', IFNULL(TRIM(VSBED::text), '^^') 
            , '||', IFNULL(TRIM(ROUTE::text), '^^') 
            , '||', IFNULL(TRIM(SIGNI::text), '^^') 
            , '||', IFNULL(TRIM(EXTI1::text), '^^') 
            , '||', IFNULL(TRIM(EXTI2::text), '^^') 
            , '||', IFNULL(TRIM(TPBEZ::text), '^^') 
            , '||', IFNULL(TRIM(STDIS::text), '^^') 
            , '||', IFNULL(TRIM(DTDIS::text), '^^') 
            , '||', IFNULL(TRIM(UZDIS::text), '^^') 
            , '||', IFNULL(TRIM(STREG::text), '^^') 
            , '||', IFNULL(TRIM(DPREG::text), '^^') 
            , '||', IFNULL(TRIM(UPREG::text), '^^') 
            , '||', IFNULL(TRIM(DAREG::text), '^^') 
            , '||', IFNULL(TRIM(UAREG::text), '^^') 
            , '||', IFNULL(TRIM(STLBG::text), '^^') 
            , '||', IFNULL(TRIM(DPLBG::text), '^^') 
            , '||', IFNULL(TRIM(UPLBG::text), '^^') 
            , '||', IFNULL(TRIM(DALBG::text), '^^') 
            , '||', IFNULL(TRIM(UALBG::text), '^^') 
            , '||', IFNULL(TRIM(STLAD::text), '^^') 
            , '||', IFNULL(TRIM(DPLEN::text), '^^') 
            , '||', IFNULL(TRIM(UPLEN::text), '^^') 
            , '||', IFNULL(TRIM(DALEN::text), '^^') 
            , '||', IFNULL(TRIM(UALEN::text), '^^') 
            , '||', IFNULL(TRIM(STABF::text), '^^') 
            , '||', IFNULL(TRIM(DPABF::text), '^^') 
            , '||', IFNULL(TRIM(UPABF::text), '^^') 
            , '||', IFNULL(TRIM(DTABF::text), '^^') 
            , '||', IFNULL(TRIM(UZABF::text), '^^') 
            , '||', IFNULL(TRIM(STTBG::text), '^^') 
            , '||', IFNULL(TRIM(DPTBG::text), '^^') 
            , '||', IFNULL(TRIM(UPTBG::text), '^^') 
            , '||', IFNULL(TRIM(DATBG::text), '^^') 
            , '||', IFNULL(TRIM(UATBG::text), '^^') 
            , '||', IFNULL(TRIM(STTEN::text), '^^') 
            , '||', IFNULL(TRIM(DPTEN::text), '^^') 
            , '||', IFNULL(TRIM(UPTEN::text), '^^') 
            , '||', IFNULL(TRIM(DATEN::text), '^^') 
            , '||', IFNULL(TRIM(UATEN::text), '^^') 
            , '||', IFNULL(TRIM(STTRG::text), '^^') 
            , '||', IFNULL(TRIM(TDLNR::text), '^^') 
            , '||', IFNULL(TRIM(TERNR::text), '^^') 
            , '||', IFNULL(TRIM(PKSTK::text), '^^') 
            , '||', IFNULL(TRIM(DTMEG::text), '^^') 
            , '||', IFNULL(TRIM(DTMEV::text), '^^') 
            , '||', IFNULL(TRIM(DISTZ::text), '^^') 
            , '||', IFNULL(TRIM(MEDST::text), '^^') 
            , '||', IFNULL(TRIM(FAHZT::text), '^^') 
            , '||', IFNULL(TRIM(GESZT::text), '^^') 
            , '||', IFNULL(TRIM(MEIZT::text), '^^') 
            , '||', IFNULL(TRIM(STAFO::text), '^^') 
            , '||', IFNULL(TRIM(FBSTA::text), '^^') 
            , '||', IFNULL(TRIM(FBGST::text), '^^') 
            , '||', IFNULL(TRIM(ARSTA::text), '^^') 
            , '||', IFNULL(TRIM(ARGST::text), '^^') 
            , '||', IFNULL(TRIM(STERM_DONE::text), '^^') 
            , '||', IFNULL(TRIM(VSE_FRK::text), '^^') 
            , '||', IFNULL(TRIM(KKALSM::text), '^^') 
            , '||', IFNULL(TRIM(SDABW::text), '^^') 
            , '||', IFNULL(TRIM(FRKRL::text), '^^') 
            , '||', IFNULL(TRIM(GESZTD::text), '^^') 
            , '||', IFNULL(TRIM(FAHZTD::text), '^^') 
            , '||', IFNULL(TRIM(GESZTDA::text), '^^') 
            , '||', IFNULL(TRIM(FAHZTDA::text), '^^') 
            , '||', IFNULL(TRIM(ROCPY_DONE::text), '^^') 
            , '||', IFNULL(TRIM(HANDLE::text), '^^') 
            , '||', IFNULL(TRIM(TSEGFL::text), '^^') 
            , '||', IFNULL(TRIM(TSEGTP::text), '^^') 
            , '||', IFNULL(TRIM(ADD01::text), '^^') 
            , '||', IFNULL(TRIM(ADD02::text), '^^') 
            , '||', IFNULL(TRIM(ADD03::text), '^^') 
            , '||', IFNULL(TRIM(ADD04::text), '^^') 
            , '||', IFNULL(TRIM(TEXT1::text), '^^') 
            , '||', IFNULL(TRIM(TEXT2::text), '^^') 
            , '||', IFNULL(TRIM(TEXT3::text), '^^') 
            , '||', IFNULL(TRIM(TEXT4::text), '^^') 
            , '||', IFNULL(TRIM(PROLI::text), '^^') 
            , '||', IFNULL(TRIM(DGTLOCK::text), '^^') 
            , '||', IFNULL(TRIM(DGMDDAT::text), '^^') 
            , '||', IFNULL(TRIM(CONT_DG::text), '^^') 
            , '||', IFNULL(TRIM(WARZTD::text), '^^') 
            , '||', IFNULL(TRIM(WARZTDA::text), '^^') 
            , '||', IFNULL(TRIM(AULWE::text), '^^') 
            , '||', IFNULL(TRIM(TNDRST::text), '^^') 
            , '||', IFNULL(TRIM(TNDRRC::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(TNDRDAT::text), '^^') 
            , '||', IFNULL(TRIM(TNDRZET::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_MAXP::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_MAXC::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_ACTP::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_ACTC::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_CARR::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_CRNM::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_TRKID::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_EXPD::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_EXPT::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_ERPD::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_ERPT::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_LTPD::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_LTPT::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_ERDD::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_ERDT::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_LTDD::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_LTDT::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_LDLG::text), '^^') 
            , '||', IFNULL(TRIM(TNDR_LDLU::text), '^^') 
            , '||', IFNULL(TRIM(KZHULFR::text), '^^') 
            , '||', IFNULL(TRIM(ALLOWED_TWGT::text), '^^') 
            , '||', IFNULL(TRIM(VLSTK::text), '^^') 
            , '||', IFNULL(TRIM(VERURSYS::text), '^^') 
            , '||', IFNULL(TRIM(CM_IDENT::text), '^^') 
            , '||', IFNULL(TRIM(CM_SEQUENCE::text), '^^') 
            , '||', IFNULL(TRIM(EXT_FREIGHT_ORD::text), '^^') 
            , '||', IFNULL(TRIM(EXT_TM_SYS::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_RPFAR1::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_RPFAR2::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_RPMOWA::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_RPANHAE::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_RPFLGNR::text), '^^') 
            , '||', IFNULL(TRIM(VSO_R_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

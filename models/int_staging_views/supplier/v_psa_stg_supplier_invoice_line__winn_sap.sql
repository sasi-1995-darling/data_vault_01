---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_rseg') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_RSEG' )

/*
SRC_SRC            as ( SELECT * FROM sap_ecc_prd.z_rseg )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        BELNR                                                        as                                      INVOICE_ID_BK
      , BELNR
      , BUZEI                                                        as                                    INVOICE_LINE_BK
      , MANDT
      , GJAHR
      , BUZEI
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
      , GLREQUEST
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ(SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16), 'YYYYMMDDHH24MISS.FF9'))) as                                           LOAD_DTS
    FROM SRC_SRC
)

, LOGIC_ref_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_ref_bkcc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
    INNER JOIN LOGIC_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          INVOICE_ID_BK
        , BELNR
        , INVOICE_LINE_BK
        , MANDT
        , GJAHR
        , BUZEI
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
        , GLREQUEST
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , LOAD_DTS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BELNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BUZEI as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_INVOICE_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BELNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BELNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BELNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BUZEI as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SUPPLIER_INVOICE_LINE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(GJAHR::text), '^^') 
            , '||', IFNULL(TRIM(EBELN::text), '^^') 
            , '||', IFNULL(TRIM(EBELP::text), '^^') 
            , '||', IFNULL(TRIM(ZEKKN::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(BWKEY::text), '^^') 
            , '||', IFNULL(TRIM(BWTAR::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(WRBTR::text), '^^') 
            , '||', IFNULL(TRIM(SHKZG::text), '^^') 
            , '||', IFNULL(TRIM(MWSKZ::text), '^^') 
            , '||', IFNULL(TRIM(TXJCD::text), '^^') 
            , '||', IFNULL(TRIM(MENGE::text), '^^') 
            , '||', IFNULL(TRIM(BSTME::text), '^^') 
            , '||', IFNULL(TRIM(BPMNG::text), '^^') 
            , '||', IFNULL(TRIM(BPRME::text), '^^') 
            , '||', IFNULL(TRIM(LBKUM::text), '^^') 
            , '||', IFNULL(TRIM(VRKUM::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(PSTYP::text), '^^') 
            , '||', IFNULL(TRIM(KNTTP::text), '^^') 
            , '||', IFNULL(TRIM(BKLAS::text), '^^') 
            , '||', IFNULL(TRIM(EREKZ::text), '^^') 
            , '||', IFNULL(TRIM(EXKBE::text), '^^') 
            , '||', IFNULL(TRIM(XEKBZ::text), '^^') 
            , '||', IFNULL(TRIM(TBTKZ::text), '^^') 
            , '||', IFNULL(TRIM(SPGRP::text), '^^') 
            , '||', IFNULL(TRIM(SPGRM::text), '^^') 
            , '||', IFNULL(TRIM(SPGRT::text), '^^') 
            , '||', IFNULL(TRIM(SPGRG::text), '^^') 
            , '||', IFNULL(TRIM(SPGRV::text), '^^') 
            , '||', IFNULL(TRIM(SPGRQ::text), '^^') 
            , '||', IFNULL(TRIM(SPGRS::text), '^^') 
            , '||', IFNULL(TRIM(SPGRC::text), '^^') 
            , '||', IFNULL(TRIM(SPGREXT::text), '^^') 
            , '||', IFNULL(TRIM(BUSTW::text), '^^') 
            , '||', IFNULL(TRIM(XBLNR::text), '^^') 
            , '||', IFNULL(TRIM(XRUEB::text), '^^') 
            , '||', IFNULL(TRIM(BNKAN::text), '^^') 
            , '||', IFNULL(TRIM(KSCHL::text), '^^') 
            , '||', IFNULL(TRIM(SALK3::text), '^^') 
            , '||', IFNULL(TRIM(VMSAL::text), '^^') 
            , '||', IFNULL(TRIM(XLIFO::text), '^^') 
            , '||', IFNULL(TRIM(LFBNR::text), '^^') 
            , '||', IFNULL(TRIM(LFGJA::text), '^^') 
            , '||', IFNULL(TRIM(LFPOS::text), '^^') 
            , '||', IFNULL(TRIM(MATBF::text), '^^') 
            , '||', IFNULL(TRIM(RBMNG::text), '^^') 
            , '||', IFNULL(TRIM(BPRBM::text), '^^') 
            , '||', IFNULL(TRIM(RBWWR::text), '^^') 
            , '||', IFNULL(TRIM(LFEHL::text), '^^') 
            , '||', IFNULL(TRIM(GRICD::text), '^^') 
            , '||', IFNULL(TRIM(GRIRG::text), '^^') 
            , '||', IFNULL(TRIM(GITYP::text), '^^') 
            , '||', IFNULL(TRIM(PACKNO::text), '^^') 
            , '||', IFNULL(TRIM(INTROW::text), '^^') 
            , '||', IFNULL(TRIM(SGTXT::text), '^^') 
            , '||', IFNULL(TRIM(XSKRL::text), '^^') 
            , '||', IFNULL(TRIM(KZMEK::text), '^^') 
            , '||', IFNULL(TRIM(MRMOK::text), '^^') 
            , '||', IFNULL(TRIM(STUNR::text), '^^') 
            , '||', IFNULL(TRIM(ZAEHK::text), '^^') 
            , '||', IFNULL(TRIM(STOCK_POSTING::text), '^^') 
            , '||', IFNULL(TRIM(STOCK_POSTING_PP::text), '^^') 
            , '||', IFNULL(TRIM(STOCK_POSTING_PY::text), '^^') 
            , '||', IFNULL(TRIM(WEREC::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(FRBNR::text), '^^') 
            , '||', IFNULL(TRIM(XHISTMA::text), '^^') 
            , '||', IFNULL(TRIM(COMPLAINT_REASON::text), '^^') 
            , '||', IFNULL(TRIM(RETAMT_FC::text), '^^') 
            , '||', IFNULL(TRIM(RETPC::text), '^^') 
            , '||', IFNULL(TRIM(RETDUEDT::text), '^^') 
            , '||', IFNULL(TRIM(XRETTAXNET::text), '^^') 
            , '||', IFNULL(TRIM(RE_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ERP_CONTRACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ERP_CONTRACT_ITM::text), '^^') 
            , '||', IFNULL(TRIM(SRM_CONTRACT_ID::text), '^^') 
            , '||', IFNULL(TRIM(SRM_CONTRACT_ITM::text), '^^') 
            , '||', IFNULL(TRIM(CONT_PSTYP::text), '^^') 
            , '||', IFNULL(TRIM(SRVMAPKEY::text), '^^') 
            , '||', IFNULL(TRIM(CHARG::text), '^^') 
            , '||', IFNULL(TRIM(INV_ITM_ORIGIN::text), '^^') 
            , '||', IFNULL(TRIM(INVREL::text), '^^') 
            , '||', IFNULL(TRIM(XDINV::text), '^^') 
            , '||', IFNULL(TRIM(DIFF_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(XCPRF::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON::text), '^^') 
            , '||', IFNULL(TRIM(FSH_COLLECTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_THEME::text), '^^') 
            , '||', IFNULL(TRIM(LICNO::text), '^^') 
            , '||', IFNULL(TRIM(ZEILE::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SCAT::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC1::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC2::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC3::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

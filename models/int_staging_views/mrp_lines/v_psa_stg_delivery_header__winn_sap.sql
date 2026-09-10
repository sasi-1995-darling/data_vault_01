---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_likp') }} as SRC  ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_likp )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        VBELN                                                        as                                        DELIVERY_BK
      , MANDT
      , VBELN
      , GLREQUEST
      , ERNAM
      , ERZET
      , ERDAT
      , BZIRK
      , VSTEL
      , VKORG
      , LFART
      , AUTLF
      , KZAZU
      , WADAT
      , LDDAT
      , TDDAT
      , LFDAT
      , KODAT
      , ABLAD
      , INCO1
      , INCO2
      , EXPKZ
      , ROUTE
      , FAKSK
      , LIFSK
      , VBTYP
      , KNFAK
      , TPQUA
      , TPGRP
      , LPRIO
      , VSBED
      , KUNNR
      , KUNAG
      , KDGRP
      , STZKL
      , STZZU
      , BTGEW
      , NTGEW
      , GEWEI
      , VOLUM
      , VOLEH
      , ANZPK
      , BEROT
      , LFUHR
      , GRULG
      , LSTEL
      , TRAGR
      , FKARV
      , FKDAT
      , PERFK
      , ROUTA
      , STAFO
      , KALSM
      , KNUMV
      , WAERK
      , VKBUR
      , VBEAK
      , ZUKRL
      , VERUR
      , COMMN
      , STWAE
      , STCUR
      , EXNUM
      , AENAM
      , AEDAT
      , LGNUM
      , LISPL
      , VKOIV
      , VTWIV
      , SPAIV
      , FKAIV
      , PIOIV
      , FKDIV
      , KUNIV
      , KKBER
      , KNKLI
      , GRUPP
      , SBGRP
      , CTLPC
      , CMWAE
      , AMTBL
      , BOLNR
      , LIFNR
      , TRATY
      , TRAID
      , CMFRE
      , CMNGV
      , XABLN
      , BLDAT
      , WADAT_IST
      , TRSPG
      , TPSID
      , LIFEX
      , TERNR
      , KALSM_CH
      , KLIEF
      , KALSP
      , KNUMP
      , NETWR
      , AULWE
      , WERKS
      , LCNUM
      , ABSSC
      , KOUHR
      , TDUHR
      , LDUHR
      , WAUHR
      , LGTOR
      , LGBZO
      , AKWAE
      , AKKUR
      , AKPRZ
      , PROLI
      , XBLNR
      , HANDLE
      , TSEGFL
      , TSEGTP
      , TZONIS
      , TZONRC
      , CONT_DG
      , VERURSYS
      , KZWAB
      , VLSTK
      , TCODE
      , VSART
      , TRMTYP
      , SDABW
      , VBUND
      , XWOFF
      , DIRTA
      , PRVBE
      , FOLAR
      , PODAT
      , POTIM
      , VGANZ
      , IMWRK
      , SPE_LOEKZ
      , SPE_LOC_SEQ
      , SPE_ACC_APP_STS
      , SPE_SHP_INF_STS
      , SPE_RET_CANC
      , SPE_WAUHR_IST
      , SPE_WAZONE_IST
      , SPE_REV_VLSTK
      , SPE_LE_SCENARIO
      , SPE_ORIG_SYS
      , SPE_CHNG_SYS
      , SPE_GEOROUTE
      , SPE_GEOROUTEIND
      , SPE_CARRIER_IND
      , SPE_GTS_REL
      , SPE_GTS_RT_CDE
      , SPE_REL_TMSTMP
      , SPE_UNIT_SYSTEM
      , SPE_INV_BFR_GI
      , SPE_QI_STATUS
      , SPE_RED_IND
      , SAKES
      , SPE_LIFEX_TYPE
      , SPE_TTYPE
      , SPE_PRO_NUMBER
      , LOC_GUID
      , SPE_BILLING_IND
      , PRINTER_PROFILE
      , MSR_ACTIVE
      , PRTNR
      , STGE_LOC_CHANGE
      , TM_CTRL_KEY
      , DLV_SPLIT_INITIA
      , DLV_VERSION
      , HANDOVERLOC
      , HANDOVERDATE
      , HANDOVERTIME
      , HANDOVERTZONE
      , INCOV
      , INCO2_L
      , INCO3_L
      , "/BEV1/LULEINH"                                              as                                       BEV1_LULEINH
      , "/BEV1/RPFAESS"                                              as                                       BEV1_RPFAESS
      , "/BEV1/RPKIST"                                               as                                        BEV1_RPKIST
      , "/BEV1/RPCONT"                                               as                                        BEV1_RPCONT
      , "/BEV1/RPSONST"                                              as                                       BEV1_RPSONST
      , "/BEV1/RPFLGNR"                                              as                                       BEV1_RPFLGNR
      , BORGR_GRP
      , FSH_TRANSACTION
      , FSH_VAS_LAST_ITEM
      , FSH_VAS_CG
      , ZZORC
      , ZZCUSTTL
      , ZZTMS
      , ZZCONSOLIDATE
      , ZZNETPRICE
      , ZZAPNTMNT
      , ZZTMSEXE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
            )
        ))                                                           as                                           LOAD_DTS
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
        DELIVERY_BK
      , MANDT
      , VBELN
      , GLREQUEST
      , ERNAM
      , ERZET
      , ERDAT
      , BZIRK
      , VSTEL
      , VKORG
      , LFART
      , AUTLF
      , KZAZU
      , WADAT
      , LDDAT
      , TDDAT
      , LFDAT
      , KODAT
      , ABLAD
      , INCO1
      , INCO2
      , EXPKZ
      , ROUTE
      , FAKSK
      , LIFSK
      , VBTYP
      , KNFAK
      , TPQUA
      , TPGRP
      , LPRIO
      , VSBED
      , KUNNR
      , KUNAG
      , KDGRP
      , STZKL
      , STZZU
      , BTGEW
      , NTGEW
      , GEWEI
      , VOLUM
      , VOLEH
      , ANZPK
      , BEROT
      , LFUHR
      , GRULG
      , LSTEL
      , TRAGR
      , FKARV
      , FKDAT
      , PERFK
      , ROUTA
      , STAFO
      , KALSM
      , KNUMV
      , WAERK
      , VKBUR
      , VBEAK
      , ZUKRL
      , VERUR
      , COMMN
      , STWAE
      , STCUR
      , EXNUM
      , AENAM
      , AEDAT
      , LGNUM
      , LISPL
      , VKOIV
      , VTWIV
      , SPAIV
      , FKAIV
      , PIOIV
      , FKDIV
      , KUNIV
      , KKBER
      , KNKLI
      , GRUPP
      , SBGRP
      , CTLPC
      , CMWAE
      , AMTBL
      , BOLNR
      , LIFNR
      , TRATY
      , TRAID
      , CMFRE
      , CMNGV
      , XABLN
      , BLDAT
      , WADAT_IST
      , TRSPG
      , TPSID
      , LIFEX
      , TERNR
      , KALSM_CH
      , KLIEF
      , KALSP
      , KNUMP
      , NETWR
      , AULWE
      , WERKS
      , LCNUM
      , ABSSC
      , KOUHR
      , TDUHR
      , LDUHR
      , WAUHR
      , LGTOR
      , LGBZO
      , AKWAE
      , AKKUR
      , AKPRZ
      , PROLI
      , XBLNR
      , HANDLE
      , TSEGFL
      , TSEGTP
      , TZONIS
      , TZONRC
      , CONT_DG
      , VERURSYS
      , KZWAB
      , VLSTK
      , TCODE
      , VSART
      , TRMTYP
      , SDABW
      , VBUND
      , XWOFF
      , DIRTA
      , PRVBE
      , FOLAR
      , PODAT
      , POTIM
      , VGANZ
      , IMWRK
      , SPE_LOEKZ
      , SPE_LOC_SEQ
      , SPE_ACC_APP_STS
      , SPE_SHP_INF_STS
      , SPE_RET_CANC
      , SPE_WAUHR_IST
      , SPE_WAZONE_IST
      , SPE_REV_VLSTK
      , SPE_LE_SCENARIO
      , SPE_ORIG_SYS
      , SPE_CHNG_SYS
      , SPE_GEOROUTE
      , SPE_GEOROUTEIND
      , SPE_CARRIER_IND
      , SPE_GTS_REL
      , SPE_GTS_RT_CDE
      , SPE_REL_TMSTMP
      , SPE_UNIT_SYSTEM
      , SPE_INV_BFR_GI
      , SPE_QI_STATUS
      , SPE_RED_IND
      , SAKES
      , SPE_LIFEX_TYPE
      , SPE_TTYPE
      , SPE_PRO_NUMBER
      , LOC_GUID
      , SPE_BILLING_IND
      , PRINTER_PROFILE
      , MSR_ACTIVE
      , PRTNR
      , STGE_LOC_CHANGE
      , TM_CTRL_KEY
      , DLV_SPLIT_INITIA
      , DLV_VERSION
      , HANDOVERLOC
      , HANDOVERDATE
      , HANDOVERTIME
      , HANDOVERTZONE
      , INCOV
      , INCO2_L
      , INCO3_L
      , BEV1_LULEINH
      , BEV1_RPFAESS
      , BEV1_RPKIST
      , BEV1_RPCONT
      , BEV1_RPSONST
      , BEV1_RPFLGNR
      , BORGR_GRP
      , FSH_TRANSACTION
      , FSH_VAS_LAST_ITEM
      , FSH_VAS_CG
      , ZZORC
      , ZZCUSTTL
      , ZZTMS
      , ZZCONSOLIDATE
      , ZZNETPRICE
      , ZZAPNTMNT
      , ZZTMSEXE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_LIKP' 
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
          DELIVERY_BK
        , MANDT
        , VBELN
        , GLREQUEST
        , ERNAM
        , ERZET
        , ERDAT
        , BZIRK
        , VSTEL
        , VKORG
        , LFART
        , AUTLF
        , KZAZU
        , WADAT
        , LDDAT
        , TDDAT
        , LFDAT
        , KODAT
        , ABLAD
        , INCO1
        , INCO2
        , EXPKZ
        , ROUTE
        , FAKSK
        , LIFSK
        , VBTYP
        , KNFAK
        , TPQUA
        , TPGRP
        , LPRIO
        , VSBED
        , KUNNR
        , KUNAG
        , KDGRP
        , STZKL
        , STZZU
        , BTGEW
        , NTGEW
        , GEWEI
        , VOLUM
        , VOLEH
        , ANZPK
        , BEROT
        , LFUHR
        , GRULG
        , LSTEL
        , TRAGR
        , FKARV
        , FKDAT
        , PERFK
        , ROUTA
        , STAFO
        , KALSM
        , KNUMV
        , WAERK
        , VKBUR
        , VBEAK
        , ZUKRL
        , VERUR
        , COMMN
        , STWAE
        , STCUR
        , EXNUM
        , AENAM
        , AEDAT
        , LGNUM
        , LISPL
        , VKOIV
        , VTWIV
        , SPAIV
        , FKAIV
        , PIOIV
        , FKDIV
        , KUNIV
        , KKBER
        , KNKLI
        , GRUPP
        , SBGRP
        , CTLPC
        , CMWAE
        , AMTBL
        , BOLNR
        , LIFNR
        , TRATY
        , TRAID
        , CMFRE
        , CMNGV
        , XABLN
        , BLDAT
        , WADAT_IST
        , TRSPG
        , TPSID
        , LIFEX
        , TERNR
        , KALSM_CH
        , KLIEF
        , KALSP
        , KNUMP
        , NETWR
        , AULWE
        , WERKS
        , LCNUM
        , ABSSC
        , KOUHR
        , TDUHR
        , LDUHR
        , WAUHR
        , LGTOR
        , LGBZO
        , AKWAE
        , AKKUR
        , AKPRZ
        , PROLI
        , XBLNR
        , HANDLE
        , TSEGFL
        , TSEGTP
        , TZONIS
        , TZONRC
        , CONT_DG
        , VERURSYS
        , KZWAB
        , VLSTK
        , TCODE
        , VSART
        , TRMTYP
        , SDABW
        , VBUND
        , XWOFF
        , DIRTA
        , PRVBE
        , FOLAR
        , PODAT
        , POTIM
        , VGANZ
        , IMWRK
        , SPE_LOEKZ
        , SPE_LOC_SEQ
        , SPE_ACC_APP_STS
        , SPE_SHP_INF_STS
        , SPE_RET_CANC
        , SPE_WAUHR_IST
        , SPE_WAZONE_IST
        , SPE_REV_VLSTK
        , SPE_LE_SCENARIO
        , SPE_ORIG_SYS
        , SPE_CHNG_SYS
        , SPE_GEOROUTE
        , SPE_GEOROUTEIND
        , SPE_CARRIER_IND
        , SPE_GTS_REL
        , SPE_GTS_RT_CDE
        , SPE_REL_TMSTMP
        , SPE_UNIT_SYSTEM
        , SPE_INV_BFR_GI
        , SPE_QI_STATUS
        , SPE_RED_IND
        , SAKES
        , SPE_LIFEX_TYPE
        , SPE_TTYPE
        , SPE_PRO_NUMBER
        , LOC_GUID
        , SPE_BILLING_IND
        , PRINTER_PROFILE
        , MSR_ACTIVE
        , PRTNR
        , STGE_LOC_CHANGE
        , TM_CTRL_KEY
        , DLV_SPLIT_INITIA
        , DLV_VERSION
        , HANDOVERLOC
        , HANDOVERDATE
        , HANDOVERTIME
        , HANDOVERTZONE
        , INCOV
        , INCO2_L
        , INCO3_L
        , BEV1_LULEINH
        , BEV1_RPFAESS
        , BEV1_RPKIST
        , BEV1_RPCONT
        , BEV1_RPSONST
        , BEV1_RPFLGNR
        , BORGR_GRP
        , FSH_TRANSACTION
        , FSH_VAS_LAST_ITEM
        , FSH_VAS_CG
        , ZZORC
        , ZZCUSTTL
        , ZZTMS
        , ZZCONSOLIDATE
        , ZZNETPRICE
        , ZZAPNTMNT
        , ZZTMSEXE
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DELIVERY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^')
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERZET::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(BZIRK::text), '^^') 
            , '||', IFNULL(TRIM(VSTEL::text), '^^') 
            , '||', IFNULL(TRIM(VKORG::text), '^^') 
            , '||', IFNULL(TRIM(LFART::text), '^^') 
            , '||', IFNULL(TRIM(AUTLF::text), '^^') 
            , '||', IFNULL(TRIM(KZAZU::text), '^^') 
            , '||', IFNULL(TRIM(WADAT::text), '^^') 
            , '||', IFNULL(TRIM(LDDAT::text), '^^') 
            , '||', IFNULL(TRIM(TDDAT::text), '^^') 
            , '||', IFNULL(TRIM(LFDAT::text), '^^') 
            , '||', IFNULL(TRIM(KODAT::text), '^^') 
            , '||', IFNULL(TRIM(ABLAD::text), '^^') 
            , '||', IFNULL(TRIM(INCO1::text), '^^') 
            , '||', IFNULL(TRIM(INCO2::text), '^^') 
            , '||', IFNULL(TRIM(EXPKZ::text), '^^') 
            , '||', IFNULL(TRIM(ROUTE::text), '^^') 
            , '||', IFNULL(TRIM(FAKSK::text), '^^') 
            , '||', IFNULL(TRIM(LIFSK::text), '^^') 
            , '||', IFNULL(TRIM(VBTYP::text), '^^') 
            , '||', IFNULL(TRIM(KNFAK::text), '^^') 
            , '||', IFNULL(TRIM(TPQUA::text), '^^') 
            , '||', IFNULL(TRIM(TPGRP::text), '^^') 
            , '||', IFNULL(TRIM(LPRIO::text), '^^') 
            , '||', IFNULL(TRIM(VSBED::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(KUNAG::text), '^^') 
            , '||', IFNULL(TRIM(KDGRP::text), '^^') 
            , '||', IFNULL(TRIM(STZKL::text), '^^') 
            , '||', IFNULL(TRIM(STZZU::text), '^^') 
            , '||', IFNULL(TRIM(BTGEW::text), '^^') 
            , '||', IFNULL(TRIM(NTGEW::text), '^^') 
            , '||', IFNULL(TRIM(GEWEI::text), '^^') 
            , '||', IFNULL(TRIM(VOLUM::text), '^^') 
            , '||', IFNULL(TRIM(VOLEH::text), '^^') 
            , '||', IFNULL(TRIM(ANZPK::text), '^^') 
            , '||', IFNULL(TRIM(BEROT::text), '^^') 
            , '||', IFNULL(TRIM(LFUHR::text), '^^') 
            , '||', IFNULL(TRIM(GRULG::text), '^^') 
            , '||', IFNULL(TRIM(LSTEL::text), '^^') 
            , '||', IFNULL(TRIM(TRAGR::text), '^^') 
            , '||', IFNULL(TRIM(FKARV::text), '^^') 
            , '||', IFNULL(TRIM(FKDAT::text), '^^') 
            , '||', IFNULL(TRIM(PERFK::text), '^^') 
            , '||', IFNULL(TRIM(ROUTA::text), '^^') 
            , '||', IFNULL(TRIM(STAFO::text), '^^') 
            , '||', IFNULL(TRIM(KALSM::text), '^^') 
            , '||', IFNULL(TRIM(KNUMV::text), '^^') 
            , '||', IFNULL(TRIM(WAERK::text), '^^') 
            , '||', IFNULL(TRIM(VKBUR::text), '^^') 
            , '||', IFNULL(TRIM(VBEAK::text), '^^') 
            , '||', IFNULL(TRIM(ZUKRL::text), '^^') 
            , '||', IFNULL(TRIM(VERUR::text), '^^') 
            , '||', IFNULL(TRIM(COMMN::text), '^^') 
            , '||', IFNULL(TRIM(STWAE::text), '^^') 
            , '||', IFNULL(TRIM(STCUR::text), '^^') 
            , '||', IFNULL(TRIM(EXNUM::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(LGNUM::text), '^^') 
            , '||', IFNULL(TRIM(LISPL::text), '^^') 
            , '||', IFNULL(TRIM(VKOIV::text), '^^') 
            , '||', IFNULL(TRIM(VTWIV::text), '^^') 
            , '||', IFNULL(TRIM(SPAIV::text), '^^') 
            , '||', IFNULL(TRIM(FKAIV::text), '^^') 
            , '||', IFNULL(TRIM(PIOIV::text), '^^') 
            , '||', IFNULL(TRIM(FKDIV::text), '^^') 
            , '||', IFNULL(TRIM(KUNIV::text), '^^') 
            , '||', IFNULL(TRIM(KKBER::text), '^^') 
            , '||', IFNULL(TRIM(KNKLI::text), '^^') 
            , '||', IFNULL(TRIM(GRUPP::text), '^^') 
            , '||', IFNULL(TRIM(SBGRP::text), '^^') 
            , '||', IFNULL(TRIM(CTLPC::text), '^^') 
            , '||', IFNULL(TRIM(CMWAE::text), '^^') 
            , '||', IFNULL(TRIM(AMTBL::text), '^^') 
            , '||', IFNULL(TRIM(BOLNR::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(TRATY::text), '^^') 
            , '||', IFNULL(TRIM(TRAID::text), '^^') 
            , '||', IFNULL(TRIM(CMFRE::text), '^^') 
            , '||', IFNULL(TRIM(CMNGV::text), '^^') 
            , '||', IFNULL(TRIM(XABLN::text), '^^') 
            , '||', IFNULL(TRIM(BLDAT::text), '^^') 
            , '||', IFNULL(TRIM(WADAT_IST::text), '^^') 
            , '||', IFNULL(TRIM(TRSPG::text), '^^') 
            , '||', IFNULL(TRIM(TPSID::text), '^^') 
            , '||', IFNULL(TRIM(LIFEX::text), '^^') 
            , '||', IFNULL(TRIM(TERNR::text), '^^') 
            , '||', IFNULL(TRIM(KALSM_CH::text), '^^') 
            , '||', IFNULL(TRIM(KLIEF::text), '^^') 
            , '||', IFNULL(TRIM(KALSP::text), '^^') 
            , '||', IFNULL(TRIM(KNUMP::text), '^^') 
            , '||', IFNULL(TRIM(NETWR::text), '^^') 
            , '||', IFNULL(TRIM(AULWE::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(LCNUM::text), '^^') 
            , '||', IFNULL(TRIM(ABSSC::text), '^^') 
            , '||', IFNULL(TRIM(KOUHR::text), '^^') 
            , '||', IFNULL(TRIM(TDUHR::text), '^^') 
            , '||', IFNULL(TRIM(LDUHR::text), '^^') 
            , '||', IFNULL(TRIM(WAUHR::text), '^^') 
            , '||', IFNULL(TRIM(LGTOR::text), '^^') 
            , '||', IFNULL(TRIM(LGBZO::text), '^^') 
            , '||', IFNULL(TRIM(AKWAE::text), '^^') 
            , '||', IFNULL(TRIM(AKKUR::text), '^^') 
            , '||', IFNULL(TRIM(AKPRZ::text), '^^') 
            , '||', IFNULL(TRIM(PROLI::text), '^^') 
            , '||', IFNULL(TRIM(XBLNR::text), '^^') 
            , '||', IFNULL(TRIM(HANDLE::text), '^^') 
            , '||', IFNULL(TRIM(TSEGFL::text), '^^') 
            , '||', IFNULL(TRIM(TSEGTP::text), '^^') 
            , '||', IFNULL(TRIM(TZONIS::text), '^^') 
            , '||', IFNULL(TRIM(TZONRC::text), '^^') 
            , '||', IFNULL(TRIM(CONT_DG::text), '^^') 
            , '||', IFNULL(TRIM(VERURSYS::text), '^^') 
            , '||', IFNULL(TRIM(KZWAB::text), '^^') 
            , '||', IFNULL(TRIM(VLSTK::text), '^^') 
            , '||', IFNULL(TRIM(TCODE::text), '^^') 
            , '||', IFNULL(TRIM(VSART::text), '^^') 
            , '||', IFNULL(TRIM(TRMTYP::text), '^^') 
            , '||', IFNULL(TRIM(SDABW::text), '^^') 
            , '||', IFNULL(TRIM(VBUND::text), '^^') 
            , '||', IFNULL(TRIM(XWOFF::text), '^^') 
            , '||', IFNULL(TRIM(DIRTA::text), '^^') 
            , '||', IFNULL(TRIM(PRVBE::text), '^^') 
            , '||', IFNULL(TRIM(FOLAR::text), '^^') 
            , '||', IFNULL(TRIM(PODAT::text), '^^') 
            , '||', IFNULL(TRIM(POTIM::text), '^^') 
            , '||', IFNULL(TRIM(VGANZ::text), '^^') 
            , '||', IFNULL(TRIM(IMWRK::text), '^^') 
            , '||', IFNULL(TRIM(SPE_LOEKZ::text), '^^') 
            , '||', IFNULL(TRIM(SPE_LOC_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(SPE_ACC_APP_STS::text), '^^') 
            , '||', IFNULL(TRIM(SPE_SHP_INF_STS::text), '^^') 
            , '||', IFNULL(TRIM(SPE_RET_CANC::text), '^^') 
            , '||', IFNULL(TRIM(SPE_WAUHR_IST::text), '^^') 
            , '||', IFNULL(TRIM(SPE_WAZONE_IST::text), '^^') 
            , '||', IFNULL(TRIM(SPE_REV_VLSTK::text), '^^') 
            , '||', IFNULL(TRIM(SPE_LE_SCENARIO::text), '^^') 
            , '||', IFNULL(TRIM(SPE_ORIG_SYS::text), '^^') 
            , '||', IFNULL(TRIM(SPE_CHNG_SYS::text), '^^') 
            , '||', IFNULL(TRIM(SPE_GEOROUTE::text), '^^') 
            , '||', IFNULL(TRIM(SPE_GEOROUTEIND::text), '^^') 
            , '||', IFNULL(TRIM(SPE_CARRIER_IND::text), '^^') 
            , '||', IFNULL(TRIM(SPE_GTS_REL::text), '^^') 
            , '||', IFNULL(TRIM(SPE_GTS_RT_CDE::text), '^^') 
            , '||', IFNULL(TRIM(SPE_REL_TMSTMP::text), '^^') 
            , '||', IFNULL(TRIM(SPE_UNIT_SYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(SPE_INV_BFR_GI::text), '^^') 
            , '||', IFNULL(TRIM(SPE_QI_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(SPE_RED_IND::text), '^^') 
            , '||', IFNULL(TRIM(SAKES::text), '^^') 
            , '||', IFNULL(TRIM(SPE_LIFEX_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SPE_TTYPE::text), '^^') 
            , '||', IFNULL(TRIM(SPE_PRO_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(LOC_GUID::text), '^^') 
            , '||', IFNULL(TRIM(SPE_BILLING_IND::text), '^^') 
            , '||', IFNULL(TRIM(PRINTER_PROFILE::text), '^^') 
            , '||', IFNULL(TRIM(MSR_ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(PRTNR::text), '^^') 
            , '||', IFNULL(TRIM(STGE_LOC_CHANGE::text), '^^') 
            , '||', IFNULL(TRIM(TM_CTRL_KEY::text), '^^') 
            , '||', IFNULL(TRIM(DLV_SPLIT_INITIA::text), '^^') 
            , '||', IFNULL(TRIM(DLV_VERSION::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVERLOC::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVERDATE::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVERTIME::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVERTZONE::text), '^^') 
            , '||', IFNULL(TRIM(INCOV::text), '^^') 
            , '||', IFNULL(TRIM(INCO2_L::text), '^^') 
            , '||', IFNULL(TRIM(INCO3_L::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_LULEINH::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_RPFAESS::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_RPKIST::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_RPCONT::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_RPSONST::text), '^^') 
            , '||', IFNULL(TRIM(BEV1_RPFLGNR::text), '^^') 
            , '||', IFNULL(TRIM(BORGR_GRP::text), '^^') 
            , '||', IFNULL(TRIM(FSH_TRANSACTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_LAST_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_CG::text), '^^') 
            , '||', IFNULL(TRIM(ZZORC::text), '^^') 
            , '||', IFNULL(TRIM(ZZCUSTTL::text), '^^') 
            , '||', IFNULL(TRIM(ZZTMS::text), '^^') 
            , '||', IFNULL(TRIM(ZZCONSOLIDATE::text), '^^') 
            , '||', IFNULL(TRIM(ZZNETPRICE::text), '^^') 
            , '||', IFNULL(TRIM(ZZAPNTMNT::text), '^^') 
            , '||', IFNULL(TRIM(ZZTMSEXE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

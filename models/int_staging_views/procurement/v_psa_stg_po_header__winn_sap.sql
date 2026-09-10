---- SRC LAYER ----
WITH
SRC_E              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_ekko') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_E              as ( SELECT * FROM sap_ecc_prd.z_ekko )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_E as (
    SELECT
        EBELN                                                        as                                       PO_HEADER_BK
      , MANDT
      , EBELN
      , GLREQUEST
      , GLSOURCESYSTEM
      , BUKRS
      , BSTYP
      , BSART
      , BSAKZ
      , LOEKZ
      , STATU
      , AEDAT
      , ERNAM
      , PINCR
      , LPONR
      , LIFNR
      , SPRAS
      , ZTERM
      , ZBD1T
      , ZBD2T
      , ZBD3T
      , ZBD1P
      , ZBD2P
      , EKORG
      , EKGRP
      , WAERS
      , WKURS
      , KUFIX
      , BEDAT
      , KDATB
      , KDATE
      , BWBDT
      , ANGDT
      , BNDDT
      , GWLDT
      , AUSNR
      , ANGNR
      , IHRAN
      , IHREZ
      , VERKF
      , TELF1
      , LLIEF
      , KUNNR
      , KONNR
      , ABGRU
      , AUTLF
      , WEAKT
      , RESWK
      , LBLIF
      , INCO1
      , INCO2
      , KTWRT
      , SUBMI
      , KNUMV
      , KALSM
      , STAFO
      , LIFRE
      , EXNUM
      , UNSEZ
      , LOGSY
      , UPINC
      , STAKO
      , FRGGR
      , FRGSX
      , FRGKE
      , FRGZU
      , FRGRL
      , LANDS
      , LPHIS
      , ADRNR
      , STCEG_L
      , STCEG
      , ABSGR
      , ADDNR
      , KORNR
      , MEMORY
      , PROCSTAT
      , RLWRT
      , REVNO
      , SCMPROC
      , REASON_CODE
      , MEMORYTYPE
      , RETTP
      , RETPC
      , DPTYP
      , DPPCT
      , DPAMT
      , DPDAT
      , MSR_ID
      , HIERARCHY_EXISTS
      , THRESHOLD_EXISTS
      , LEGAL_CONTRACT
      , DESCRIPTION
      , RELEASE_DATE
      , VSART
      , HANDOVERLOC
      , SHIPCOND
      , INCOV
      , INCO2_L
      , INCO3_L
      , FORCE_ID
      , FORCE_CNT
      , RELOC_ID
      , RELOC_SEQ_ID
      , SOURCE_LOGSYS
      , FSH_TRANSACTION
      , FSH_ITEM_GROUP
      , FSH_VAS_LAST_ITEM
      , FSH_OS_STG_CHANGE
      , ZZ3RDPO
      , ZZNO_EMAIL
      , ZZFRZ_SHPDT
      , VZSKZ
      , FSH_SNST_STATUS
      , POHF_TYPE
      , EQ_EINDT
      , EQ_WERKS
      , FIXPO
      , EKGRP_ALLOW
      , WERKS_ALLOW
      , CONTRACT_ALLOW
      , PSTYP_ALLOW
      , FIXPO_ALLOW
      , KEY_ID_ALLOW
      , AUREL_ALLOW
      , DELPER_ALLOW
      , EINDT_ALLOW
      , LTSNR_ALLOW
      , OTB_LEVEL
      , OTB_COND_TYPE
      , KEY_ID
      , OTB_VALUE
      , OTB_CURR
      , OTB_RES_VALUE
      , OTB_SPEC_VALUE
      , SPR_RSN_PROFILE
      , BUDG_TYPE
      , OTB_STATUS
      , OTB_REASON
      , CHECK_TYPE
      , CON_OTB_REQ
      , CON_PREBOOK_LEV
      , CON_DISTR_LEV
      , ZZACKIND_SENT
      , ZZACCIND_SENT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_E
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_E as (
    SELECT
        PO_HEADER_BK
      , MANDT
      , EBELN
      , GLREQUEST
      , GLSOURCESYSTEM
      , BUKRS
      , BSTYP
      , BSART
      , BSAKZ
      , LOEKZ
      , STATU
      , AEDAT
      , ERNAM
      , PINCR
      , LPONR
      , LIFNR
      , SPRAS
      , ZTERM
      , ZBD1T
      , ZBD2T
      , ZBD3T
      , ZBD1P
      , ZBD2P
      , EKORG
      , EKGRP
      , WAERS
      , WKURS
      , KUFIX
      , BEDAT
      , KDATB
      , KDATE
      , BWBDT
      , ANGDT
      , BNDDT
      , GWLDT
      , AUSNR
      , ANGNR
      , IHRAN
      , IHREZ
      , VERKF
      , TELF1
      , LLIEF
      , KUNNR
      , KONNR
      , ABGRU
      , AUTLF
      , WEAKT
      , RESWK
      , LBLIF
      , INCO1
      , INCO2
      , KTWRT
      , SUBMI
      , KNUMV
      , KALSM
      , STAFO
      , LIFRE
      , EXNUM
      , UNSEZ
      , LOGSY
      , UPINC
      , STAKO
      , FRGGR
      , FRGSX
      , FRGKE
      , FRGZU
      , FRGRL
      , LANDS
      , LPHIS
      , ADRNR
      , STCEG_L
      , STCEG
      , ABSGR
      , ADDNR
      , KORNR
      , MEMORY
      , PROCSTAT
      , RLWRT
      , REVNO
      , SCMPROC
      , REASON_CODE
      , MEMORYTYPE
      , RETTP
      , RETPC
      , DPTYP
      , DPPCT
      , DPAMT
      , DPDAT
      , MSR_ID
      , HIERARCHY_EXISTS
      , THRESHOLD_EXISTS
      , LEGAL_CONTRACT
      , DESCRIPTION
      , RELEASE_DATE
      , VSART
      , HANDOVERLOC
      , SHIPCOND
      , INCOV
      , INCO2_L
      , INCO3_L
      , FORCE_ID
      , FORCE_CNT
      , RELOC_ID
      , RELOC_SEQ_ID
      , SOURCE_LOGSYS
      , FSH_TRANSACTION
      , FSH_ITEM_GROUP
      , FSH_VAS_LAST_ITEM
      , FSH_OS_STG_CHANGE
      , ZZ3RDPO
      , ZZNO_EMAIL
      , ZZFRZ_SHPDT
      , VZSKZ
      , FSH_SNST_STATUS
      , POHF_TYPE
      , EQ_EINDT
      , EQ_WERKS
      , FIXPO
      , EKGRP_ALLOW
      , WERKS_ALLOW
      , CONTRACT_ALLOW
      , PSTYP_ALLOW
      , FIXPO_ALLOW
      , KEY_ID_ALLOW
      , AUREL_ALLOW
      , DELPER_ALLOW
      , EINDT_ALLOW
      , LTSNR_ALLOW
      , OTB_LEVEL
      , OTB_COND_TYPE
      , KEY_ID
      , OTB_VALUE
      , OTB_CURR
      , OTB_RES_VALUE
      , OTB_SPEC_VALUE
      , SPR_RSN_PROFILE
      , BUDG_TYPE
      , OTB_STATUS
      , OTB_REASON
      , CHECK_TYPE
      , CON_OTB_REQ
      , CON_PREBOOK_LEV
      , CON_DISTR_LEV
      , ZZACKIND_SENT
      , ZZACCIND_SENT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_E
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_E as (
    SELECT *
    FROM RENAME_E
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_EKKO'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_E
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PO_HEADER_BK
        , MANDT
        , EBELN
        , GLREQUEST
        , GLSOURCESYSTEM
        , BUKRS
        , BSTYP
        , BSART
        , BSAKZ
        , LOEKZ
        , STATU
        , AEDAT
        , ERNAM
        , PINCR
        , LPONR
        , LIFNR
        , SPRAS
        , ZTERM
        , ZBD1T
        , ZBD2T
        , ZBD3T
        , ZBD1P
        , ZBD2P
        , EKORG
        , EKGRP
        , WAERS
        , WKURS
        , KUFIX
        , BEDAT
        , KDATB
        , KDATE
        , BWBDT
        , ANGDT
        , BNDDT
        , GWLDT
        , AUSNR
        , ANGNR
        , IHRAN
        , IHREZ
        , VERKF
        , TELF1
        , LLIEF
        , KUNNR
        , KONNR
        , ABGRU
        , AUTLF
        , WEAKT
        , RESWK
        , LBLIF
        , INCO1
        , INCO2
        , KTWRT
        , SUBMI
        , KNUMV
        , KALSM
        , STAFO
        , LIFRE
        , EXNUM
        , UNSEZ
        , LOGSY
        , UPINC
        , STAKO
        , FRGGR
        , FRGSX
        , FRGKE
        , FRGZU
        , FRGRL
        , LANDS
        , LPHIS
        , ADRNR
        , STCEG_L
        , STCEG
        , ABSGR
        , ADDNR
        , KORNR
        , MEMORY
        , PROCSTAT
        , RLWRT
        , REVNO
        , SCMPROC
        , REASON_CODE
        , MEMORYTYPE
        , RETTP
        , RETPC
        , DPTYP
        , DPPCT
        , DPAMT
        , DPDAT
        , MSR_ID
        , HIERARCHY_EXISTS
        , THRESHOLD_EXISTS
        , LEGAL_CONTRACT
        , DESCRIPTION
        , RELEASE_DATE
        , VSART
        , HANDOVERLOC
        , SHIPCOND
        , INCOV
        , INCO2_L
        , INCO3_L
        , FORCE_ID
        , FORCE_CNT
        , RELOC_ID
        , RELOC_SEQ_ID
        , SOURCE_LOGSYS
        , FSH_TRANSACTION
        , FSH_ITEM_GROUP
        , FSH_VAS_LAST_ITEM
        , FSH_OS_STG_CHANGE
        , ZZ3RDPO
        , ZZNO_EMAIL
        , ZZFRZ_SHPDT
        , VZSKZ
        , FSH_SNST_STATUS
        , POHF_TYPE
        , EQ_EINDT
        , EQ_WERKS
        , FIXPO
        , EKGRP_ALLOW
        , WERKS_ALLOW
        , CONTRACT_ALLOW
        , PSTYP_ALLOW
        , FIXPO_ALLOW
        , KEY_ID_ALLOW
        , AUREL_ALLOW
        , DELPER_ALLOW
        , EINDT_ALLOW
        , LTSNR_ALLOW
        , OTB_LEVEL
        , OTB_COND_TYPE
        , KEY_ID
        , OTB_VALUE
        , OTB_CURR
        , OTB_RES_VALUE
        , OTB_SPEC_VALUE
        , SPR_RSN_PROFILE
        , BUDG_TYPE
        , OTB_STATUS
        , OTB_REASON
        , CHECK_TYPE
        , CON_OTB_REQ
        , CON_PREBOOK_LEV
        , CON_DISTR_LEV
        , ZZACKIND_SENT
        , ZZACCIND_SENT
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(BSTYP::text), '^^') 
            , '||', IFNULL(TRIM(BSART::text), '^^') 
            , '||', IFNULL(TRIM(BSAKZ::text), '^^') 
            , '||', IFNULL(TRIM(LOEKZ::text), '^^') 
            , '||', IFNULL(TRIM(STATU::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(PINCR::text), '^^') 
            , '||', IFNULL(TRIM(LPONR::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(ZTERM::text), '^^') 
            , '||', IFNULL(TRIM(ZBD1T::text), '^^') 
            , '||', IFNULL(TRIM(ZBD2T::text), '^^') 
            , '||', IFNULL(TRIM(ZBD3T::text), '^^') 
            , '||', IFNULL(TRIM(ZBD1P::text), '^^') 
            , '||', IFNULL(TRIM(ZBD2P::text), '^^') 
            , '||', IFNULL(TRIM(EKORG::text), '^^') 
            , '||', IFNULL(TRIM(EKGRP::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(WKURS::text), '^^') 
            , '||', IFNULL(TRIM(KUFIX::text), '^^') 
            , '||', IFNULL(TRIM(BEDAT::text), '^^') 
            , '||', IFNULL(TRIM(KDATB::text), '^^') 
            , '||', IFNULL(TRIM(KDATE::text), '^^') 
            , '||', IFNULL(TRIM(BWBDT::text), '^^') 
            , '||', IFNULL(TRIM(ANGDT::text), '^^') 
            , '||', IFNULL(TRIM(BNDDT::text), '^^') 
            , '||', IFNULL(TRIM(GWLDT::text), '^^') 
            , '||', IFNULL(TRIM(AUSNR::text), '^^') 
            , '||', IFNULL(TRIM(ANGNR::text), '^^') 
            , '||', IFNULL(TRIM(IHRAN::text), '^^') 
            , '||', IFNULL(TRIM(IHREZ::text), '^^') 
            , '||', IFNULL(TRIM(VERKF::text), '^^') 
            , '||', IFNULL(TRIM(TELF1::text), '^^') 
            , '||', IFNULL(TRIM(LLIEF::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(KONNR::text), '^^') 
            , '||', IFNULL(TRIM(ABGRU::text), '^^') 
            , '||', IFNULL(TRIM(AUTLF::text), '^^') 
            , '||', IFNULL(TRIM(WEAKT::text), '^^') 
            , '||', IFNULL(TRIM(RESWK::text), '^^') 
            , '||', IFNULL(TRIM(LBLIF::text), '^^') 
            , '||', IFNULL(TRIM(INCO1::text), '^^') 
            , '||', IFNULL(TRIM(INCO2::text), '^^') 
            , '||', IFNULL(TRIM(KTWRT::text), '^^') 
            , '||', IFNULL(TRIM(SUBMI::text), '^^') 
            , '||', IFNULL(TRIM(KNUMV::text), '^^') 
            , '||', IFNULL(TRIM(KALSM::text), '^^') 
            , '||', IFNULL(TRIM(STAFO::text), '^^') 
            , '||', IFNULL(TRIM(LIFRE::text), '^^') 
            , '||', IFNULL(TRIM(EXNUM::text), '^^') 
            , '||', IFNULL(TRIM(UNSEZ::text), '^^') 
            , '||', IFNULL(TRIM(LOGSY::text), '^^') 
            , '||', IFNULL(TRIM(UPINC::text), '^^') 
            , '||', IFNULL(TRIM(STAKO::text), '^^') 
            , '||', IFNULL(TRIM(FRGGR::text), '^^') 
            , '||', IFNULL(TRIM(FRGSX::text), '^^') 
            , '||', IFNULL(TRIM(FRGKE::text), '^^') 
            , '||', IFNULL(TRIM(FRGZU::text), '^^') 
            , '||', IFNULL(TRIM(FRGRL::text), '^^') 
            , '||', IFNULL(TRIM(LANDS::text), '^^') 
            , '||', IFNULL(TRIM(LPHIS::text), '^^') 
            , '||', IFNULL(TRIM(ADRNR::text), '^^') 
            , '||', IFNULL(TRIM(STCEG_L::text), '^^') 
            , '||', IFNULL(TRIM(STCEG::text), '^^') 
            , '||', IFNULL(TRIM(ABSGR::text), '^^') 
            , '||', IFNULL(TRIM(ADDNR::text), '^^') 
            , '||', IFNULL(TRIM(KORNR::text), '^^') 
            , '||', IFNULL(TRIM(MEMORY::text), '^^') 
            , '||', IFNULL(TRIM(PROCSTAT::text), '^^') 
            , '||', IFNULL(TRIM(RLWRT::text), '^^') 
            , '||', IFNULL(TRIM(REVNO::text), '^^') 
            , '||', IFNULL(TRIM(SCMPROC::text), '^^') 
            , '||', IFNULL(TRIM(REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(MEMORYTYPE::text), '^^') 
            , '||', IFNULL(TRIM(RETTP::text), '^^') 
            , '||', IFNULL(TRIM(RETPC::text), '^^') 
            , '||', IFNULL(TRIM(DPTYP::text), '^^') 
            , '||', IFNULL(TRIM(DPPCT::text), '^^') 
            , '||', IFNULL(TRIM(DPAMT::text), '^^') 
            , '||', IFNULL(TRIM(DPDAT::text), '^^') 
            , '||', IFNULL(TRIM(MSR_ID::text), '^^') 
            , '||', IFNULL(TRIM(HIERARCHY_EXISTS::text), '^^') 
            , '||', IFNULL(TRIM(THRESHOLD_EXISTS::text), '^^') 
            , '||', IFNULL(TRIM(LEGAL_CONTRACT::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(RELEASE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(VSART::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVERLOC::text), '^^') 
            , '||', IFNULL(TRIM(SHIPCOND::text), '^^') 
            , '||', IFNULL(TRIM(INCOV::text), '^^') 
            , '||', IFNULL(TRIM(INCO2_L::text), '^^') 
            , '||', IFNULL(TRIM(INCO3_L::text), '^^') 
            , '||', IFNULL(TRIM(FORCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(FORCE_CNT::text), '^^') 
            , '||', IFNULL(TRIM(RELOC_ID::text), '^^') 
            , '||', IFNULL(TRIM(RELOC_SEQ_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_LOGSYS::text), '^^') 
            , '||', IFNULL(TRIM(FSH_TRANSACTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_ITEM_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_LAST_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(FSH_OS_STG_CHANGE::text), '^^') 
            , '||', IFNULL(TRIM(ZZ3RDPO::text), '^^') 
            , '||', IFNULL(TRIM(ZZNO_EMAIL::text), '^^') 
            , '||', IFNULL(TRIM(ZZFRZ_SHPDT::text), '^^') 
            , '||', IFNULL(TRIM(VZSKZ::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SNST_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(POHF_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(EQ_EINDT::text), '^^') 
            , '||', IFNULL(TRIM(EQ_WERKS::text), '^^') 
            , '||', IFNULL(TRIM(FIXPO::text), '^^') 
            , '||', IFNULL(TRIM(EKGRP_ALLOW::text), '^^') 
            , '||', IFNULL(TRIM(WERKS_ALLOW::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACT_ALLOW::text), '^^') 
            , '||', IFNULL(TRIM(PSTYP_ALLOW::text), '^^') 
            , '||', IFNULL(TRIM(FIXPO_ALLOW::text), '^^') 
            , '||', IFNULL(TRIM(KEY_ID_ALLOW::text), '^^') 
            , '||', IFNULL(TRIM(AUREL_ALLOW::text), '^^') 
            , '||', IFNULL(TRIM(DELPER_ALLOW::text), '^^') 
            , '||', IFNULL(TRIM(EINDT_ALLOW::text), '^^') 
            , '||', IFNULL(TRIM(LTSNR_ALLOW::text), '^^') 
            , '||', IFNULL(TRIM(OTB_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(OTB_COND_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(KEY_ID::text), '^^') 
            , '||', IFNULL(TRIM(OTB_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(OTB_CURR::text), '^^') 
            , '||', IFNULL(TRIM(OTB_RES_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(OTB_SPEC_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(SPR_RSN_PROFILE::text), '^^') 
            , '||', IFNULL(TRIM(BUDG_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(OTB_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(OTB_REASON::text), '^^') 
            , '||', IFNULL(TRIM(CHECK_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CON_OTB_REQ::text), '^^') 
            , '||', IFNULL(TRIM(CON_PREBOOK_LEV::text), '^^') 
            , '||', IFNULL(TRIM(CON_DISTR_LEV::text), '^^') 
            , '||', IFNULL(TRIM(ZZACKIND_SENT::text), '^^') 
            , '||', IFNULL(TRIM(ZZACCIND_SENT::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

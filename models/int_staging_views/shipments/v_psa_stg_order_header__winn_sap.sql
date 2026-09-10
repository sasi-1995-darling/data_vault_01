---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_vbak') }} as SRC),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_vbak )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(coalesce(VBELN,'-1'))                                as                                    ORDER_HEADER_BK
      , MANDT
      , VBELN
      , GLREQUEST
      , ERDAT
      , ERZET
      , ERNAM
      , ANGDT
      , BNDDT
      , AUDAT
      , VBTYP
      , TRVOG
      , AUART
      , AUGRU
      , GWLDT
      , SUBMI
      , LIFSK
      , FAKSK
      , NETWR
      , WAERK
      , VKORG
      , VTWEG
      , SPART
      , VKGRP
      , VKBUR
      , GSBER
      , GSKST
      , GUEBG
      , GUEEN
      , KNUMV
      , VDATU
      , VPRGR
      , AUTLF
      , VBKLA
      , VBKLT
      , KALSM
      , VSBED
      , FKARA
      , AWAHR
      , KTEXT
      , BSTNK
      , BSARK
      , BSTDK
      , BSTZD
      , IHREZ
      , BNAME
      , TELF1
      , MAHZA
      , MAHDT
      , KUNNR
      , KOSTL
      , STAFO
      , STWAE
      , AEDAT
      , KVGR1
      , KVGR2
      , KVGR3
      , KVGR4
      , KVGR5
      , KNUMA
      , KOKRS
      , PS_PSP_PNR
      , KURST
      , KKBER
      , KNKLI
      , GRUPP
      , SBGRP
      , CTLPC
      , CMWAE
      , CMFRE
      , CMNUP
      , CMNGV
      , AMTBL
      , HITYP_PR
      , ABRVW
      , ABDIS
      , VGBEL
      , OBJNR
      , BUKRS_VF
      , TAXK1
      , TAXK2
      , TAXK3
      , TAXK4
      , TAXK5
      , TAXK6
      , TAXK7
      , TAXK8
      , TAXK9
      , XBLNR
      , ZUONR
      , VGTYP
      , KALSM_CH
      , AGRZR
      , AUFNR
      , QMNUM
      , VBELN_GRP
      , SCHEME_GRP
      , ABRUF_PART
      , ABHOD
      , ABHOV
      , ABHOB
      , RPLNR
      , VZEIT
      , STCEG_L
      , LANDTX
      , XEGDR
      , ENQUEUE_GRP
      , DAT_FZAU
      , FMBDAT
      , VSNMR_V
      , HANDLE
      , PROLI
      , CONT_DG
      , CRM_GUID
      , UPD_TMSTMP
      , MSR_ID
      , TM_CTRL_KEY
      , HANDOVERLOC
      , _DATAAGING
      , PSM_BUDAT
      , FSH_KVGR6
      , FSH_KVGR7
      , FSH_KVGR8
      , FSH_KVGR9
      , FSH_KVGR10
      , FSH_REREG
      , FSH_CQ_CHECK
      , FSH_VRSN_STATUS
      , FSH_TRANSACTION
      , FSH_VAS_CG
      , FSH_CANDATE
      , FSH_SS
      , FSH_OS_STG_CHANGE
      , SWENR
      , SMENR
      , PHASE
      , MTLAUR
      , STAGE
      , HB_CONT_REASON
      , HB_EXPDATE
      , HB_RESDATE
      , MILL_APPL_ID
      , TAS
      , BETC
      , MOD_ALLOW
      , CANCEL_ALLOW
      , PAY_METHOD
      , BPN
      , REP_FREQ
      , LOGSYSB
      , KALCD
      , MULTI
      , SPPAYM
      , WTYSC_CLM_HDR
      , ZZKNUMAK
      , BZIRK
      , ZZRSD
      , ZZRCG
      , ZZORC
      , ZZBUILDER
      , ZZAUFNR
      , ZZCUSTTL
      , ZZJOBTYPE
      , ZZJOBNAME
      , ZZJOBCITY
      , ZZJOBREGION
      , ZZJOBCOUNTRY
      , ZZJOBPOSTCODE
      , ZZJOBUNITS
      , ZZJOBBUILDER
      , ZZJOBPLUMBER
      , ZZQUOTETYPE
      , ZZDRAFT
      , ZZOUTCOME
      , ZZOUTCOMEDT
      , ZZESTSTARTDT
      , ZZREVNUM
      , ZZCRMACTIVITY
      , ZZVIP
      , ZZVPA
      , ZZVALVESPER
      , ZZPROGRAM
      , ZZNATIONAL
      , ZZBLDPROGAMT
      , ZZLEADREF
      , ZZLEADSOURCE
      , ZZPROMOCODE
      , ZZCRMNUM
      , ZZ3RDPARTAXMPT
      , ZZRDI
      , ZZTMS
      , ZZCONSOLIDATE
      , ZZAPNTMNT
      , ZZSTRSHPDTE
      , ZZENDSHPDTE
      , ZZTMSEXE
      , ZZERR
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
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
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        ORDER_HEADER_BK
      , MANDT
      , VBELN
      , GLREQUEST
      , ERDAT
      , ERZET
      , ERNAM
      , ANGDT
      , BNDDT
      , AUDAT
      , VBTYP
      , TRVOG
      , AUART
      , AUGRU
      , GWLDT
      , SUBMI
      , LIFSK
      , FAKSK
      , NETWR
      , WAERK
      , VKORG
      , VTWEG
      , SPART
      , VKGRP
      , VKBUR
      , GSBER
      , GSKST
      , GUEBG
      , GUEEN
      , KNUMV
      , VDATU
      , VPRGR
      , AUTLF
      , VBKLA
      , VBKLT
      , KALSM
      , VSBED
      , FKARA
      , AWAHR
      , KTEXT
      , BSTNK
      , BSARK
      , BSTDK
      , BSTZD
      , IHREZ
      , BNAME
      , TELF1
      , MAHZA
      , MAHDT
      , KUNNR
      , KOSTL
      , STAFO
      , STWAE
      , AEDAT
      , KVGR1
      , KVGR2
      , KVGR3
      , KVGR4
      , KVGR5
      , KNUMA
      , KOKRS
      , PS_PSP_PNR
      , KURST
      , KKBER
      , KNKLI
      , GRUPP
      , SBGRP
      , CTLPC
      , CMWAE
      , CMFRE
      , CMNUP
      , CMNGV
      , AMTBL
      , HITYP_PR
      , ABRVW
      , ABDIS
      , VGBEL
      , OBJNR
      , BUKRS_VF
      , TAXK1
      , TAXK2
      , TAXK3
      , TAXK4
      , TAXK5
      , TAXK6
      , TAXK7
      , TAXK8
      , TAXK9
      , XBLNR
      , ZUONR
      , VGTYP
      , KALSM_CH
      , AGRZR
      , AUFNR
      , QMNUM
      , VBELN_GRP
      , SCHEME_GRP
      , ABRUF_PART
      , ABHOD
      , ABHOV
      , ABHOB
      , RPLNR
      , VZEIT
      , STCEG_L
      , LANDTX
      , XEGDR
      , ENQUEUE_GRP
      , DAT_FZAU
      , FMBDAT
      , VSNMR_V
      , HANDLE
      , PROLI
      , CONT_DG
      , CRM_GUID
      , UPD_TMSTMP
      , MSR_ID
      , TM_CTRL_KEY
      , HANDOVERLOC
      , _DATAAGING
      , PSM_BUDAT
      , FSH_KVGR6
      , FSH_KVGR7
      , FSH_KVGR8
      , FSH_KVGR9
      , FSH_KVGR10
      , FSH_REREG
      , FSH_CQ_CHECK
      , FSH_VRSN_STATUS
      , FSH_TRANSACTION
      , FSH_VAS_CG
      , FSH_CANDATE
      , FSH_SS
      , FSH_OS_STG_CHANGE
      , SWENR
      , SMENR
      , PHASE
      , MTLAUR
      , STAGE
      , HB_CONT_REASON
      , HB_EXPDATE
      , HB_RESDATE
      , MILL_APPL_ID
      , TAS
      , BETC
      , MOD_ALLOW
      , CANCEL_ALLOW
      , PAY_METHOD
      , BPN
      , REP_FREQ
      , LOGSYSB
      , KALCD
      , MULTI
      , SPPAYM
      , WTYSC_CLM_HDR
      , ZZKNUMAK
      , BZIRK
      , ZZRSD
      , ZZRCG
      , ZZORC
      , ZZBUILDER
      , ZZAUFNR
      , ZZCUSTTL
      , ZZJOBTYPE
      , ZZJOBNAME
      , ZZJOBCITY
      , ZZJOBREGION
      , ZZJOBCOUNTRY
      , ZZJOBPOSTCODE
      , ZZJOBUNITS
      , ZZJOBBUILDER
      , ZZJOBPLUMBER
      , ZZQUOTETYPE
      , ZZDRAFT
      , ZZOUTCOME
      , ZZOUTCOMEDT
      , ZZESTSTARTDT
      , ZZREVNUM
      , ZZCRMACTIVITY
      , ZZVIP
      , ZZVPA
      , ZZVALVESPER
      , ZZPROGRAM
      , ZZNATIONAL
      , ZZBLDPROGAMT
      , ZZLEADREF
      , ZZLEADSOURCE
      , ZZPROMOCODE
      , ZZCRMNUM
      , ZZ3RDPARTAXMPT
      , ZZRDI
      , ZZTMS
      , ZZCONSOLIDATE
      , ZZAPNTMNT
      , ZZSTRSHPDTE
      , ZZENDSHPDTE
      , ZZTMSEXE
      , ZZERR
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , LOAD_DTS
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_VBAK'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ORDER_HEADER_BK
        , MANDT
        , VBELN
        , GLREQUEST
        , ERDAT
        , ERZET
        , ERNAM
        , ANGDT
        , BNDDT
        , AUDAT
        , VBTYP
        , TRVOG
        , AUART
        , AUGRU
        , GWLDT
        , SUBMI
        , LIFSK
        , FAKSK
        , NETWR
        , WAERK
        , VKORG
        , VTWEG
        , SPART
        , VKGRP
        , VKBUR
        , GSBER
        , GSKST
        , GUEBG
        , GUEEN
        , KNUMV
        , VDATU
        , VPRGR
        , AUTLF
        , VBKLA
        , VBKLT
        , KALSM
        , VSBED
        , FKARA
        , AWAHR
        , KTEXT
        , BSTNK
        , BSARK
        , BSTDK
        , BSTZD
        , IHREZ
        , BNAME
        , TELF1
        , MAHZA
        , MAHDT
        , KUNNR
        , KOSTL
        , STAFO
        , STWAE
        , AEDAT
        , KVGR1
        , KVGR2
        , KVGR3
        , KVGR4
        , KVGR5
        , KNUMA
        , KOKRS
        , PS_PSP_PNR
        , KURST
        , KKBER
        , KNKLI
        , GRUPP
        , SBGRP
        , CTLPC
        , CMWAE
        , CMFRE
        , CMNUP
        , CMNGV
        , AMTBL
        , HITYP_PR
        , ABRVW
        , ABDIS
        , VGBEL
        , OBJNR
        , BUKRS_VF
        , TAXK1
        , TAXK2
        , TAXK3
        , TAXK4
        , TAXK5
        , TAXK6
        , TAXK7
        , TAXK8
        , TAXK9
        , XBLNR
        , ZUONR
        , VGTYP
        , KALSM_CH
        , AGRZR
        , AUFNR
        , QMNUM
        , VBELN_GRP
        , SCHEME_GRP
        , ABRUF_PART
        , ABHOD
        , ABHOV
        , ABHOB
        , RPLNR
        , VZEIT
        , STCEG_L
        , LANDTX
        , XEGDR
        , ENQUEUE_GRP
        , DAT_FZAU
        , FMBDAT
        , VSNMR_V
        , HANDLE
        , PROLI
        , CONT_DG
        , CRM_GUID
        , UPD_TMSTMP
        , MSR_ID
        , TM_CTRL_KEY
        , HANDOVERLOC
        , _DATAAGING
        , PSM_BUDAT
        , FSH_KVGR6
        , FSH_KVGR7
        , FSH_KVGR8
        , FSH_KVGR9
        , FSH_KVGR10
        , FSH_REREG
        , FSH_CQ_CHECK
        , FSH_VRSN_STATUS
        , FSH_TRANSACTION
        , FSH_VAS_CG
        , FSH_CANDATE
        , FSH_SS
        , FSH_OS_STG_CHANGE
        , SWENR
        , SMENR
        , PHASE
        , MTLAUR
        , STAGE
        , HB_CONT_REASON
        , HB_EXPDATE
        , HB_RESDATE
        , MILL_APPL_ID
        , TAS
        , BETC
        , MOD_ALLOW
        , CANCEL_ALLOW
        , PAY_METHOD
        , BPN
        , REP_FREQ
        , LOGSYSB
        , KALCD
        , MULTI
        , SPPAYM
        , WTYSC_CLM_HDR
        , ZZKNUMAK
        , BZIRK
        , ZZRSD
        , ZZRCG
        , ZZORC
        , ZZBUILDER
        , ZZAUFNR
        , ZZCUSTTL
        , ZZJOBTYPE
        , ZZJOBNAME
        , ZZJOBCITY
        , ZZJOBREGION
        , ZZJOBCOUNTRY
        , ZZJOBPOSTCODE
        , ZZJOBUNITS
        , ZZJOBBUILDER
        , ZZJOBPLUMBER
        , ZZQUOTETYPE
        , ZZDRAFT
        , ZZOUTCOME
        , ZZOUTCOMEDT
        , ZZESTSTARTDT
        , ZZREVNUM
        , ZZCRMACTIVITY
        , ZZVIP
        , ZZVPA
        , ZZVALVESPER
        , ZZPROGRAM
        , ZZNATIONAL
        , ZZBLDPROGAMT
        , ZZLEADREF
        , ZZLEADSOURCE
        , ZZPROMOCODE
        , ZZCRMNUM
        , ZZ3RDPARTAXMPT
        , ZZRDI
        , ZZTMS
        , ZZCONSOLIDATE
        , ZZAPNTMNT
        , ZZSTRSHPDTE
        , ZZENDSHPDTE
        , ZZTMSEXE
        , ZZERR
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , PSA_DELETE_IND
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERZET::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ANGDT::text), '^^') 
            , '||', IFNULL(TRIM(BNDDT::text), '^^') 
            , '||', IFNULL(TRIM(AUDAT::text), '^^') 
            , '||', IFNULL(TRIM(VBTYP::text), '^^') 
            , '||', IFNULL(TRIM(TRVOG::text), '^^') 
            , '||', IFNULL(TRIM(AUART::text), '^^') 
            , '||', IFNULL(TRIM(AUGRU::text), '^^') 
            , '||', IFNULL(TRIM(GWLDT::text), '^^') 
            , '||', IFNULL(TRIM(SUBMI::text), '^^') 
            , '||', IFNULL(TRIM(LIFSK::text), '^^') 
            , '||', IFNULL(TRIM(FAKSK::text), '^^') 
            , '||', IFNULL(TRIM(NETWR::text), '^^') 
            , '||', IFNULL(TRIM(WAERK::text), '^^') 
            , '||', IFNULL(TRIM(VKORG::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(VKGRP::text), '^^') 
            , '||', IFNULL(TRIM(VKBUR::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(GSKST::text), '^^') 
            , '||', IFNULL(TRIM(GUEBG::text), '^^') 
            , '||', IFNULL(TRIM(GUEEN::text), '^^') 
            , '||', IFNULL(TRIM(KNUMV::text), '^^') 
            , '||', IFNULL(TRIM(VDATU::text), '^^') 
            , '||', IFNULL(TRIM(VPRGR::text), '^^') 
            , '||', IFNULL(TRIM(AUTLF::text), '^^') 
            , '||', IFNULL(TRIM(VBKLA::text), '^^') 
            , '||', IFNULL(TRIM(VBKLT::text), '^^') 
            , '||', IFNULL(TRIM(KALSM::text), '^^') 
            , '||', IFNULL(TRIM(VSBED::text), '^^') 
            , '||', IFNULL(TRIM(FKARA::text), '^^') 
            , '||', IFNULL(TRIM(AWAHR::text), '^^') 
            , '||', IFNULL(TRIM(KTEXT::text), '^^') 
            , '||', IFNULL(TRIM(BSTNK::text), '^^') 
            , '||', IFNULL(TRIM(BSARK::text), '^^') 
            , '||', IFNULL(TRIM(BSTDK::text), '^^') 
            , '||', IFNULL(TRIM(BSTZD::text), '^^') 
            , '||', IFNULL(TRIM(IHREZ::text), '^^') 
            , '||', IFNULL(TRIM(BNAME::text), '^^') 
            , '||', IFNULL(TRIM(TELF1::text), '^^') 
            , '||', IFNULL(TRIM(MAHZA::text), '^^') 
            , '||', IFNULL(TRIM(MAHDT::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(KOSTL::text), '^^') 
            , '||', IFNULL(TRIM(STAFO::text), '^^') 
            , '||', IFNULL(TRIM(STWAE::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(KVGR1::text), '^^') 
            , '||', IFNULL(TRIM(KVGR2::text), '^^') 
            , '||', IFNULL(TRIM(KVGR3::text), '^^') 
            , '||', IFNULL(TRIM(KVGR4::text), '^^') 
            , '||', IFNULL(TRIM(KVGR5::text), '^^') 
            , '||', IFNULL(TRIM(KNUMA::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(PS_PSP_PNR::text), '^^') 
            , '||', IFNULL(TRIM(KURST::text), '^^') 
            , '||', IFNULL(TRIM(KKBER::text), '^^') 
            , '||', IFNULL(TRIM(KNKLI::text), '^^') 
            , '||', IFNULL(TRIM(GRUPP::text), '^^') 
            , '||', IFNULL(TRIM(SBGRP::text), '^^') 
            , '||', IFNULL(TRIM(CTLPC::text), '^^') 
            , '||', IFNULL(TRIM(CMWAE::text), '^^') 
            , '||', IFNULL(TRIM(CMFRE::text), '^^') 
            , '||', IFNULL(TRIM(CMNUP::text), '^^') 
            , '||', IFNULL(TRIM(CMNGV::text), '^^') 
            , '||', IFNULL(TRIM(AMTBL::text), '^^') 
            , '||', IFNULL(TRIM(HITYP_PR::text), '^^') 
            , '||', IFNULL(TRIM(ABRVW::text), '^^') 
            , '||', IFNULL(TRIM(ABDIS::text), '^^') 
            , '||', IFNULL(TRIM(VGBEL::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS_VF::text), '^^') 
            , '||', IFNULL(TRIM(TAXK1::text), '^^') 
            , '||', IFNULL(TRIM(TAXK2::text), '^^') 
            , '||', IFNULL(TRIM(TAXK3::text), '^^') 
            , '||', IFNULL(TRIM(TAXK4::text), '^^') 
            , '||', IFNULL(TRIM(TAXK5::text), '^^') 
            , '||', IFNULL(TRIM(TAXK6::text), '^^') 
            , '||', IFNULL(TRIM(TAXK7::text), '^^') 
            , '||', IFNULL(TRIM(TAXK8::text), '^^') 
            , '||', IFNULL(TRIM(TAXK9::text), '^^') 
            , '||', IFNULL(TRIM(XBLNR::text), '^^') 
            , '||', IFNULL(TRIM(ZUONR::text), '^^') 
            , '||', IFNULL(TRIM(VGTYP::text), '^^') 
            , '||', IFNULL(TRIM(KALSM_CH::text), '^^') 
            , '||', IFNULL(TRIM(AGRZR::text), '^^') 
            , '||', IFNULL(TRIM(AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(QMNUM::text), '^^') 
            , '||', IFNULL(TRIM(VBELN_GRP::text), '^^') 
            , '||', IFNULL(TRIM(SCHEME_GRP::text), '^^') 
            , '||', IFNULL(TRIM(ABRUF_PART::text), '^^') 
            , '||', IFNULL(TRIM(ABHOD::text), '^^') 
            , '||', IFNULL(TRIM(ABHOV::text), '^^') 
            , '||', IFNULL(TRIM(ABHOB::text), '^^') 
            , '||', IFNULL(TRIM(RPLNR::text), '^^') 
            , '||', IFNULL(TRIM(VZEIT::text), '^^') 
            , '||', IFNULL(TRIM(STCEG_L::text), '^^') 
            , '||', IFNULL(TRIM(LANDTX::text), '^^') 
            , '||', IFNULL(TRIM(XEGDR::text), '^^') 
            , '||', IFNULL(TRIM(ENQUEUE_GRP::text), '^^') 
            , '||', IFNULL(TRIM(DAT_FZAU::text), '^^') 
            , '||', IFNULL(TRIM(FMBDAT::text), '^^') 
            , '||', IFNULL(TRIM(VSNMR_V::text), '^^') 
            , '||', IFNULL(TRIM(HANDLE::text), '^^') 
            , '||', IFNULL(TRIM(PROLI::text), '^^') 
            , '||', IFNULL(TRIM(CONT_DG::text), '^^') 
            , '||', IFNULL(TRIM(CRM_GUID::text), '^^') 
            , '||', IFNULL(TRIM(UPD_TMSTMP::text), '^^') 
            , '||', IFNULL(TRIM(MSR_ID::text), '^^') 
            , '||', IFNULL(TRIM(TM_CTRL_KEY::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVERLOC::text), '^^') 
            , '||', IFNULL(TRIM(_DATAAGING::text), '^^') 
            , '||', IFNULL(TRIM(PSM_BUDAT::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR6::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR7::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR8::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR9::text), '^^') 
            , '||', IFNULL(TRIM(FSH_KVGR10::text), '^^') 
            , '||', IFNULL(TRIM(FSH_REREG::text), '^^') 
            , '||', IFNULL(TRIM(FSH_CQ_CHECK::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VRSN_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(FSH_TRANSACTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VAS_CG::text), '^^') 
            , '||', IFNULL(TRIM(FSH_CANDATE::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SS::text), '^^') 
            , '||', IFNULL(TRIM(FSH_OS_STG_CHANGE::text), '^^') 
            , '||', IFNULL(TRIM(SWENR::text), '^^') 
            , '||', IFNULL(TRIM(SMENR::text), '^^') 
            , '||', IFNULL(TRIM(PHASE::text), '^^') 
            , '||', IFNULL(TRIM(MTLAUR::text), '^^') 
            , '||', IFNULL(TRIM(STAGE::text), '^^') 
            , '||', IFNULL(TRIM(HB_CONT_REASON::text), '^^') 
            , '||', IFNULL(TRIM(HB_EXPDATE::text), '^^') 
            , '||', IFNULL(TRIM(HB_RESDATE::text), '^^') 
            , '||', IFNULL(TRIM(MILL_APPL_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAS::text), '^^') 
            , '||', IFNULL(TRIM(BETC::text), '^^') 
            , '||', IFNULL(TRIM(MOD_ALLOW::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_ALLOW::text), '^^') 
            , '||', IFNULL(TRIM(PAY_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(BPN::text), '^^') 
            , '||', IFNULL(TRIM(REP_FREQ::text), '^^') 
            , '||', IFNULL(TRIM(LOGSYSB::text), '^^') 
            , '||', IFNULL(TRIM(KALCD::text), '^^') 
            , '||', IFNULL(TRIM(MULTI::text), '^^') 
            , '||', IFNULL(TRIM(SPPAYM::text), '^^') 
            , '||', IFNULL(TRIM(WTYSC_CLM_HDR::text), '^^') 
            , '||', IFNULL(TRIM(ZZKNUMAK::text), '^^') 
            , '||', IFNULL(TRIM(BZIRK::text), '^^') 
            , '||', IFNULL(TRIM(ZZRSD::text), '^^') 
            , '||', IFNULL(TRIM(ZZRCG::text), '^^') 
            , '||', IFNULL(TRIM(ZZORC::text), '^^') 
            , '||', IFNULL(TRIM(ZZBUILDER::text), '^^') 
            , '||', IFNULL(TRIM(ZZAUFNR::text), '^^') 
            , '||', IFNULL(TRIM(ZZCUSTTL::text), '^^') 
            , '||', IFNULL(TRIM(ZZJOBTYPE::text), '^^') 
            , '||', IFNULL(TRIM(ZZJOBNAME::text), '^^') 
            , '||', IFNULL(TRIM(ZZJOBCITY::text), '^^') 
            , '||', IFNULL(TRIM(ZZJOBREGION::text), '^^') 
            , '||', IFNULL(TRIM(ZZJOBCOUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(ZZJOBPOSTCODE::text), '^^') 
            , '||', IFNULL(TRIM(ZZJOBUNITS::text), '^^') 
            , '||', IFNULL(TRIM(ZZJOBBUILDER::text), '^^') 
            , '||', IFNULL(TRIM(ZZJOBPLUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ZZQUOTETYPE::text), '^^') 
            , '||', IFNULL(TRIM(ZZDRAFT::text), '^^') 
            , '||', IFNULL(TRIM(ZZOUTCOME::text), '^^') 
            , '||', IFNULL(TRIM(ZZOUTCOMEDT::text), '^^') 
            , '||', IFNULL(TRIM(ZZESTSTARTDT::text), '^^') 
            , '||', IFNULL(TRIM(ZZREVNUM::text), '^^') 
            , '||', IFNULL(TRIM(ZZCRMACTIVITY::text), '^^') 
            , '||', IFNULL(TRIM(ZZVIP::text), '^^') 
            , '||', IFNULL(TRIM(ZZVPA::text), '^^') 
            , '||', IFNULL(TRIM(ZZVALVESPER::text), '^^') 
            , '||', IFNULL(TRIM(ZZPROGRAM::text), '^^') 
            , '||', IFNULL(TRIM(ZZNATIONAL::text), '^^') 
            , '||', IFNULL(TRIM(ZZBLDPROGAMT::text), '^^') 
            , '||', IFNULL(TRIM(ZZLEADREF::text), '^^') 
            , '||', IFNULL(TRIM(ZZLEADSOURCE::text), '^^') 
            , '||', IFNULL(TRIM(ZZPROMOCODE::text), '^^') 
            , '||', IFNULL(TRIM(ZZCRMNUM::text), '^^') 
            , '||', IFNULL(TRIM(ZZ3RDPARTAXMPT::text), '^^') 
            , '||', IFNULL(TRIM(ZZRDI::text), '^^') 
            , '||', IFNULL(TRIM(ZZTMS::text), '^^') 
            , '||', IFNULL(TRIM(ZZCONSOLIDATE::text), '^^') 
            , '||', IFNULL(TRIM(ZZAPNTMNT::text), '^^') 
            , '||', IFNULL(TRIM(ZZSTRSHPDTE::text), '^^') 
            , '||', IFNULL(TRIM(ZZENDSHPDTE::text), '^^') 
            , '||', IFNULL(TRIM(ZZTMSEXE::text), '^^') 
            , '||', IFNULL(TRIM(ZZERR::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

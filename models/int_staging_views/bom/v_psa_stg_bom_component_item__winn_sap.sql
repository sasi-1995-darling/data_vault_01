---- SRC LAYER ----
WITH
SRC_stp            as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_stpo') }} as SRC  ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_stas           as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_stas') }} as SRC 
                        qualify 1= row_number()over(partition by STLNR, STLKN, STLTY order by psa_load_dts desc)  ),
SRC_stko           as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_stko') }} as SRC 
                        qualify 1= row_number()over(partition by STLNR, STLTY, STLAL order by psa_load_dts desc)  ),
SRC_mast           as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_mast') }} as SRC 
                        qualify 1= row_number()over(partition by STLNR, STLAL order by psa_load_dts desc)  )

/*
SRC_stp            as ( SELECT * FROM sap_ecc_prd.z_stpo )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_stas           as ( SELECT * FROM sap_ecc_prd.z_stas )
, SRC_stko           as ( SELECT * FROM sap_ecc_prd.z_stko )
, SRC_mast           as ( SELECT * FROM sap_ecc_prd.z_mast )
*/
---- LOGIC LAYER ----

, LOGIC_stp as (
    SELECT
        STLNR                                                        as                                             BOM_BK
      , COALESCE(NULLIF(TRIM(IDNRK),''),'-1')                        as                                            ITEM_BK
      , MANDT
      , STLTY
      , STLNR
      , STLKN
      , STPOZ
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LKENZ
      , VGKNT
      , VGPZL
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , IDNRK
      , PSWRK
      , POSTP
      , POSNR
      , SORTF
      , MEINS
      , MENGE
      , FMENG
      , AUSCH
      , AVOAU
      , NETAU
      , SCHGT
      , BEIKZ
      , ERSKZ
      , RVREL
      , SANFE
      , SANIN
      , SANKA
      , SANKO
      , SANVS
      , STKKZ
      , REKRI
      , REKRS
      , CADPO
      , NFMAT
      , NLFZT
      , VERTI
      , ALPOS
      , EWAHR
      , EKGRP
      , LIFZT
      , LIFNR
      , PREIS
      , PEINH
      , WAERS
      , SAKTO
      , ROANZ
      , ROMS1
      , ROMS2
      , ROMS3
      , ROMEI
      , ROMEN
      , RFORM
      , UPSKZ
      , VALKZ
      , LTXSP
      , POTX1
      , POTX2
      , OBJTY
      , MATKL
      , WEBAZ
      , DOKAR
      , DOKNR
      , DOKVR
      , DOKTL
      , CSSTR
      , CLASS
      , KLART
      , POTPR
      , AWAKZ
      , INSKZ
      , VCEKZ
      , VSTKZ
      , VACKZ
      , EKORG
      , CLOBK
      , CLMUL
      , CLALT
      , CVIEW
      , KNOBJ
      , LGORT
      , KZKUP
      , INTRM
      , TPEKZ
      , STVKN
      , DVDAT
      , DVNAM
      , DSPST
      , ALPST
      , ALPRF
      , ALPGR
      , KZNFP
      , NFGRP
      , NFEAG
      , KNDVB
      , KNDBZ
      , KSTTY
      , KSTNR
      , KSTKN
      , KSTPZ
      , CLSZU
      , KZCLB
      , AEHLP
      , PRVBE
      , NLFZV
      , NLFMV
      , IDPOS
      , IDHIS
      , IDVAR
      , ALEKZ
      , ITMID
      , GUID
      , ITSOB
      , RFPNT
      , GUIDX
      , SGT_CMKZ
      , SGT_CATV
      , VALID_TO
      , VALID_TO_RKEY
      , ECN_TO
      , ECN_TO_RKEY
      , CUFACTOR
      , FSH_VMKZ
      , FSH_PGQR
      , FSH_PGQRRF
      , FSH_CRITICAL_COMP
      , FSH_CRITICAL_LEVEL
      , FUNCID
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
    FROM SRC_stp
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)

, LOGIC_stas as (
    SELECT
        STLNR                                                        as                                         stas_STLNR
      , STLKN                                                        as                                         stas_STLKN
      , STLTY                                                        as                                         stas_STLTY
      , STLAL                                                        as                                         stas_STLAL
    FROM SRC_stas
)

, LOGIC_stko as (
    SELECT
        STLNR                                                        as                                         stko_STLNR
      , STLAL                                                        as                                         stko_STLAL
      , STLTY                                                        as                                         stko_STLTY
    FROM SRC_stko
)

, LOGIC_mast as (
    SELECT
        STLNR                                                        as                                         mast_STLNR
      , STLAL                                                        as                                         mast_STLAL
      , STLAN                                                        as                                         mast_STLAN
    FROM SRC_mast
)
---- RENAME LAYER ----

, RENAME_stp as (
    SELECT
        BOM_BK
      , ITEM_BK
      , MANDT
      , STLTY
      , STLNR
      , STLKN
      , STPOZ
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LKENZ
      , VGKNT
      , VGPZL
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , IDNRK
      , PSWRK
      , POSTP
      , POSNR
      , SORTF
      , MEINS
      , MENGE
      , FMENG
      , AUSCH
      , AVOAU
      , NETAU
      , SCHGT
      , BEIKZ
      , ERSKZ
      , RVREL
      , SANFE
      , SANIN
      , SANKA
      , SANKO
      , SANVS
      , STKKZ
      , REKRI
      , REKRS
      , CADPO
      , NFMAT
      , NLFZT
      , VERTI
      , ALPOS
      , EWAHR
      , EKGRP
      , LIFZT
      , LIFNR
      , PREIS
      , PEINH
      , WAERS
      , SAKTO
      , ROANZ
      , ROMS1
      , ROMS2
      , ROMS3
      , ROMEI
      , ROMEN
      , RFORM
      , UPSKZ
      , VALKZ
      , LTXSP
      , POTX1
      , POTX2
      , OBJTY
      , MATKL
      , WEBAZ
      , DOKAR
      , DOKNR
      , DOKVR
      , DOKTL
      , CSSTR
      , CLASS
      , KLART
      , POTPR
      , AWAKZ
      , INSKZ
      , VCEKZ
      , VSTKZ
      , VACKZ
      , EKORG
      , CLOBK
      , CLMUL
      , CLALT
      , CVIEW
      , KNOBJ
      , LGORT
      , KZKUP
      , INTRM
      , TPEKZ
      , STVKN
      , DVDAT
      , DVNAM
      , DSPST
      , ALPST
      , ALPRF
      , ALPGR
      , KZNFP
      , NFGRP
      , NFEAG
      , KNDVB
      , KNDBZ
      , KSTTY
      , KSTNR
      , KSTKN
      , KSTPZ
      , CLSZU
      , KZCLB
      , AEHLP
      , PRVBE
      , NLFZV
      , NLFMV
      , IDPOS
      , IDHIS
      , IDVAR
      , ALEKZ
      , ITMID
      , GUID
      , ITSOB
      , RFPNT
      , GUIDX
      , SGT_CMKZ
      , SGT_CATV
      , VALID_TO
      , VALID_TO_RKEY
      , ECN_TO
      , ECN_TO_RKEY
      , CUFACTOR
      , FSH_VMKZ
      , FSH_PGQR
      , FSH_PGQRRF
      , FSH_CRITICAL_COMP
      , FSH_CRITICAL_LEVEL
      , FUNCID
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_stp
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)

, RENAME_stas as (
    SELECT
        stas_STLNR
      , stas_STLKN
      , stas_STLTY
      , stas_STLAL
    FROM LOGIC_stas
)

, RENAME_stko as (
    SELECT
        stko_STLNR
      , stko_STLAL
      , stko_STLTY
    FROM LOGIC_stko
)

, RENAME_mast as (
    SELECT
        mast_STLNR
      , mast_STLAL
      , mast_STLAN
    FROM LOGIC_mast
)
---- FILTER LAYER ----

, FILTER_stp as (
    SELECT *
    FROM RENAME_stp
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_STPO'
)

, FILTER_stas as (
    SELECT *
    FROM RENAME_stas
)

, FILTER_stko as (
    SELECT *
    FROM RENAME_stko
)

, FILTER_mast as (
    SELECT *
    FROM RENAME_mast
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_stp
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
    LEFT JOIN FILTER_stas
        ON FILTER_stp.STLNR = stas_STLNR AND STLKN = stas_STLKN AND STLTY = stas_STLTY
    LEFT JOIN FILTER_stko
        ON FILTER_stas.stas_STLNR = stko_STLNR  AND stas_STLAL = stko_STLAL  AND stas_STLTY = stko_STLTY
    LEFT JOIN FILTER_mast
        ON FILTER_stko.stko_STLNR = mast_STLNR  AND stko_STLAL = mast_STLAL
)

---- FINAL LAYER ----
SELECT
          BOM_BK
        , ITEM_BK
        , CASE WHEN nvl(mast_STLAN, '') = '1'  AND STLTY = 'M' AND  nvl(IDNRK,'') = ''  THEN '-2' 	
 WHEN nvl(mast_STLAN, '')  = '1' AND STLTY <> 'M' AND nvl(IDNRK,'') = ''  THEN '-1'
 WHEN nvl(mast_STLAN, '') <> '1' AND STLTY <> 'M' AND nvl(IDNRK,'') = ''  THEN '-1'
 WHEN nvl(mast_STLAN, '') = '2' AND STLTY = 'M' AND nvl(IDNRK,'') = ''  THEN '-1'
ELSE IDNRK     
END  as DRVD_IDNRK
        , MANDT
        , STLTY
        , STLNR
        , STLKN
        , STPOZ
        , GLREQUEST
        , DATUV
        , TECHV
        , AENNR
        , LKENZ
        , VGKNT
        , VGPZL
        , ANDAT
        , ANNAM
        , AEDAT
        , AENAM
        , IDNRK
        , PSWRK
        , POSTP
        , POSNR
        , SORTF
        , MEINS
        , MENGE
        , FMENG
        , AUSCH
        , AVOAU
        , NETAU
        , SCHGT
        , BEIKZ
        , ERSKZ
        , RVREL
        , SANFE
        , SANIN
        , SANKA
        , SANKO
        , SANVS
        , STKKZ
        , REKRI
        , REKRS
        , CADPO
        , NFMAT
        , NLFZT
        , VERTI
        , ALPOS
        , EWAHR
        , EKGRP
        , LIFZT
        , LIFNR
        , PREIS
        , PEINH
        , WAERS
        , SAKTO
        , ROANZ
        , ROMS1
        , ROMS2
        , ROMS3
        , ROMEI
        , ROMEN
        , RFORM
        , UPSKZ
        , VALKZ
        , LTXSP
        , POTX1
        , POTX2
        , OBJTY
        , MATKL
        , WEBAZ
        , DOKAR
        , DOKNR
        , DOKVR
        , DOKTL
        , CSSTR
        , CLASS
        , KLART
        , POTPR
        , AWAKZ
        , INSKZ
        , VCEKZ
        , VSTKZ
        , VACKZ
        , EKORG
        , CLOBK
        , CLMUL
        , CLALT
        , CVIEW
        , KNOBJ
        , LGORT
        , KZKUP
        , INTRM
        , TPEKZ
        , STVKN
        , DVDAT
        , DVNAM
        , DSPST
        , ALPST
        , ALPRF
        , ALPGR
        , KZNFP
        , NFGRP
        , NFEAG
        , KNDVB
        , KNDBZ
        , KSTTY
        , KSTNR
        , KSTKN
        , KSTPZ
        , CLSZU
        , KZCLB
        , AEHLP
        , PRVBE
        , NLFZV
        , NLFMV
        , IDPOS
        , IDHIS
        , IDVAR
        , ALEKZ
        , ITMID
        , GUID
        , ITSOB
        , RFPNT
        , GUIDX
        , SGT_CMKZ
        , SGT_CATV
        , VALID_TO
        , VALID_TO_RKEY
        , ECN_TO
        , ECN_TO_RKEY
        , CUFACTOR
        , FSH_VMKZ
        , FSH_PGQR
        , FSH_PGQRRF
        , FSH_CRITICAL_COMP
        , FSH_CRITICAL_LEVEL
        , FUNCID
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
          COALESCE(NULLIF(TRIM(CAST(STLNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(IDNRK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_BOM_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(STLNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as BOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_IDNRK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(STLTY::text), '^^') 
            , '||', IFNULL(TRIM(STLKN::text), '^^') 
            , '||', IFNULL(TRIM(STPOZ::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(DATUV::text), '^^') 
            , '||', IFNULL(TRIM(TECHV::text), '^^') 
            , '||', IFNULL(TRIM(AENNR::text), '^^') 
            , '||', IFNULL(TRIM(LKENZ::text), '^^') 
            , '||', IFNULL(TRIM(VGKNT::text), '^^') 
            , '||', IFNULL(TRIM(VGPZL::text), '^^') 
            , '||', IFNULL(TRIM(ANDAT::text), '^^') 
            , '||', IFNULL(TRIM(ANNAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(PSWRK::text), '^^') 
            , '||', IFNULL(TRIM(POSTP::text), '^^') 
            , '||', IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(SORTF::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(MENGE::text), '^^') 
            , '||', IFNULL(TRIM(FMENG::text), '^^') 
            , '||', IFNULL(TRIM(AUSCH::text), '^^') 
            , '||', IFNULL(TRIM(AVOAU::text), '^^') 
            , '||', IFNULL(TRIM(NETAU::text), '^^') 
            , '||', IFNULL(TRIM(SCHGT::text), '^^') 
            , '||', IFNULL(TRIM(BEIKZ::text), '^^') 
            , '||', IFNULL(TRIM(ERSKZ::text), '^^') 
            , '||', IFNULL(TRIM(RVREL::text), '^^') 
            , '||', IFNULL(TRIM(SANFE::text), '^^') 
            , '||', IFNULL(TRIM(SANIN::text), '^^') 
            , '||', IFNULL(TRIM(SANKA::text), '^^') 
            , '||', IFNULL(TRIM(SANKO::text), '^^') 
            , '||', IFNULL(TRIM(SANVS::text), '^^') 
            , '||', IFNULL(TRIM(STKKZ::text), '^^') 
            , '||', IFNULL(TRIM(REKRI::text), '^^') 
            , '||', IFNULL(TRIM(REKRS::text), '^^') 
            , '||', IFNULL(TRIM(CADPO::text), '^^') 
            , '||', IFNULL(TRIM(NFMAT::text), '^^') 
            , '||', IFNULL(TRIM(NLFZT::text), '^^') 
            , '||', IFNULL(TRIM(VERTI::text), '^^') 
            , '||', IFNULL(TRIM(ALPOS::text), '^^') 
            , '||', IFNULL(TRIM(EWAHR::text), '^^') 
            , '||', IFNULL(TRIM(EKGRP::text), '^^') 
            , '||', IFNULL(TRIM(LIFZT::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(PREIS::text), '^^') 
            , '||', IFNULL(TRIM(PEINH::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(SAKTO::text), '^^') 
            , '||', IFNULL(TRIM(ROANZ::text), '^^') 
            , '||', IFNULL(TRIM(ROMS1::text), '^^') 
            , '||', IFNULL(TRIM(ROMS2::text), '^^') 
            , '||', IFNULL(TRIM(ROMS3::text), '^^') 
            , '||', IFNULL(TRIM(ROMEI::text), '^^') 
            , '||', IFNULL(TRIM(ROMEN::text), '^^') 
            , '||', IFNULL(TRIM(RFORM::text), '^^') 
            , '||', IFNULL(TRIM(UPSKZ::text), '^^') 
            , '||', IFNULL(TRIM(VALKZ::text), '^^') 
            , '||', IFNULL(TRIM(LTXSP::text), '^^') 
            , '||', IFNULL(TRIM(POTX1::text), '^^') 
            , '||', IFNULL(TRIM(POTX2::text), '^^') 
            , '||', IFNULL(TRIM(OBJTY::text), '^^') 
            , '||', IFNULL(TRIM(MATKL::text), '^^') 
            , '||', IFNULL(TRIM(WEBAZ::text), '^^') 
            , '||', IFNULL(TRIM(DOKAR::text), '^^') 
            , '||', IFNULL(TRIM(DOKNR::text), '^^') 
            , '||', IFNULL(TRIM(DOKVR::text), '^^') 
            , '||', IFNULL(TRIM(DOKTL::text), '^^') 
            , '||', IFNULL(TRIM(CSSTR::text), '^^') 
            , '||', IFNULL(TRIM(CLASS::text), '^^') 
            , '||', IFNULL(TRIM(KLART::text), '^^') 
            , '||', IFNULL(TRIM(POTPR::text), '^^') 
            , '||', IFNULL(TRIM(AWAKZ::text), '^^') 
            , '||', IFNULL(TRIM(INSKZ::text), '^^') 
            , '||', IFNULL(TRIM(VCEKZ::text), '^^') 
            , '||', IFNULL(TRIM(VSTKZ::text), '^^') 
            , '||', IFNULL(TRIM(VACKZ::text), '^^') 
            , '||', IFNULL(TRIM(EKORG::text), '^^') 
            , '||', IFNULL(TRIM(CLOBK::text), '^^') 
            , '||', IFNULL(TRIM(CLMUL::text), '^^') 
            , '||', IFNULL(TRIM(CLALT::text), '^^') 
            , '||', IFNULL(TRIM(CVIEW::text), '^^') 
            , '||', IFNULL(TRIM(KNOBJ::text), '^^') 
            , '||', IFNULL(TRIM(LGORT::text), '^^') 
            , '||', IFNULL(TRIM(KZKUP::text), '^^') 
            , '||', IFNULL(TRIM(INTRM::text), '^^') 
            , '||', IFNULL(TRIM(TPEKZ::text), '^^') 
            , '||', IFNULL(TRIM(STVKN::text), '^^') 
            , '||', IFNULL(TRIM(DVDAT::text), '^^') 
            , '||', IFNULL(TRIM(DVNAM::text), '^^') 
            , '||', IFNULL(TRIM(DSPST::text), '^^') 
            , '||', IFNULL(TRIM(ALPST::text), '^^') 
            , '||', IFNULL(TRIM(ALPRF::text), '^^') 
            , '||', IFNULL(TRIM(ALPGR::text), '^^') 
            , '||', IFNULL(TRIM(KZNFP::text), '^^') 
            , '||', IFNULL(TRIM(NFGRP::text), '^^') 
            , '||', IFNULL(TRIM(NFEAG::text), '^^') 
            , '||', IFNULL(TRIM(KNDVB::text), '^^') 
            , '||', IFNULL(TRIM(KNDBZ::text), '^^') 
            , '||', IFNULL(TRIM(KSTTY::text), '^^') 
            , '||', IFNULL(TRIM(KSTNR::text), '^^') 
            , '||', IFNULL(TRIM(KSTKN::text), '^^') 
            , '||', IFNULL(TRIM(KSTPZ::text), '^^') 
            , '||', IFNULL(TRIM(CLSZU::text), '^^') 
            , '||', IFNULL(TRIM(KZCLB::text), '^^') 
            , '||', IFNULL(TRIM(AEHLP::text), '^^') 
            , '||', IFNULL(TRIM(PRVBE::text), '^^') 
            , '||', IFNULL(TRIM(NLFZV::text), '^^') 
            , '||', IFNULL(TRIM(NLFMV::text), '^^') 
            , '||', IFNULL(TRIM(IDPOS::text), '^^') 
            , '||', IFNULL(TRIM(IDHIS::text), '^^') 
            , '||', IFNULL(TRIM(IDVAR::text), '^^') 
            , '||', IFNULL(TRIM(ALEKZ::text), '^^') 
            , '||', IFNULL(TRIM(ITMID::text), '^^') 
            , '||', IFNULL(TRIM(GUID::text), '^^') 
            , '||', IFNULL(TRIM(ITSOB::text), '^^') 
            , '||', IFNULL(TRIM(RFPNT::text), '^^') 
            , '||', IFNULL(TRIM(GUIDX::text), '^^') 
            , '||', IFNULL(TRIM(SGT_CMKZ::text), '^^') 
            , '||', IFNULL(TRIM(SGT_CATV::text), '^^') 
            , '||', IFNULL(TRIM(VALID_TO::text), '^^') 
            , '||', IFNULL(TRIM(VALID_TO_RKEY::text), '^^') 
            , '||', IFNULL(TRIM(ECN_TO::text), '^^') 
            , '||', IFNULL(TRIM(ECN_TO_RKEY::text), '^^') 
            , '||', IFNULL(TRIM(CUFACTOR::text), '^^') 
            , '||', IFNULL(TRIM(FSH_VMKZ::text), '^^') 
            , '||', IFNULL(TRIM(FSH_PGQR::text), '^^') 
            , '||', IFNULL(TRIM(FSH_PGQRRF::text), '^^') 
            , '||', IFNULL(TRIM(FSH_CRITICAL_COMP::text), '^^') 
            , '||', IFNULL(TRIM(FSH_CRITICAL_LEVEL::text), '^^') 
            , '||', IFNULL(TRIM(FUNCID::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

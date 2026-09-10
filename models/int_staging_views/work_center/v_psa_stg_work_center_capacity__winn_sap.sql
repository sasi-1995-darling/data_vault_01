---- SRC LAYER ----
WITH
SRC_a              as ( SELECT WERKS, ARBPL, ZEIWN, STAND, MANDT, OBJTY, OBJID, GLREQUEST, BEGDA, ENDDA, AEDAT_GRND, AENAM_GRND, AEDAT_VORA, AENAM_VORA, AEDAT_TERM, AENAM_TERM, AEDAT_TECH, AENAM_TECH, VERWE, LVORM, PAR01, PAR02, PAR03, PAR04, PAR05, PAR06, PARU1, PARU2, PARU3, PARU4, PARU5, PARU6, PARV1, PARV2, PARV3, PARV4, PARV5, PARV6, PLANV, VERAN, VGWTS, VGM01, VGM02, VGM03, VGM04, VGM05, VGM06, XDEFA, XKOST, XSPRR, XTERM, ZGR01, ZGR02, ZGR03, ZGR04, ZGR05, ZGR06, KTSCH, LOANZ, LOART, LOGRP, QUALF, RASCH, STEUS, VGE01, VGE02, VGE03, VGE04, VGE05, VGE06, KTSCH_REF, LOART_REF, LOANZ_REF, LOGRP_REF, QUALF_REF, RASCH_REF, STEUS_REF, FORT1, FORT2, FORT3, KAPID, ORTGR, ZWNOR, ZEIWM, ZWMIN, FORMR, MATYP, CPLGR, SORTB, MTRVP, MTMVP, MTPVP, RSANZ, PDEST, HROID, FORTN, ZGR01_REF, ZGR02_REF, ZGR03_REF, ZGR04_REF, ZGR05_REF, ZGR06_REF, STEUS_C, STEUS_I, STEUS_N, STEUS_Q, RUZUS, RSANZ_REF, HR, PRVBE, SUBSYS, BDEGR, RGEKZ, HRTYP, SLWID, LIFNR, SLWID_REF, LIFNR_REF, VGARB, VGDIM, HRPLVAR, VGDAU, STOBJ, RESGR, LGORT_RES, MIXMAT, ISTBED_KZ, PPSKZ, SRTYPE, SNTYPE, GLDELFLAG, GLSOURCESYSTEM, GLCHANGETIME, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND FROM {{ source('sap_ecc_prd', 'z_crhd') }} as SRC  ),
SRC_bkcc           as ( SELECT REC_SRC, BKCC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_crhd )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        coalesce(nullif(trim(WERKS), ''), '-1')                                         as                                           PLANT_BK
      , coalesce(nullif(trim(ARBPL), ''), '-1')                                         as                                     WORK_CENTER_BK
      , coalesce(nullif(trim(ZEIWN), ''), '-1')                                         as                                             UOM_BK
      , coalesce(nullif(trim(STAND), ''), '-1')                                         as                            WORK_CENTER_LOCATION_BK
      , MANDT
      , OBJTY
      , OBJID
      , GLREQUEST
      , BEGDA
      , ENDDA
      , AEDAT_GRND
      , AENAM_GRND
      , AEDAT_VORA
      , AENAM_VORA
      , AEDAT_TERM
      , AENAM_TERM
      , AEDAT_TECH
      , AENAM_TECH
      , ARBPL
      , WERKS
      , VERWE
      , LVORM
      , PAR01
      , PAR02
      , PAR03
      , PAR04
      , PAR05
      , PAR06
      , PARU1
      , PARU2
      , PARU3
      , PARU4
      , PARU5
      , PARU6
      , PARV1
      , PARV2
      , PARV3
      , PARV4
      , PARV5
      , PARV6
      , PLANV
      , STAND
      , VERAN
      , VGWTS
      , VGM01
      , VGM02
      , VGM03
      , VGM04
      , VGM05
      , VGM06
      , XDEFA
      , XKOST
      , XSPRR
      , XTERM
      , ZGR01
      , ZGR02
      , ZGR03
      , ZGR04
      , ZGR05
      , ZGR06
      , KTSCH
      , LOANZ
      , LOART
      , LOGRP
      , QUALF
      , RASCH
      , STEUS
      , VGE01
      , VGE02
      , VGE03
      , VGE04
      , VGE05
      , VGE06
      , KTSCH_REF
      , LOART_REF
      , LOANZ_REF
      , LOGRP_REF
      , QUALF_REF
      , RASCH_REF
      , STEUS_REF
      , FORT1
      , FORT2
      , FORT3
      , KAPID
      , ORTGR
      , ZEIWN
      , ZWNOR
      , ZEIWM
      , ZWMIN
      , FORMR
      , MATYP
      , CPLGR
      , SORTB
      , MTRVP
      , MTMVP
      , MTPVP
      , RSANZ
      , PDEST
      , HROID
      , FORTN
      , ZGR01_REF
      , ZGR02_REF
      , ZGR03_REF
      , ZGR04_REF
      , ZGR05_REF
      , ZGR06_REF
      , STEUS_C
      , STEUS_I
      , STEUS_N
      , STEUS_Q
      , RUZUS
      , RSANZ_REF
      , HR
      , PRVBE
      , SUBSYS
      , BDEGR
      , RGEKZ
      , HRTYP
      , SLWID
      , LIFNR
      , SLWID_REF
      , LIFNR_REF
      , VGARB
      , VGDIM
      , HRPLVAR
      , VGDAU
      , STOBJ
      , RESGR
      , LGORT_RES
      , MIXMAT
      , ISTBED_KZ
      , PPSKZ
      , SRTYPE
      , SNTYPE
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
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
        ))    as LOAD_DTS
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
        PLANT_BK
      , WORK_CENTER_BK
      , UOM_BK
      , WORK_CENTER_LOCATION_BK
      , MANDT
      , OBJTY
      , OBJID
      , GLREQUEST
      , BEGDA
      , ENDDA
      , AEDAT_GRND
      , AENAM_GRND
      , AEDAT_VORA
      , AENAM_VORA
      , AEDAT_TERM
      , AENAM_TERM
      , AEDAT_TECH
      , AENAM_TECH
      , ARBPL
      , WERKS
      , VERWE
      , LVORM
      , PAR01
      , PAR02
      , PAR03
      , PAR04
      , PAR05
      , PAR06
      , PARU1
      , PARU2
      , PARU3
      , PARU4
      , PARU5
      , PARU6
      , PARV1
      , PARV2
      , PARV3
      , PARV4
      , PARV5
      , PARV6
      , PLANV
      , STAND
      , VERAN
      , VGWTS
      , VGM01
      , VGM02
      , VGM03
      , VGM04
      , VGM05
      , VGM06
      , XDEFA
      , XKOST
      , XSPRR
      , XTERM
      , ZGR01
      , ZGR02
      , ZGR03
      , ZGR04
      , ZGR05
      , ZGR06
      , KTSCH
      , LOANZ
      , LOART
      , LOGRP
      , QUALF
      , RASCH
      , STEUS
      , VGE01
      , VGE02
      , VGE03
      , VGE04
      , VGE05
      , VGE06
      , KTSCH_REF
      , LOART_REF
      , LOANZ_REF
      , LOGRP_REF
      , QUALF_REF
      , RASCH_REF
      , STEUS_REF
      , FORT1
      , FORT2
      , FORT3
      , KAPID
      , ORTGR
      , ZEIWN
      , ZWNOR
      , ZEIWM
      , ZWMIN
      , FORMR
      , MATYP
      , CPLGR
      , SORTB
      , MTRVP
      , MTMVP
      , MTPVP
      , RSANZ
      , PDEST
      , HROID
      , FORTN
      , ZGR01_REF
      , ZGR02_REF
      , ZGR03_REF
      , ZGR04_REF
      , ZGR05_REF
      , ZGR06_REF
      , STEUS_C
      , STEUS_I
      , STEUS_N
      , STEUS_Q
      , RUZUS
      , RSANZ_REF
      , HR
      , PRVBE
      , SUBSYS
      , BDEGR
      , RGEKZ
      , HRTYP
      , SLWID
      , LIFNR
      , SLWID_REF
      , LIFNR_REF
      , VGARB
      , VGDIM
      , HRPLVAR
      , VGDAU
      , STOBJ
      , RESGR
      , LGORT_RES
      , MIXMAT
      , ISTBED_KZ
      , PPSKZ
      , SRTYPE
      , SNTYPE
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_CRHD'
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
          KAPID                                                        as CAPACITY_DC
        , PLANT_BK
        , WORK_CENTER_BK
        , UOM_BK
        , WORK_CENTER_LOCATION_BK
        , MANDT
        , OBJTY
        , OBJID
        , GLREQUEST
        , BEGDA
        , ENDDA
        , AEDAT_GRND
        , AENAM_GRND
        , AEDAT_VORA
        , AENAM_VORA
        , AEDAT_TERM
        , AENAM_TERM
        , AEDAT_TECH
        , AENAM_TECH
        , ARBPL
        , WERKS
        , VERWE
        , LVORM
        , PAR01
        , PAR02
        , PAR03
        , PAR04
        , PAR05
        , PAR06
        , PARU1
        , PARU2
        , PARU3
        , PARU4
        , PARU5
        , PARU6
        , PARV1
        , PARV2
        , PARV3
        , PARV4
        , PARV5
        , PARV6
        , PLANV
        , STAND
        , VERAN
        , VGWTS
        , VGM01
        , VGM02
        , VGM03
        , VGM04
        , VGM05
        , VGM06
        , XDEFA
        , XKOST
        , XSPRR
        , XTERM
        , ZGR01
        , ZGR02
        , ZGR03
        , ZGR04
        , ZGR05
        , ZGR06
        , KTSCH
        , LOANZ
        , LOART
        , LOGRP
        , QUALF
        , RASCH
        , STEUS
        , VGE01
        , VGE02
        , VGE03
        , VGE04
        , VGE05
        , VGE06
        , KTSCH_REF
        , LOART_REF
        , LOANZ_REF
        , LOGRP_REF
        , QUALF_REF
        , RASCH_REF
        , STEUS_REF
        , FORT1
        , FORT2
        , FORT3
        , KAPID
        , ORTGR
        , ZEIWN
        , ZWNOR
        , ZEIWM
        , ZWMIN
        , FORMR
        , MATYP
        , CPLGR
        , SORTB
        , MTRVP
        , MTMVP
        , MTPVP
        , RSANZ
        , PDEST
        , HROID
        , FORTN
        , ZGR01_REF
        , ZGR02_REF
        , ZGR03_REF
        , ZGR04_REF
        , ZGR05_REF
        , ZGR06_REF
        , STEUS_C
        , STEUS_I
        , STEUS_N
        , STEUS_Q
        , RUZUS
        , RSANZ_REF
        , HR
        , PRVBE
        , SUBSYS
        , BDEGR
        , RGEKZ
        , HRTYP
        , SLWID
        , LIFNR
        , SLWID_REF
        , LIFNR_REF
        , VGARB
        , VGDIM
        , HRPLVAR
        , VGDAU
        , STOBJ
        , RESGR
        , LGORT_RES
        , MIXMAT
        , ISTBED_KZ
        , PPSKZ
        , SRTYPE
        , SNTYPE
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WORK_CENTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')  
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as WORK_CENTER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as UOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WORK_CENTER_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as WORK_CENTER_LOCATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(WORK_CENTER_BK as VARCHAR)),''), '^^')        
        , COALESCE(NULLIF(TRIM(CAST(WORK_CENTER_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(KAPID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_WORK_CENTER_CAPACITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(OBJTY::text), '^^') 
            , '||', IFNULL(TRIM(OBJID::text), '^^') 
            , '||', IFNULL(TRIM(BEGDA::text), '^^') 
            , '||', IFNULL(TRIM(ENDDA::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT_GRND::text), '^^') 
            , '||', IFNULL(TRIM(AENAM_GRND::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT_VORA::text), '^^') 
            , '||', IFNULL(TRIM(AENAM_VORA::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT_TERM::text), '^^') 
            , '||', IFNULL(TRIM(AENAM_TERM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT_TECH::text), '^^') 
            , '||', IFNULL(TRIM(AENAM_TECH::text), '^^') 
            , '||', IFNULL(TRIM(VERWE::text), '^^') 
            , '||', IFNULL(TRIM(LVORM::text), '^^') 
            , '||', IFNULL(TRIM(PAR01::text), '^^') 
            , '||', IFNULL(TRIM(PAR02::text), '^^') 
            , '||', IFNULL(TRIM(PAR03::text), '^^') 
            , '||', IFNULL(TRIM(PAR04::text), '^^') 
            , '||', IFNULL(TRIM(PAR05::text), '^^') 
            , '||', IFNULL(TRIM(PAR06::text), '^^') 
            , '||', IFNULL(TRIM(PARU1::text), '^^') 
            , '||', IFNULL(TRIM(PARU2::text), '^^') 
            , '||', IFNULL(TRIM(PARU3::text), '^^') 
            , '||', IFNULL(TRIM(PARU4::text), '^^') 
            , '||', IFNULL(TRIM(PARU5::text), '^^') 
            , '||', IFNULL(TRIM(PARU6::text), '^^') 
            , '||', IFNULL(TRIM(PARV1::text), '^^') 
            , '||', IFNULL(TRIM(PARV2::text), '^^') 
            , '||', IFNULL(TRIM(PARV3::text), '^^') 
            , '||', IFNULL(TRIM(PARV4::text), '^^') 
            , '||', IFNULL(TRIM(PARV5::text), '^^') 
            , '||', IFNULL(TRIM(PARV6::text), '^^') 
            , '||', IFNULL(TRIM(PLANV::text), '^^') 
            , '||', IFNULL(TRIM(VERAN::text), '^^') 
            , '||', IFNULL(TRIM(VGWTS::text), '^^') 
            , '||', IFNULL(TRIM(VGM01::text), '^^') 
            , '||', IFNULL(TRIM(VGM02::text), '^^') 
            , '||', IFNULL(TRIM(VGM03::text), '^^') 
            , '||', IFNULL(TRIM(VGM04::text), '^^') 
            , '||', IFNULL(TRIM(VGM05::text), '^^') 
            , '||', IFNULL(TRIM(VGM06::text), '^^') 
            , '||', IFNULL(TRIM(XDEFA::text), '^^') 
            , '||', IFNULL(TRIM(XKOST::text), '^^') 
            , '||', IFNULL(TRIM(XSPRR::text), '^^') 
            , '||', IFNULL(TRIM(XTERM::text), '^^') 
            , '||', IFNULL(TRIM(ZGR01::text), '^^') 
            , '||', IFNULL(TRIM(ZGR02::text), '^^') 
            , '||', IFNULL(TRIM(ZGR03::text), '^^') 
            , '||', IFNULL(TRIM(ZGR04::text), '^^') 
            , '||', IFNULL(TRIM(ZGR05::text), '^^') 
            , '||', IFNULL(TRIM(ZGR06::text), '^^') 
            , '||', IFNULL(TRIM(KTSCH::text), '^^') 
            , '||', IFNULL(TRIM(LOANZ::text), '^^') 
            , '||', IFNULL(TRIM(LOART::text), '^^') 
            , '||', IFNULL(TRIM(LOGRP::text), '^^') 
            , '||', IFNULL(TRIM(QUALF::text), '^^') 
            , '||', IFNULL(TRIM(RASCH::text), '^^') 
            , '||', IFNULL(TRIM(STEUS::text), '^^') 
            , '||', IFNULL(TRIM(VGE01::text), '^^') 
            , '||', IFNULL(TRIM(VGE02::text), '^^') 
            , '||', IFNULL(TRIM(VGE03::text), '^^') 
            , '||', IFNULL(TRIM(VGE04::text), '^^') 
            , '||', IFNULL(TRIM(VGE05::text), '^^') 
            , '||', IFNULL(TRIM(VGE06::text), '^^') 
            , '||', IFNULL(TRIM(KTSCH_REF::text), '^^') 
            , '||', IFNULL(TRIM(LOART_REF::text), '^^') 
            , '||', IFNULL(TRIM(LOANZ_REF::text), '^^') 
            , '||', IFNULL(TRIM(LOGRP_REF::text), '^^') 
            , '||', IFNULL(TRIM(QUALF_REF::text), '^^') 
            , '||', IFNULL(TRIM(RASCH_REF::text), '^^') 
            , '||', IFNULL(TRIM(STEUS_REF::text), '^^') 
            , '||', IFNULL(TRIM(FORT1::text), '^^') 
            , '||', IFNULL(TRIM(FORT2::text), '^^') 
            , '||', IFNULL(TRIM(FORT3::text), '^^') 
            , '||', IFNULL(TRIM(KAPID::text), '^^') 
            , '||', IFNULL(TRIM(ORTGR::text), '^^') 
            , '||', IFNULL(TRIM(ZWNOR::text), '^^') 
            , '||', IFNULL(TRIM(ZEIWM::text), '^^') 
            , '||', IFNULL(TRIM(ZWMIN::text), '^^') 
            , '||', IFNULL(TRIM(FORMR::text), '^^') 
            , '||', IFNULL(TRIM(MATYP::text), '^^') 
            , '||', IFNULL(TRIM(CPLGR::text), '^^') 
            , '||', IFNULL(TRIM(SORTB::text), '^^') 
            , '||', IFNULL(TRIM(MTRVP::text), '^^') 
            , '||', IFNULL(TRIM(MTMVP::text), '^^') 
            , '||', IFNULL(TRIM(MTPVP::text), '^^') 
            , '||', IFNULL(TRIM(RSANZ::text), '^^') 
            , '||', IFNULL(TRIM(PDEST::text), '^^') 
            , '||', IFNULL(TRIM(HROID::text), '^^') 
            , '||', IFNULL(TRIM(FORTN::text), '^^') 
            , '||', IFNULL(TRIM(ZGR01_REF::text), '^^') 
            , '||', IFNULL(TRIM(ZGR02_REF::text), '^^') 
            , '||', IFNULL(TRIM(ZGR03_REF::text), '^^') 
            , '||', IFNULL(TRIM(ZGR04_REF::text), '^^') 
            , '||', IFNULL(TRIM(ZGR05_REF::text), '^^') 
            , '||', IFNULL(TRIM(ZGR06_REF::text), '^^') 
            , '||', IFNULL(TRIM(STEUS_C::text), '^^') 
            , '||', IFNULL(TRIM(STEUS_I::text), '^^') 
            , '||', IFNULL(TRIM(STEUS_N::text), '^^') 
            , '||', IFNULL(TRIM(STEUS_Q::text), '^^') 
            , '||', IFNULL(TRIM(RUZUS::text), '^^') 
            , '||', IFNULL(TRIM(RSANZ_REF::text), '^^') 
            , '||', IFNULL(TRIM(HR::text), '^^') 
            , '||', IFNULL(TRIM(PRVBE::text), '^^') 
            , '||', IFNULL(TRIM(SUBSYS::text), '^^') 
            , '||', IFNULL(TRIM(BDEGR::text), '^^') 
            , '||', IFNULL(TRIM(RGEKZ::text), '^^') 
            , '||', IFNULL(TRIM(HRTYP::text), '^^') 
            , '||', IFNULL(TRIM(SLWID::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(SLWID_REF::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR_REF::text), '^^') 
            , '||', IFNULL(TRIM(VGARB::text), '^^') 
            , '||', IFNULL(TRIM(VGDIM::text), '^^') 
            , '||', IFNULL(TRIM(HRPLVAR::text), '^^') 
            , '||', IFNULL(TRIM(VGDAU::text), '^^') 
            , '||', IFNULL(TRIM(STOBJ::text), '^^') 
            , '||', IFNULL(TRIM(RESGR::text), '^^') 
            , '||', IFNULL(TRIM(LGORT_RES::text), '^^') 
            , '||', IFNULL(TRIM(MIXMAT::text), '^^') 
            , '||', IFNULL(TRIM(ISTBED_KZ::text), '^^') 
            , '||', IFNULL(TRIM(PPSKZ::text), '^^') 
            , '||', IFNULL(TRIM(SRTYPE::text), '^^') 
            , '||', IFNULL(TRIM(SNTYPE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
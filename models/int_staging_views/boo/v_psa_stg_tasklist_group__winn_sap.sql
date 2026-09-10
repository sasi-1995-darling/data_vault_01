---- SRC LAYER ----
WITH
SRC_a              as ( SELECT ABANZ, ABDAT, ADPSP, AEDAT, AENAM, AENNR, AESZN, ANDAT, ANLZU, ANNAM, ARBID, ARBTY, BMSCH, CCOAA, CHRULE, CLNDR, DATUV, DELKZ, EXTNUM, FLG_CAPO, FLG_CHK, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, ISTRU, IWERK, KOKRS, KTEXT, KZKFG, LOEKZ, LOSBS, LOSVN, MANDT, MEINH, MES_ROUTINGID, MS_FLAG, NETID, PARKZ, PLNAL, PLNME, PLNNR, PLNNR_ALT, PLNTY, PPKZTLZU, PPOOL, PROFIDNETZ, PRTYP, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSPNR, QDYNHEAD, QDYNREGEL, QDYNSTRING, QKZRASTER, QPRZIEHVER, QVECODE, QVEDATUM, QVEGRUPPE, QVEMENGE, QVERSNPRZV, QVEVERSION, QVEWERKS, REODAT, SLWBEZ, STATU, STLAL, STLNR, STLTY, STRAT, STUPR, ST_ARBID, TECHV, TL_EXTID, TSTMP_BW, TTRAS, TXTSP, UMREN, UMREZ, VAGRP, VERWE, WERKS, XHIERTL, ZAEHL FROM {{ source('sap_ecc_prd', 'z_plko') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_plko )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MANDT
      , PLNTY
      , PLNNR
      , PLNAL
      , ZAEHL
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LOEKZ
      , PARKZ
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , VERWE
      , WERKS
      , STATU
      , PLNME
      , LOSVN
      , LOSBS
      , VAGRP
      , AESZN
      , KTEXT
      , TXTSP
      , ABDAT
      , ABANZ
      , PROFIDNETZ
      , KOKRS
      , QVEWERKS
      , QVEMENGE
      , QVEVERSION
      , QVEDATUM
      , QVEGRUPPE
      , QVECODE
      , QDYNREGEL
      , QDYNHEAD
      , QPRZIEHVER
      , QVERSNPRZV
      , QKZRASTER
      , QDYNSTRING
      , STRAT
      , PPOOL
      , ISTRU
      , IWERK
      , ANLZU
      , ARBID
      , EXTNUM
      , DELKZ
      , ARBTY
      , STUPR
      , CLNDR
      , PRTYP
      , REODAT
      , NETID
      , FLG_CHK
      , PSPNR
      , TTRAS
      , KZKFG
      , PLNNR_ALT
      , FLG_CAPO
      , STLTY
      , STLNR
      , STLAL
      , SLWBEZ
      , PPKZTLZU
      , CHRULE
      , CCOAA
      , ST_ARBID
      , MEINH
      , UMREZ
      , UMREN
      , BMSCH
      , ADPSP
      , MS_FLAG
      , TSTMP_BW
      , MES_ROUTINGID
      , XHIERTL
      , TL_EXTID
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
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
      , COALESCE(ISTRU, '-1')                                        as                                   ASSEMBLY_ITEM_BK
      , COALESCE(IWERK, '-1')                                        as                                  PLANNING_PLANT_BK
      , CONCAT_WS('||', PLNTY, PLNNR)                                as                                  TASKLIST_GROUP_BK
      , COALESCE(STLNR, '-1')                                        as                                             BOM_BK
      , COALESCE(AENNR, '-1')                                        as                                   CHANGE_MASTER_BK
      , PLNAL                                                        as                       TASKLIST_GROUP_VARIANT_ID_DC
      , COALESCE(WERKS, '-1')                                        as                                           PLANT_BK
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
      , PLNTY
      , PLNNR
      , PLNAL
      , ZAEHL
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LOEKZ
      , PARKZ
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , VERWE
      , WERKS
      , STATU
      , PLNME
      , LOSVN
      , LOSBS
      , VAGRP
      , AESZN
      , KTEXT
      , TXTSP
      , ABDAT
      , ABANZ
      , PROFIDNETZ
      , KOKRS
      , QVEWERKS
      , QVEMENGE
      , QVEVERSION
      , QVEDATUM
      , QVEGRUPPE
      , QVECODE
      , QDYNREGEL
      , QDYNHEAD
      , QPRZIEHVER
      , QVERSNPRZV
      , QKZRASTER
      , QDYNSTRING
      , STRAT
      , PPOOL
      , ISTRU
      , IWERK
      , ANLZU
      , ARBID
      , EXTNUM
      , DELKZ
      , ARBTY
      , STUPR
      , CLNDR
      , PRTYP
      , REODAT
      , NETID
      , FLG_CHK
      , PSPNR
      , TTRAS
      , KZKFG
      , PLNNR_ALT
      , FLG_CAPO
      , STLTY
      , STLNR
      , STLAL
      , SLWBEZ
      , PPKZTLZU
      , CHRULE
      , CCOAA
      , ST_ARBID
      , MEINH
      , UMREZ
      , UMREN
      , BMSCH
      , ADPSP
      , MS_FLAG
      , TSTMP_BW
      , MES_ROUTINGID
      , XHIERTL
      , TL_EXTID
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , ASSEMBLY_ITEM_BK
      , PLANNING_PLANT_BK
      , TASKLIST_GROUP_BK
      , BOM_BK
      , CHANGE_MASTER_BK
      , TASKLIST_GROUP_VARIANT_ID_DC
      , PLANT_BK
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_PLKO'
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
        , PLNTY
        , PLNNR
        , PLNAL
        , ZAEHL
        , GLREQUEST
        , DATUV
        , TECHV
        , AENNR
        , LOEKZ
        , PARKZ
        , ANDAT
        , ANNAM
        , AEDAT
        , AENAM
        , VERWE
        , WERKS
        , STATU
        , PLNME
        , LOSVN
        , LOSBS
        , VAGRP
        , AESZN
        , KTEXT
        , TXTSP
        , ABDAT
        , ABANZ
        , PROFIDNETZ
        , KOKRS
        , QVEWERKS
        , QVEMENGE
        , QVEVERSION
        , QVEDATUM
        , QVEGRUPPE
        , QVECODE
        , QDYNREGEL
        , QDYNHEAD
        , QPRZIEHVER
        , QVERSNPRZV
        , QKZRASTER
        , QDYNSTRING
        , STRAT
        , PPOOL
        , ISTRU
        , IWERK
        , ANLZU
        , ARBID
        , EXTNUM
        , DELKZ
        , ARBTY
        , STUPR
        , CLNDR
        , PRTYP
        , REODAT
        , NETID
        , FLG_CHK
        , PSPNR
        , TTRAS
        , KZKFG
        , PLNNR_ALT
        , FLG_CAPO
        , STLTY
        , STLNR
        , STLAL
        , SLWBEZ
        , PPKZTLZU
        , CHRULE
        , CCOAA
        , ST_ARBID
        , MEINH
        , UMREZ
        , UMREN
        , BMSCH
        , ADPSP
        , MS_FLAG
        , TSTMP_BW
        , MES_ROUTINGID
        , XHIERTL
        , TL_EXTID
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , ASSEMBLY_ITEM_BK
        , PLANNING_PLANT_BK
        , TASKLIST_GROUP_BK
        , BOM_BK
        , CHANGE_MASTER_BK
        , TASKLIST_GROUP_VARIANT_ID_DC
        , PLANT_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ASSEMBLY_ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ASSEMBLY_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANNING_PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANNING_PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(TASKLIST_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as TASKLIST_GROUP_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as BOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CHANGE_MASTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CHANGE_MASTER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(TASKLIST_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ASSEMBLY_ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANNING_PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CHANGE_MASTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_PLANT_TASKLIST_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(PLNAL::text), '^^') 
            , '||', IFNULL(TRIM(ZAEHL::text), '^^') 
            , '||', IFNULL(TRIM(DATUV::text), '^^') 
            , '||', IFNULL(TRIM(TECHV::text), '^^') 
            , '||', IFNULL(TRIM(AENNR::text), '^^') 
            , '||', IFNULL(TRIM(LOEKZ::text), '^^') 
            , '||', IFNULL(TRIM(PARKZ::text), '^^') 
            , '||', IFNULL(TRIM(ANDAT::text), '^^') 
            , '||', IFNULL(TRIM(ANNAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(VERWE::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(STATU::text), '^^') 
            , '||', IFNULL(TRIM(PLNME::text), '^^') 
            , '||', IFNULL(TRIM(LOSVN::text), '^^') 
            , '||', IFNULL(TRIM(LOSBS::text), '^^') 
            , '||', IFNULL(TRIM(VAGRP::text), '^^') 
            , '||', IFNULL(TRIM(AESZN::text), '^^') 
            , '||', IFNULL(TRIM(KTEXT::text), '^^') 
            , '||', IFNULL(TRIM(TXTSP::text), '^^') 
            , '||', IFNULL(TRIM(ABDAT::text), '^^') 
            , '||', IFNULL(TRIM(ABANZ::text), '^^') 
            , '||', IFNULL(TRIM(PROFIDNETZ::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(QVEWERKS::text), '^^') 
            , '||', IFNULL(TRIM(QVEMENGE::text), '^^') 
            , '||', IFNULL(TRIM(QVEVERSION::text), '^^') 
            , '||', IFNULL(TRIM(QVEDATUM::text), '^^') 
            , '||', IFNULL(TRIM(QVEGRUPPE::text), '^^') 
            , '||', IFNULL(TRIM(QVECODE::text), '^^') 
            , '||', IFNULL(TRIM(QDYNREGEL::text), '^^') 
            , '||', IFNULL(TRIM(QDYNHEAD::text), '^^') 
            , '||', IFNULL(TRIM(QPRZIEHVER::text), '^^') 
            , '||', IFNULL(TRIM(QVERSNPRZV::text), '^^') 
            , '||', IFNULL(TRIM(QKZRASTER::text), '^^') 
            , '||', IFNULL(TRIM(QDYNSTRING::text), '^^') 
            , '||', IFNULL(TRIM(STRAT::text), '^^') 
            , '||', IFNULL(TRIM(PPOOL::text), '^^') 
            , '||', IFNULL(TRIM(ISTRU::text), '^^') 
            , '||', IFNULL(TRIM(IWERK::text), '^^') 
            , '||', IFNULL(TRIM(ANLZU::text), '^^') 
            , '||', IFNULL(TRIM(ARBID::text), '^^') 
            , '||', IFNULL(TRIM(EXTNUM::text), '^^') 
            , '||', IFNULL(TRIM(DELKZ::text), '^^') 
            , '||', IFNULL(TRIM(ARBTY::text), '^^') 
            , '||', IFNULL(TRIM(STUPR::text), '^^') 
            , '||', IFNULL(TRIM(CLNDR::text), '^^') 
            , '||', IFNULL(TRIM(PRTYP::text), '^^') 
            , '||', IFNULL(TRIM(REODAT::text), '^^') 
            , '||', IFNULL(TRIM(NETID::text), '^^') 
            , '||', IFNULL(TRIM(FLG_CHK::text), '^^') 
            , '||', IFNULL(TRIM(PSPNR::text), '^^') 
            , '||', IFNULL(TRIM(TTRAS::text), '^^') 
            , '||', IFNULL(TRIM(KZKFG::text), '^^') 
            , '||', IFNULL(TRIM(PLNNR_ALT::text), '^^') 
            , '||', IFNULL(TRIM(FLG_CAPO::text), '^^') 
            , '||', IFNULL(TRIM(STLTY::text), '^^') 
            , '||', IFNULL(TRIM(STLNR::text), '^^') 
            , '||', IFNULL(TRIM(STLAL::text), '^^') 
            , '||', IFNULL(TRIM(SLWBEZ::text), '^^') 
            , '||', IFNULL(TRIM(PPKZTLZU::text), '^^') 
            , '||', IFNULL(TRIM(CHRULE::text), '^^') 
            , '||', IFNULL(TRIM(CCOAA::text), '^^') 
            , '||', IFNULL(TRIM(ST_ARBID::text), '^^') 
            , '||', IFNULL(TRIM(MEINH::text), '^^') 
            , '||', IFNULL(TRIM(UMREZ::text), '^^') 
            , '||', IFNULL(TRIM(UMREN::text), '^^') 
            , '||', IFNULL(TRIM(BMSCH::text), '^^') 
            , '||', IFNULL(TRIM(ADPSP::text), '^^') 
            , '||', IFNULL(TRIM(MS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TSTMP_BW::text), '^^') 
            , '||', IFNULL(TRIM(MES_ROUTINGID::text), '^^') 
            , '||', IFNULL(TRIM(XHIERTL::text), '^^') 
            , '||', IFNULL(TRIM(TL_EXTID::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_a              as ( SELECT ABARB, ADPSP, AENNR, APLZT, APRIO, ARSNR, ARSPS, ATRKZ, AUFLD, AUFNR, AUFNT, AUFPL, AUFPT, BEDID, BMEINS, BMENGE, BREAKS, CFB_ADTDAYS, CFB_BBDPI, CFB_DATOFM, CFB_LZEIH, CFB_MAXLZ, CHSCH, CH_PROC, COLORDPROC, CONF_KEY, COSTUPD, CSPLIT, CUOBJ, CY_SEQNR, DISPO, FEVOR, FHORI, FLG_AOB, FLG_ARBEI, FLG_BUNDLE, FREIZ, FSH_MPROD_ORD, FTRMI, FTRMP, FTRMS, FTRPS, GAMNG, GASMG, GETRI, GEUZI, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, GLTPP, GLTPS, GLTRI, GLTRP, GLTRS, GLUPP, GLUPS, GLUZP, GLUZS, GMEIN, GROID, GSBTR, GSTPP, GSTPS, GSTRI, GSTRP, GSTRS, GSUPP, GSUPS, GSUZI, GSUZP, GSUZS, IASMG, IGMNG, KAPT_SICHZ, KAPT_VORGZ, KAPVERSA, KBED, KKALKR, KLVARI, KLVARP, KZERB, LEAD_AUFNR, LKNOT, LODIV, MANDT, MAUFNR, MAX_GAMNG, MES_ROUTINGID, MILL_OC_ZUSKZ, MILL_RATIO, MZAEHL, NAUCOST, NAUTERM, NETZKONT, NOPCOST, NO_DISP, NTZUE, OBJTYPE, OIHANTYP, PAENR, PDATV, PLART, PLAUF, PLGRP, PLNAL, PLNAW, PLNBEZ, PLNME, PLNNR, PLNTY, PLSVB, PLSVN, PNETENDD, PNETENDT, PNETSTARTD, PNETSTARTT, POSNR_RMA, POSNV_RMA, PRODNET, PROFID, PRONR, PRUEFLOS, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PVERW, RATID, RDKZP, REDKZ, REVLV, RGEKZ, RKNOT, RMANR, RMNGA, RMZHL, RSHID, RSHTY, RSNID, RSNTY, RSNUM, RUECK, SAENR, SBMEH, SBMNG, SDATV, SFCPF, SICHZ, SICHZ_TRM, SLSBS, SLSVN, SPLSTAT, STLAL, STLAN, STLBEZ, STLNR, STLST, STLTY, STUFE, ST_ARBID, TERHW, TERKZ, TRKZP, TRMDT, UPTER, VFMNG, VORGZ, VORGZ_TRM, VORUE, VSNMR_V, VWEGX, WEGXX, ZAEHL, ZKRIZ FROM {{ source('sap_ecc_prd', 'z_afko') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_afko )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MANDT
      , AUFNR
      , GLREQUEST
      , GLTRP
      , GSTRP
      , FTRMS
      , GLTRS
      , GSTRS
      , GSTRI
      , GETRI
      , GLTRI
      , FTRMI
      , FTRMP
      , RSNUM
      , GASMG
      , GAMNG
      , GMEIN
      , PLNBEZ
      , PLNTY
      , PLNNR
      , PLNAW
      , PLNAL
      , PVERW
      , PLAUF
      , PLSVB
      , PLNME
      , PLSVN
      , PDATV
      , PAENR
      , PLGRP
      , LODIV
      , STLTY
      , STLBEZ
      , STLST
      , STLNR
      , SDATV
      , SBMNG
      , SBMEH
      , SAENR
      , STLAL
      , STLAN
      , SLSVN
      , SLSBS
      , AUFLD
      , DISPO
      , AUFPL
      , FEVOR
      , FHORI
      , TERKZ
      , REDKZ
      , APRIO
      , NTZUE
      , VORUE
      , PROFID
      , VORGZ
      , SICHZ
      , FREIZ
      , UPTER
      , BEDID
      , PRONR
      , ZAEHL
      , MZAEHL
      , ZKRIZ
      , PRUEFLOS
      , KLVARP
      , KLVARI
      , RGEKZ
      , PLART
      , FLG_AOB
      , FLG_ARBEI
      , GLTPP
      , GSTPP
      , GLTPS
      , GSTPS
      , FTRPS
      , RDKZP
      , TRKZP
      , RUECK
      , RMZHL
      , IGMNG
      , RATID
      , GROID
      , CUOBJ
      , GLUZS
      , GSUZS
      , REVLV
      , RSHTY
      , RSHID
      , RSNTY
      , RSNID
      , NAUTERM
      , NAUCOST
      , STUFE
      , WEGXX
      , VWEGX
      , ARSNR
      , ARSPS
      , MAUFNR
      , LKNOT
      , RKNOT
      , PRODNET
      , IASMG
      , ABARB
      , AUFNT
      , AUFPT
      , APLZT
      , NO_DISP
      , CSPLIT
      , AENNR
      , CY_SEQNR
      , BREAKS
      , VORGZ_TRM
      , SICHZ_TRM
      , TRMDT
      , GLUZP
      , GSUZP
      , GSUZI
      , GEUZI
      , GLUPP
      , GSUPP
      , GLUPS
      , GSUPS
      , CHSCH
      , KAPT_VORGZ
      , KAPT_SICHZ
      , LEAD_AUFNR
      , PNETSTARTD
      , PNETSTARTT
      , PNETENDD
      , PNETENDT
      , KBED
      , KKALKR
      , SFCPF
      , RMNGA
      , GSBTR
      , VFMNG
      , NOPCOST
      , NETZKONT
      , ATRKZ
      , OBJTYPE
      , CH_PROC
      , KAPVERSA
      , COLORDPROC
      , KZERB
      , CONF_KEY
      , ST_ARBID
      , VSNMR_V
      , TERHW
      , SPLSTAT
      , COSTUPD
      , MAX_GAMNG
      , MES_ROUTINGID
      , ADPSP
      , RMANR
      , POSNR_RMA
      , POSNV_RMA
      , CFB_MAXLZ
      , CFB_LZEIH
      , CFB_ADTDAYS
      , CFB_DATOFM
      , CFB_BBDPI
      , OIHANTYP
      , FSH_MPROD_ORD
      , FLG_BUNDLE
      , MILL_RATIO
      , BMEINS
      , BMENGE
      , MILL_OC_ZUSKZ
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
      , AUFNR
      , GLREQUEST
      , GLTRP
      , GSTRP
      , FTRMS
      , GLTRS
      , GSTRS
      , GSTRI
      , GETRI
      , GLTRI
      , FTRMI
      , FTRMP
      , RSNUM
      , GASMG
      , GAMNG
      , GMEIN
      , PLNBEZ
      , PLNTY
      , PLNNR
      , PLNAW
      , PLNAL
      , PVERW
      , PLAUF
      , PLSVB
      , PLNME
      , PLSVN
      , PDATV
      , PAENR
      , PLGRP
      , LODIV
      , STLTY
      , STLBEZ
      , STLST
      , STLNR
      , SDATV
      , SBMNG
      , SBMEH
      , SAENR
      , STLAL
      , STLAN
      , SLSVN
      , SLSBS
      , AUFLD
      , DISPO
      , AUFPL
      , FEVOR
      , FHORI
      , TERKZ
      , REDKZ
      , APRIO
      , NTZUE
      , VORUE
      , PROFID
      , VORGZ
      , SICHZ
      , FREIZ
      , UPTER
      , BEDID
      , PRONR
      , ZAEHL
      , MZAEHL
      , ZKRIZ
      , PRUEFLOS
      , KLVARP
      , KLVARI
      , RGEKZ
      , PLART
      , FLG_AOB
      , FLG_ARBEI
      , GLTPP
      , GSTPP
      , GLTPS
      , GSTPS
      , FTRPS
      , RDKZP
      , TRKZP
      , RUECK
      , RMZHL
      , IGMNG
      , RATID
      , GROID
      , CUOBJ
      , GLUZS
      , GSUZS
      , REVLV
      , RSHTY
      , RSHID
      , RSNTY
      , RSNID
      , NAUTERM
      , NAUCOST
      , STUFE
      , WEGXX
      , VWEGX
      , ARSNR
      , ARSPS
      , MAUFNR
      , LKNOT
      , RKNOT
      , PRODNET
      , IASMG
      , ABARB
      , AUFNT
      , AUFPT
      , APLZT
      , NO_DISP
      , CSPLIT
      , AENNR
      , CY_SEQNR
      , BREAKS
      , VORGZ_TRM
      , SICHZ_TRM
      , TRMDT
      , GLUZP
      , GSUZP
      , GSUZI
      , GEUZI
      , GLUPP
      , GSUPP
      , GLUPS
      , GSUPS
      , CHSCH
      , KAPT_VORGZ
      , KAPT_SICHZ
      , LEAD_AUFNR
      , PNETSTARTD
      , PNETSTARTT
      , PNETENDD
      , PNETENDT
      , KBED
      , KKALKR
      , SFCPF
      , RMNGA
      , GSBTR
      , VFMNG
      , NOPCOST
      , NETZKONT
      , ATRKZ
      , OBJTYPE
      , CH_PROC
      , KAPVERSA
      , COLORDPROC
      , KZERB
      , CONF_KEY
      , ST_ARBID
      , VSNMR_V
      , TERHW
      , SPLSTAT
      , COSTUPD
      , MAX_GAMNG
      , MES_ROUTINGID
      , ADPSP
      , RMANR
      , POSNR_RMA
      , POSNV_RMA
      , CFB_MAXLZ
      , CFB_LZEIH
      , CFB_ADTDAYS
      , CFB_DATOFM
      , CFB_BBDPI
      , OIHANTYP
      , FSH_MPROD_ORD
      , FLG_BUNDLE
      , MILL_RATIO
      , BMEINS
      , BMENGE
      , MILL_OC_ZUSKZ
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_AFKO'
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
          AUFNR                                                                                                 as PRODUCTION_ORDER_BK
        , COALESCE(NULLIF(UPPER(TRIM(LEAD_AUFNR)), ''), '-1')                                                   as LEAD_PRODUCTION_ORDER_BK
        , COALESCE(NULLIF(UPPER(TRIM(RSNUM)), ''), '-1')                                                        as RESERVATION_BK
        , COALESCE(NULLIF(UPPER(TRIM(ARSPS)), ''), '-1')                                                        as RESERVATION_LINE_BK
        , COALESCE(NULLIF(UPPER(TRIM(PLNBEZ)), ''), '-1')                                                       as ROUTING_PLANNED_ITEM_BK
        , COALESCE(NULLIF(UPPER(TRIM(AUFPT)), ''), '-1')                                                        as ROUTING_NUMBER_OPERATIONS_BK
        , COALESCE(NULLIF(UPPER(TRIM(AUFPL)), ''), '-1')                                                        as PRODUCTION_ORDER_ROUTING_NUMBER_BK
        , COALESCE(NULLIF(UPPER(TRIM(STLBEZ)), ''), '-1')                                                       as BOM_SPECIFIED_ITEM_BK
        , COALESCE(NULLIF(UPPER(TRIM(BMEINS)), ''), '-1')                                                       as BASE_UOM_BK
        , COALESCE(NULLIF(UPPER(TRIM(GMEIN)), ''), '-1')                                                        as PRODUCTION_ORDER_BASE_UOM_BK
        , COALESCE(NULLIF(UPPER(TRIM(SBMEH)), ''), '-1')                                                        as BASE_QUANTITY_UOM_BK
        , COALESCE(NULLIF(UPPER(TRIM(PLNME)), ''), '-1')                                                        as PLANNED_ROUTING_UOM_BK
        , COALESCE(NULLIF(UPPER(TRIM(PAENR)), ''), '-1')                                                        as ROUTING_CHANGE_NUMBER_BK
        , COALESCE(NULLIF(UPPER(TRIM(SAENR)), ''), '-1')                                                        as BOM_CHANGE_NUMBER_BK
        , COALESCE(NULLIF(UPPER(TRIM(AENNR)), ''), '-1')                                                        as ENGINEERING_CHANGE_NUMBER_BK
        , COALESCE(NULLIF(UPPER(TRIM(STLNR)), ''), '-1')                                                        as BOM_BK
        , MANDT
        , AUFNR
        , GLREQUEST
        , GLTRP
        , GSTRP
        , FTRMS
        , GLTRS
        , GSTRS
        , GSTRI
        , GETRI
        , GLTRI
        , FTRMI
        , FTRMP
        , RSNUM
        , GASMG
        , GAMNG
        , GMEIN
        , PLNBEZ
        , PLNTY
        , PLNNR
        , PLNAW
        , PLNAL
        , PVERW
        , PLAUF
        , PLSVB
        , PLNME
        , PLSVN
        , PDATV
        , PAENR
        , PLGRP
        , LODIV
        , STLTY
        , STLBEZ
        , STLST
        , STLNR
        , SDATV
        , SBMNG
        , SBMEH
        , SAENR
        , STLAL
        , STLAN
        , SLSVN
        , SLSBS
        , AUFLD
        , DISPO
        , AUFPL
        , FEVOR
        , FHORI
        , TERKZ
        , REDKZ
        , APRIO
        , NTZUE
        , VORUE
        , PROFID
        , VORGZ
        , SICHZ
        , FREIZ
        , UPTER
        , BEDID
        , PRONR
        , ZAEHL
        , MZAEHL
        , ZKRIZ
        , PRUEFLOS
        , KLVARP
        , KLVARI
        , RGEKZ
        , PLART
        , FLG_AOB
        , FLG_ARBEI
        , GLTPP
        , GSTPP
        , GLTPS
        , GSTPS
        , FTRPS
        , RDKZP
        , TRKZP
        , RUECK
        , RMZHL
        , IGMNG
        , RATID
        , GROID
        , CUOBJ
        , GLUZS
        , GSUZS
        , REVLV
        , RSHTY
        , RSHID
        , RSNTY
        , RSNID
        , NAUTERM
        , NAUCOST
        , STUFE
        , WEGXX
        , VWEGX
        , ARSNR
        , ARSPS
        , MAUFNR
        , LKNOT
        , RKNOT
        , PRODNET
        , IASMG
        , ABARB
        , AUFNT
        , AUFPT
        , APLZT
        , NO_DISP
        , CSPLIT
        , AENNR
        , CY_SEQNR
        , BREAKS
        , VORGZ_TRM
        , SICHZ_TRM
        , TRMDT
        , GLUZP
        , GSUZP
        , GSUZI
        , GEUZI
        , GLUPP
        , GSUPP
        , GLUPS
        , GSUPS
        , CHSCH
        , KAPT_VORGZ
        , KAPT_SICHZ
        , LEAD_AUFNR
        , PNETSTARTD
        , PNETSTARTT
        , PNETENDD
        , PNETENDT
        , KBED
        , KKALKR
        , SFCPF
        , RMNGA
        , GSBTR
        , VFMNG
        , NOPCOST
        , NETZKONT
        , ATRKZ
        , OBJTYPE
        , CH_PROC
        , KAPVERSA
        , COLORDPROC
        , KZERB
        , CONF_KEY
        , ST_ARBID
        , VSNMR_V
        , TERHW
        , SPLSTAT
        , COSTUPD
        , MAX_GAMNG
        , MES_ROUTINGID
        , ADPSP
        , RMANR
        , POSNR_RMA
        , POSNV_RMA
        , CFB_MAXLZ
        , CFB_LZEIH
        , CFB_ADTDAYS
        , CFB_DATOFM
        , CFB_BBDPI
        , OIHANTYP
        , FSH_MPROD_ORD
        , FLG_BUNDLE
        , MILL_RATIO
        , BMEINS
        , BMENGE
        , MILL_OC_ZUSKZ
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
      )) as LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(AUFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCTION_ORDER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LEAD_PRODUCTION_ORDER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEAD_PRODUCTION_ORDER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RESERVATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RESERVATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RESERVATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RESERVATION_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RESERVATION_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ROUTING_PLANNED_ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ROUTING_PLANNED_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ROUTING_NUMBER_OPERATIONS_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ROUTING_NUMBER_OPERATIONS_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCTION_ORDER_ROUTING_NUMBER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCTION_ORDER_ROUTING_NUMBER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BOM_SPECIFIED_ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as BOM_SPECIFIED_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BASE_UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as BASE_UOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCTION_ORDER_BASE_UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCTION_ORDER_BASE_UOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BASE_QUANTITY_UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as BASE_QUANTITY_UOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANNED_ROUTING_UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANNED_ROUTING_UOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ROUTING_CHANGE_NUMBER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ROUTING_CHANGE_NUMBER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BOM_CHANGE_NUMBER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as BOM_CHANGE_NUMBER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ENGINEERING_CHANGE_NUMBER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ENGINEERING_CHANGE_NUMBER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as BOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(AUFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LEAD_AUFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RSNUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ARSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ARSPS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLNBEZ as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(STLBEZ as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(GMEIN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SBMEH as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLNME as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PAENR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SAENR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(AENNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(STLNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(AUFPT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(AUFPL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BMEINS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_PRODUCTION_ORDER_ROUTING_RESERVATION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(GLTRP::text), '^^') 
            , '||', IFNULL(TRIM(GSTRP::text), '^^') 
            , '||', IFNULL(TRIM(FTRMS::text), '^^') 
            , '||', IFNULL(TRIM(GLTRS::text), '^^') 
            , '||', IFNULL(TRIM(GSTRS::text), '^^') 
            , '||', IFNULL(TRIM(GSTRI::text), '^^') 
            , '||', IFNULL(TRIM(GETRI::text), '^^') 
            , '||', IFNULL(TRIM(GLTRI::text), '^^') 
            , '||', IFNULL(TRIM(FTRMI::text), '^^') 
            , '||', IFNULL(TRIM(FTRMP::text), '^^') 
            , '||', IFNULL(TRIM(RSNUM::text), '^^') 
            , '||', IFNULL(TRIM(GASMG::text), '^^') 
            , '||', IFNULL(TRIM(GAMNG::text), '^^') 
            , '||', IFNULL(TRIM(GMEIN::text), '^^') 
            , '||', IFNULL(TRIM(PLNBEZ::text), '^^') 
            , '||', IFNULL(TRIM(PLNTY::text), '^^') 
            , '||', IFNULL(TRIM(PLNNR::text), '^^') 
            , '||', IFNULL(TRIM(PLNAW::text), '^^') 
            , '||', IFNULL(TRIM(PLNAL::text), '^^') 
            , '||', IFNULL(TRIM(PVERW::text), '^^') 
            , '||', IFNULL(TRIM(PLAUF::text), '^^') 
            , '||', IFNULL(TRIM(PLSVB::text), '^^') 
            , '||', IFNULL(TRIM(PLNME::text), '^^') 
            , '||', IFNULL(TRIM(PLSVN::text), '^^') 
            , '||', IFNULL(TRIM(PDATV::text), '^^') 
            , '||', IFNULL(TRIM(PAENR::text), '^^') 
            , '||', IFNULL(TRIM(PLGRP::text), '^^') 
            , '||', IFNULL(TRIM(LODIV::text), '^^') 
            , '||', IFNULL(TRIM(STLTY::text), '^^') 
            , '||', IFNULL(TRIM(STLBEZ::text), '^^') 
            , '||', IFNULL(TRIM(STLST::text), '^^') 
            , '||', IFNULL(TRIM(STLNR::text), '^^') 
            , '||', IFNULL(TRIM(SDATV::text), '^^') 
            , '||', IFNULL(TRIM(SBMNG::text), '^^') 
            , '||', IFNULL(TRIM(SBMEH::text), '^^') 
            , '||', IFNULL(TRIM(SAENR::text), '^^') 
            , '||', IFNULL(TRIM(STLAL::text), '^^') 
            , '||', IFNULL(TRIM(STLAN::text), '^^') 
            , '||', IFNULL(TRIM(SLSVN::text), '^^') 
            , '||', IFNULL(TRIM(SLSBS::text), '^^') 
            , '||', IFNULL(TRIM(AUFLD::text), '^^') 
            , '||', IFNULL(TRIM(DISPO::text), '^^') 
            , '||', IFNULL(TRIM(AUFPL::text), '^^') 
            , '||', IFNULL(TRIM(FEVOR::text), '^^') 
            , '||', IFNULL(TRIM(FHORI::text), '^^') 
            , '||', IFNULL(TRIM(TERKZ::text), '^^') 
            , '||', IFNULL(TRIM(REDKZ::text), '^^') 
            , '||', IFNULL(TRIM(APRIO::text), '^^') 
            , '||', IFNULL(TRIM(NTZUE::text), '^^') 
            , '||', IFNULL(TRIM(VORUE::text), '^^') 
            , '||', IFNULL(TRIM(PROFID::text), '^^') 
            , '||', IFNULL(TRIM(VORGZ::text), '^^') 
            , '||', IFNULL(TRIM(SICHZ::text), '^^') 
            , '||', IFNULL(TRIM(FREIZ::text), '^^') 
            , '||', IFNULL(TRIM(UPTER::text), '^^') 
            , '||', IFNULL(TRIM(BEDID::text), '^^') 
            , '||', IFNULL(TRIM(PRONR::text), '^^') 
            , '||', IFNULL(TRIM(ZAEHL::text), '^^') 
            , '||', IFNULL(TRIM(MZAEHL::text), '^^') 
            , '||', IFNULL(TRIM(ZKRIZ::text), '^^') 
            , '||', IFNULL(TRIM(PRUEFLOS::text), '^^') 
            , '||', IFNULL(TRIM(KLVARP::text), '^^') 
            , '||', IFNULL(TRIM(KLVARI::text), '^^') 
            , '||', IFNULL(TRIM(RGEKZ::text), '^^') 
            , '||', IFNULL(TRIM(PLART::text), '^^') 
            , '||', IFNULL(TRIM(FLG_AOB::text), '^^') 
            , '||', IFNULL(TRIM(FLG_ARBEI::text), '^^') 
            , '||', IFNULL(TRIM(GLTPP::text), '^^') 
            , '||', IFNULL(TRIM(GSTPP::text), '^^') 
            , '||', IFNULL(TRIM(GLTPS::text), '^^') 
            , '||', IFNULL(TRIM(GSTPS::text), '^^') 
            , '||', IFNULL(TRIM(FTRPS::text), '^^') 
            , '||', IFNULL(TRIM(RDKZP::text), '^^') 
            , '||', IFNULL(TRIM(TRKZP::text), '^^') 
            , '||', IFNULL(TRIM(RUECK::text), '^^') 
            , '||', IFNULL(TRIM(RMZHL::text), '^^') 
            , '||', IFNULL(TRIM(IGMNG::text), '^^') 
            , '||', IFNULL(TRIM(RATID::text), '^^') 
            , '||', IFNULL(TRIM(GROID::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ::text), '^^') 
            , '||', IFNULL(TRIM(GLUZS::text), '^^') 
            , '||', IFNULL(TRIM(GSUZS::text), '^^') 
            , '||', IFNULL(TRIM(REVLV::text), '^^') 
            , '||', IFNULL(TRIM(RSHTY::text), '^^') 
            , '||', IFNULL(TRIM(RSHID::text), '^^') 
            , '||', IFNULL(TRIM(RSNTY::text), '^^') 
            , '||', IFNULL(TRIM(RSNID::text), '^^') 
            , '||', IFNULL(TRIM(NAUTERM::text), '^^') 
            , '||', IFNULL(TRIM(NAUCOST::text), '^^') 
            , '||', IFNULL(TRIM(STUFE::text), '^^') 
            , '||', IFNULL(TRIM(WEGXX::text), '^^') 
            , '||', IFNULL(TRIM(VWEGX::text), '^^') 
            , '||', IFNULL(TRIM(ARSNR::text), '^^') 
            , '||', IFNULL(TRIM(ARSPS::text), '^^') 
            , '||', IFNULL(TRIM(MAUFNR::text), '^^') 
            , '||', IFNULL(TRIM(LKNOT::text), '^^') 
            , '||', IFNULL(TRIM(RKNOT::text), '^^') 
            , '||', IFNULL(TRIM(PRODNET::text), '^^') 
            , '||', IFNULL(TRIM(IASMG::text), '^^') 
            , '||', IFNULL(TRIM(ABARB::text), '^^') 
            , '||', IFNULL(TRIM(AUFNT::text), '^^') 
            , '||', IFNULL(TRIM(AUFPT::text), '^^') 
            , '||', IFNULL(TRIM(APLZT::text), '^^') 
            , '||', IFNULL(TRIM(NO_DISP::text), '^^') 
            , '||', IFNULL(TRIM(CSPLIT::text), '^^') 
            , '||', IFNULL(TRIM(AENNR::text), '^^') 
            , '||', IFNULL(TRIM(CY_SEQNR::text), '^^') 
            , '||', IFNULL(TRIM(BREAKS::text), '^^') 
            , '||', IFNULL(TRIM(VORGZ_TRM::text), '^^') 
            , '||', IFNULL(TRIM(SICHZ_TRM::text), '^^') 
            , '||', IFNULL(TRIM(TRMDT::text), '^^') 
            , '||', IFNULL(TRIM(GLUZP::text), '^^') 
            , '||', IFNULL(TRIM(GSUZP::text), '^^') 
            , '||', IFNULL(TRIM(GSUZI::text), '^^') 
            , '||', IFNULL(TRIM(GEUZI::text), '^^') 
            , '||', IFNULL(TRIM(GLUPP::text), '^^') 
            , '||', IFNULL(TRIM(GSUPP::text), '^^') 
            , '||', IFNULL(TRIM(GLUPS::text), '^^') 
            , '||', IFNULL(TRIM(GSUPS::text), '^^') 
            , '||', IFNULL(TRIM(CHSCH::text), '^^') 
            , '||', IFNULL(TRIM(KAPT_VORGZ::text), '^^') 
            , '||', IFNULL(TRIM(KAPT_SICHZ::text), '^^') 
            , '||', IFNULL(TRIM(LEAD_AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(PNETSTARTD::text), '^^') 
            , '||', IFNULL(TRIM(PNETSTARTT::text), '^^') 
            , '||', IFNULL(TRIM(PNETENDD::text), '^^') 
            , '||', IFNULL(TRIM(PNETENDT::text), '^^') 
            , '||', IFNULL(TRIM(KBED::text), '^^') 
            , '||', IFNULL(TRIM(KKALKR::text), '^^') 
            , '||', IFNULL(TRIM(SFCPF::text), '^^') 
            , '||', IFNULL(TRIM(RMNGA::text), '^^') 
            , '||', IFNULL(TRIM(GSBTR::text), '^^') 
            , '||', IFNULL(TRIM(VFMNG::text), '^^') 
            , '||', IFNULL(TRIM(NOPCOST::text), '^^') 
            , '||', IFNULL(TRIM(NETZKONT::text), '^^') 
            , '||', IFNULL(TRIM(ATRKZ::text), '^^') 
            , '||', IFNULL(TRIM(OBJTYPE::text), '^^') 
            , '||', IFNULL(TRIM(CH_PROC::text), '^^') 
            , '||', IFNULL(TRIM(KAPVERSA::text), '^^') 
            , '||', IFNULL(TRIM(COLORDPROC::text), '^^') 
            , '||', IFNULL(TRIM(KZERB::text), '^^') 
            , '||', IFNULL(TRIM(CONF_KEY::text), '^^') 
            , '||', IFNULL(TRIM(ST_ARBID::text), '^^') 
            , '||', IFNULL(TRIM(VSNMR_V::text), '^^') 
            , '||', IFNULL(TRIM(TERHW::text), '^^') 
            , '||', IFNULL(TRIM(SPLSTAT::text), '^^') 
            , '||', IFNULL(TRIM(COSTUPD::text), '^^') 
            , '||', IFNULL(TRIM(MAX_GAMNG::text), '^^') 
            , '||', IFNULL(TRIM(MES_ROUTINGID::text), '^^') 
            , '||', IFNULL(TRIM(ADPSP::text), '^^') 
            , '||', IFNULL(TRIM(RMANR::text), '^^') 
            , '||', IFNULL(TRIM(POSNR_RMA::text), '^^') 
            , '||', IFNULL(TRIM(POSNV_RMA::text), '^^') 
            , '||', IFNULL(TRIM(CFB_MAXLZ::text), '^^') 
            , '||', IFNULL(TRIM(CFB_LZEIH::text), '^^') 
            , '||', IFNULL(TRIM(CFB_ADTDAYS::text), '^^') 
            , '||', IFNULL(TRIM(CFB_DATOFM::text), '^^') 
            , '||', IFNULL(TRIM(CFB_BBDPI::text), '^^') 
            , '||', IFNULL(TRIM(OIHANTYP::text), '^^') 
            , '||', IFNULL(TRIM(FSH_MPROD_ORD::text), '^^') 
            , '||', IFNULL(TRIM(FLG_BUNDLE::text), '^^') 
            , '||', IFNULL(TRIM(MILL_RATIO::text), '^^') 
            , '||', IFNULL(TRIM(BMEINS::text), '^^') 
            , '||', IFNULL(TRIM(BMENGE::text), '^^') 
            , '||', IFNULL(TRIM(MILL_OC_ZUSKZ::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
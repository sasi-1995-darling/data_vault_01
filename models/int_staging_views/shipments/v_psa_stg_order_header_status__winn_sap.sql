---- SRC LAYER ----
WITH
SRC_vbuk           as ( SELECT ABSTK, AEDAT, BESTK, BLOCK, BUCHK, CMGST, CMPS0, CMPS1, CMPS2, CMPSA, CMPSB, CMPSC, CMPSD, CMPSE, CMPSF, CMPSG, CMPSH, 
                        CMPSI, CMPSJ, CMPSK, CMPSL, CMPSM, CMPS_CM, CMPS_TE, COSTA, DCSTK, FKIVK, FKSAK, FKSTK, FMSTK, FSH_AR_STAT_HDR, FSSTK, GBSTK, 
                        GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, HDALL, HDALS, KOQUK, KOSTK, LFGSK, LFSTK, LSSTK, LVSTK, MANDT, MANEK, PDSTK, 
                        PKSTK, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, RELIK, RFGSK, RFSTK, RRSTA, SAPRL, SPE_TMPID, SPSTG, TRSTA, UVALL, UVALS, 
                        UVFAK, UVFAS, UVGEK, UVK01, UVK02, UVK03, UVK04, UVK05, UVPAK, UVPAS, UVPIK, UVPIS, UVPRS, UVS01, UVS02, UVS03, UVS04, UVS05, 
                        UVVLK, UVVLS, UVWAK, UVWAS, VBELN, VBOBJ, VBTYP, VBTYP_EXT, VESTK, VLSTK, WBSTK FROM {{ source('sap_ecc_prd', 'z_vbuk') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_vbuk           as ( SELECT * FROM sap_ecc_prd.z_vbuk )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_vbuk as (
    SELECT
        COALESCE(NULLIF(TRIM(VBELN),''),'-1')                        as                                    ORDER_HEADER_BK
      , MANDT
      , VBELN
      , GLREQUEST
      , RFSTK
      , RFGSK
      , BESTK
      , LFSTK
      , LFGSK
      , WBSTK
      , FKSTK
      , FKSAK
      , BUCHK
      , ABSTK
      , GBSTK
      , KOSTK
      , LVSTK
      , UVALS
      , UVVLS
      , UVFAS
      , UVALL
      , UVVLK
      , UVFAK
      , UVPRS
      , VBTYP
      , VBOBJ
      , AEDAT
      , TRY_TO_DATE(AEDAT, 'YYYYMMDD')                               as                                           AEDAT_DT
      , FKIVK
      , RELIK
      , UVK01
      , UVK02
      , UVK03
      , UVK04
      , UVK05
      , UVS01
      , UVS02
      , UVS03
      , UVS04
      , UVS05
      , PKSTK
      , CMPSA
      , CMPSB
      , CMPSC
      , CMPSD
      , CMPSE
      , CMPSF
      , CMPSG
      , CMPSH
      , CMPSI
      , CMPSJ
      , CMPSK
      , CMPSL
      , CMPS0
      , CMPS1
      , CMPS2
      , CMGST
      , TRSTA
      , KOQUK
      , COSTA
      , SAPRL
      , UVPAS
      , UVPIS
      , UVWAS
      , UVPAK
      , UVPIK
      , UVWAK
      , UVGEK
      , CMPSM
      , DCSTK
      , VESTK
      , VLSTK
      , RRSTA
      , BLOCK
      , FSSTK
      , LSSTK
      , SPSTG
      , PDSTK
      , FMSTK
      , MANEK
      , SPE_TMPID
      , HDALL
      , HDALS
      , CMPS_CM
      , CMPS_TE
      , VBTYP_EXT
      , FSH_AR_STAT_HDR
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            CONVERT_TIMEZONE(
            'UTC',
            TO_TIMESTAMP_NTZ(
            SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16),
            'YYYYMMDDHH24MISS.FF9'
            )
            )
        )                                                            as                                           LOAD_DTS
    FROM SRC_vbuk
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_vbuk as (
    SELECT
        ORDER_HEADER_BK
      , MANDT
      , VBELN
      , GLREQUEST
      , RFSTK
      , RFGSK
      , BESTK
      , LFSTK
      , LFGSK
      , WBSTK
      , FKSTK
      , FKSAK
      , BUCHK
      , ABSTK
      , GBSTK
      , KOSTK
      , LVSTK
      , UVALS
      , UVVLS
      , UVFAS
      , UVALL
      , UVVLK
      , UVFAK
      , UVPRS
      , VBTYP
      , VBOBJ
      , AEDAT
      , AEDAT_DT
      , FKIVK
      , RELIK
      , UVK01
      , UVK02
      , UVK03
      , UVK04
      , UVK05
      , UVS01
      , UVS02
      , UVS03
      , UVS04
      , UVS05
      , PKSTK
      , CMPSA
      , CMPSB
      , CMPSC
      , CMPSD
      , CMPSE
      , CMPSF
      , CMPSG
      , CMPSH
      , CMPSI
      , CMPSJ
      , CMPSK
      , CMPSL
      , CMPS0
      , CMPS1
      , CMPS2
      , CMGST
      , TRSTA
      , KOQUK
      , COSTA
      , SAPRL
      , UVPAS
      , UVPIS
      , UVWAS
      , UVPAK
      , UVPIK
      , UVWAK
      , UVGEK
      , CMPSM
      , DCSTK
      , VESTK
      , VLSTK
      , RRSTA
      , BLOCK
      , FSSTK
      , LSSTK
      , SPSTG
      , PDSTK
      , FMSTK
      , MANEK
      , SPE_TMPID
      , HDALL
      , HDALS
      , CMPS_CM
      , CMPS_TE
      , VBTYP_EXT
      , FSH_AR_STAT_HDR
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_vbuk
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_vbuk as (
    SELECT *
    FROM RENAME_vbuk
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_VBUK'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_vbuk
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ORDER_HEADER_BK
        , MANDT
        , VBELN
        , GLREQUEST
        , RFSTK
        , RFGSK
        , BESTK
        , LFSTK
        , LFGSK
        , WBSTK
        , FKSTK
        , FKSAK
        , BUCHK
        , ABSTK
        , GBSTK
        , KOSTK
        , LVSTK
        , UVALS
        , UVVLS
        , UVFAS
        , UVALL
        , UVVLK
        , UVFAK
        , UVPRS
        , VBTYP
        , VBOBJ
        , AEDAT
        , AEDAT_DT
        , FKIVK
        , RELIK
        , UVK01
        , UVK02
        , UVK03
        , UVK04
        , UVK05
        , UVS01
        , UVS02
        , UVS03
        , UVS04
        , UVS05
        , PKSTK
        , CMPSA
        , CMPSB
        , CMPSC
        , CMPSD
        , CMPSE
        , CMPSF
        , CMPSG
        , CMPSH
        , CMPSI
        , CMPSJ
        , CMPSK
        , CMPSL
        , CMPS0
        , CMPS1
        , CMPS2
        , CMGST
        , TRSTA
        , KOQUK
        , COSTA
        , SAPRL
        , UVPAS
        , UVPIS
        , UVWAS
        , UVPAK
        , UVPIK
        , UVWAK
        , UVGEK
        , CMPSM
        , DCSTK
        , VESTK
        , VLSTK
        , RRSTA
        , BLOCK
        , FSSTK
        , LSSTK
        , SPSTG
        , PDSTK
        , FMSTK
        , MANEK
        , SPE_TMPID
        , HDALL
        , HDALS
        , CMPS_CM
        , CMPS_TE
        , VBTYP_EXT
        , FSH_AR_STAT_HDR
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
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(RFSTK::text), '^^') 
            , '||', IFNULL(TRIM(RFGSK::text), '^^') 
            , '||', IFNULL(TRIM(BESTK::text), '^^') 
            , '||', IFNULL(TRIM(LFSTK::text), '^^') 
            , '||', IFNULL(TRIM(LFGSK::text), '^^') 
            , '||', IFNULL(TRIM(WBSTK::text), '^^') 
            , '||', IFNULL(TRIM(FKSTK::text), '^^') 
            , '||', IFNULL(TRIM(FKSAK::text), '^^') 
            , '||', IFNULL(TRIM(BUCHK::text), '^^') 
            , '||', IFNULL(TRIM(ABSTK::text), '^^') 
            , '||', IFNULL(TRIM(GBSTK::text), '^^') 
            , '||', IFNULL(TRIM(KOSTK::text), '^^') 
            , '||', IFNULL(TRIM(LVSTK::text), '^^') 
            , '||', IFNULL(TRIM(UVALS::text), '^^') 
            , '||', IFNULL(TRIM(UVVLS::text), '^^') 
            , '||', IFNULL(TRIM(UVFAS::text), '^^') 
            , '||', IFNULL(TRIM(UVALL::text), '^^') 
            , '||', IFNULL(TRIM(UVVLK::text), '^^') 
            , '||', IFNULL(TRIM(UVFAK::text), '^^') 
            , '||', IFNULL(TRIM(UVPRS::text), '^^') 
            , '||', IFNULL(TRIM(VBTYP::text), '^^') 
            , '||', IFNULL(TRIM(VBOBJ::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(FKIVK::text), '^^') 
            , '||', IFNULL(TRIM(RELIK::text), '^^') 
            , '||', IFNULL(TRIM(UVK01::text), '^^') 
            , '||', IFNULL(TRIM(UVK02::text), '^^') 
            , '||', IFNULL(TRIM(UVK03::text), '^^') 
            , '||', IFNULL(TRIM(UVK04::text), '^^') 
            , '||', IFNULL(TRIM(UVK05::text), '^^') 
            , '||', IFNULL(TRIM(UVS01::text), '^^') 
            , '||', IFNULL(TRIM(UVS02::text), '^^') 
            , '||', IFNULL(TRIM(UVS03::text), '^^') 
            , '||', IFNULL(TRIM(UVS04::text), '^^') 
            , '||', IFNULL(TRIM(UVS05::text), '^^') 
            , '||', IFNULL(TRIM(PKSTK::text), '^^') 
            , '||', IFNULL(TRIM(CMPSA::text), '^^') 
            , '||', IFNULL(TRIM(CMPSB::text), '^^') 
            , '||', IFNULL(TRIM(CMPSC::text), '^^') 
            , '||', IFNULL(TRIM(CMPSD::text), '^^') 
            , '||', IFNULL(TRIM(CMPSE::text), '^^') 
            , '||', IFNULL(TRIM(CMPSF::text), '^^') 
            , '||', IFNULL(TRIM(CMPSG::text), '^^') 
            , '||', IFNULL(TRIM(CMPSH::text), '^^') 
            , '||', IFNULL(TRIM(CMPSI::text), '^^') 
            , '||', IFNULL(TRIM(CMPSJ::text), '^^') 
            , '||', IFNULL(TRIM(CMPSK::text), '^^') 
            , '||', IFNULL(TRIM(CMPSL::text), '^^') 
            , '||', IFNULL(TRIM(CMPS0::text), '^^') 
            , '||', IFNULL(TRIM(CMPS1::text), '^^') 
            , '||', IFNULL(TRIM(CMPS2::text), '^^') 
            , '||', IFNULL(TRIM(CMGST::text), '^^') 
            , '||', IFNULL(TRIM(TRSTA::text), '^^') 
            , '||', IFNULL(TRIM(KOQUK::text), '^^') 
            , '||', IFNULL(TRIM(COSTA::text), '^^') 
            , '||', IFNULL(TRIM(SAPRL::text), '^^') 
            , '||', IFNULL(TRIM(UVPAS::text), '^^') 
            , '||', IFNULL(TRIM(UVPIS::text), '^^') 
            , '||', IFNULL(TRIM(UVWAS::text), '^^') 
            , '||', IFNULL(TRIM(UVPAK::text), '^^') 
            , '||', IFNULL(TRIM(UVPIK::text), '^^') 
            , '||', IFNULL(TRIM(UVWAK::text), '^^') 
            , '||', IFNULL(TRIM(UVGEK::text), '^^') 
            , '||', IFNULL(TRIM(CMPSM::text), '^^') 
            , '||', IFNULL(TRIM(DCSTK::text), '^^') 
            , '||', IFNULL(TRIM(VESTK::text), '^^') 
            , '||', IFNULL(TRIM(VLSTK::text), '^^') 
            , '||', IFNULL(TRIM(RRSTA::text), '^^') 
            , '||', IFNULL(TRIM(BLOCK::text), '^^') 
            , '||', IFNULL(TRIM(FSSTK::text), '^^') 
            , '||', IFNULL(TRIM(LSSTK::text), '^^') 
            , '||', IFNULL(TRIM(SPSTG::text), '^^') 
            , '||', IFNULL(TRIM(PDSTK::text), '^^') 
            , '||', IFNULL(TRIM(FMSTK::text), '^^') 
            , '||', IFNULL(TRIM(MANEK::text), '^^') 
            , '||', IFNULL(TRIM(SPE_TMPID::text), '^^') 
            , '||', IFNULL(TRIM(HDALL::text), '^^') 
            , '||', IFNULL(TRIM(HDALS::text), '^^') 
            , '||', IFNULL(TRIM(CMPS_CM::text), '^^') 
            , '||', IFNULL(TRIM(CMPS_TE::text), '^^') 
            , '||', IFNULL(TRIM(VBTYP_EXT::text), '^^') 
            , '||', IFNULL(TRIM(FSH_AR_STAT_HDR::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

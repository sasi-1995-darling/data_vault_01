---- SRC LAYER ----
WITH
SRC_k              as ( SELECT ALEMT, AUTH_KE_NO_STD, AUTH_KE_USE_ADD1, AUTH_KE_USE_ADD2, AUTH_USE_ADD1, AUTH_USE_ADD2, AUTH_USE_NO_STD, BEZEI, BLART, BPHINR, CTYP, CVACT, CVPROF, DEFPRCTR, DPRCT, ERKRS, FIKRS, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, KHINR, KOKFI, KOKRS, KOMP0, KOMP1, KOMP2, KSTAR_FID, KSTAR_FIN, KTOPL, LMONA, LOGSYSTEM, MANDT, MD_LOGSYSTEM, PCACUR, PCACURTP, PCATRCUR, PCA_ACC_DIFF, PCA_ALEMT, PCA_VALU, PCBEL, PCLDG, PHINR, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, RCLAC, RCL_PRIMAC, TP_VALOHB, VNAME, WAERS, XBPALE, XWBUK FROM {{ source('sap_ecc_prd', 'z_tka01') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_k              as ( SELECT * FROM sap_ecc_prd.z_tka01 )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_k as (
    SELECT
       CONVERT_TIMEZONE('UTC', IFF(
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
      , to_char(coalesce(nullif(trim(KOKRS), ''), '-1'))             as                                CONTROLLING_AREA_BK
      , MANDT
      , KOKRS
      , GLREQUEST
      , BEZEI
      , WAERS
      , KTOPL
      , LMONA
      , KOKFI
      , LOGSYSTEM
      , ALEMT
      , MD_LOGSYSTEM
      , KHINR
      , KOMP1
      , KOMP0
      , KOMP2
      , ERKRS
      , DPRCT
      , PHINR
      , PCLDG
      , PCBEL
      , XWBUK
      , BPHINR
      , XBPALE
      , KSTAR_FIN
      , KSTAR_FID
      , PCACUR
      , PCACURTP
      , PCATRCUR
      , CTYP
      , RCLAC
      , BLART
      , FIKRS
      , RCL_PRIMAC
      , PCA_ALEMT
      , PCA_VALU
      , CVPROF
      , CVACT
      , VNAME
      , PCA_ACC_DIFF
      , TP_VALOHB
      , DEFPRCTR
      , AUTH_USE_NO_STD
      , AUTH_USE_ADD1
      , AUTH_USE_ADD2
      , AUTH_KE_NO_STD
      , AUTH_KE_USE_ADD1
      , AUTH_KE_USE_ADD2
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_k
)

, LOGIC_A as (
    SELECT
        BKCC
        , REC_SRC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_k as (
    SELECT
       LOAD_DTS
      , CONTROLLING_AREA_BK
      , MANDT
      , KOKRS
      , GLREQUEST
      , BEZEI
      , WAERS
      , KTOPL
      , LMONA
      , KOKFI
      , LOGSYSTEM
      , ALEMT
      , MD_LOGSYSTEM
      , KHINR
      , KOMP1
      , KOMP0
      , KOMP2
      , ERKRS
      , DPRCT
      , PHINR
      , PCLDG
      , PCBEL
      , XWBUK
      , BPHINR
      , XBPALE
      , KSTAR_FIN
      , KSTAR_FID
      , PCACUR
      , PCACURTP
      , PCATRCUR
      , CTYP
      , RCLAC
      , BLART
      , FIKRS
      , RCL_PRIMAC
      , PCA_ALEMT
      , PCA_VALU
      , CVPROF
      , CVACT
      , VNAME
      , PCA_ACC_DIFF
      , TP_VALOHB
      , DEFPRCTR
      , AUTH_USE_NO_STD
      , AUTH_USE_ADD1
      , AUTH_USE_ADD2
      , AUTH_KE_NO_STD
      , AUTH_KE_USE_ADD1
      , AUTH_KE_USE_ADD2
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_k
)

, RENAME_A as (
    SELECT
        BKCC
        , REC_SRC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_k as (
    SELECT *
    FROM RENAME_k
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_TKA01'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_k
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
         LOAD_DTS
        , CONTROLLING_AREA_BK
        , MANDT
        , KOKRS
        , GLREQUEST
        , BEZEI
        , WAERS
        , KTOPL
        , LMONA
        , KOKFI
        , LOGSYSTEM
        , ALEMT
        , MD_LOGSYSTEM
        , KHINR
        , KOMP1
        , KOMP0
        , KOMP2
        , ERKRS
        , DPRCT
        , PHINR
        , PCLDG
        , PCBEL
        , XWBUK
        , BPHINR
        , XBPALE
        , KSTAR_FIN
        , KSTAR_FID
        , PCACUR
        , PCACURTP
        , PCATRCUR
        , CTYP
        , RCLAC
        , BLART
        , FIKRS
        , RCL_PRIMAC
        , PCA_ALEMT
        , PCA_VALU
        , CVPROF
        , CVACT
        , VNAME
        , PCA_ACC_DIFF
        , TP_VALOHB
        , DEFPRCTR
        , AUTH_USE_NO_STD
        , AUTH_USE_ADD1
        , AUTH_USE_ADD2
        , AUTH_KE_NO_STD
        , AUTH_KE_USE_ADD1
        , AUTH_KE_USE_ADD2
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                CONTROLLING_AREA_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CONTROLLING_AREA_BK::text), '^^') 
            , '||', IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(BEZEI::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(KTOPL::text), '^^') 
            , '||', IFNULL(TRIM(LMONA::text), '^^') 
            , '||', IFNULL(TRIM(KOKFI::text), '^^') 
            , '||', IFNULL(TRIM(LOGSYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(ALEMT::text), '^^') 
            , '||', IFNULL(TRIM(MD_LOGSYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(KHINR::text), '^^') 
            , '||', IFNULL(TRIM(KOMP1::text), '^^') 
            , '||', IFNULL(TRIM(KOMP0::text), '^^') 
            , '||', IFNULL(TRIM(KOMP2::text), '^^') 
            , '||', IFNULL(TRIM(ERKRS::text), '^^') 
            , '||', IFNULL(TRIM(DPRCT::text), '^^') 
            , '||', IFNULL(TRIM(PHINR::text), '^^') 
            , '||', IFNULL(TRIM(PCLDG::text), '^^') 
            , '||', IFNULL(TRIM(PCBEL::text), '^^') 
            , '||', IFNULL(TRIM(XWBUK::text), '^^') 
            , '||', IFNULL(TRIM(BPHINR::text), '^^') 
            , '||', IFNULL(TRIM(XBPALE::text), '^^') 
            , '||', IFNULL(TRIM(KSTAR_FIN::text), '^^') 
            , '||', IFNULL(TRIM(KSTAR_FID::text), '^^') 
            , '||', IFNULL(TRIM(PCACUR::text), '^^') 
            , '||', IFNULL(TRIM(PCACURTP::text), '^^') 
            , '||', IFNULL(TRIM(PCATRCUR::text), '^^') 
            , '||', IFNULL(TRIM(CTYP::text), '^^') 
            , '||', IFNULL(TRIM(RCLAC::text), '^^') 
            , '||', IFNULL(TRIM(BLART::text), '^^') 
            , '||', IFNULL(TRIM(FIKRS::text), '^^') 
            , '||', IFNULL(TRIM(RCL_PRIMAC::text), '^^') 
            , '||', IFNULL(TRIM(PCA_ALEMT::text), '^^') 
            , '||', IFNULL(TRIM(PCA_VALU::text), '^^') 
            , '||', IFNULL(TRIM(CVPROF::text), '^^') 
            , '||', IFNULL(TRIM(CVACT::text), '^^') 
            , '||', IFNULL(TRIM(VNAME::text), '^^') 
            , '||', IFNULL(TRIM(PCA_ACC_DIFF::text), '^^') 
            , '||', IFNULL(TRIM(TP_VALOHB::text), '^^') 
            , '||', IFNULL(TRIM(DEFPRCTR::text), '^^') 
            , '||', IFNULL(TRIM(AUTH_USE_NO_STD::text), '^^') 
            , '||', IFNULL(TRIM(AUTH_USE_ADD1::text), '^^') 
            , '||', IFNULL(TRIM(AUTH_USE_ADD2::text), '^^') 
            , '||', IFNULL(TRIM(AUTH_KE_NO_STD::text), '^^') 
            , '||', IFNULL(TRIM(AUTH_KE_USE_ADD1::text), '^^') 
            , '||', IFNULL(TRIM(AUTH_KE_USE_ADD2::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_LOAD_DTS::text), '^^') 
            , '||', IFNULL(TRIM(PSA_RECORD_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

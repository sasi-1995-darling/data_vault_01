---- SRC LAYER ----
WITH
SRC_psa            as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_vbup') }} as SRC  ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_psa            as ( SELECT * FROM SAP_ECC_PRD.Z_VBUP )
, SRC_bkcc           as ( SELECT * FROM raw_vault.REF_BUSINESS_KEY_COLLISION )
*/
---- LOGIC LAYER ----

, LOGIC_psa as (
    SELECT
        MANDT
      , CONCAT_WS('||', COALESCE(VBELN, ''), COALESCE(POSNR, ''))     as                                         ORDER_LINE_BK
      , VBELN
      , POSNR
      , GLREQUEST
      , RFSTA
      , RFGSA
      , BESTA
      , LFSTA
      , LFGSA
      , WBSTA
      , FKSTA
      , FKSAA
      , ABSTA
      , GBSTA
      , KOSTA
      , LVSTA
      , UVALL
      , UVVLK
      , UVFAK
      , UVPRS
      , FKIVP
      , UVP01
      , UVP02
      , UVP03
      , UVP04
      , UVP05
      , PKSTA
      , KOQUA
      , COSTA
      , CMPPI
      , CMPPJ
      , UVPIK
      , UVPAK
      , UVWAK
      , DCSTA
      , RRSTA
      , VLSTP
      , FSSTA
      , LSSTA
      , PDSTA
      , MANEK
      , HDALL
      , LTSPS
      , FSH_AR_STAT_ITM
      , MILL_VS_VSSTA
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
    FROM SRC_psa
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_psa as (
    SELECT
        MANDT
      , ORDER_LINE_BK
      , VBELN
      , POSNR
      , GLREQUEST
      , RFSTA
      , RFGSA
      , BESTA
      , LFSTA
      , LFGSA
      , WBSTA
      , FKSTA
      , FKSAA
      , ABSTA
      , GBSTA
      , KOSTA
      , LVSTA
      , UVALL
      , UVVLK
      , UVFAK
      , UVPRS
      , FKIVP
      , UVP01
      , UVP02
      , UVP03
      , UVP04
      , UVP05
      , PKSTA
      , KOQUA
      , COSTA
      , CMPPI
      , CMPPJ
      , UVPIK
      , UVPAK
      , UVWAK
      , DCSTA
      , RRSTA
      , VLSTP
      , FSSTA
      , LSSTA
      , PDSTA
      , MANEK
      , HDALL
      , LTSPS
      , FSH_AR_STAT_ITM
      , MILL_VS_VSSTA
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_psa
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_psa as (
    SELECT *
    FROM RENAME_psa
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_VBUP'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_psa
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          MANDT
        , ORDER_LINE_BK
        , VBELN
        , POSNR
        , GLREQUEST
        , RFSTA
        , RFGSA
        , BESTA
        , LFSTA
        , LFGSA
        , WBSTA
        , FKSTA
        , FKSAA
        , ABSTA
        , GBSTA
        , KOSTA
        , LVSTA
        , UVALL
        , UVVLK
        , UVFAK
        , UVPRS
        , FKIVP
        , UVP01
        , UVP02
        , UVP03
        , UVP04
        , UVP05
        , PKSTA
        , KOQUA
        , COSTA
        , CMPPI
        , CMPPJ
        , UVPIK
        , UVPAK
        , UVWAK
        , DCSTA
        , RRSTA
        , VLSTP
        , FSSTA
        , LSSTA
        , PDSTA
        , MANEK
        , HDALL
        , LTSPS
        , FSH_AR_STAT_ITM
        , MILL_VS_VSSTA
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
        , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_LINE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(RFSTA::text), '^^') 
            , '||', IFNULL(TRIM(RFGSA::text), '^^') 
            , '||', IFNULL(TRIM(BESTA::text), '^^') 
            , '||', IFNULL(TRIM(LFSTA::text), '^^') 
            , '||', IFNULL(TRIM(LFGSA::text), '^^') 
            , '||', IFNULL(TRIM(WBSTA::text), '^^') 
            , '||', IFNULL(TRIM(FKSTA::text), '^^') 
            , '||', IFNULL(TRIM(FKSAA::text), '^^') 
            , '||', IFNULL(TRIM(ABSTA::text), '^^') 
            , '||', IFNULL(TRIM(GBSTA::text), '^^') 
            , '||', IFNULL(TRIM(KOSTA::text), '^^') 
            , '||', IFNULL(TRIM(LVSTA::text), '^^') 
            , '||', IFNULL(TRIM(UVALL::text), '^^') 
            , '||', IFNULL(TRIM(UVVLK::text), '^^') 
            , '||', IFNULL(TRIM(UVFAK::text), '^^') 
            , '||', IFNULL(TRIM(UVPRS::text), '^^') 
            , '||', IFNULL(TRIM(FKIVP::text), '^^') 
            , '||', IFNULL(TRIM(UVP01::text), '^^') 
            , '||', IFNULL(TRIM(UVP02::text), '^^') 
            , '||', IFNULL(TRIM(UVP03::text), '^^') 
            , '||', IFNULL(TRIM(UVP04::text), '^^') 
            , '||', IFNULL(TRIM(UVP05::text), '^^') 
            , '||', IFNULL(TRIM(PKSTA::text), '^^') 
            , '||', IFNULL(TRIM(KOQUA::text), '^^') 
            , '||', IFNULL(TRIM(COSTA::text), '^^') 
            , '||', IFNULL(TRIM(CMPPI::text), '^^') 
            , '||', IFNULL(TRIM(CMPPJ::text), '^^') 
            , '||', IFNULL(TRIM(UVPIK::text), '^^') 
            , '||', IFNULL(TRIM(UVPAK::text), '^^') 
            , '||', IFNULL(TRIM(UVWAK::text), '^^') 
            , '||', IFNULL(TRIM(DCSTA::text), '^^') 
            , '||', IFNULL(TRIM(RRSTA::text), '^^') 
            , '||', IFNULL(TRIM(VLSTP::text), '^^') 
            , '||', IFNULL(TRIM(FSSTA::text), '^^') 
            , '||', IFNULL(TRIM(LSSTA::text), '^^') 
            , '||', IFNULL(TRIM(PDSTA::text), '^^') 
            , '||', IFNULL(TRIM(MANEK::text), '^^') 
            , '||', IFNULL(TRIM(HDALL::text), '^^') 
            , '||', IFNULL(TRIM(LTSPS::text), '^^') 
            , '||', IFNULL(TRIM(FSH_AR_STAT_ITM::text), '^^') 
            , '||', IFNULL(TRIM(MILL_VS_VSSTA::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(PSA_RECORD_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

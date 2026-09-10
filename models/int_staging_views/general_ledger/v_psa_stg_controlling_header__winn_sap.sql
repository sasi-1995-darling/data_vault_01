---- SRC LAYER ----
WITH
SRC_SRC_S          as ( SELECT ALEBN, ALEBZ, AWORG, AWORG_REV, AWREF_REV, AWSYS, AWTYP, BELNR, BLART, BLDAT, BLTXT, BUDAT, CPUDT, CPUTM, CTYP1, CTYP2, CTYP3, CTYP4, DELBZ, GJAHR, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, KOKRS, KURST, KWAER, LOGSYSTEM, MANDT, ORGVG, PERAB, PERBI, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REFBK, REFBN, REFBT, REFGJ, STFLG, STOKZ, SUMBZ, TIMESTMP, USNAM, VALDT, VARNR, VERSN, VRGNG, WSDAT FROM {{ source('sap_ecc_prd', 'z_cobk') }} as SRC  ),
SRC_SRC_A          as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_SRC_S          as ( SELECT * FROM sap_ecc_prd.z_cobk )
SRC_SRC_A          as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC_S as (
    SELECT
        to_char(coalesce(KOKRS,'-1'))                                as                                CONTROLLING_AREA_BK
      , to_char(coalesce(BELNR,'-1'))                                as                                CONTROLLING_LEDGER_HEADER_BK
      , MANDT
      , KOKRS
      , BELNR
      , GLREQUEST
      , GJAHR
      , VERSN
      , VRGNG
      , TIMESTMP
      , PERAB
      , PERBI
      , BLDAT
      , BUDAT
      , CPUDT
      , USNAM
      , BLTXT
      , STFLG
      , STOKZ
      , REFBT
      , REFBN
      , REFBK
      , REFGJ
      , BLART
      , ORGVG
      , SUMBZ
      , DELBZ
      , WSDAT
      , KURST
      , VARNR
      , KWAER
      , CTYP1
      , CTYP2
      , CTYP3
      , CTYP4
      , AWTYP
      , AWORG
      , LOGSYSTEM
      , CPUTM
      , ALEBZ
      , ALEBN
      , AWSYS
      , AWREF_REV
      , AWORG_REV
      , VALDT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_SRC_S
)

, LOGIC_SRC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_SRC_A
)
---- RENAME LAYER ----

, RENAME_SRC_S as (
    SELECT
        CONTROLLING_AREA_BK
      , CONTROLLING_LEDGER_HEADER_BK    
      , MANDT
      , KOKRS
      , BELNR
      , GLREQUEST
      , GJAHR
      , VERSN
      , VRGNG
      , TIMESTMP
      , PERAB
      , PERBI
      , BLDAT
      , BUDAT
      , CPUDT
      , USNAM
      , BLTXT
      , STFLG
      , STOKZ
      , REFBT
      , REFBN
      , REFBK
      , REFGJ
      , BLART
      , ORGVG
      , SUMBZ
      , DELBZ
      , WSDAT
      , KURST
      , VARNR
      , KWAER
      , CTYP1
      , CTYP2
      , CTYP3
      , CTYP4
      , AWTYP
      , AWORG
      , LOGSYSTEM
      , CPUTM
      , ALEBZ
      , ALEBN
      , AWSYS
      , AWREF_REV
      , AWORG_REV
      , VALDT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_SRC_S
)

, RENAME_SRC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_SRC_A
)
---- FILTER LAYER ----

, FILTER_SRC_S as (
    SELECT *
    FROM RENAME_SRC_S
)

, FILTER_SRC_A as (
    SELECT *
    FROM RENAME_SRC_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_COBK'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SRC_S
    INNER JOIN FILTER_SRC_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CONTROLLING_AREA_BK
        , CONTROLLING_LEDGER_HEADER_BK
        , MANDT
        , KOKRS
        , BELNR
        , GLREQUEST
        , GJAHR
        , VERSN
        , VRGNG
        , TIMESTMP
        , PERAB
        , PERBI
        , BLDAT
        , BUDAT
        , CPUDT
        , USNAM
        , BLTXT
        , STFLG
        , STOKZ
        , REFBT
        , REFBN
        , REFBK
        , REFGJ
        , BLART
        , ORGVG
        , SUMBZ
        , DELBZ
        , WSDAT
        , KURST
        , VARNR
        , KWAER
        , CTYP1
        , CTYP2
        , CTYP3
        , CTYP4
        , AWTYP
        , AWORG
        , LOGSYSTEM
        , CPUTM
        , ALEBZ
        , ALEBN
        , AWSYS
        , AWREF_REV
        , AWORG_REV
        , VALDT
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
        ))  as LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
             COALESCE(NULLIF(TRIM(CAST(CONTROLLING_LEDGER_HEADER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                CONTROLLING_LEDGER_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
              COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                CONTROLLING_AREA_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
              COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(CONTROLLING_LEDGER_HEADER_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                CONTROLLING_HEADER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(BELNR::text), '^^') 
            , '||', IFNULL(TRIM(GJAHR::text), '^^') 
            , '||', IFNULL(TRIM(VERSN::text), '^^') 
            , '||', IFNULL(TRIM(VRGNG::text), '^^') 
            , '||', IFNULL(TRIM(TIMESTMP::text), '^^') 
            , '||', IFNULL(TRIM(PERAB::text), '^^') 
            , '||', IFNULL(TRIM(PERBI::text), '^^') 
            , '||', IFNULL(TRIM(BLDAT::text), '^^') 
            , '||', IFNULL(TRIM(BUDAT::text), '^^') 
            , '||', IFNULL(TRIM(CPUDT::text), '^^') 
            , '||', IFNULL(TRIM(USNAM::text), '^^') 
            , '||', IFNULL(TRIM(BLTXT::text), '^^') 
            , '||', IFNULL(TRIM(STFLG::text), '^^') 
            , '||', IFNULL(TRIM(STOKZ::text), '^^') 
            , '||', IFNULL(TRIM(REFBT::text), '^^') 
            , '||', IFNULL(TRIM(REFBN::text), '^^') 
            , '||', IFNULL(TRIM(REFBK::text), '^^') 
            , '||', IFNULL(TRIM(REFGJ::text), '^^') 
            , '||', IFNULL(TRIM(BLART::text), '^^') 
            , '||', IFNULL(TRIM(ORGVG::text), '^^') 
            , '||', IFNULL(TRIM(SUMBZ::text), '^^') 
            , '||', IFNULL(TRIM(DELBZ::text), '^^') 
            , '||', IFNULL(TRIM(WSDAT::text), '^^') 
            , '||', IFNULL(TRIM(KURST::text), '^^') 
            , '||', IFNULL(TRIM(VARNR::text), '^^') 
            , '||', IFNULL(TRIM(KWAER::text), '^^') 
            , '||', IFNULL(TRIM(CTYP1::text), '^^') 
            , '||', IFNULL(TRIM(CTYP2::text), '^^') 
            , '||', IFNULL(TRIM(CTYP3::text), '^^') 
            , '||', IFNULL(TRIM(CTYP4::text), '^^') 
            , '||', IFNULL(TRIM(AWTYP::text), '^^') 
            , '||', IFNULL(TRIM(AWORG::text), '^^') 
            , '||', IFNULL(TRIM(LOGSYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(CPUTM::text), '^^') 
            , '||', IFNULL(TRIM(ALEBZ::text), '^^') 
            , '||', IFNULL(TRIM(ALEBN::text), '^^') 
            , '||', IFNULL(TRIM(AWSYS::text), '^^') 
            , '||', IFNULL(TRIM(AWREF_REV::text), '^^') 
            , '||', IFNULL(TRIM(AWORG_REV::text), '^^') 
            , '||', IFNULL(TRIM(VALDT::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

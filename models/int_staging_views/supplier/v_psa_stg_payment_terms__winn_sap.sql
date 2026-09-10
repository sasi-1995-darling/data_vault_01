---- SRC LAYER ----
WITH
SRC_S              as ( SELECT F_OBSOLETE, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, KOART, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, TXN08, XCHPB, XCHPM, XSCRC, XSPLT, XZBRV, ZDART, ZFAEL, ZLSCH, ZMONA, ZPRZ1, ZPRZ2, ZSCHF, ZSMN1, ZSMN2, ZSMN3, ZSTG1, ZSTG2, ZSTG3, ZTAG1, ZTAG2, ZTAG3, ZTAGG, ZTERM FROM {{ source('sap_ecc_prd', 'z_t052') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_t052 )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        ZTERM                                                        as                                    PAYMENT_TERM_BK
      , ZTERM
      , MANDT
      , ZTAGG
      , GLREQUEST
      , ZDART
      , ZFAEL
      , ZMONA
      , ZTAG1
      , ZPRZ1
      , ZTAG2
      , ZPRZ2
      , ZTAG3
      , ZSTG1
      , ZSMN1
      , ZSTG2
      , ZSMN2
      , ZSTG3
      , ZSMN3
      , XZBRV
      , ZSCHF
      , XCHPB
      , TXN08
      , ZLSCH
      , XCHPM
      , KOART
      , XSPLT
      , XSCRC
      , F_OBSOLETE
      , GLDELFLAG
      , GLCHANGETIME
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        ))                                                           as                                  GLCHANGETIME_DTTM
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y',PSA_LOAD_DTS,GLCHANGETIME_DTTM)) as                                           LOAD_DTS
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        PAYMENT_TERM_BK
      , ZTERM
      , MANDT
      , ZTAGG
      , GLREQUEST
      , ZDART
      , ZFAEL
      , ZMONA
      , ZTAG1
      , ZPRZ1
      , ZTAG2
      , ZPRZ2
      , ZTAG3
      , ZSTG1
      , ZSMN1
      , ZSTG2
      , ZSMN2
      , ZSTG3
      , ZSMN3
      , XZBRV
      , ZSCHF
      , XCHPB
      , TXN08
      , ZLSCH
      , XCHPM
      , KOART
      , XSPLT
      , XSCRC
      , F_OBSOLETE
      , GLDELFLAG
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        BKCC
      , REC_SRC
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T052'
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
          PAYMENT_TERM_BK
        , ZTERM
        , MANDT
        , ZTAGG
        , GLREQUEST
        , ZDART
        , ZFAEL
        , ZMONA
        , ZTAG1
        , ZPRZ1
        , ZTAG2
        , ZPRZ2
        , ZTAG3
        , ZSTG1
        , ZSMN1
        , ZSTG2
        , ZSMN2
        , ZSTG3
        , ZSMN3
        , XZBRV
        , ZSCHF
        , XCHPB
        , TXN08
        , ZLSCH
        , XCHPM
        , KOART
        , XSPLT
        , XSCRC
        , F_OBSOLETE
        , GLDELFLAG
        , GLCHANGETIME
        , GLCHANGETIME_DTTM
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ZTERM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(ZTAGG::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(ZDART::text), '^^') 
            , '||', IFNULL(TRIM(ZFAEL::text), '^^') 
            , '||', IFNULL(TRIM(ZMONA::text), '^^') 
            , '||', IFNULL(TRIM(ZTAG1::text), '^^') 
            , '||', IFNULL(TRIM(ZPRZ1::text), '^^') 
            , '||', IFNULL(TRIM(ZTAG2::text), '^^') 
            , '||', IFNULL(TRIM(ZPRZ2::text), '^^') 
            , '||', IFNULL(TRIM(ZTAG3::text), '^^') 
            , '||', IFNULL(TRIM(ZSTG1::text), '^^') 
            , '||', IFNULL(TRIM(ZSMN1::text), '^^') 
            , '||', IFNULL(TRIM(ZSTG2::text), '^^') 
            , '||', IFNULL(TRIM(ZSMN2::text), '^^') 
            , '||', IFNULL(TRIM(ZSTG3::text), '^^') 
            , '||', IFNULL(TRIM(ZSMN3::text), '^^') 
            , '||', IFNULL(TRIM(XZBRV::text), '^^') 
            , '||', IFNULL(TRIM(ZSCHF::text), '^^') 
            , '||', IFNULL(TRIM(XCHPB::text), '^^') 
            , '||', IFNULL(TRIM(TXN08::text), '^^') 
            , '||', IFNULL(TRIM(ZLSCH::text), '^^') 
            , '||', IFNULL(TRIM(XCHPM::text), '^^') 
            , '||', IFNULL(TRIM(KOART::text), '^^') 
            , '||', IFNULL(TRIM(XSPLT::text), '^^') 
            , '||', IFNULL(TRIM(XSCRC::text), '^^') 
            , '||', IFNULL(TRIM(F_OBSOLETE::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

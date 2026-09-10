---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_qmih') }} as SRC  ),
SRC_b              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM SAP_ECC_PRD.Z_QMIH )
, SRC_b              as ( SELECT * FROM RAW_VAULT.REF_BUSINESS_KEY_COLLISION )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(MANDT as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(QMNUM as VARCHAR)),''), '^^')
        )))                                                          as                                  QUALITY_EXCEPT_BK
      , MANDT
      , QMNUM
      , GLREQUEST
      , IWERK
      , ILOAN
      , ILOAI
      , EQUNR
      , BAUTL
      , EBORT
      , MSAUS
      , AUSVN
      , AUSBS
      , AUZTV
      , AUZTB
      , AUSZT
      , MAUEH
      , BTPLN
      , BEQUI
      , AUSWK
      , VERFV
      , VERFN
      , VERFM
      , ANLZV
      , ANLZN
      , ANLZE
      , INSPK
      , DATAN
      , INGRP
      , WARPL
      , ABNUM
      , WAPOS
      , KDAUF
      , KDPOS
      , SCREENTY
      , PLNTY
      , PLNNR
      , PLNAL
      , REVNR
      , ZAEHL
      , PAMS_PTSTF
      , PAMS_PTSTT
      , PAMS_ATSTF
      , PAMS_ATSTT
      , PAMS_POOL
      , PAMS_KOSTL
      , PAMS_AUFNR
      , PAMS_PROID
      , PAMS_KOKRS
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        ))                                                           as                                           LOAD_DTS
    FROM SRC_a
)

, LOGIC_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        QUALITY_EXCEPT_BK
      , MANDT
      , QMNUM
      , GLREQUEST
      , IWERK
      , ILOAN
      , ILOAI
      , EQUNR
      , BAUTL
      , EBORT
      , MSAUS
      , AUSVN
      , AUSBS
      , AUZTV
      , AUZTB
      , AUSZT
      , MAUEH
      , BTPLN
      , BEQUI
      , AUSWK
      , VERFV
      , VERFN
      , VERFM
      , ANLZV
      , ANLZN
      , ANLZE
      , INSPK
      , DATAN
      , INGRP
      , WARPL
      , ABNUM
      , WAPOS
      , KDAUF
      , KDPOS
      , SCREENTY
      , PLNTY
      , PLNNR
      , PLNAL
      , REVNR
      , ZAEHL
      , PAMS_PTSTF
      , PAMS_PTSTT
      , PAMS_ATSTF
      , PAMS_ATSTT
      , PAMS_POOL
      , PAMS_KOSTL
      , PAMS_AUFNR
      , PAMS_PROID
      , PAMS_KOKRS
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , LOAD_DTS
    FROM LOGIC_a
)

, RENAME_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_b as (
    SELECT *
    FROM RENAME_b
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_QMIH'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_b
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          QUALITY_EXCEPT_BK
        , MANDT
        , QMNUM
        , GLREQUEST
        , IWERK
        , ILOAN
        , ILOAI
        , EQUNR
        , BAUTL
        , EBORT
        , MSAUS
        , AUSVN
        , AUSBS
        , AUZTV
        , AUZTB
        , AUSZT
        , MAUEH
        , BTPLN
        , BEQUI
        , AUSWK
        , VERFV
        , VERFN
        , VERFM
        , ANLZV
        , ANLZN
        , ANLZE
        , INSPK
        , DATAN
        , INGRP
        , WARPL
        , ABNUM
        , WAPOS
        , KDAUF
        , KDPOS
        , SCREENTY
        , PLNTY
        , PLNNR
        , PLNAL
        , REVNR
        , ZAEHL
        , PAMS_PTSTF
        , PAMS_PTSTT
        , PAMS_ATSTF
        , PAMS_ATSTT
        , PAMS_POOL
        , PAMS_KOSTL
        , PAMS_AUFNR
        , PAMS_PROID
        , PAMS_KOKRS
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , LOAD_DTS
        , REC_SRC
        , 'FB WINN'                                                    as BRAND
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MANDT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(QMNUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as QUALITY_EXCEPT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(QMNUM::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(IWERK::text), '^^') 
            , '||', IFNULL(TRIM(ILOAN::text), '^^') 
            , '||', IFNULL(TRIM(ILOAI::text), '^^') 
            , '||', IFNULL(TRIM(EQUNR::text), '^^') 
            , '||', IFNULL(TRIM(BAUTL::text), '^^') 
            , '||', IFNULL(TRIM(EBORT::text), '^^') 
            , '||', IFNULL(TRIM(MSAUS::text), '^^') 
            , '||', IFNULL(TRIM(AUSVN::text), '^^') 
            , '||', IFNULL(TRIM(AUSBS::text), '^^') 
            , '||', IFNULL(TRIM(AUZTV::text), '^^') 
            , '||', IFNULL(TRIM(AUZTB::text), '^^') 
            , '||', IFNULL(TRIM(AUSZT::text), '^^') 
            , '||', IFNULL(TRIM(MAUEH::text), '^^') 
            , '||', IFNULL(TRIM(BTPLN::text), '^^') 
            , '||', IFNULL(TRIM(BEQUI::text), '^^') 
            , '||', IFNULL(TRIM(AUSWK::text), '^^') 
            , '||', IFNULL(TRIM(VERFV::text), '^^') 
            , '||', IFNULL(TRIM(VERFN::text), '^^') 
            , '||', IFNULL(TRIM(VERFM::text), '^^') 
            , '||', IFNULL(TRIM(ANLZV::text), '^^') 
            , '||', IFNULL(TRIM(ANLZN::text), '^^') 
            , '||', IFNULL(TRIM(ANLZE::text), '^^') 
            , '||', IFNULL(TRIM(INSPK::text), '^^') 
            , '||', IFNULL(TRIM(DATAN::text), '^^') 
            , '||', IFNULL(TRIM(INGRP::text), '^^') 
            , '||', IFNULL(TRIM(WARPL::text), '^^') 
            , '||', IFNULL(TRIM(ABNUM::text), '^^') 
            , '||', IFNULL(TRIM(WAPOS::text), '^^') 
            , '||', IFNULL(TRIM(KDAUF::text), '^^') 
            , '||', IFNULL(TRIM(KDPOS::text), '^^') 
            , '||', IFNULL(TRIM(SCREENTY::text), '^^') 
            , '||', IFNULL(TRIM(PLNTY::text), '^^') 
            , '||', IFNULL(TRIM(PLNNR::text), '^^') 
            , '||', IFNULL(TRIM(PLNAL::text), '^^') 
            , '||', IFNULL(TRIM(REVNR::text), '^^') 
            , '||', IFNULL(TRIM(ZAEHL::text), '^^') 
            , '||', IFNULL(TRIM(PAMS_PTSTF::text), '^^') 
            , '||', IFNULL(TRIM(PAMS_PTSTT::text), '^^') 
            , '||', IFNULL(TRIM(PAMS_ATSTF::text), '^^') 
            , '||', IFNULL(TRIM(PAMS_ATSTT::text), '^^') 
            , '||', IFNULL(TRIM(PAMS_POOL::text), '^^') 
            , '||', IFNULL(TRIM(PAMS_KOSTL::text), '^^') 
            , '||', IFNULL(TRIM(PAMS_AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(PAMS_PROID::text), '^^') 
            , '||', IFNULL(TRIM(PAMS_KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLCHANGETIME::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

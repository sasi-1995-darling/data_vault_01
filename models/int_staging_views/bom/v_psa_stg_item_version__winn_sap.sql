---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_mkal') }} as SRC  ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_mkal )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        WERKS                                                        as                                           PLANT_BK
      , MATNR                                                        as                                            ITEM_BK
      , MANDT
      , MATNR
      , WERKS
      , VERID
      , GLREQUEST
      , GLSOURCESYSTEM
      , BDATU
      , ADATU
      , STLAL
      , STLAN
      , PLNTY
      , PLNNR
      , ALNAL
      , BESKZ
      , SOBSL
      , LOSGR
      , MDV01
      , MDV02
      , TEXT1
      , EWAHR
      , VERTO
      , SERKZ
      , BSTMI
      , BSTMA
      , RGEKZ
      , ALORT
      , PLTYG
      , PLNNG
      , ALNAG
      , PLTYM
      , PLNNM
      , ALNAM
      , CSPLT
      , MATKO
      , ELPRO
      , PRVBE
      , PRFG_F
      , PRDAT
      , MKSP
      , PRFG_R
      , PRFG_G
      , PRFG_S
      , UCMAT
      , PPEGUID
      , GLDELFLAG
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
        ))                                                          as                                           LOAD_DTS
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
      , ITEM_BK
      , MANDT
      , MATNR
      , WERKS
      , VERID
      , GLREQUEST
      , GLSOURCESYSTEM
      , BDATU
      , ADATU
      , STLAL
      , STLAN
      , PLNTY
      , PLNNR
      , ALNAL
      , BESKZ
      , SOBSL
      , LOSGR
      , MDV01
      , MDV02
      , TEXT1
      , EWAHR
      , VERTO
      , SERKZ
      , BSTMI
      , BSTMA
      , RGEKZ
      , ALORT
      , PLTYG
      , PLNNG
      , ALNAG
      , PLTYM
      , PLNNM
      , ALNAM
      , CSPLT
      , MATKO
      , ELPRO
      , PRVBE
      , PRFG_F
      , PRDAT
      , MKSP
      , PRFG_R
      , PRFG_G
      , PRFG_S
      , UCMAT
      , PPEGUID
      , GLDELFLAG
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_MKAL'
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
          PLANT_BK
        , ITEM_BK
        , MANDT
        , MATNR
        , WERKS
        , VERID
        , GLREQUEST
        , GLSOURCESYSTEM
        , BDATU
        , ADATU
        , STLAL
        , STLAN
        , PLNTY
        , PLNNR
        , ALNAL
        , BESKZ
        , SOBSL
        , LOSGR
        , MDV01
        , MDV02
        , TEXT1
        , EWAHR
        , VERTO
        , SERKZ
        , BSTMI
        , BSTMA
        , RGEKZ
        , ALORT
        , PLTYG
        , PLNNG
        , ALNAG
        , PLTYM
        , PLNNM
        , ALNAM
        , CSPLT
        , MATKO
        , ELPRO
        , PRVBE
        , PRFG_F
        , PRDAT
        , MKSP
        , PRFG_R
        , PRFG_G
        , PRFG_S
        , UCMAT
        , PPEGUID
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(VERID::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(BDATU::text), '^^') 
            , '||', IFNULL(TRIM(ADATU::text), '^^') 
            , '||', IFNULL(TRIM(STLAL::text), '^^') 
            , '||', IFNULL(TRIM(STLAN::text), '^^') 
            , '||', IFNULL(TRIM(PLNTY::text), '^^') 
            , '||', IFNULL(TRIM(PLNNR::text), '^^') 
            , '||', IFNULL(TRIM(ALNAL::text), '^^') 
            , '||', IFNULL(TRIM(BESKZ::text), '^^') 
            , '||', IFNULL(TRIM(SOBSL::text), '^^') 
            , '||', IFNULL(TRIM(LOSGR::text), '^^') 
            , '||', IFNULL(TRIM(MDV01::text), '^^') 
            , '||', IFNULL(TRIM(MDV02::text), '^^') 
            , '||', IFNULL(TRIM(TEXT1::text), '^^') 
            , '||', IFNULL(TRIM(EWAHR::text), '^^') 
            , '||', IFNULL(TRIM(VERTO::text), '^^') 
            , '||', IFNULL(TRIM(SERKZ::text), '^^') 
            , '||', IFNULL(TRIM(BSTMI::text), '^^') 
            , '||', IFNULL(TRIM(BSTMA::text), '^^') 
            , '||', IFNULL(TRIM(RGEKZ::text), '^^') 
            , '||', IFNULL(TRIM(ALORT::text), '^^') 
            , '||', IFNULL(TRIM(PLTYG::text), '^^') 
            , '||', IFNULL(TRIM(PLNNG::text), '^^') 
            , '||', IFNULL(TRIM(ALNAG::text), '^^') 
            , '||', IFNULL(TRIM(PLTYM::text), '^^') 
            , '||', IFNULL(TRIM(PLNNM::text), '^^') 
            , '||', IFNULL(TRIM(ALNAM::text), '^^') 
            , '||', IFNULL(TRIM(CSPLT::text), '^^') 
            , '||', IFNULL(TRIM(MATKO::text), '^^') 
            , '||', IFNULL(TRIM(ELPRO::text), '^^') 
            , '||', IFNULL(TRIM(PRVBE::text), '^^') 
            , '||', IFNULL(TRIM(PRFG_F::text), '^^') 
            , '||', IFNULL(TRIM(PRDAT::text), '^^') 
            , '||', IFNULL(TRIM(MKSP::text), '^^') 
            , '||', IFNULL(TRIM(PRFG_R::text), '^^') 
            , '||', IFNULL(TRIM(PRFG_G::text), '^^') 
            , '||', IFNULL(TRIM(PRFG_S::text), '^^') 
            , '||', IFNULL(TRIM(UCMAT::text), '^^') 
            , '||', IFNULL(TRIM(PPEGUID::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

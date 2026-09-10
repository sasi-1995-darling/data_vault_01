---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ALTME, ANZSN, BESTQ, CHARG, CUOBJ, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, HU_LGORT, KZBEI, LGORT, MANDT, MATNR, POSNR, POSNR_GEN, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSTYV, P_MATERIAL, QPLOS, SERAIL, SGT_SCAT, SOBKZ, SONUM, SPE_IDPLATE, UNVEL, VBELN, VBTYP, VEANZ, VELIN, VEMEH, VEMNG, VEMNG_FLO, VENUM, VEPOS, VFDAT, WDATU, WERKS, WRF_CHARSTC1, WRF_CHARSTC2, WRF_CHARSTC3, XCHAR FROM {{ source('sap_ecc_prd', 'z_vepo') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM SAP_ECC_PRD.Z_VEPO )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        VENUM                                                        as                                   HANDLING_UNIT_BK
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , MANDT
      , VENUM
      , VEPOS
      , GLREQUEST
      , GLSOURCESYSTEM
      , VELIN
      , VBELN
      , POSNR
      , VBTYP
      , UNVEL
      , VEMNG
      , VEMNG_FLO
      , VEMEH
      , ALTME
      , VEANZ
      , KZBEI
      , MATNR
      , CHARG
      , WERKS
      , LGORT
      , CUOBJ
      , BESTQ
      , SOBKZ
      , SONUM
      , QPLOS
      , ANZSN
      , SERAIL
      , PSTYV
      , POSNR_GEN
      , P_MATERIAL
      , WDATU
      , VFDAT
      , HU_LGORT
      , XCHAR
      , SPE_IDPLATE
      , SGT_SCAT
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_D1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_D1 as (
    SELECT
        HANDLING_UNIT_BK
      , LOAD_DTS
      , MANDT
      , VENUM
      , VEPOS
      , GLREQUEST
      , GLSOURCESYSTEM
      , VELIN
      , VBELN
      , POSNR
      , VBTYP
      , UNVEL
      , VEMNG
      , VEMNG_FLO
      , VEMEH
      , ALTME
      , VEANZ
      , KZBEI
      , MATNR
      , CHARG
      , WERKS
      , LGORT
      , CUOBJ
      , BESTQ
      , SOBKZ
      , SONUM
      , QPLOS
      , ANZSN
      , SERAIL
      , PSTYV
      , POSNR_GEN
      , P_MATERIAL
      , WDATU
      , VFDAT
      , HU_LGORT
      , XCHAR
      , SPE_IDPLATE
      , SGT_SCAT
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_D1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_D1 as (
    SELECT *
    FROM RENAME_D1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.SAP_ECC_PRD.Z_VEPO'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          HANDLING_UNIT_BK
        , LOAD_DTS
        , MANDT
        , VENUM
        , VEPOS
        , GLREQUEST
        , GLSOURCESYSTEM
        , VELIN
        , VBELN
        , POSNR
        , VBTYP
        , UNVEL
        , VEMNG
        , VEMNG_FLO
        , VEMEH
        , ALTME
        , VEANZ
        , KZBEI
        , MATNR
        , CHARG
        , WERKS
        , LGORT
        , CUOBJ
        , BESTQ
        , SOBKZ
        , SONUM
        , QPLOS
        , ANZSN
        , SERAIL
        , PSTYV
        , POSNR_GEN
        , P_MATERIAL
        , WDATU
        , VFDAT
        , HU_LGORT
        , XCHAR
        , SPE_IDPLATE
        , SGT_SCAT
        , WRF_CHARSTC1
        , WRF_CHARSTC2
        , WRF_CHARSTC3
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(HANDLING_UNIT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as HANDLING_UNIT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DELIVERY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DELIVERY_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VEPOS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_HANDLING_UNIT_CONTENT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VEPOS::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(VELIN::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(VBTYP::text), '^^') 
            , '||', IFNULL(TRIM(UNVEL::text), '^^') 
            , '||', IFNULL(TRIM(VEMNG::text), '^^') 
            , '||', IFNULL(TRIM(VEMNG_FLO::text), '^^') 
            , '||', IFNULL(TRIM(VEMEH::text), '^^') 
            , '||', IFNULL(TRIM(ALTME::text), '^^') 
            , '||', IFNULL(TRIM(VEANZ::text), '^^') 
            , '||', IFNULL(TRIM(KZBEI::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(CHARG::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(LGORT::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ::text), '^^') 
            , '||', IFNULL(TRIM(BESTQ::text), '^^') 
            , '||', IFNULL(TRIM(SOBKZ::text), '^^') 
            , '||', IFNULL(TRIM(SONUM::text), '^^') 
            , '||', IFNULL(TRIM(QPLOS::text), '^^') 
            , '||', IFNULL(TRIM(ANZSN::text), '^^') 
            , '||', IFNULL(TRIM(SERAIL::text), '^^') 
            , '||', IFNULL(TRIM(PSTYV::text), '^^') 
            , '||', IFNULL(TRIM(POSNR_GEN::text), '^^') 
            , '||', IFNULL(TRIM(P_MATERIAL::text), '^^') 
            , '||', IFNULL(TRIM(WDATU::text), '^^') 
            , '||', IFNULL(TRIM(VFDAT::text), '^^') 
            , '||', IFNULL(TRIM(HU_LGORT::text), '^^') 
            , '||', IFNULL(TRIM(XCHAR::text), '^^') 
            , '||', IFNULL(TRIM(SPE_IDPLATE::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SCAT::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC1::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC2::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC3::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLCHANGETIME::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

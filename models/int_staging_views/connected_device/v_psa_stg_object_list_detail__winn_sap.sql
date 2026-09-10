---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT BAUTL, BEARB, DATUM, EQSNR, EQUNR, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, IHNUM, ILOAN, MANDT, MATNR, OBJVW, OBKNR, OBZAE, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SERNR, SORTF, TASER, UII FROM {{ source('sap_ecc_prd', 'z_objk') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM SAP_ECC_PRD.Z_OBJK )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        OBKNR                                                        as                                     OBJECT_LIST_BK
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , MANDT
      , OBKNR
      , OBZAE
      , GLREQUEST
      , GLSOURCESYSTEM
      , EQUNR
      , IHNUM
      , BAUTL
      , ILOAN
      , SORTF
      , BEARB
      , OBJVW
      , SERNR
      , MATNR
      , DATUM
      , EQSNR
      , TASER
      , UII
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
        OBJECT_LIST_BK
      , LOAD_DTS
      , MANDT
      , OBKNR
      , OBZAE
      , GLREQUEST
      , GLSOURCESYSTEM
      , EQUNR
      , IHNUM
      , BAUTL
      , ILOAN
      , SORTF
      , BEARB
      , OBJVW
      , SERNR
      , MATNR
      , DATUM
      , EQSNR
      , TASER
      , UII
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
    WHERE rec_src = 'US.SAP_ECC_PRD.Z_OBJK'
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
          OBJECT_LIST_BK
        , LOAD_DTS
        , MANDT
        , OBKNR
        , OBZAE
        , GLREQUEST
        , GLSOURCESYSTEM
        , EQUNR
        , IHNUM
        , BAUTL
        , ILOAN
        , SORTF
        , BEARB
        , OBJVW
        , SERNR
        , MATNR
        , DATUM
        , EQSNR
        , TASER
        , UII
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(OBJECT_LIST_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as OBJECT_LIST_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EQUNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as EQUIPMENT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(OBKNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(OBZAE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(EQUNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_OBJECT_LIST_DETAIL_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(OBZAE::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(EQUNR::text), '^^') 
            , '||', IFNULL(TRIM(IHNUM::text), '^^') 
            , '||', IFNULL(TRIM(BAUTL::text), '^^') 
            , '||', IFNULL(TRIM(ILOAN::text), '^^') 
            , '||', IFNULL(TRIM(SORTF::text), '^^') 
            , '||', IFNULL(TRIM(BEARB::text), '^^') 
            , '||', IFNULL(TRIM(OBJVW::text), '^^') 
            , '||', IFNULL(TRIM(SERNR::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(DATUM::text), '^^') 
            , '||', IFNULL(TRIM(EQSNR::text), '^^') 
            , '||', IFNULL(TRIM(TASER::text), '^^') 
            , '||', IFNULL(TRIM(UII::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLCHANGETIME::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

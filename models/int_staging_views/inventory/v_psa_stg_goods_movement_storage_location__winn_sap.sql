---- SRC LAYER ----
WITH
SRC_a              as ( SELECT DISKZ, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, KUNNR, LGOBE, LGORT, LIFNR, MANDT, MESBS, MESST, OIB_TNKASSIGN, OIG_ITRFL, OIH_LICNO, PARLG, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SPART, VKORG, VSTEL, VTWEG, WERKS, XBLGO, XBUFX, XHUPF, XLONG, XRESS FROM {{ source('sap_ecc_prd', 'z_t001l') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_t001l )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        LGORT                                                        as                      GOODS_STORAGE_LOCATION_BK
      , WERKS                                                        as                                           PLANT_BK
      , coalesce(nullif(trim(VKORG), ''), '-1')                                                      as                         SALES_ORGANIZATION_BK
      , coalesce(nullif(trim(VTWEG), ''), '-1')                                                      as                            DISTRIBUTION_CHANNEL_BK
      , coalesce(nullif(trim(LIFNR), ''), '-1')                                                      as                           SUPPLIER_BK
      , MANDT
      , WERKS
      , LGORT
      , GLREQUEST
      , GLSOURCESYSTEM
      , LGOBE
      , SPART
      , XLONG
      , XBUFX
      , DISKZ
      , XBLGO
      , XRESS
      , XHUPF
      , PARLG
      , VKORG
      , VTWEG
      , VSTEL
      , LIFNR
      , KUNNR
      , MESBS
      , MESST
      , OIH_LICNO
      , OIG_ITRFL
      , OIB_TNKASSIGN
      , GLDELFLAG
      , GLCHANGETIME
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
        GOODS_STORAGE_LOCATION_BK
      , PLANT_BK
      , SALES_ORGANIZATION_BK
      , DISTRIBUTION_CHANNEL_BK
      , SUPPLIER_BK
      , MANDT
      , WERKS
      , LGORT
      , GLREQUEST
      , GLSOURCESYSTEM
      , LGOBE
      , SPART
      , XLONG
      , XBUFX
      , DISKZ
      , XBLGO
      , XRESS
      , XHUPF
      , PARLG
      , VKORG
      , VTWEG
      , VSTEL
      , LIFNR
      , KUNNR
      , MESBS
      , MESST
      , OIH_LICNO
      , OIG_ITRFL
      , OIB_TNKASSIGN
      , GLDELFLAG
      , GLCHANGETIME
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T001L' 
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
          GOODS_STORAGE_LOCATION_BK
        , PLANT_BK
        , SALES_ORGANIZATION_BK
        , DISTRIBUTION_CHANNEL_BK
        , SUPPLIER_BK
        , MANDT
        , WERKS
        , LGORT
        , GLREQUEST
        , GLSOURCESYSTEM
        , LGOBE
        , XLONG
        , XBUFX
        , DISKZ
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
      )) as LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LGORT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VKORG as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VTWEG as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_PLANT_GOODS_STORAGE_LOCATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LGORT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as GOODS_STORAGE_LOCATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VKORG as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SALES_ORGANIZATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VTWEG as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DISTRIBUTION_CHANNEL_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SUPPLIER_BK as VARCHAR)),''), '^^') 
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(LGOBE::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(XLONG::text), '^^') 
            , '||', IFNULL(TRIM(XBUFX::text), '^^') 
            , '||', IFNULL(TRIM(DISKZ::text), '^^') 
            , '||', IFNULL(TRIM(XBLGO::text), '^^') 
            , '||', IFNULL(TRIM(XRESS::text), '^^') 
            , '||', IFNULL(TRIM(XHUPF::text), '^^') 
            , '||', IFNULL(TRIM(PARLG::text), '^^') 
            , '||', IFNULL(TRIM(VKORG::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG::text), '^^') 
            , '||', IFNULL(TRIM(VSTEL::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(MESBS::text), '^^') 
            , '||', IFNULL(TRIM(MESST::text), '^^') 
            , '||', IFNULL(TRIM(OIH_LICNO::text), '^^') 
            , '||', IFNULL(TRIM(OIG_ITRFL::text), '^^') 
            , '||', IFNULL(TRIM(OIB_TNKASSIGN::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

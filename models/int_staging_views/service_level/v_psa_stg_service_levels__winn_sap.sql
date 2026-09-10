---- SRC LAYER ----
WITH
SRC_zservlevel     as ( SELECT ERDAT, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, KODAT_IST, KUNNR, KWMENG, LFIMG, LGORT, MANDT, MATNR, MEINS, MULTONTIME, 
                        NETPR, NETWR, ONT_PIKMG, ORDEVALDT, PERFECTORDER, PIKMG, PNETWR, POSNR, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSTYV, SNETWR, 
                        SPART, VBELN, VKORG, VSTEL, VTWEG, WADAT, WADAT_IST, WAERK, WERKS, ZFILLDIFF, ZLINEFILL, ZONTIME, ZONTIMEDIFF, ZPLINEFILL, ZPONTIME, 
                        ZRELEASED, ZSERVCODE, ZSERVTYPE, ZZENDSHPDTE, ZZGRACE FROM {{ source('sap_ecc_prd', 'z_zservlevel') }} as SRC 
                        WHERE ERDAT::INTEGER >= 20230101 /*This filter is to limit excess data from pre-2023 from entering stage and to optimize downstream objects*/  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_zservlevel     as ( SELECT * FROM sap_ecc_prd.z_zservlevel )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_zservlevel as (
    SELECT
        COALESCE(NULLIF(TRIM(MATNR),''),'-1')                        as                                            ITEM_BK
      , COALESCE(NULLIF(TRIM(WERKS),''),'-1')                        as                                           PLANT_BK
      , KUNNR                                                        as                                        CUSTOMER_BK
      , VKORG                                                        as                              SALES_ORGANIZATION_BK
      , VTWEG                                                        as                            DISTRIBUTION_CHANNEL_BK
      , SPART                                                        as                                        DIVISION_BK
      , COALESCE(NULLIF(TRIM(LGORT),''),'-1')                        as                          GOODS_STORAGE_LOCATION_BK
      , VBELN                                                        as                                    ORDER_HEADER_BK
      , CONCAT_WS('||', COALESCE(VBELN, ''), COALESCE(POSNR, ''))    as                                      ORDER_LINE_BK
      , MANDT
      , ERDAT
      , VBELN
      , POSNR
      , KUNNR
      , VKORG
      , VTWEG
      , SPART
      , ZSERVCODE
      , GLREQUEST
      , ZSERVTYPE
      , WERKS
      , LGORT
      , MATNR
      , NETPR
      , WADAT
      , WADAT_IST
      , KWMENG
      , LFIMG
      , NETWR
      , SNETWR
      , ZLINEFILL
      , ZONTIME
      , ZRELEASED
      , WAERK
      , PSTYV
      , MEINS
      , PERFECTORDER
      , ORDEVALDT
      , MULTONTIME
      , VSTEL
      , ONT_PIKMG
      , KODAT_IST
      , PIKMG
      , PNETWR
      , ZPLINEFILL
      , ZPONTIME
      , ZFILLDIFF
      , ZONTIMEDIFF
      , ZZENDSHPDTE
      , ZZGRACE
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
        ))                                                           as                                           LOAD_DTS
    FROM SRC_zservlevel
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_zservlevel as (
    SELECT
        ITEM_BK
      , PLANT_BK
      , CUSTOMER_BK
      , SALES_ORGANIZATION_BK
      , DISTRIBUTION_CHANNEL_BK
      , DIVISION_BK
      , GOODS_STORAGE_LOCATION_BK
      , ORDER_HEADER_BK
      , ORDER_LINE_BK
      , MANDT
      , ERDAT
      , VBELN
      , POSNR
      , KUNNR
      , VKORG
      , VTWEG
      , SPART
      , ZSERVCODE
      , GLREQUEST
      , ZSERVTYPE
      , WERKS
      , LGORT
      , MATNR
      , NETPR
      , WADAT
      , WADAT_IST
      , KWMENG
      , LFIMG
      , NETWR
      , SNETWR
      , ZLINEFILL
      , ZONTIME
      , ZRELEASED
      , WAERK
      , PSTYV
      , MEINS
      , PERFECTORDER
      , ORDEVALDT
      , MULTONTIME
      , VSTEL
      , ONT_PIKMG
      , KODAT_IST
      , PIKMG
      , PNETWR
      , ZPLINEFILL
      , ZPONTIME
      , ZFILLDIFF
      , ZONTIMEDIFF
      , ZZENDSHPDTE
      , ZZGRACE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_zservlevel
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_zservlevel as (
    SELECT *
    FROM RENAME_zservlevel
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_ZSERVLEVEL'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_zservlevel
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ITEM_BK
        , PLANT_BK
        , CUSTOMER_BK
        , SALES_ORGANIZATION_BK
        , DISTRIBUTION_CHANNEL_BK
        , DIVISION_BK
        , GOODS_STORAGE_LOCATION_BK
        , ORDER_HEADER_BK
        , ORDER_LINE_BK
        , MANDT
        , ERDAT
        , TRY_TO_DATE(ERDAT, 'YYYYMMDD')                               as ERDAT_DT
        , VBELN
        , POSNR
        , KUNNR
        , VKORG
        , VTWEG
        , SPART
        , ZSERVCODE
        , GLREQUEST
        , ZSERVTYPE
        , WERKS
        , LGORT
        , MATNR
        , NETPR
        , WADAT
        , TRY_TO_DATE(WADAT, 'YYYYMMDD')                               as WADAT_DT
        , WADAT_IST
        , TRY_TO_DATE(WADAT_IST, 'YYYYMMDD')                           as WADAT_IST_DT
        , KWMENG
        , LFIMG
        , NETWR
        , SNETWR
        , ZLINEFILL
        , ZONTIME
        , ZRELEASED
        , WAERK
        , PSTYV
        , MEINS
        , PERFECTORDER
        , ORDEVALDT
        , TRY_TO_DATE(ORDEVALDT, 'YYYYMMDD')                           as ORDEVALDT_DT
        , MULTONTIME
        , VSTEL
        , ONT_PIKMG
        , KODAT_IST
        , TRY_TO_DATE(KODAT_IST, 'YYYYMMDD')                           as KODAT_IST_DT
        , PIKMG
        , PNETWR
        , ZPLINEFILL
        , ZPONTIME
        , ZFILLDIFF
        , ZONTIMEDIFF
        , ZZENDSHPDTE
        , ZZGRACE
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
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SALES_ORGANIZATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DISTRIBUTION_CHANNEL_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DIVISION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(GOODS_STORAGE_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as GOODS_STORAGE_LOCATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ZSERVCODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(GOODS_STORAGE_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SERVICE_LEVELS_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_CUSTOMER_SALES_ORGANIZATION_DISTRIBUTION_CHANNEL_DIVISION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(VKORG::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(ZSERVCODE::text), '^^') 
            , '||', IFNULL(TRIM(ZSERVTYPE::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(LGORT::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(NETPR::text), '^^') 
            , '||', IFNULL(TRIM(WADAT::text), '^^') 
            , '||', IFNULL(TRIM(WADAT_IST::text), '^^') 
            , '||', IFNULL(TRIM(KWMENG::text), '^^') 
            , '||', IFNULL(TRIM(LFIMG::text), '^^') 
            , '||', IFNULL(TRIM(NETWR::text), '^^') 
            , '||', IFNULL(TRIM(SNETWR::text), '^^') 
            , '||', IFNULL(TRIM(ZLINEFILL::text), '^^') 
            , '||', IFNULL(TRIM(ZONTIME::text), '^^') 
            , '||', IFNULL(TRIM(ZRELEASED::text), '^^') 
            , '||', IFNULL(TRIM(WAERK::text), '^^') 
            , '||', IFNULL(TRIM(PSTYV::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(PERFECTORDER::text), '^^') 
            , '||', IFNULL(TRIM(ORDEVALDT::text), '^^') 
            , '||', IFNULL(TRIM(MULTONTIME::text), '^^') 
            , '||', IFNULL(TRIM(VSTEL::text), '^^') 
            , '||', IFNULL(TRIM(ONT_PIKMG::text), '^^') 
            , '||', IFNULL(TRIM(KODAT_IST::text), '^^') 
            , '||', IFNULL(TRIM(PIKMG::text), '^^') 
            , '||', IFNULL(TRIM(PNETWR::text), '^^') 
            , '||', IFNULL(TRIM(ZPLINEFILL::text), '^^') 
            , '||', IFNULL(TRIM(ZPONTIME::text), '^^') 
            , '||', IFNULL(TRIM(ZFILLDIFF::text), '^^') 
            , '||', IFNULL(TRIM(ZONTIMEDIFF::text), '^^') 
            , '||', IFNULL(TRIM(ZZENDSHPDTE::text), '^^') 
            , '||', IFNULL(TRIM(ZZGRACE::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

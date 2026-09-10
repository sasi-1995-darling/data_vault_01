---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_zdw_s600') }} as SRC 
                        where try_to_date(sptag, 'YYYYMMDD') >= '2024-04-20' ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_zdw_s600 )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        MANDT
      , SSOUR
      , VRSIO
      , SPMON
      , SPTAG
      , try_to_date(sptag, 'YYYYMMDD')                               as                                           SPTAG_DT
      , SPWOC
      , SPBUP
      , KUNNR
      , MATNR
      , WERKS
      , WADAT
      , coalesce(
            to_char(try_to_date(WADAT, 'YYYYMMDD')), ''
        )                                                            as                                           WADAT_DT
      , VBELN
      , POSNR
      , AUART
      , STWAE_01
      , ABGRU
      , GLREQUEST
      , PERIV
      , VWDAT
      , VRKME
      , WAERK
      , KWMENG
      , NETWR
      , ERZET
      , ERDAT
      , try_to_date(ERDAT, 'YYYYMMDD')                               as                                           ERDAT_DT
      , ZOUT_QTY
      , ZOUT_DOL
      , ZSHIP_QTY
      , VKORG
      , VTWEG
      , SPART
      , LFREL
      , PSTYV
      , BSTNK
      , ZZORC
      , AUGRU
      , WWRSN
      , WWSTP
      , Z532_KWERT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        ))                                                           as                                           LOAD_DTS
      , MATNR                                                        as                                            ITEM_BK
      , KUNNR                                                        as                                        CUSTOMER_BK
      , WERKS                                                        as                                           PLANT_BK
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        MANDT
      , SSOUR
      , VRSIO
      , SPMON
      , SPTAG
      , SPTAG_DT
      , SPWOC
      , SPBUP
      , KUNNR
      , MATNR
      , WERKS
      , WADAT
      , WADAT_DT
      , VBELN
      , POSNR
      , AUART
      , STWAE_01
      , ABGRU
      , GLREQUEST
      , PERIV
      , VWDAT
      , VRKME
      , WAERK
      , KWMENG
      , NETWR
      , ERZET
      , ERDAT
      , ERDAT_DT
      , ZOUT_QTY
      , ZOUT_DOL
      , ZSHIP_QTY
      , VKORG
      , VTWEG
      , SPART
      , LFREL
      , PSTYV
      , BSTNK
      , ZZORC
      , AUGRU
      , WWRSN
      , WWSTP
      , Z532_KWERT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , ITEM_BK
      , CUSTOMER_BK
      , PLANT_BK
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.S600'
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
          CONCAT(
        mandt, '||',
        ssour, '||',
        vrsio, '||',
        spmon, '||',
        sptag_dt, '||',
        spwoc, '||',
        spbup, '||',
        kunnr, '||',
        matnr, '||',
        werks, '||',
        wadat_dt, '||',
        vbeln, '||',
        posnr, '||',
        auart, '||',
        stwae_01, '||',
        abgru
    ) as SHIPMENT_INPUTS_BK
        , MANDT
        , SSOUR
        , VRSIO
        , SPMON
        , SPTAG
        , SPTAG_DT
        , SPWOC
        , SPBUP
        , KUNNR
        , MATNR
        , WERKS
        , WADAT
        , WADAT_DT
        , VBELN
        , POSNR
        , AUART
        , STWAE_01
        , ABGRU
        , GLREQUEST
        , PERIV
        , VWDAT
        , VRKME
        , WAERK
        , KWMENG
        , NETWR
        , ERZET
        , ERDAT
        , ERDAT_DT
        , ZOUT_QTY
        , ZOUT_DOL
        , ZSHIP_QTY
        , VKORG
        , VTWEG
        , SPART
        , LFREL
        , PSTYV
        , BSTNK
        , ZZORC
        , AUGRU
        , WWRSN
        , WWSTP
        , Z532_KWERT
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , ITEM_BK
        , CUSTOMER_BK
        , PLANT_BK
        , CONCAT(
        KUNNR, '||',
        vkorg, '||',
        vtweg, '||',
        spart
    ) as CUST_SALES_AREA_BK
        , CONCAT(
matnr, '||',kunnr, '||',mandt, '||',ssour, '||',vrsio, '||',spmon, '||',sptag_dt, '||',spwoc, '||',spbup, '||',kunnr, '||',matnr, '||',werks, '||',wadat_dt, '||',vbeln, '||',trim(posnr), '||',auart, '||',stwae_01, '||',abgru, '||',kunnr, '||',vkorg, '||',vtweg, '||',spart
) as ITEM_CUST_SHIPMENT_INPUTS_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SHIPMENT_INPUTS_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SHIPMENT_INPUTS_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUST_SALES_AREA_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUST_SALES_AREA_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_CUST_SHIPMENT_INPUTS_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_CUST_SHIPMENT_INPUTS_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(SSOUR::text), '^^') 
            , '||', IFNULL(TRIM(VRSIO::text), '^^') 
            , '||', IFNULL(TRIM(SPMON::text), '^^') 
            , '||', IFNULL(TRIM(SPTAG::text), '^^') 
            , '||', IFNULL(TRIM(SPTAG_DT::text), '^^') 
            , '||', IFNULL(TRIM(SPWOC::text), '^^') 
            , '||', IFNULL(TRIM(SPBUP::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(WADAT::text), '^^') 
            , '||', IFNULL(TRIM(WADAT_DT::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(AUART::text), '^^') 
            , '||', IFNULL(TRIM(STWAE_01::text), '^^') 
            , '||', IFNULL(TRIM(ABGRU::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(PERIV::text), '^^') 
            , '||', IFNULL(TRIM(VWDAT::text), '^^') 
            , '||', IFNULL(TRIM(VRKME::text), '^^') 
            , '||', IFNULL(TRIM(WAERK::text), '^^') 
            , '||', IFNULL(TRIM(KWMENG::text), '^^') 
            , '||', IFNULL(TRIM(NETWR::text), '^^') 
            , '||', IFNULL(TRIM(ERZET::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT_DT::text), '^^') 
            , '||', IFNULL(TRIM(ZOUT_QTY::text), '^^') 
            , '||', IFNULL(TRIM(ZOUT_DOL::text), '^^') 
            , '||', IFNULL(TRIM(ZSHIP_QTY::text), '^^') 
            , '||', IFNULL(TRIM(VKORG::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(LFREL::text), '^^') 
            , '||', IFNULL(TRIM(PSTYV::text), '^^') 
            , '||', IFNULL(TRIM(BSTNK::text), '^^') 
            , '||', IFNULL(TRIM(ZZORC::text), '^^') 
            , '||', IFNULL(TRIM(AUGRU::text), '^^') 
            , '||', IFNULL(TRIM(WWRSN::text), '^^') 
            , '||', IFNULL(TRIM(WWSTP::text), '^^') 
            , '||', IFNULL(TRIM(Z532_KWERT::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

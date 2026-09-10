---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ABGRU, COMPLETEDATE, CONFIRMCOMP, CONFIRMDATE, CONFIRMNEEDED, CONFIRMTIME, CONFSTATUS, CONTRACTORID, ERDAT, ERNAM, ERZET, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, INSTALLDATE, INSTALLMATNR, INSTALLRECID, INSTALLWADAT, INVOICEAMT, INVOICEITEMID, KUNNR, LFIMG, LIFNR, MANDT, ORDERID, POSNR, POSNR_VL, PRODUCTINSTALLED, PRODUCTWADAT, PRODUCT_POSNR, PROD_POSNR_VL, PROD_VBELN_VL, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SERVICENAME, SERVICEQTY, SERVICESKU, VBELN, VBELN_VL, VENDINVOICEDATE, VENDINVOICEID, VRKME, WAERK FROM {{ source('sap_ecc_prd', 'z_zvinstall') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM SAP_ECC_PRD.Z_ZVINSTALL )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        INSTALLRECID                                                 as                                    INSTALLATION_BK
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , MANDT
      , INSTALLRECID
      , GLREQUEST
      , LIFNR
      , VENDINVOICEID
      , VENDINVOICEDATE
      , ORDERID
      , CONTRACTORID
      , INVOICEITEMID
      , SERVICESKU
      , SERVICENAME
      , SERVICEQTY
      , INVOICEAMT
      , INSTALLDATE
      , COMPLETEDATE
      , WAERK
      , ERNAM
      , ERDAT
      , ERZET
      , VBELN
      , POSNR
      , KUNNR
      , INSTALLMATNR
      , PRODUCTINSTALLED
      , PRODUCT_POSNR
      , ABGRU
      , VBELN_VL
      , POSNR_VL
      , LFIMG
      , VRKME
      , INSTALLWADAT
      , PRODUCTWADAT
      , PROD_VBELN_VL
      , PROD_POSNR_VL
      , CONFIRMNEEDED
      , CONFIRMCOMP
      , CONFSTATUS
      , CONFIRMDATE
      , CONFIRMTIME
      , GLDELFLAG
      , GLSOURCESYSTEM
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
        INSTALLATION_BK
      , LOAD_DTS
      , MANDT
      , INSTALLRECID
      , GLREQUEST
      , LIFNR
      , VENDINVOICEID
      , VENDINVOICEDATE
      , ORDERID
      , CONTRACTORID
      , INVOICEITEMID
      , SERVICESKU
      , SERVICENAME
      , SERVICEQTY
      , INVOICEAMT
      , INSTALLDATE
      , COMPLETEDATE
      , WAERK
      , ERNAM
      , ERDAT
      , ERZET
      , VBELN
      , POSNR
      , KUNNR
      , INSTALLMATNR
      , PRODUCTINSTALLED
      , PRODUCT_POSNR
      , ABGRU
      , VBELN_VL
      , POSNR_VL
      , LFIMG
      , VRKME
      , INSTALLWADAT
      , PRODUCTWADAT
      , PROD_VBELN_VL
      , PROD_POSNR_VL
      , CONFIRMNEEDED
      , CONFIRMCOMP
      , CONFSTATUS
      , CONFIRMDATE
      , CONFIRMTIME
      , GLDELFLAG
      , GLSOURCESYSTEM
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
    WHERE rec_src = 'US.SAP_ECC_PRD.Z_ZVINSTALL'
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
          INSTALLATION_BK
        , LOAD_DTS
        , MANDT
        , INSTALLRECID
        , GLREQUEST
        , LIFNR
        , VENDINVOICEID
        , VENDINVOICEDATE
        , ORDERID
        , CONTRACTORID
        , INVOICEITEMID
        , SERVICESKU
        , SERVICENAME
        , SERVICEQTY
        , INVOICEAMT
        , INSTALLDATE
        , COMPLETEDATE
        , WAERK
        , ERNAM
        , ERDAT
        , ERZET
        , VBELN
        , POSNR
        , KUNNR
        , INSTALLMATNR
        , PRODUCTINSTALLED
        , PRODUCT_POSNR
        , ABGRU
        , VBELN_VL
        , POSNR_VL
        , LFIMG
        , VRKME
        , INSTALLWADAT
        , PRODUCTWADAT
        , PROD_VBELN_VL
        , PROD_POSNR_VL
        , CONFIRMNEEDED
        , CONFIRMCOMP
        , CONFSTATUS
        , CONFIRMDATE
        , CONFIRMTIME
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INSTALLATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INSTALLATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(KUNNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN_VL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DELIVERY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VBELN_VL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR_VL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DELIVERY_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INSTALLMATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(KUNNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(INSTALLMATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(INSTALLRECID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_INSTALLATION_DETAIL_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INSTALLRECID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VBELN_VL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(POSNR_VL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_INSTALLATION_DELIVERY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(VENDINVOICEID::text), '^^') 
            , '||', IFNULL(TRIM(VENDINVOICEDATE::text), '^^') 
            , '||', IFNULL(TRIM(ORDERID::text), '^^') 
            , '||', IFNULL(TRIM(CONTRACTORID::text), '^^') 
            , '||', IFNULL(TRIM(INVOICEITEMID::text), '^^') 
            , '||', IFNULL(TRIM(SERVICESKU::text), '^^') 
            , '||', IFNULL(TRIM(SERVICENAME::text), '^^') 
            , '||', IFNULL(TRIM(SERVICEQTY::text), '^^') 
            , '||', IFNULL(TRIM(INVOICEAMT::text), '^^') 
            , '||', IFNULL(TRIM(INSTALLDATE::text), '^^') 
            , '||', IFNULL(TRIM(COMPLETEDATE::text), '^^') 
            , '||', IFNULL(TRIM(WAERK::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERZET::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(INSTALLMATNR::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCTINSTALLED::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_POSNR::text), '^^') 
            , '||', IFNULL(TRIM(ABGRU::text), '^^') 
            , '||', IFNULL(TRIM(VBELN_VL::text), '^^') 
            , '||', IFNULL(TRIM(POSNR_VL::text), '^^') 
            , '||', IFNULL(TRIM(LFIMG::text), '^^') 
            , '||', IFNULL(TRIM(VRKME::text), '^^') 
            , '||', IFNULL(TRIM(INSTALLWADAT::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCTWADAT::text), '^^') 
            , '||', IFNULL(TRIM(PROD_VBELN_VL::text), '^^') 
            , '||', IFNULL(TRIM(PROD_POSNR_VL::text), '^^') 
            , '||', IFNULL(TRIM(CONFIRMNEEDED::text), '^^') 
            , '||', IFNULL(TRIM(CONFIRMCOMP::text), '^^') 
            , '||', IFNULL(TRIM(CONFSTATUS::text), '^^') 
            , '||', IFNULL(TRIM(CONFIRMDATE::text), '^^') 
            , '||', IFNULL(TRIM(CONFIRMTIME::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(GLCHANGETIME::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

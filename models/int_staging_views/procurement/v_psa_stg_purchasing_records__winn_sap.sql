---- SRC LAYER ----
WITH
SRC_eina           as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_eina') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_eina           as ( SELECT * FROM sap_ecc_prd.z_eina )
, SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_eina as (
    SELECT
        INFNR                                                        as                               PURCHASING_RECORD_BK
      , LIFNR                                                        as                                        SUPPLIER_BK
      , MATNR                                                        as                                            ITEM_BK
      , MANDT
      , INFNR
      , MATNR
      , MATKL
      , LIFNR
      , LOEKZ
      , ERDAT
      , ERNAM
      , TXZ01
      , SORTL
      , MEINS
      , UMREZ
      , UMREN
      , IDNLF
      , VERKF
      , TELF1
      , MAHN1
      , MAHN2
      , MAHN3
      , URZNR
      , URZDT
      , URZLA
      , URZTP
      , URZZT
      , LMEIN
      , REGIO
      , VABME
      , LTSNR
      , LTSSF
      , WGLIF
      , RUECK
      , LIFAB
      , LIFBI
      , KOLIF
      , ANZPU
      , PUNEI
      , RELIF
      , MFRNR
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
      , GLREQUEST
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_eina
)

, LOGIC_ref_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_ref_bkcc
)
---- RENAME LAYER ----

, RENAME_eina as (
    SELECT
        PURCHASING_RECORD_BK
      , SUPPLIER_BK
      , ITEM_BK
      , MANDT
      , INFNR
      , MATNR
      , MATKL
      , LIFNR
      , LOEKZ
      , ERDAT
      , ERNAM
      , TXZ01
      , SORTL
      , MEINS
      , UMREZ
      , UMREN
      , IDNLF
      , VERKF
      , TELF1
      , MAHN1
      , MAHN2
      , MAHN3
      , URZNR
      , URZDT
      , URZLA
      , URZTP
      , URZZT
      , LMEIN
      , REGIO
      , VABME
      , LTSNR
      , LTSSF
      , WGLIF
      , RUECK
      , LIFAB
      , LIFBI
      , KOLIF
      , ANZPU
      , PUNEI
      , RELIF
      , MFRNR
      , GLDELFLAG
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , GLREQUEST
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_eina
)

, RENAME_ref_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_ref_bkcc
)
---- FILTER LAYER ----

, FILTER_eina as (
    SELECT *
    FROM RENAME_eina
)

, FILTER_ref_bkcc as (
    SELECT *
    FROM RENAME_ref_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_EINA'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_eina
    INNER JOIN FILTER_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PURCHASING_RECORD_BK
        , SUPPLIER_BK
        , ITEM_BK
        , MANDT
        , INFNR
        , MATNR
        , MATKL
        , LIFNR
        , LOEKZ
        , ERDAT
        , ERNAM
        , TXZ01
        , SORTL
        , MEINS
        , UMREZ
        , UMREN
        , IDNLF
        , VERKF
        , TELF1
        , MAHN1
        , MAHN2
        , MAHN3
        , URZNR
        , URZDT
        , URZLA
        , URZTP
        , URZZT
        , LMEIN
        , REGIO
        , VABME
        , LTSNR
        , LTSSF
        , WGLIF
        , RUECK
        , LIFAB
        , LIFBI
        , KOLIF
        , ANZPU
        , PUNEI
        , RELIF
        , MFRNR
        , GLDELFLAG
        , GLCHANGETIME
        , GLCHANGETIME_DTTM
        , GLREQUEST
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(INFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_PURCHASING_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_RECORD_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LIFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(MATKL::text), '^^') 
            , '||', IFNULL(TRIM(LOEKZ::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(TXZ01::text), '^^') 
            , '||', IFNULL(TRIM(SORTL::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(UMREZ::text), '^^') 
            , '||', IFNULL(TRIM(UMREN::text), '^^') 
            , '||', IFNULL(TRIM(IDNLF::text), '^^') 
            , '||', IFNULL(TRIM(VERKF::text), '^^') 
            , '||', IFNULL(TRIM(TELF1::text), '^^') 
            , '||', IFNULL(TRIM(MAHN1::text), '^^') 
            , '||', IFNULL(TRIM(MAHN2::text), '^^') 
            , '||', IFNULL(TRIM(MAHN3::text), '^^') 
            , '||', IFNULL(TRIM(URZNR::text), '^^') 
            , '||', IFNULL(TRIM(URZDT::text), '^^') 
            , '||', IFNULL(TRIM(URZLA::text), '^^') 
            , '||', IFNULL(TRIM(URZTP::text), '^^') 
            , '||', IFNULL(TRIM(URZZT::text), '^^') 
            , '||', IFNULL(TRIM(LMEIN::text), '^^') 
            , '||', IFNULL(TRIM(REGIO::text), '^^') 
            , '||', IFNULL(TRIM(VABME::text), '^^') 
            , '||', IFNULL(TRIM(LTSNR::text), '^^') 
            , '||', IFNULL(TRIM(LTSSF::text), '^^') 
            , '||', IFNULL(TRIM(WGLIF::text), '^^') 
            , '||', IFNULL(TRIM(RUECK::text), '^^') 
            , '||', IFNULL(TRIM(LIFAB::text), '^^') 
            , '||', IFNULL(TRIM(LIFBI::text), '^^') 
            , '||', IFNULL(TRIM(KOLIF::text), '^^') 
            , '||', IFNULL(TRIM(ANZPU::text), '^^') 
            , '||', IFNULL(TRIM(PUNEI::text), '^^') 
            , '||', IFNULL(TRIM(RELIF::text), '^^') 
            , '||', IFNULL(TRIM(MFRNR::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

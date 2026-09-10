---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_cepc') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_cepc )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(coalesce(SPRAS,'-1'))                                as                                    LANGUAGE_KEY_BK
      , to_char(coalesce(PRCTR,'-1'))                                as                                    PROFIT_CENTER_BK
      , to_char(coalesce(DATBI,'-1'))                                as                                    VALID_DATE_BK
      , to_char(coalesce(KOKRS,'-1'))                                as                                    CONTROLLING_AREA_BK
      , MANDT
      , PRCTR
      , DATBI
      , KOKRS
      , GLREQUEST
      , DATAB
      , ERSDA
      , USNAM
      , MERKMAL
      , ABTEI
      , VERAK
      , VERAK_USER
      , WAERS
      , NPRCTR
      , LAND1
      , ANRED
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , ORT01
      , ORT02
      , STRAS
      , PFACH
      , PSTLZ
      , PSTL2
      , SPRAS
      , TELBX
      , TELF1
      , TELF2
      , TELFX
      , TELTX
      , TELX1
      , DATLT
      , DRNAM
      , KHINR
      , BUKRS
      , VNAME
      , RECID
      , ETYPE
      , TXJCD
      , REGIO
      , KVEWE
      , KAPPL
      , KALSM
      , LOGSYSTEM
      , LOCK_IND
      , PCA_TEMPLATE
      , SEGMENT
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
        LANGUAGE_KEY_BK
      , PROFIT_CENTER_BK
      , VALID_DATE_BK
      , CONTROLLING_AREA_BK
      , MANDT
      , PRCTR
      , DATBI
      , KOKRS
      , GLREQUEST
      , DATAB
      , ERSDA
      , USNAM
      , MERKMAL
      , ABTEI
      , VERAK
      , VERAK_USER
      , WAERS
      , NPRCTR
      , LAND1
      , ANRED
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , ORT01
      , ORT02
      , STRAS
      , PFACH
      , PSTLZ
      , PSTL2
      , SPRAS
      , TELBX
      , TELF1
      , TELF2
      , TELFX
      , TELTX
      , TELX1
      , DATLT
      , DRNAM
      , KHINR
      , BUKRS
      , VNAME
      , RECID
      , ETYPE
      , TXJCD
      , REGIO
      , KVEWE
      , KAPPL
      , KALSM
      , LOGSYSTEM
      , LOCK_IND
      , PCA_TEMPLATE
      , SEGMENT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_CEPC'
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
          
          LANGUAGE_KEY_BK
        , PROFIT_CENTER_BK
        , VALID_DATE_BK
        , CONTROLLING_AREA_BK
        , MANDT
        , PRCTR
        , DATBI
        , KOKRS
        , GLREQUEST
        , DATAB
        , ERSDA
        , USNAM
        , MERKMAL
        , ABTEI
        , VERAK
        , VERAK_USER
        , WAERS
        , NPRCTR
        , LAND1
        , ANRED
        , NAME1
        , NAME2
        , NAME3
        , NAME4
        , ORT01
        , ORT02
        , STRAS
        , PFACH
        , PSTLZ
        , PSTL2
        , SPRAS
        , TELBX
        , TELF1
        , TELF2
        , TELFX
        , TELTX
        , TELX1
        , DATLT
        , DRNAM
        , KHINR
        , BUKRS
        , VNAME
        , RECID
        , ETYPE
        , TXJCD
        , REGIO
        , KVEWE
        , KAPPL
        , KALSM
        , LOGSYSTEM
        , LOCK_IND
        , PCA_TEMPLATE
        , SEGMENT
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
          COALESCE(NULLIF(TRIM(CAST(PROFIT_CENTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VALID_DATE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as OBJECT_NUMBER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(PRCTR::text), '^^') 
            , '||', IFNULL(TRIM(DATBI::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(DATAB::text), '^^') 
            , '||', IFNULL(TRIM(ERSDA::text), '^^') 
            , '||', IFNULL(TRIM(USNAM::text), '^^') 
            , '||', IFNULL(TRIM(MERKMAL::text), '^^') 
            , '||', IFNULL(TRIM(ABTEI::text), '^^') 
            , '||', IFNULL(TRIM(VERAK::text), '^^') 
            , '||', IFNULL(TRIM(VERAK_USER::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(NPRCTR::text), '^^') 
            , '||', IFNULL(TRIM(LAND1::text), '^^') 
            , '||', IFNULL(TRIM(ANRED::text), '^^') 
            , '||', IFNULL(TRIM(NAME1::text), '^^') 
            , '||', IFNULL(TRIM(NAME2::text), '^^') 
            , '||', IFNULL(TRIM(NAME3::text), '^^') 
            , '||', IFNULL(TRIM(NAME4::text), '^^') 
            , '||', IFNULL(TRIM(ORT01::text), '^^') 
            , '||', IFNULL(TRIM(ORT02::text), '^^') 
            , '||', IFNULL(TRIM(STRAS::text), '^^') 
            , '||', IFNULL(TRIM(PFACH::text), '^^') 
            , '||', IFNULL(TRIM(PSTLZ::text), '^^') 
            , '||', IFNULL(TRIM(PSTL2::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(TELBX::text), '^^') 
            , '||', IFNULL(TRIM(TELF1::text), '^^') 
            , '||', IFNULL(TRIM(TELF2::text), '^^') 
            , '||', IFNULL(TRIM(TELFX::text), '^^') 
            , '||', IFNULL(TRIM(TELTX::text), '^^') 
            , '||', IFNULL(TRIM(TELX1::text), '^^') 
            , '||', IFNULL(TRIM(DATLT::text), '^^') 
            , '||', IFNULL(TRIM(DRNAM::text), '^^') 
            , '||', IFNULL(TRIM(KHINR::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(VNAME::text), '^^') 
            , '||', IFNULL(TRIM(RECID::text), '^^') 
            , '||', IFNULL(TRIM(ETYPE::text), '^^') 
            , '||', IFNULL(TRIM(TXJCD::text), '^^') 
            , '||', IFNULL(TRIM(REGIO::text), '^^') 
            , '||', IFNULL(TRIM(KVEWE::text), '^^') 
            , '||', IFNULL(TRIM(KAPPL::text), '^^') 
            , '||', IFNULL(TRIM(KALSM::text), '^^') 
            , '||', IFNULL(TRIM(LOGSYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(LOCK_IND::text), '^^') 
            , '||', IFNULL(TRIM(PCA_TEMPLATE::text), '^^') 
            , '||', IFNULL(TRIM(SEGMENT::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

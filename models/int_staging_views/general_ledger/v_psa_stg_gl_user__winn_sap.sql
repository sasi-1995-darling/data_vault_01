---- SRC LAYER ----
WITH
SRC_S              as ( SELECT ABTLG, BNAME, BUINR, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, KOSTL, LAND1, MANDT, NAME1, NAME2, NAME3, NAME4, ORT01, ORT02, PFACH, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSTL2, PSTLZ, REGIO, ROONR, SALUT, SPRAS, STRAS, TEL01, TEL02, TELFX, TELNR, TELPR, TELTX, TELX1, TZONE FROM {{ source('sap_ecc_prd', 'z_usr03') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_usr03 )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        MANDT
      , BNAME
      , GLREQUEST
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , SALUT
      , ABTLG
      , KOSTL
      , BUINR
      , ROONR
      , STRAS
      , PFACH
      , PSTLZ
      , ORT01
      , REGIO
      , LAND1
      , SPRAS
      , TELPR
      , TELNR
      , TEL01
      , TEL02
      , TELX1
      , TELFX
      , TELTX
      , ORT02
      , PSTL2
      , TZONE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
      , BNAME
      , GLREQUEST
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , SALUT
      , ABTLG
      , KOSTL
      , BUINR
      , ROONR
      , STRAS
      , PFACH
      , PSTLZ
      , ORT01
      , REGIO
      , LAND1
      , SPRAS
      , TELPR
      , TELNR
      , TEL01
      , TEL02
      , TELX1
      , TELFX
      , TELTX
      , ORT02
      , PSTL2
      , TZONE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_USR03'
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
          to_char(coalesce(nullif(trim(BNAME), ''), '-1'))                      as USER_NAME_BK
        , MANDT
        , BNAME
        , GLREQUEST
        , NAME1
        , NAME2
        , NAME3
        , NAME4
        , SALUT
        , ABTLG
        , KOSTL
        , BUINR
        , ROONR
        , STRAS
        , PFACH
        , PSTLZ
        , ORT01
        , REGIO
        , LAND1
        , SPRAS
        , TELPR
        , TELNR
        , TEL01
        , TEL02
        , TELX1
        , TELFX
        , TELTX
        , ORT02
        , PSTL2
        , TZONE
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
        ))  as LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(USER_NAME_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as USER_NAME_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(BNAME::text), '^^') 
            , '||', IFNULL(TRIM(NAME1::text), '^^') 
            , '||', IFNULL(TRIM(NAME2::text), '^^') 
            , '||', IFNULL(TRIM(NAME3::text), '^^') 
            , '||', IFNULL(TRIM(NAME4::text), '^^') 
            , '||', IFNULL(TRIM(SALUT::text), '^^') 
            , '||', IFNULL(TRIM(ABTLG::text), '^^') 
            , '||', IFNULL(TRIM(KOSTL::text), '^^') 
            , '||', IFNULL(TRIM(BUINR::text), '^^') 
            , '||', IFNULL(TRIM(ROONR::text), '^^') 
            , '||', IFNULL(TRIM(STRAS::text), '^^') 
            , '||', IFNULL(TRIM(PFACH::text), '^^') 
            , '||', IFNULL(TRIM(PSTLZ::text), '^^') 
            , '||', IFNULL(TRIM(ORT01::text), '^^') 
            , '||', IFNULL(TRIM(REGIO::text), '^^') 
            , '||', IFNULL(TRIM(LAND1::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(TELPR::text), '^^') 
            , '||', IFNULL(TRIM(TELNR::text), '^^') 
            , '||', IFNULL(TRIM(TEL01::text), '^^') 
            , '||', IFNULL(TRIM(TEL02::text), '^^') 
            , '||', IFNULL(TRIM(TELX1::text), '^^') 
            , '||', IFNULL(TRIM(TELFX::text), '^^') 
            , '||', IFNULL(TRIM(TELTX::text), '^^') 
            , '||', IFNULL(TRIM(ORT02::text), '^^') 
            , '||', IFNULL(TRIM(PSTL2::text), '^^') 
            , '||', IFNULL(TRIM(TZONE::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
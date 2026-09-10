---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_ska1') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_SKA1 )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        CONVERT_TIMEZONE('UTC', IFF(
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
      , MANDT
      , to_char(coalesce(KTOPL,'-1'))                                as                                           GL_COA_BK
      , to_char(coalesce(SAKNR,'-1'))                                as                                           GL_ACCOUNT_NUMBER_BK
      , KTOPL      
      , SAKNR
      , GLREQUEST
      , XBILK
      , SAKAN
      , BILKT
      , ERDAT
      , ERNAM
      , GVTYP
      , KTOKS
      , MUSTR
      , VBUND
      , XLOEV
      , XSPEA
      , XSPEB
      , XSPEP
      , MCOD1
      , FUNC_AREA
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        ))                                                           as                                  GLCHANGETIME_DTTM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
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
        LOAD_DTS
      , MANDT
      , GL_COA_BK
      , GL_ACCOUNT_NUMBER_BK
      , KTOPL
      , SAKNR
      , GLREQUEST
      , XBILK
      , SAKAN
      , BILKT
      , ERDAT
      , ERNAM
      , GVTYP
      , KTOKS
      , MUSTR
      , VBUND
      , XLOEV
      , XSPEA
      , XSPEB
      , XSPEP
      , MCOD1
      , FUNC_AREA
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME 
      , GLCHANGETIME_DTTM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_SKA1'
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
          
         LOAD_DTS
        , MANDT
        , GL_COA_BK
        , GL_ACCOUNT_NUMBER_BK
        , KTOPL
        , SAKNR
        , GLREQUEST
        , XBILK
        , SAKAN
        , BILKT
        , ERDAT
        , ERNAM
        , GVTYP
        , KTOKS
        , MUSTR
        , VBUND
        , XLOEV
        , XSPEA
        , XSPEB
        , XSPEP
        , MCOD1
        , FUNC_AREA
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , GLCHANGETIME_DTTM
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||'
        , COALESCE(NULLIF(TRIM(CAST(GL_ACCOUNT_NUMBER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as GL_ACCOUNT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(KTOPL::text), '^^') 
            , '||', IFNULL(TRIM(SAKNR::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(XBILK::text), '^^') 
            , '||', IFNULL(TRIM(SAKAN::text), '^^') 
            , '||', IFNULL(TRIM(BILKT::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(GVTYP::text), '^^') 
            , '||', IFNULL(TRIM(KTOKS::text), '^^') 
            , '||', IFNULL(TRIM(MUSTR::text), '^^') 
            , '||', IFNULL(TRIM(VBUND::text), '^^') 
            , '||', IFNULL(TRIM(XLOEV::text), '^^') 
            , '||', IFNULL(TRIM(XSPEA::text), '^^') 
            , '||', IFNULL(TRIM(XSPEB::text), '^^') 
            , '||', IFNULL(TRIM(XSPEP::text), '^^') 
            , '||', IFNULL(TRIM(MCOD1::text), '^^') 
            , '||', IFNULL(TRIM(FUNC_AREA::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

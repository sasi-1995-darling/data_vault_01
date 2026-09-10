---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_skb1') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.Z_SKB1 )
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
      , to_char(coalesce(BUKRS,'-1'))                                as                                           GL_COMPANY_CODE_BK
      , to_char(coalesce(SAKNR,'-1'))                                as                                           GL_ACCOUNT_NUMBER_BK
      , BUKRS
      , SAKNR
      , GLREQUEST
      , BEGRU
      , BUSAB
      , DATLZ
      , ERDAT
      , ERNAM
      , FDGRV
      , FDLEV
      , FIPLS
      , FSTAG
      , HBKID
      , HKTID
      , KDFSL
      , MITKZ
      , MWSKZ
      , STEXT
      , VZSKZ
      , WAERS
      , WMETH
      , XGKON
      , XINTB
      , XKRES
      , XLOEB
      , XNKON
      , XOPVW
      , XSPEB
      , ZINDT
      , ZINRT
      , ZUAWA
      , ALTKT
      , XMITK
      , RECID
      , FIPOS
      , XMWNO
      , XSALH
      , BEWGP
      , INFKY
      , TOGRU
      , XLGCLR
      , MCAKEY
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
      , GL_COMPANY_CODE_BK
      , GL_ACCOUNT_NUMBER_BK
      , BUKRS
      , SAKNR
      , GLREQUEST
      , BEGRU
      , BUSAB
      , DATLZ
      , ERDAT
      , ERNAM
      , FDGRV
      , FDLEV
      , FIPLS
      , FSTAG
      , HBKID
      , HKTID
      , KDFSL
      , MITKZ
      , MWSKZ
      , STEXT
      , VZSKZ
      , WAERS
      , WMETH
      , XGKON
      , XINTB
      , XKRES
      , XLOEB
      , XNKON
      , XOPVW
      , XSPEB
      , ZINDT
      , ZINRT
      , ZUAWA
      , ALTKT
      , XMITK
      , RECID
      , FIPOS
      , XMWNO
      , XSALH
      , BEWGP
      , INFKY
      , TOGRU
      , XLGCLR
      , MCAKEY
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_SKB1'
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
        , GL_COMPANY_CODE_BK
        , GL_ACCOUNT_NUMBER_BK
        , BUKRS
        , SAKNR
        , GLREQUEST
        , BEGRU
        , BUSAB
        , DATLZ
        , ERDAT
        , ERNAM
        , FDGRV
        , FDLEV
        , FIPLS
        , FSTAG
        , HBKID
        , HKTID
        , KDFSL
        , MITKZ
        , MWSKZ
        , STEXT
        , VZSKZ
        , WAERS
        , WMETH
        , XGKON
        , XINTB
        , XKRES
        , XLOEB
        , XNKON
        , XOPVW
        , XSPEB
        , ZINDT
        , ZINRT
        , ZUAWA
        , ALTKT
        , XMITK
        , RECID
        , FIPOS
        , XMWNO
        , XSALH
        , BEWGP
        , INFKY
        , TOGRU
        , XLGCLR
        , MCAKEY
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , GLCHANGETIME_DTTM
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(GL_COMPANY_CODE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(GL_ACCOUNT_NUMBER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as GL_ACCOUNT_DETAILS_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(GL_COMPANY_CODE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as GL_ACCOUNT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(GL_ACCOUNT_NUMBER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(SAKNR::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(BEGRU::text), '^^') 
            , '||', IFNULL(TRIM(BUSAB::text), '^^') 
            , '||', IFNULL(TRIM(DATLZ::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(FDGRV::text), '^^') 
            , '||', IFNULL(TRIM(FDLEV::text), '^^') 
            , '||', IFNULL(TRIM(FIPLS::text), '^^') 
            , '||', IFNULL(TRIM(FSTAG::text), '^^') 
            , '||', IFNULL(TRIM(HBKID::text), '^^') 
            , '||', IFNULL(TRIM(HKTID::text), '^^') 
            , '||', IFNULL(TRIM(KDFSL::text), '^^') 
            , '||', IFNULL(TRIM(MITKZ::text), '^^') 
            , '||', IFNULL(TRIM(MWSKZ::text), '^^') 
            , '||', IFNULL(TRIM(STEXT::text), '^^') 
            , '||', IFNULL(TRIM(VZSKZ::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(WMETH::text), '^^') 
            , '||', IFNULL(TRIM(XGKON::text), '^^') 
            , '||', IFNULL(TRIM(XINTB::text), '^^') 
            , '||', IFNULL(TRIM(XKRES::text), '^^') 
            , '||', IFNULL(TRIM(XLOEB::text), '^^') 
            , '||', IFNULL(TRIM(XNKON::text), '^^') 
            , '||', IFNULL(TRIM(XOPVW::text), '^^') 
            , '||', IFNULL(TRIM(XSPEB::text), '^^') 
            , '||', IFNULL(TRIM(ZINDT::text), '^^') 
            , '||', IFNULL(TRIM(ZINRT::text), '^^') 
            , '||', IFNULL(TRIM(ZUAWA::text), '^^') 
            , '||', IFNULL(TRIM(ALTKT::text), '^^') 
            , '||', IFNULL(TRIM(XMITK::text), '^^') 
            , '||', IFNULL(TRIM(RECID::text), '^^') 
            , '||', IFNULL(TRIM(FIPOS::text), '^^') 
            , '||', IFNULL(TRIM(XMWNO::text), '^^') 
            , '||', IFNULL(TRIM(XSALH::text), '^^') 
            , '||', IFNULL(TRIM(BEWGP::text), '^^') 
            , '||', IFNULL(TRIM(INFKY::text), '^^') 
            , '||', IFNULL(TRIM(TOGRU::text), '^^') 
            , '||', IFNULL(TRIM(XLGCLR::text), '^^') 
            , '||', IFNULL(TRIM(MCAKEY::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^')  
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

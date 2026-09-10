---- SRC LAYER ----
WITH
SRC_S              as ( SELECT MANDT, RCOMP, GLREQUEST, NAME1, CNTRY, NAME2, LANGU, STRET, POBOX, PSTLC, CITY, CURR, MODCP, GLSIP, RESTA, RFORM, ZWEIG, MCOMP, MCLNT, LCCOMP, STRT2, INDPO, GLDELFLAG, GLSOURCESYSTEM, GLCHANGETIME, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND FROM {{ source('sap_ecc_prd', 'z_t880') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_t880 )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        MANDT
      , RCOMP
      , GLREQUEST
      , NAME1
      , CNTRY
      , NAME2
      , LANGU
      , STRET
      , POBOX
      , PSTLC
      , CITY
      , CURR
      , MODCP
      , GLSIP
      , RESTA
      , RFORM
      , ZWEIG
      , MCOMP
      , MCLNT
      , LCCOMP
      , STRT2
      , INDPO
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME                                          
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
      , RCOMP
      , GLREQUEST
      , NAME1
      , CNTRY
      , NAME2
      , LANGU
      , STRET
      , POBOX
      , PSTLC
      , CITY
      , CURR
      , MODCP
      , GLSIP
      , RESTA
      , RFORM
      , ZWEIG
      , MCOMP
      , MCLNT
      , LCCOMP
      , STRT2
      , INDPO
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T880'
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
          to_char(coalesce(nullif(trim(RCOMP), ''), '-1'))             as ENTITY_BK
        , MANDT
        , RCOMP
        , GLREQUEST
        , NAME1
        , CNTRY
        , NAME2
        , LANGU
        , STRET
        , POBOX
        , PSTLC
        , CITY
        , CURR
        , MODCP
        , GLSIP
        , RESTA
        , RFORM
        , ZWEIG
        , MCOMP
        , MCLNT
        , LCCOMP
        , STRT2
        , INDPO
        , GLDELFLAG
        , GLSOURCESYSTEM
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
        ))  as LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ENTITY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ENTITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(RCOMP::text), '^^') 
            , '||', IFNULL(TRIM(NAME1::text), '^^') 
            , '||', IFNULL(TRIM(CNTRY::text), '^^') 
            , '||', IFNULL(TRIM(NAME2::text), '^^') 
            , '||', IFNULL(TRIM(LANGU::text), '^^') 
            , '||', IFNULL(TRIM(STRET::text), '^^') 
            , '||', IFNULL(TRIM(POBOX::text), '^^') 
            , '||', IFNULL(TRIM(PSTLC::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(CURR::text), '^^') 
            , '||', IFNULL(TRIM(MODCP::text), '^^') 
            , '||', IFNULL(TRIM(GLSIP::text), '^^') 
            , '||', IFNULL(TRIM(RESTA::text), '^^') 
            , '||', IFNULL(TRIM(RFORM::text), '^^') 
            , '||', IFNULL(TRIM(ZWEIG::text), '^^') 
            , '||', IFNULL(TRIM(MCOMP::text), '^^') 
            , '||', IFNULL(TRIM(MCLNT::text), '^^') 
            , '||', IFNULL(TRIM(LCCOMP::text), '^^') 
            , '||', IFNULL(TRIM(STRT2::text), '^^') 
            , '||', IFNULL(TRIM(INDPO::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

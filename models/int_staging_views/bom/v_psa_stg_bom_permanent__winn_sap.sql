---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_stzu') }} as SRC  ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_stzu )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        STLNR                                                        as                                             BOM_BK
      , MANDT
      , STLTY
      , STLNR
      , GLREQUEST
      , STLAN
      , EXSTL
      , ALTST
      , VARST
      , KBAUS
      , LTXSP
      , STLBE
      , ZTEXT
      , WRKAN
      , HISDT
      , HISSR
      , HISTK
      , STUEZ
      , MAXKN
      , KZPLN
      , AENRL
      , CLSMX
      , STLDT
      , STLTM
      , MAXKAN
      , TSTMP
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
      ))   as                                    LOAD_DTS
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
        BOM_BK
      , MANDT
      , STLTY
      , STLNR
      , GLREQUEST
      , STLAN
      , EXSTL
      , ALTST
      , VARST
      , KBAUS
      , LTXSP
      , STLBE
      , ZTEXT
      , WRKAN
      , HISDT
      , HISSR
      , HISTK
      , STUEZ
      , MAXKN
      , KZPLN
      , AENRL
      , CLSMX
      , STLDT
      , STLTM
      , MAXKAN
      , TSTMP
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_STZU'
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
          BOM_BK
        , MANDT
        , STLTY
        , STLNR
        , GLREQUEST
        , STLAN
        , EXSTL
        , ALTST
        , VARST
        , KBAUS
        , LTXSP
        , STLBE
        , ZTEXT
        , WRKAN
        , HISDT
        , HISSR
        , HISTK
        , STUEZ
        , MAXKN
        , KZPLN
        , AENRL
        , CLSMX
        , STLDT
        , STLTM
        , MAXKAN
        , TSTMP
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
          COALESCE(NULLIF(TRIM(CAST(STLNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as BOM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(STLTY::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(STLAN::text), '^^') 
            , '||', IFNULL(TRIM(EXSTL::text), '^^') 
            , '||', IFNULL(TRIM(ALTST::text), '^^') 
            , '||', IFNULL(TRIM(VARST::text), '^^') 
            , '||', IFNULL(TRIM(KBAUS::text), '^^') 
            , '||', IFNULL(TRIM(LTXSP::text), '^^') 
            , '||', IFNULL(TRIM(STLBE::text), '^^') 
            , '||', IFNULL(TRIM(ZTEXT::text), '^^') 
            , '||', IFNULL(TRIM(WRKAN::text), '^^') 
            , '||', IFNULL(TRIM(HISDT::text), '^^') 
            , '||', IFNULL(TRIM(HISSR::text), '^^') 
            , '||', IFNULL(TRIM(HISTK::text), '^^') 
            , '||', IFNULL(TRIM(STUEZ::text), '^^') 
            , '||', IFNULL(TRIM(MAXKN::text), '^^') 
            , '||', IFNULL(TRIM(KZPLN::text), '^^') 
            , '||', IFNULL(TRIM(AENRL::text), '^^') 
            , '||', IFNULL(TRIM(CLSMX::text), '^^') 
            , '||', IFNULL(TRIM(STLDT::text), '^^') 
            , '||', IFNULL(TRIM(STLTM::text), '^^') 
            , '||', IFNULL(TRIM(MAXKAN::text), '^^') 
            , '||', IFNULL(TRIM(TSTMP::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

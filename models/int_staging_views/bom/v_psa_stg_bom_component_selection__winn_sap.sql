---- SRC LAYER ----
WITH
SRC_stas           as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_stas') }} as SRC  ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_stas           as ( SELECT * FROM sap_ecc_prd.z_stas )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_stas as (
    SELECT
        STLNR                                                        as                                             BOM_BK
      , MANDT
      , STLTY
      , STLNR
      , STLAL
      , STLKN
      , STASZ
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LKENZ
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , DVDAT
      , DVNAM
      , AEHLP
      , STVKN
      , IDPOS
      , IDVAR
      , LPSRT
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
    FROM SRC_stas
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_stas as (
    SELECT
        BOM_BK
      , MANDT
      , STLTY
      , STLNR
      , STLAL
      , STLKN
      , STASZ
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LKENZ
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , DVDAT
      , DVNAM
      , AEHLP
      , STVKN
      , IDPOS
      , IDVAR
      , LPSRT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_stas
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_stas as (
    SELECT *
    FROM RENAME_stas
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_STAS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_stas
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          BOM_BK
        , MANDT
        , STLTY
        , STLNR
        , STLAL
        , STLKN
        , STASZ
        , GLREQUEST
        , DATUV
        , TECHV
        , AENNR
        , LKENZ
        , ANDAT
        , ANNAM
        , AEDAT
        , AENAM
        , DVDAT
        , DVNAM
        , AEHLP
        , STVKN
        , IDPOS
        , IDVAR
        , LPSRT
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
            , '||', IFNULL(TRIM(STLAL::text), '^^') 
            , '||', IFNULL(TRIM(STLKN::text), '^^') 
            , '||', IFNULL(TRIM(STASZ::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(DATUV::text), '^^') 
            , '||', IFNULL(TRIM(TECHV::text), '^^') 
            , '||', IFNULL(TRIM(AENNR::text), '^^') 
            , '||', IFNULL(TRIM(LKENZ::text), '^^') 
            , '||', IFNULL(TRIM(ANDAT::text), '^^') 
            , '||', IFNULL(TRIM(ANNAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(DVDAT::text), '^^') 
            , '||', IFNULL(TRIM(DVNAM::text), '^^') 
            , '||', IFNULL(TRIM(AEHLP::text), '^^') 
            , '||', IFNULL(TRIM(STVKN::text), '^^') 
            , '||', IFNULL(TRIM(IDPOS::text), '^^') 
            , '||', IFNULL(TRIM(IDVAR::text), '^^') 
            , '||', IFNULL(TRIM(LPSRT::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

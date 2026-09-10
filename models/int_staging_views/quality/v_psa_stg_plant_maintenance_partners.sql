---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_ihpa') }} as SRC  ),
SRC_b              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM SAP_ECC_PRD.Z_IHPA )
, SRC_b              as ( SELECT * FROM RAW_VAULT.REF_BUSINESS_KEY_COLLISION )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COUNTER as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(MANDT as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(OBJNR as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(PARVW as VARCHAR)),''), '^^')
        )))                                                          as                      PLANT_MAINTENANCE_PARTNERS_BK
      , MANDT
      , OBJNR
      , PARVW
      , COUNTER
      , GLREQUEST
      , OBTYP
      , PARNR
      , INHER
      , ERDAT
      , ERZEIT
      , ERNAM
      , AEDAT
      , AEZEIT
      , AENAM
      , KZLOESCH
      , ADRNR
      , TZONSP
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
        ))                                                           as                                           LOAD_DTS
      , 'FB WINN'                                                    as                                              BRAND
    FROM SRC_a
)

, LOGIC_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        PLANT_MAINTENANCE_PARTNERS_BK
      , MANDT
      , OBJNR
      , PARVW
      , COUNTER
      , GLREQUEST
      , OBTYP
      , PARNR
      , INHER
      , ERDAT
      , ERZEIT
      , ERNAM
      , AEDAT
      , AEZEIT
      , AENAM
      , KZLOESCH
      , ADRNR
      , TZONSP
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , LOAD_DTS
      , BRAND
    FROM LOGIC_a
)

, RENAME_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_b as (
    SELECT *
    FROM RENAME_b
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_IHPA'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_b
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PLANT_MAINTENANCE_PARTNERS_BK
        , MANDT
        , OBJNR
        , PARVW
        , COUNTER
        , GLREQUEST
        , OBTYP
        , PARNR
        , INHER
        , ERDAT
        , ERZEIT
        , ERNAM
        , AEDAT
        , AEZEIT
        , AENAM
        , KZLOESCH
        , ADRNR
        , TZONSP
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , LOAD_DTS
        , REC_SRC
        , BRAND
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COUNTER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MANDT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(OBJNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PARVW as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_MAINTENANCE_PARTNERS_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(PARVW::text), '^^') 
            , '||', IFNULL(TRIM(COUNTER::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(OBTYP::text), '^^') 
            , '||', IFNULL(TRIM(PARNR::text), '^^') 
            , '||', IFNULL(TRIM(INHER::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERZEIT::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(AEZEIT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(KZLOESCH::text), '^^') 
            , '||', IFNULL(TRIM(ADRNR::text), '^^') 
            , '||', IFNULL(TRIM(TZONSP::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLCHANGETIME::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ANZSN, DATUM, EXIDV, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, MANDT, OBKNR, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, UZEIT, VENUM, VEPOS, VORGANG FROM {{ source('sap_ecc_prd', 'z_ser06') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM SAP_ECC_PRD.Z_SER06 )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , MANDT
      , OBKNR
      , GLREQUEST
      , GLSOURCESYSTEM
      , VENUM
      , VEPOS
      , EXIDV
      , DATUM
      , UZEIT
      , ANZSN
      , VORGANG
      , GLDELFLAG
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
        LOAD_DTS
      , MANDT
      , OBKNR
      , GLREQUEST
      , GLSOURCESYSTEM
      , VENUM
      , VEPOS
      , EXIDV
      , DATUM
      , UZEIT
      , ANZSN
      , VORGANG
      , GLDELFLAG
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
    WHERE rec_src = 'US.SAP_ECC_PRD.Z_SER06'
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
          LOAD_DTS
        , MANDT
        , OBKNR
        , GLREQUEST
        , GLSOURCESYSTEM
        , VENUM
        , VEPOS
        , EXIDV
        , DATUM
        , UZEIT
        , ANZSN
        , VORGANG
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(OBKNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as OBJECT_LIST_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as HANDLING_UNIT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(OBKNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VENUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SERIAL_NUMBER_HU_ASSIGNMENT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(VEPOS::text), '^^') 
            , '||', IFNULL(TRIM(EXIDV::text), '^^') 
            , '||', IFNULL(TRIM(DATUM::text), '^^') 
            , '||', IFNULL(TRIM(UZEIT::text), '^^') 
            , '||', IFNULL(TRIM(ANZSN::text), '^^') 
            , '||', IFNULL(TRIM(VORGANG::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLCHANGETIME::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

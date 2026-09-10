
---- SRC LAYER ----
WITH
SRC_a              as ( SELECT MANDT,ANZHL, ANZSH, ANZTG, DATUB, FABTG, FIRST, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, KAPID, KKOPF, NGRAD, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SPROG, VERSN, WOTAG FROM {{ source('sap_ecc_prd', 'z_kazy') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )
/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_kazy )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MANDT  
      , KAPID                                                        as                                        CAPACITY_BK
      , KAPID
      , VERSN
      , DATUB
      , GLREQUEST
      , ANZHL
      , ANZSH
      , ANZTG
      , FABTG
      , NGRAD
      , SPROG
      , WOTAG
      , KKOPF
      , FIRST
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
        ))                                                           as                                           LOAD_DTS
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
        CAPACITY_BK
      , KAPID
      , MANDT
      , VERSN
      , DATUB
      , GLREQUEST
      , ANZHL
      , ANZSH
      , ANZTG
      , FABTG
      , NGRAD
      , SPROG
      , WOTAG
      , KKOPF
      , FIRST
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_KAZY'
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
          CAPACITY_BK
        , KAPID
        , MANDT
        , VERSN
        , DATUB
        , GLREQUEST
        , ANZHL
        , ANZSH
        , ANZTG
        , FABTG
        , NGRAD
        , SPROG
        , WOTAG
        , KKOPF
        , FIRST
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CAPACITY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CAPACITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(KAPID::text), '^^')
            , '||', IFNULL(TRIM(MANDT::text), '^^')  
            , '||', IFNULL(TRIM(VERSN::text), '^^') 
            , '||', IFNULL(TRIM(DATUB::text), '^^') 
            , '||', IFNULL(TRIM(ANZHL::text), '^^') 
            , '||', IFNULL(TRIM(ANZSH::text), '^^') 
            , '||', IFNULL(TRIM(ANZTG::text), '^^') 
            , '||', IFNULL(TRIM(FABTG::text), '^^') 
            , '||', IFNULL(TRIM(NGRAD::text), '^^') 
            , '||', IFNULL(TRIM(SPROG::text), '^^') 
            , '||', IFNULL(TRIM(WOTAG::text), '^^') 
            , '||', IFNULL(TRIM(KKOPF::text), '^^') 
            , '||', IFNULL(TRIM(FIRST::text), '^^')
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
---- SRC LAYER ----
WITH
SRC_a              as ( SELECT AEDAT, AENAM, AENNR, ANDAT, ANNAM, DATUV, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, LOEKZ, MANDT, PARKZ, PLNAL, PLNFL, PLNKN, PLNNR, PLNTY, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, TECHV, ZAEHL FROM {{ source('sap_ecc_prd', 'z_plas') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_plas )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MANDT
      , PLNTY
      , PLNNR
      , PLNAL
      , PLNFL
      , PLNKN
      , ZAEHL
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LOEKZ
      , PARKZ
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
            ))
        )                                                            as                                           LOAD_DTS
      , CONCAT_WS('||', PLNTY, PLNNR)                                as                                  TASKLIST_GROUP_BK
      , CONCAT_WS('||', PLNTY, PLNNR, PLNKN)                         as                              TASKLIST_OPERATION_BK
      , PLNAL                                                        as                                   GROUP_COUNTER_DC
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
        MANDT
      , PLNTY
      , PLNNR
      , PLNAL
      , PLNFL
      , PLNKN
      , ZAEHL
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LOEKZ
      , PARKZ
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , TASKLIST_GROUP_BK
      , TASKLIST_OPERATION_BK
      , GROUP_COUNTER_DC
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_PLAS'
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
          MANDT
        , PLNTY
        , PLNNR
        , PLNAL
        , PLNFL
        , PLNKN
        , ZAEHL
        , GLREQUEST
        , DATUV
        , TECHV
        , AENNR
        , LOEKZ
        , PARKZ
        , ANDAT
        , ANNAM
        , AEDAT
        , AENAM
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , TASKLIST_GROUP_BK
        , TASKLIST_OPERATION_BK
        , GROUP_COUNTER_DC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(TASKLIST_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as TASKLIST_GROUP_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(TASKLIST_OPERATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as TASKLIST_OPERATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(TASKLIST_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(TASKLIST_OPERATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_TASKLIST_OPERATION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(PLNAL::text), '^^') 
            , '||', IFNULL(TRIM(PLNFL::text), '^^') 
            , '||', IFNULL(TRIM(ZAEHL::text), '^^') 
            , '||', IFNULL(TRIM(DATUV::text), '^^') 
            , '||', IFNULL(TRIM(TECHV::text), '^^') 
            , '||', IFNULL(TRIM(AENNR::text), '^^') 
            , '||', IFNULL(TRIM(LOEKZ::text), '^^') 
            , '||', IFNULL(TRIM(PARKZ::text), '^^') 
            , '||', IFNULL(TRIM(ANDAT::text), '^^') 
            , '||', IFNULL(TRIM(ANNAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

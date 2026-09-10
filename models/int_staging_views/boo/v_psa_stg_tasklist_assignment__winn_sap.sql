---- SRC LAYER ----
WITH
SRC_a              as ( SELECT AEDAT, AENAM, AENNR, ANDAT, ANNAM, DATUV, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, KUNR, LIFNR, LOEKZ, MANDT, MATNR, MS_OBJECT, MS_OBJTYPE, PARKZ, PLNAL, PLNNR, PLNTY, POSNR, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSPNR, SUCHFELD, TECHV, VBELN, WERKS, ZAEHL, ZKRIZ FROM {{ source('sap_ecc_prd', 'z_mapl') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_mapl )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MANDT
      , MATNR
      , WERKS
      , PLNTY
      , PLNNR
      , PLNAL
      , ZKRIZ
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
      , LIFNR
      , KUNR
      , SUCHFELD
      , VBELN
      , POSNR
      , PSPNR
      , MS_OBJECT
      , MS_OBJTYPE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
      , PLNAL                                                        as                                   GROUP_COUNTER_DC
      , WERKS                                                        as                                           PLANT_BK
      , MATNR                                                        as                                            ITEM_BK
      , AENNR                                                        as                                   CHANGE_MASTER_BK
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
      , MATNR
      , WERKS
      , PLNTY
      , PLNNR
      , PLNAL
      , ZKRIZ
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
      , LIFNR
      , KUNR
      , SUCHFELD
      , VBELN
      , POSNR
      , PSPNR
      , MS_OBJECT
      , MS_OBJTYPE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , TASKLIST_GROUP_BK
      , GROUP_COUNTER_DC
      , PLANT_BK
      , ITEM_BK
      , CHANGE_MASTER_BK
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_MAPL'
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
        , MATNR
        , WERKS
        , PLNTY
        , PLNNR
        , PLNAL
        , ZKRIZ
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
        , LIFNR
        , KUNR
        , SUCHFELD
        , VBELN
        , POSNR
        , PSPNR
        , MS_OBJECT
        , MS_OBJTYPE
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , TASKLIST_GROUP_BK
        , GROUP_COUNTER_DC
        , PLANT_BK
        , ITEM_BK
        , CHANGE_MASTER_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(TASKLIST_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as TASKLIST_GROUP_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(TASKLIST_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CHANGE_MASTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CHANGE_MASTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CHANGE_MASTER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(PLNTY::text), '^^') 
            , '||', IFNULL(TRIM(PLNNR::text), '^^') 
            , '||', IFNULL(TRIM(ZKRIZ::text), '^^') 
            , '||', IFNULL(TRIM(DATUV::text), '^^') 
            , '||', IFNULL(TRIM(TECHV::text), '^^') 
            , '||', IFNULL(TRIM(AENNR::text), '^^') 
            , '||', IFNULL(TRIM(LOEKZ::text), '^^') 
            , '||', IFNULL(TRIM(PARKZ::text), '^^') 
            , '||', IFNULL(TRIM(ANDAT::text), '^^') 
            , '||', IFNULL(TRIM(ANNAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(KUNR::text), '^^') 
            , '||', IFNULL(TRIM(SUCHFELD::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(PSPNR::text), '^^') 
            , '||', IFNULL(TRIM(MS_OBJECT::text), '^^') 
            , '||', IFNULL(TRIM(MS_OBJTYPE::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

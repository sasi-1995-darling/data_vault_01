---- SRC LAYER ----
WITH
SRC_ca             as ( SELECT AEDAT_KAPA, AENAM_KAPA, BEGDA, CANUM, CAP_BACKFLUSH_PR, CAP_BACKFLUSH_SU, CAP_BACKFLUSH_TD, CAROL, ENDDA, FORK1, FORK2, FORK3, FORKN, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, ISTBED_KZ, KAPID, MANDT, OBJID, OBJTY, PROZT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, VERT1, VERT2, VERT3, VERTN, VGWT1, VGWT2, VGWT3, VGWTN FROM {{ source('sap_ecc_prd', 'z_crca') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_hd             as ( SELECT ARBPL, OBJID, OBJTY, WERKS, STAND FROM {{ source('sap_ecc_prd', 'z_crhd') }} as SRC 
                        qualify 1= row_number()over(partition by ARBPL, OBJTY, OBJID order by PSA_LOAD_DTS desc)  )

/*
SRC_ca             as ( SELECT * FROM sap_ecc_prd.z_crca )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_hd             as ( SELECT * FROM sap_ecc_prd.z_crhd )
*/
---- LOGIC LAYER ----

, LOGIC_ca as (
    SELECT
        KAPID                                                        as                                        CAPACITY_BK
      , MANDT
      , OBJTY
      , OBJID
      , CANUM
      , GLREQUEST
      , BEGDA
      , ENDDA
      , AEDAT_KAPA
      , AENAM_KAPA
      , KAPID
      , FORK1
      , FORK2
      , FORK3
      , FORKN
      , PROZT
      , VERT1
      , VERT2
      , VERT3
      , VERTN
      , CAROL
      , ISTBED_KZ
      , VGWT1
      , VGWT2
      , VGWT3
      , VGWTN
      , CAP_BACKFLUSH_SU
      , CAP_BACKFLUSH_PR
      , CAP_BACKFLUSH_TD
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
        ))                                                           as                                           LOAD_DTS
    FROM SRC_ca
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)

, LOGIC_hd as (
    SELECT
        ARBPL
      , WERKS
      , STAND
      , coalesce(nullif(trim(UPPER(ARBPL)), ''), '-1')       as WORK_CENTER_BK
      , coalesce(nullif(trim(UPPER(WERKS)), ''), '-1')       as PLANT_BK  
      , coalesce(nullif(trim(UPPER(STAND)), ''), '-1')       as WORK_CENTER_LOCATION_BK
      , OBJTY                                                as hd_OBJTY
      , OBJID                                                as hd_OBJID
    FROM SRC_hd
)
---- RENAME LAYER ----

, RENAME_hd as (
    SELECT
        ARBPL
      , WERKS
      , STAND
      , WORK_CENTER_BK
      , PLANT_BK
      , WORK_CENTER_LOCATION_BK
      , hd_OBJTY
      , hd_OBJID
    FROM LOGIC_hd
)

, RENAME_ca as (
    SELECT
        CAPACITY_BK
      , MANDT
      , OBJTY
      , OBJID
      , CANUM
      , GLREQUEST
      , BEGDA
      , ENDDA
      , AEDAT_KAPA
      , AENAM_KAPA
      , KAPID
      , FORK1
      , FORK2
      , FORK3
      , FORKN
      , PROZT
      , VERT1
      , VERT2
      , VERT3
      , VERTN
      , CAROL
      , ISTBED_KZ
      , VGWT1
      , VGWT2
      , VGWT3
      , VGWTN
      , CAP_BACKFLUSH_SU
      , CAP_BACKFLUSH_PR
      , CAP_BACKFLUSH_TD
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_ca
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_ca as (
    SELECT *
    FROM RENAME_ca
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_CRCA'
)

, FILTER_hd as (
    SELECT *
    FROM RENAME_hd
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_ca
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
    LEFT JOIN FILTER_hd
        ON OBJTY = hd_OBJTY AND OBJID = hd_OBJID
)

---- FINAL LAYER ----
SELECT
          WORK_CENTER_BK
        , PLANT_BK  
        , WORK_CENTER_LOCATION_BK
        , ARBPL
        , CAPACITY_BK
        , MANDT
        , OBJTY
        , OBJID
        , CANUM
        , GLREQUEST
        , BEGDA
        , ENDDA
        , AEDAT_KAPA
        , AENAM_KAPA
        , KAPID
        , FORK1
        , FORK2
        , FORK3
        , FORKN
        , PROZT
        , VERT1
        , VERT2
        , VERT3
        , VERTN
        , CAROL
        , ISTBED_KZ
        , VGWT1
        , VGWT2
        , VGWT3
        , VGWTN
        , CAP_BACKFLUSH_SU
        , CAP_BACKFLUSH_PR
        , CAP_BACKFLUSH_TD
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
          COALESCE(NULLIF(TRIM(CAST(WORK_CENTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as WORK_CENTER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(KAPID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CAPACITY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WORK_CENTER_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as WORK_CENTER_LOCATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(WORK_CENTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(WORK_CENTER_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(KAPID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_WORK_CENTER_CAPACITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(OBJTY::text), '^^') 
            , '||', IFNULL(TRIM(OBJID::text), '^^') 
            , '||', IFNULL(TRIM(CANUM::text), '^^')  
            , '||', IFNULL(TRIM(BEGDA::text), '^^') 
            , '||', IFNULL(TRIM(ENDDA::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT_KAPA::text), '^^') 
            , '||', IFNULL(TRIM(AENAM_KAPA::text), '^^') 
            , '||', IFNULL(TRIM(KAPID::text), '^^') 
            , '||', IFNULL(TRIM(FORK1::text), '^^') 
            , '||', IFNULL(TRIM(FORK2::text), '^^') 
            , '||', IFNULL(TRIM(FORK3::text), '^^') 
            , '||', IFNULL(TRIM(FORKN::text), '^^') 
            , '||', IFNULL(TRIM(PROZT::text), '^^') 
            , '||', IFNULL(TRIM(VERT1::text), '^^') 
            , '||', IFNULL(TRIM(VERT2::text), '^^') 
            , '||', IFNULL(TRIM(VERT3::text), '^^') 
            , '||', IFNULL(TRIM(VERTN::text), '^^') 
            , '||', IFNULL(TRIM(CAROL::text), '^^') 
            , '||', IFNULL(TRIM(ISTBED_KZ::text), '^^') 
            , '||', IFNULL(TRIM(VGWT1::text), '^^') 
            , '||', IFNULL(TRIM(VGWT2::text), '^^') 
            , '||', IFNULL(TRIM(VGWT3::text), '^^') 
            , '||', IFNULL(TRIM(VGWTN::text), '^^') 
            , '||', IFNULL(TRIM(CAP_BACKFLUSH_SU::text), '^^') 
            , '||', IFNULL(TRIM(CAP_BACKFLUSH_PR::text), '^^') 
            , '||', IFNULL(TRIM(CAP_BACKFLUSH_TD::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
---- SRC LAYER ----
WITH
SRC_cr             as ( SELECT AEDAT_TEXT, AENAM_TEXT, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, KTEXT, KTEXT_UP, MANDT, OBJID, OBJTY, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SPRAS FROM {{ source('sap_ecc_prd', 'z_crtx') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_hd             as ( SELECT ARBPL, OBJID, OBJTY, WERKS FROM {{ source('sap_ecc_prd', 'z_crhd') }} as SRC 
                        qualify 1= row_number()over(partition by ARBPL, OBJTY, OBJID order by PSA_LOAD_DTS desc)  )

/*
SRC_cr             as ( SELECT * FROM sap_ecc_prd.z_crtx )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_hd             as ( SELECT * FROM sap_ecc_prd.z_crhd )
*/
---- LOGIC LAYER ----

, LOGIC_cr as (
    SELECT
        MANDT
      , OBJTY
      , OBJID
      , SPRAS
      , GLREQUEST
      , AEDAT_TEXT
      , AENAM_TEXT
      , KTEXT
      , KTEXT_UP
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
    FROM SRC_cr
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
      , coalesce(nullif(trim(UPPER(ARBPL)), ''), '-1')               as WORK_CENTER_BK
      , OBJTY                                                        as hd_OBJTY
      , OBJID                                                        as hd_OBJID
      , coalesce(nullif(trim(WERKS), ''), '-1')                      as PLANT_BK
    FROM SRC_hd
)
---- RENAME LAYER ----

, RENAME_hd as (
    SELECT
        ARBPL
      , WORK_CENTER_BK  
      , hd_OBJTY
      , hd_OBJID
      , PLANT_BK
    FROM LOGIC_hd
)

, RENAME_cr as (
    SELECT
        MANDT
      , OBJTY
      , OBJID
      , SPRAS
      , GLREQUEST
      , AEDAT_TEXT
      , AENAM_TEXT
      , KTEXT
      , KTEXT_UP
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_cr
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_cr as (
    SELECT *
    FROM RENAME_cr
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_CRTX'
)

, FILTER_hd as (
    SELECT *
    FROM RENAME_hd
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_cr
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
    INNER JOIN FILTER_hd
        ON OBJTY = hd_OBJTY AND OBJID = hd_OBJID
)

---- FINAL LAYER ----
SELECT
          WORK_CENTER_BK
        , PLANT_BK  
        , ARBPL
        , MANDT
        , OBJTY
        , OBJID
        , SPRAS
        , GLREQUEST
        , AEDAT_TEXT
        , AENAM_TEXT
        , KTEXT
        , KTEXT_UP
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
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(OBJTY::text), '^^') 
            , '||', IFNULL(TRIM(OBJID::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(KTEXT::text), '^^') 
            , '||', IFNULL(TRIM(KTEXT_UP::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
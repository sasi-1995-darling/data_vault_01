---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_stko') }} as SRC  ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_stko )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        STLNR                                                        as                                             BOM_BK
      , MANDT
      , STLTY
      , STLNR
      , STLAL
      , STKOZ
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LKENZ
      , LOEKZ
      , VGKZL
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , BMEIN
      , BMENG
      , CADKZ
      , LABOR
      , LTXSP
      , STKTX
      , STLST
      , WRKAN
      , DVDAT
      , DVNAM
      , AEHLP
      , ALEKZ
      , GUIDX
      , VALID_TO
      , VALID_TO_RKEY
      , ECN_TO
      , ECN_TO_RKEY
      , ZZSCALE_COUNT
      , ZZWGT_TOLERANCE
      , ZZLGHT_CUR_SET
      , ZZVALVE_TESTER
      , ZZSPOUT_TESTER
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
      , STLAL
      , STKOZ
      , GLREQUEST
      , DATUV
      , TECHV
      , AENNR
      , LKENZ
      , LOEKZ
      , VGKZL
      , ANDAT
      , ANNAM
      , AEDAT
      , AENAM
      , BMEIN
      , BMENG
      , CADKZ
      , LABOR
      , LTXSP
      , STKTX
      , STLST
      , WRKAN
      , DVDAT
      , DVNAM
      , AEHLP
      , ALEKZ
      , GUIDX
      , VALID_TO
      , VALID_TO_RKEY
      , ECN_TO
      , ECN_TO_RKEY
      , ZZSCALE_COUNT
      , ZZWGT_TOLERANCE
      , ZZLGHT_CUR_SET
      , ZZVALVE_TESTER
      , ZZSPOUT_TESTER
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_STKO' 
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
        , STLAL
        , STKOZ
        , GLREQUEST
        , DATUV
        , TECHV
        , AENNR
        , LKENZ
        , LOEKZ
        , VGKZL
        , ANDAT
        , ANNAM
        , AEDAT
        , AENAM
        , BMEIN
        , BMENG
        , CADKZ
        , LABOR
        , LTXSP
        , STKTX
        , STLST
        , WRKAN
        , DVDAT
        , DVNAM
        , AEHLP
        , ALEKZ
        , GUIDX
        , VALID_TO
        , VALID_TO_RKEY
        , ECN_TO
        , ECN_TO_RKEY
        , ZZSCALE_COUNT
        , ZZWGT_TOLERANCE
        , ZZLGHT_CUR_SET
        , ZZVALVE_TESTER
        , ZZSPOUT_TESTER
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
            , '||', IFNULL(TRIM(STKOZ::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(DATUV::text), '^^') 
            , '||', IFNULL(TRIM(TECHV::text), '^^') 
            , '||', IFNULL(TRIM(AENNR::text), '^^') 
            , '||', IFNULL(TRIM(LKENZ::text), '^^') 
            , '||', IFNULL(TRIM(LOEKZ::text), '^^') 
            , '||', IFNULL(TRIM(VGKZL::text), '^^') 
            , '||', IFNULL(TRIM(ANDAT::text), '^^') 
            , '||', IFNULL(TRIM(ANNAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(BMEIN::text), '^^') 
            , '||', IFNULL(TRIM(BMENG::text), '^^') 
            , '||', IFNULL(TRIM(CADKZ::text), '^^') 
            , '||', IFNULL(TRIM(LABOR::text), '^^') 
            , '||', IFNULL(TRIM(LTXSP::text), '^^') 
            , '||', IFNULL(TRIM(STKTX::text), '^^') 
            , '||', IFNULL(TRIM(STLST::text), '^^') 
            , '||', IFNULL(TRIM(WRKAN::text), '^^') 
            , '||', IFNULL(TRIM(DVDAT::text), '^^') 
            , '||', IFNULL(TRIM(DVNAM::text), '^^') 
            , '||', IFNULL(TRIM(AEHLP::text), '^^') 
            , '||', IFNULL(TRIM(ALEKZ::text), '^^') 
            , '||', IFNULL(TRIM(GUIDX::text), '^^') 
            , '||', IFNULL(TRIM(VALID_TO::text), '^^') 
            , '||', IFNULL(TRIM(VALID_TO_RKEY::text), '^^') 
            , '||', IFNULL(TRIM(ECN_TO::text), '^^') 
            , '||', IFNULL(TRIM(ECN_TO_RKEY::text), '^^') 
            , '||', IFNULL(TRIM(ZZSCALE_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(ZZWGT_TOLERANCE::text), '^^') 
            , '||', IFNULL(TRIM(ZZLGHT_CUR_SET::text), '^^') 
            , '||', IFNULL(TRIM(ZZVALVE_TESTER::text), '^^') 
            , '||', IFNULL(TRIM(ZZSPOUT_TESTER::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_a              as ( SELECT DIMEN, FLDFA, FLDPL, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, MANDT, PARID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, UNIT, VALUE_DEF, VGFLD, VKALK, VKAPA, VKAPF, VRWRT, VTERM FROM {{ source('sap_ecc_prd', 'z_tc20') }} as SRC  ),
SRC_b              as ( SELECT PARID, SPRAS, TXT, TXTLG FROM {{ source('sap_ecc_prd', 'z_tc20t') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_tc20 )
SRC_b              as ( SELECT * FROM sap_ecc_prd.z_tc20t )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        PARID                                                        as                                           PARID_DC
      , MANDT
      , PARID
      , GLREQUEST
      , VRWRT
      , FLDPL
      , FLDFA
      , DIMEN
      , UNIT
      , VALUE_DEF
      , VGFLD
      , VKALK
      , VKAPA
      , VKAPF
      , VTERM
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
    FROM SRC_a
)

, LOGIC_b as (
    SELECT
        SPRAS
      , PARID as PARAMETER_ID
      , TXT
      , TXTLG
    FROM SRC_b
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
        PARID_DC
      , MANDT
      , PARID
      , GLREQUEST
      , VRWRT
      , FLDPL
      , FLDFA
      , DIMEN
      , UNIT
      , VALUE_DEF
      , VGFLD
      , VKALK
      , VKAPA
      , VKAPF
      , VTERM
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_a
)

, RENAME_b as (
    SELECT
        SPRAS
      , PARAMETER_ID
      , TXT
      , TXTLG
    FROM LOGIC_b
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

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_TC20'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    LEFT JOIN FILTER_b
        ON FILTER_a.parid = FILTER_b.PARAMETER_ID
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          COALESCE(NULLIF(TRIM(UNIT ), ''), '-1')                                                          as UOM_BK
        , PARID_DC
        , MANDT
        , PARID
        , GLREQUEST
        , VRWRT
        , FLDPL
        , FLDFA
        , DIMEN
        , UNIT
        , VALUE_DEF
        , VGFLD
        , VKALK
        , VKAPA
        , VKAPF
        , VTERM
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , SPRAS
        , TXT
        , TXTLG
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PARID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_UOM_FORMULA_PATTERN_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as UOM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(VRWRT::text), '^^') 
            , '||', IFNULL(TRIM(FLDPL::text), '^^') 
            , '||', IFNULL(TRIM(FLDFA::text), '^^') 
            , '||', IFNULL(TRIM(DIMEN::text), '^^') 
            , '||', IFNULL(TRIM(VALUE_DEF::text), '^^') 
            , '||', IFNULL(TRIM(VGFLD::text), '^^') 
            , '||', IFNULL(TRIM(VKALK::text), '^^') 
            , '||', IFNULL(TRIM(VKAPA::text), '^^') 
            , '||', IFNULL(TRIM(VKAPF::text), '^^') 
            , '||', IFNULL(TRIM(VTERM::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^')
            , '||', IFNULL(TRIM(TXT::text), '^^') 
            , '||', IFNULL(TRIM(TXTLG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

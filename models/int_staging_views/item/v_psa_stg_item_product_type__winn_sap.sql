---- SRC LAYER ----
WITH
SRC_zpdtpt         as ( SELECT GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SPRAS, TXT30, ZZDTP FROM {{ source('sap_ecc_prd', 'z_zpdtpt') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_zpdtpt         as ( SELECT * FROM sap_ecc_prd.z_zpdtpt )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_zpdtpt as (
    SELECT
        MANDT
      , SPRAS
      , ZZDTP
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
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
      , TXT30                                                        as                                            Z_TXT30
    FROM SRC_zpdtpt
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_zpdtpt as (
    SELECT
        MANDT
      , SPRAS
      , ZZDTP
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , Z_TXT30
    FROM LOGIC_zpdtpt
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_zpdtpt as (
    SELECT *
    FROM RENAME_zpdtpt
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_ZPDTPT'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_zpdtpt
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          MANDT
        , SPRAS
        , ZZDTP
        , GLREQUEST
        , GLSOURCESYSTEM
        , UPPER(TRIM(Z_TXT30))                                         as TXT30
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
FROM JOIN_RESULT

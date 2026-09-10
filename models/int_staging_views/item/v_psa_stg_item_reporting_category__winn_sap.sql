---- SRC LAYER ----
WITH
SRC_zrepcatgt      as ( SELECT GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SPRAS, ZZREPCATG, ZZREPCATGD FROM {{ source('sap_ecc_prd', 'z_zrepcatgt') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_zrepcatgt      as ( SELECT * FROM sap_ecc_prd.z_zrepcatgt )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_zrepcatgt as (
    SELECT
        MANDT
      , SPRAS
      , ZZREPCATG
      , GLREQUEST
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
      , ZZREPCATGD                                                   as                                       S_ZZREPCATGD
    FROM SRC_zrepcatgt
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_zrepcatgt as (
    SELECT
        MANDT
      , SPRAS
      , ZZREPCATG
      , GLREQUEST
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , S_ZZREPCATGD
    FROM LOGIC_zrepcatgt
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_zrepcatgt as (
    SELECT *
    FROM RENAME_zrepcatgt
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_ZREPTCATGT'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_zrepcatgt
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          MANDT
        , SPRAS
        , ZZREPCATG
        , GLREQUEST
        , UPPER(TRIM(S_ZZREPCATGD))                                    as ZZREPCATGD
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
FROM JOIN_RESULT

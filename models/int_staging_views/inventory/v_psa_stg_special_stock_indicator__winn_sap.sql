---- SRC LAYER ----
WITH
SRC_src            as ( SELECT GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SOBFI, SOBKZ, SOBLO, SOBVO FROM {{ source('sap_ecc_prd', 'z_t148') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_src1           as ( SELECT SOBKZ, SOTXT, SPRAS FROM {{ source('sap_ecc_prd', 'z_t148t') }} as SRC  )

/*
SRC_src            as ( SELECT * FROM sap_ecc_prd.z_t148 )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_src1           as ( SELECT * FROM sap_ecc_prd.z_t148t )
*/
---- LOGIC LAYER ----

, LOGIC_src as (
    SELECT
        MANDT
      , SOBKZ
      , GLREQUEST
      , SOBFI
      , SOBLO
      , SOBVO
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
    FROM SRC_src
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)

, LOGIC_src1 as (
    SELECT
        SPRAS
      , SOBKZ                                                        as                                           S3_SOBKZ
      , SOTXT
    FROM SRC_src1
)
---- RENAME LAYER ----

, RENAME_src as (
    SELECT
        MANDT
      , SOBKZ
      , GLREQUEST
      , SOBFI
      , SOBLO
      , SOBVO
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_src
)

, RENAME_src1 as (
    SELECT
        SPRAS
      , S3_SOBKZ
      , SOTXT
    FROM LOGIC_src1
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_src as (
    SELECT *
    FROM RENAME_src
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T148' 
)

, FILTER_src1 as (
    SELECT *
    FROM RENAME_src1
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_src
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
    INNER JOIN FILTER_src1
        ON SOBKZ = S3_SOBKZ
)

---- FINAL LAYER ----
SELECT
          MANDT
        , SOBKZ
        , GLREQUEST
        , SOBFI
        , SOBLO
        , SOBVO
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , SPRAS
        , SOTXT
        , LOAD_DTS
        , REC_SRC
        , BKCC
FROM JOIN_RESULT

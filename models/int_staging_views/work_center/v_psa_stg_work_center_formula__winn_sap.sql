---- SRC LAYER ----
WITH
SRC_a              as ( SELECT FTEXT, FTEXT2, FTEXT3, GENER, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, IDENT, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, VKALK, VKAPA, VKAPF, VTERM FROM {{ source('sap_ecc_prd', 'z_tc25') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_b              as ( SELECT IDENT, SPRAS, TXT FROM {{ source('sap_ecc_prd', 'z_tc25t') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_tc25 )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_b              as ( SELECT * FROM sap_ecc_prd.z_tc25t )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MANDT
      , IDENT
      , GLREQUEST
      , FTEXT
      , FTEXT2
      , FTEXT3
      , GENER
      , VKALK
      , VKAPA
      , VKAPF
      , VTERM
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

, LOGIC_b as (
    SELECT
        SPRAS
      , TXT
      , IDENT                                                        as                                            b_IDENT
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        MANDT
      , IDENT
      , GLREQUEST
      , FTEXT
      , FTEXT2
      , FTEXT3
      , GENER
      , VKALK
      , VKAPA
      , VKAPF
      , VTERM
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_a
)

, RENAME_b as (
    SELECT
        SPRAS
      , TXT
      , b_IDENT
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

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_TC23'
)

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
    LEFT JOIN FILTER_b
        ON IDENT = b_IDENT
)

---- FINAL LAYER ----
SELECT
          MANDT
        , IDENT
        , GLREQUEST
        , FTEXT
        , FTEXT2
        , FTEXT3
        , GENER
        , VKALK
        , VKAPA
        , VKAPF
        , VTERM
        , SPRAS
        , TXT
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

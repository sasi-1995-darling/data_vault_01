---- SRC LAYER ----
WITH
SRC_z_t416t        as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_t416t') }} as SRC  ),
SRC_z_t002t        as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_t002t') }} as SRC  )

/*
SRC_z_t416t        as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_t416t') }} as SRC  )
, SRC_z_t002t      as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_t002t') }} as SRC  )
*/
---- LOGIC LAYER ----

, LOGIC_z_t416t as (
    SELECT
        MANDT
      , SPRAS
      , STLAN
      , GLREQUEST
      , GLSOURCESYSTEM
      , ANTXT
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
        ))                                                     as                                           LOAD_DTS
    FROM SRC_z_t416t
)

, LOGIC_z_t002t as (
    SELECT
        SPRAS                                                        as                                      z_t002t_SPRAS
      , SPTXT
    FROM SRC_z_t002t
)
---- RENAME LAYER ----

, RENAME_z_t416t as (
    SELECT
        MANDT
      , SPRAS
      , STLAN
      , GLREQUEST
      , GLSOURCESYSTEM
      , ANTXT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_z_t416t
)

, RENAME_z_t002t as (
    SELECT
        z_t002t_SPRAS
      , SPTXT
    FROM LOGIC_z_t002t
)
---- FILTER LAYER ----

, FILTER_z_t416t as (
    SELECT *
    FROM RENAME_z_t416t
)

, FILTER_z_t002t as (
    SELECT *
    FROM RENAME_z_t002t
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_z_t416t
    LEFT JOIN FILTER_z_t002t
        ON SPRAS = z_t002t_SPRAS
)

---- FINAL LAYER ----
SELECT
          MANDT
        , SPTXT
        , SPRAS
        , STLAN
        , GLREQUEST
        , GLSOURCESYSTEM
        , ANTXT
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
FROM JOIN_RESULT

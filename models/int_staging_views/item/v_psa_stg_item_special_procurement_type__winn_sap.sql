---- SRC LAYER ----
WITH
SRC_s              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_t460t') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_s              as ( SELECT * FROM sap_ecc_prd.z_t460t )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        MANDT
      , SPRAS
      , WERKS
      , SOBSL
      , GLREQUEST
      , GLSOURCESYSTEM
      , LTEXT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        ))                                                           as                                           LOAD_DTS
    FROM SRC_s
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        MANDT
      , SPRAS
      , WERKS
      , SOBSL
      , GLREQUEST
      , GLSOURCESYSTEM
      , LTEXT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_s
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T460T'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          MANDT
        , SPRAS
        , WERKS
        , SOBSL
        , GLREQUEST
        , GLSOURCESYSTEM
        , LTEXT
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(SOBSL::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(LTEXT::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(LOAD_DTS::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

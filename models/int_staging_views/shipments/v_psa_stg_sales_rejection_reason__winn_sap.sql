---- SRC LAYER ----
WITH
SRC_tvagt          as ( SELECT ABGRU, BEZEI, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SPRAS FROM {{ source('sap_ecc_prd', 'z_tvagt') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_tvagt          as ( SELECT * FROM sap_ecc_prd.z_tvagt )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_tvagt as (
    SELECT
        ABGRU                                                        as                          SALES_REJECTION_REASON_BK
      , MANDT
      , SPRAS
      , ABGRU
      , GLREQUEST
      , BEZEI                                                        as                                            Z_BEZEI
      , UPPER(TRIM(Z_BEZEI))                                         as                                              BEZEI
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            CONVERT_TIMEZONE(
            'UTC',
            TO_TIMESTAMP_NTZ(
            SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16),
            'YYYYMMDDHH24MISS.FF9'
            )
            )
        )                                                            as                                           LOAD_DTS
    FROM SRC_tvagt
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_tvagt as (
    SELECT
        SALES_REJECTION_REASON_BK
      , MANDT
      , SPRAS
      , ABGRU
      , GLREQUEST
      , Z_BEZEI
      , BEZEI
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_tvagt
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_tvagt as (
    SELECT *
    FROM RENAME_tvagt
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_TVAGT'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_tvagt
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          SALES_REJECTION_REASON_BK
        , MANDT
        , SPRAS
        , ABGRU
        , GLREQUEST
        , Z_BEZEI
        , BEZEI
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(ABGRU::text), '^^') 
            , '||', IFNULL(TRIM(Z_BEZEI::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

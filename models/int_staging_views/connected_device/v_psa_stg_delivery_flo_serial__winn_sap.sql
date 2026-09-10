---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT CREATED_BY, CREATE_DATE, CREATE_TIME, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SERIALNO, VBELN FROM {{ source('sap_ecc_prd', 'z_zflo_serialnos') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM SAP_ECC_PRD.Z_ZFLO_SERIALNOS )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        VBELN                                                        as                                        DELIVERY_BK
      , IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            CONVERT_TIMEZONE('UTC',TO_TIMESTAMP_NTZ(
            SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16),'YYYYMMDDHH24MISS.FF9' )
        ))                        as                                           LOAD_DTS

      , MANDT
      , VBELN
      , SERIALNO
      , GLREQUEST
      , GLSOURCESYSTEM
      , CREATED_BY
      , CREATE_DATE
      , CREATE_TIME
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_D1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_D1 as (
    SELECT
        DELIVERY_BK
      , LOAD_DTS
      , MANDT
      , VBELN
      , SERIALNO
      , GLREQUEST
      , GLSOURCESYSTEM
      , CREATED_BY
      , CREATE_DATE
      , CREATE_TIME
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_D1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_D1 as (
    SELECT *
    FROM RENAME_D1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.SAP_ECC_PRD.Z_ZFLO_SERIALNOS'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          DELIVERY_BK
        , LOAD_DTS
        , MANDT
        , VBELN
        , SERIALNO
        , GLREQUEST
        , GLSOURCESYSTEM
        , CREATED_BY
        , CREATE_DATE
        , CREATE_TIME
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DELIVERY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DELIVERY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(SERIALNO::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATE_TIME::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLCHANGETIME::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

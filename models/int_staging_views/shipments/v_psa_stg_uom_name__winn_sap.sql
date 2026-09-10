---- SRC LAYER ----
WITH
SRC_psa            as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_t006a') }} as SRC ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_psa            as ( SELECT * FROM sap_ecc_prd.z_t006a )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_psa as (
    SELECT
        MSEHI                                                        as                                             UOM_BK
      , MANDT
      , SPRAS
      , MSEHI
      , GLREQUEST
      , GLSOURCESYSTEM
      , MSEH3
      , MSEH6
      , MSEHT
      , MSEHL
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
    FROM SRC_psa
)

, LOGIC_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_psa as (
    SELECT
        UOM_BK
      , MANDT
      , SPRAS
      , MSEHI
      , GLREQUEST
      , GLSOURCESYSTEM
      , MSEH3
      , MSEH6
      , MSEHT
      , MSEHL
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_psa
)

, RENAME_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_psa as (
    SELECT *
    FROM RENAME_psa
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T006A'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_psa
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          UOM_BK
        , MANDT
        , SPRAS
        , MSEHI
        , GLREQUEST
        , GLSOURCESYSTEM
        , MSEH3
        , MSEH6
        , MSEHT
        , MSEHL
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MSEHI as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as UOM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^')             
            , '||', IFNULL(TRIM(MSEH3::text), '^^') 
            , '||', IFNULL(TRIM(MSEH6::text), '^^') 
            , '||', IFNULL(TRIM(MSEHT::text), '^^') 
            , '||', IFNULL(TRIM(MSEHL::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

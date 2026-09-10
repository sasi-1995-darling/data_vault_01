---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_tcurr') }} as SRC  ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_tcurr )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        TO_DATE(TO_CHAR(ROUND(99999999-GDATU)), 'YYYYMMDD')          as                                    CONVERSION_DATE
      , CONCAT( FCURR, '||', TCURR, '||',KURST, '||', CONVERSION_DATE) as                                      CURR_RATES_BK
      , MANDT
      , KURST
      , FCURR
      , TCURR
      , GDATU
      , GLREQUEST
      , GLSOURCESYSTEM
      , UKURS
      , FFACT
      , TFACT
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
    FROM SRC_a
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
        CONVERSION_DATE
      , CURR_RATES_BK
      , MANDT
      , KURST
      , FCURR
      , TCURR
      , GDATU
      , GLREQUEST
      , GLSOURCESYSTEM
      , UKURS
      , FFACT
      , TFACT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_a
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_TCURR'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CONVERSION_DATE
        , CURR_RATES_BK
        , MANDT
        , KURST
        , FCURR
        , TCURR
        , GDATU
        , GLREQUEST
        , GLSOURCESYSTEM
        , UKURS
        , FFACT
        , TFACT
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
            , '||', IFNULL(TRIM(KURST::text), '^^') 
            , '||', IFNULL(TRIM(FCURR::text), '^^') 
            , '||', IFNULL(TRIM(TCURR::text), '^^') 
            , '||', IFNULL(TRIM(GDATU::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(UKURS::text), '^^') 
            , '||', IFNULL(TRIM(FFACT::text), '^^') 
            , '||', IFNULL(TRIM(TFACT::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

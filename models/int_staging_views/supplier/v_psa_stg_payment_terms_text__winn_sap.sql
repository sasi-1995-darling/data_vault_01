---- SRC LAYER ----
WITH
SRC_S              as ( SELECT GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SPRAS, TEXT1, ZTAGG, ZTERM FROM {{ source('sap_ecc_prd', 'z_t052u') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_t052u )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        ZTERM                                                        as                                    PAYMENT_TERM_BK
      , ZTERM
      , SPRAS
      , ZTAGG
      , MANDT
      , GLREQUEST
      , TEXT1
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        ))                                                           as                                  GLCHANGETIME_DTTM
      , CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y',PSA_LOAD_DTS,GLCHANGETIME_DTTM)) as                                           LOAD_DTS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        PAYMENT_TERM_BK
      , ZTERM
      , SPRAS
      , ZTAGG
      , MANDT
      , GLREQUEST
      , TEXT1
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , LOAD_DTS
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T052U'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PAYMENT_TERM_BK
        , ZTERM
        , SPRAS
        , ZTAGG
        , MANDT
        , GLREQUEST
        , TEXT1
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , GLCHANGETIME_DTTM
        , LOAD_DTS
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ZTERM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(ZTAGG::text), '^^') 
            , '||', IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(TEXT1::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(GLCHANGETIME::text), '^^') 
            , '||', IFNULL(TRIM(PSA_LOAD_DTS::text), '^^') 
            , '||', IFNULL(TRIM(PSA_RECORD_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_cepct') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_cepct )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(coalesce(SPRAS,'-1'))                                as                                    LANGUAGE_KEY_BK
      , to_char(coalesce(PRCTR,'-1'))                                as                                   PROFIT_CENTER_BK
      , to_char(coalesce(DATBI,'-1'))                                as                                      VALID_DATE_BK
      , to_char(coalesce(KOKRS,'-1'))                                as                                CONTROLLING_AREA_BK
      , MANDT
      , SPRAS
      , PRCTR
      , DATBI
      , KOKRS
      , GLREQUEST
      , GLSOURCESYSTEM
      , KTEXT
      , LTEXT
      , MCTXT
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
        ))                                                           as                                           LOAD_DTS
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
        LANGUAGE_KEY_BK
      , PROFIT_CENTER_BK
      , VALID_DATE_BK
      , CONTROLLING_AREA_BK
      , MANDT
      , SPRAS
      , PRCTR
      , DATBI
      , KOKRS
      , GLREQUEST
      , GLSOURCESYSTEM
      , KTEXT
      , LTEXT
      , MCTXT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_CEPCT'
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
          LANGUAGE_KEY_BK
        , PROFIT_CENTER_BK
        , VALID_DATE_BK
        , CONTROLLING_AREA_BK
        , MANDT
        , SPRAS
        , PRCTR
        , DATBI
        , KOKRS
        , GLREQUEST
        , GLSOURCESYSTEM
        , KTEXT
        , LTEXT
        , MCTXT
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PROFIT_CENTER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VALID_DATE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as OBJECT_NUMBER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(PRCTR::text), '^^') 
            , '||', IFNULL(TRIM(DATBI::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(KTEXT::text), '^^') 
            , '||', IFNULL(TRIM(LTEXT::text), '^^') 
            , '||', IFNULL(TRIM(MCTXT::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

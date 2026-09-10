---- SRC LAYER ----
WITH
SRC_s              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_t460a') }} as SRC ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_s              as ( SELECT * FROM sap_ecc_prd.z_t460a )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        MANDT
      , WERKS
      , WERKS                                     as                                             PLANT_BK
      , coalesce(nullif(trim(WRK02), ''), '-1')   as                                             PLANT_TRANSFER_BK
      , SOBSL
      , GLREQUEST
      , BESKZ
      , SOBES
      , WRK02
      , CLCOR
      , DUMPS
      , REWFG
      , REWRK
      , DIRPR
      , UMLDB
      , ADDIN
      , MLSCR
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
      , WERKS
      , PLANT_BK
      , PLANT_TRANSFER_BK
      , SOBSL
      , GLREQUEST
      , BESKZ
      , SOBES
      , WRK02
      , CLCOR
      , DUMPS
      , REWFG
      , REWRK
      , DIRPR
      , UMLDB
      , ADDIN
      , MLSCR
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T460A'
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
        , WERKS
        , PLANT_BK
        , PLANT_TRANSFER_BK
        , SOBSL
        , GLREQUEST
        , BESKZ
        , SOBES
        , WRK02
        , CLCOR
        , DUMPS
        , REWFG
        , REWRK
        , DIRPR
        , UMLDB
        , ADDIN
        , MLSCR
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_TRANSFER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_TRANSFER_HK                
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SOBSL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_TRANSFER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SLNK_LNK_SAME_AS_PLANT_TRANSFER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(SOBSL::text), '^^') 
            , '||', IFNULL(TRIM(BESKZ::text), '^^') 
            , '||', IFNULL(TRIM(SOBES::text), '^^') 
            , '||', IFNULL(TRIM(WRK02::text), '^^') 
            , '||', IFNULL(TRIM(CLCOR::text), '^^') 
            , '||', IFNULL(TRIM(DUMPS::text), '^^') 
            , '||', IFNULL(TRIM(REWFG::text), '^^') 
            , '||', IFNULL(TRIM(REWRK::text), '^^') 
            , '||', IFNULL(TRIM(DIRPR::text), '^^') 
            , '||', IFNULL(TRIM(UMLDB::text), '^^') 
            , '||', IFNULL(TRIM(ADDIN::text), '^^') 
            , '||', IFNULL(TRIM(MLSCR::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
            , '||', IFNULL(TRIM(LOAD_DTS::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
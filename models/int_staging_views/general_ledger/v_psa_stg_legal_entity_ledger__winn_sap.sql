---- SRC LAYER ----
WITH
SRC_S          as ( SELECT MANDT, BUKRS, RLDNR, GLREQUEST, BUKZ, PRKZ, PERIV, GLSIP, VTRHJ, CURR1, CURR2, CURR3, RCCUR, LCCUR, OCCUR, CURT1, CURT2, CURT3, LOGSYS, ALTSV, KTOPL, GLDELFLAG, GLCHANGETIME, GLSOURCESYSTEM, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND FROM {{ source('sap_ecc_prd', 'z_t882') }} as SRC  ),
SRC_A          as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S          as ( SELECT * FROM sap_ecc_prd.z_t882 )
SRC_A          as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        MANDT
      , BUKRS
      , RLDNR
      , GLREQUEST
      , BUKZ
      , PRKZ
      , PERIV
      , GLSIP
      , VTRHJ
      , CURR1
      , CURR2
      , CURR3
      , RCCUR
      , LCCUR
      , OCCUR
      , CURT1
      , CURT2
      , CURT3
      , LOGSYS
      , ALTSV
      , KTOPL
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
        MANDT
      , BUKRS
      , RLDNR
      , GLREQUEST
      , BUKZ
      , PRKZ
      , PERIV
      , GLSIP
      , VTRHJ
      , CURR1
      , CURR2
      , CURR3
      , RCCUR
      , LCCUR
      , OCCUR
      , CURT1
      , CURT2
      , CURT3
      , LOGSYS
      , ALTSV
      , KTOPL
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T882'
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
          to_char(coalesce(nullif(trim(BUKRS), ''), '-1'))                                as LEGAL_ENTITY_BK
        , to_char(coalesce(nullif(trim(RLDNR), ''), '-1'))                                as LEDGER_BK
        , MANDT
        , BUKRS
        , RLDNR
        , GLREQUEST
        , BUKZ
        , PRKZ
        , PERIV
        , GLSIP
        , VTRHJ
        , CURR1
        , CURR2
        , CURR3
        , RCCUR
        , LCCUR
        , OCCUR
        , CURT1
        , CURT2
        , CURT3
        , LOGSYS
        , ALTSV
        , KTOPL
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
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
        ))  as LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LEGAL_ENTITY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LEDGER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_LEDGER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LEGAL_ENTITY_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LEDGER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEDGER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(RLDNR::text), '^^') 
            , '||', IFNULL(TRIM(BUKZ::text), '^^') 
            , '||', IFNULL(TRIM(PRKZ::text), '^^') 
            , '||', IFNULL(TRIM(PERIV::text), '^^') 
            , '||', IFNULL(TRIM(GLSIP::text), '^^') 
            , '||', IFNULL(TRIM(VTRHJ::text), '^^') 
            , '||', IFNULL(TRIM(CURR1::text), '^^') 
            , '||', IFNULL(TRIM(CURR2::text), '^^') 
            , '||', IFNULL(TRIM(CURR3::text), '^^') 
            , '||', IFNULL(TRIM(RCCUR::text), '^^') 
            , '||', IFNULL(TRIM(LCCUR::text), '^^') 
            , '||', IFNULL(TRIM(OCCUR::text), '^^') 
            , '||', IFNULL(TRIM(CURT1::text), '^^') 
            , '||', IFNULL(TRIM(CURT2::text), '^^') 
            , '||', IFNULL(TRIM(CURT3::text), '^^') 
            , '||', IFNULL(TRIM(LOGSYS::text), '^^') 
            , '||', IFNULL(TRIM(ALTSV::text), '^^') 
            , '||', IFNULL(TRIM(KTOPL::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

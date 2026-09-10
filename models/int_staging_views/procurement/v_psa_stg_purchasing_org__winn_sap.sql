---- SRC LAYER ----
WITH
SRC_t024           as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_t024') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_t024           as ( SELECT * FROM sap_ecc_prd.Z_T024 )
, SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_t024 as (
    SELECT
        EKGRP                                                        as                                  PURCHASING_ORG_BK
      , MANDT
      , EKGRP
      , EKNAM
      , EKTEL
      , LDEST
      , TELFX
      , TEL_NUMBER
      , TEL_EXTENS
      , SMTP_ADDR
      , ERNAM
      , MSNAM
      , ZZTMCHG
      , ZZMATNR
      , ZNEWMTW
      , ZCOREMTW
      , MNCOD
      , GLDELFLAG
      , GLREQUEST
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
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_t024
)

, LOGIC_ref_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_ref_bkcc
)
---- RENAME LAYER ----

, RENAME_t024 as (
    SELECT
        PURCHASING_ORG_BK
      , MANDT
      , EKGRP
      , EKNAM
      , EKTEL
      , LDEST
      , TELFX
      , TEL_NUMBER
      , TEL_EXTENS
      , SMTP_ADDR
      , ERNAM
      , MSNAM
      , ZZTMCHG
      , ZZMATNR
      , ZNEWMTW
      , ZCOREMTW
      , MNCOD
      , GLDELFLAG
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_t024
)

, RENAME_ref_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_ref_bkcc
)
---- FILTER LAYER ----

, FILTER_t024 as (
    SELECT *
    FROM RENAME_t024
)

, FILTER_ref_bkcc as (
    SELECT *
    FROM RENAME_ref_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T024'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_t024
    INNER JOIN FILTER_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PURCHASING_ORG_BK
        , MANDT
        , EKGRP
        , EKNAM
        , EKTEL
        , LDEST
        , TELFX
        , TEL_NUMBER
        , TEL_EXTENS
        , SMTP_ADDR
        , ERNAM
        , MSNAM
        , ZZTMCHG
        , ZZMATNR
        , ZNEWMTW
        , ZCOREMTW
        , MNCOD
        , GLDELFLAG
        , GLREQUEST
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , GLCHANGETIME_DTTM
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EKGRP as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_ORG_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(EKNAM::text), '^^') 
            , '||', IFNULL(TRIM(EKTEL::text), '^^') 
            , '||', IFNULL(TRIM(LDEST::text), '^^') 
            , '||', IFNULL(TRIM(TELFX::text), '^^') 
            , '||', IFNULL(TRIM(TEL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(TEL_EXTENS::text), '^^') 
            , '||', IFNULL(TRIM(SMTP_ADDR::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(MSNAM::text), '^^') 
            , '||', IFNULL(TRIM(ZZTMCHG::text), '^^') 
            , '||', IFNULL(TRIM(ZZMATNR::text), '^^') 
            , '||', IFNULL(TRIM(ZNEWMTW::text), '^^') 
            , '||', IFNULL(TRIM(ZCOREMTW::text), '^^') 
            , '||', IFNULL(TRIM(MNCOD::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

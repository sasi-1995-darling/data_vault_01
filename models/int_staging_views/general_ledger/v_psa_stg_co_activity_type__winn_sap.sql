---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_csla') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_csla )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
      to_char(coalesce(LSTAR,'-1'))                                as ACTIVITY_TYPE_BK
      , to_char(coalesce(DATBI,'-1'))                                as VALID_DATE_BK
      , to_char(coalesce(KOKRS,'-1'))                                as CONTROLLING_AREA_BK
      , MANDT
      , KOKRS
      , LSTAR
      , DATBI
      , GLREQUEST
      , DATAB
      , LEINH
      , LATYP
      , LATYPI
      , ERSDA
      , USNAM
      , KSTTY
      , AUSEH
      , AUSFK
      , VKSTA
      , LARK1
      , LARK2
      , SPRKZ
      , HRKFT
      , FIXVO
      , TARKZ
      , YRATE
      , TARKZ_I
      , MANIST
      , MANPLAN
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
      ACTIVITY_TYPE_BK
      , VALID_DATE_BK
      , CONTROLLING_AREA_BK
      , MANDT
      , KOKRS
      , LSTAR
      , DATBI
      , GLREQUEST
      , DATAB
      , LEINH
      , LATYP
      , LATYPI
      , ERSDA
      , USNAM
      , KSTTY
      , AUSEH
      , AUSFK
      , VKSTA
      , LARK1
      , LARK2
      , SPRKZ
      , HRKFT
      , FIXVO
      , TARKZ
      , YRATE
      , TARKZ_I
      , MANIST
      , MANPLAN
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_CSLA'
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
         ACTIVITY_TYPE_BK
        , VALID_DATE_BK
        , CONTROLLING_AREA_BK
        , MANDT
        , KOKRS
        , LSTAR
        , DATBI
        , GLREQUEST
        , DATAB
        , LEINH
        , LATYP
        , LATYPI
        , ERSDA
        , USNAM
        , KSTTY
        , AUSEH
        , AUSFK
        , VKSTA
        , LARK1
        , LARK2
        , SPRKZ
        , HRKFT
        , FIXVO
        , TARKZ
        , YRATE
        , TARKZ_I
        , MANIST
        , MANPLAN
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
          COALESCE(NULLIF(TRIM(CAST(ACTIVITY_TYPE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VALID_DATE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CO_ACTIVITY_TYPE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(LSTAR::text), '^^') 
            , '||', IFNULL(TRIM(DATBI::text), '^^') 
            , '||', IFNULL(TRIM(DATAB::text), '^^') 
            , '||', IFNULL(TRIM(LEINH::text), '^^') 
            , '||', IFNULL(TRIM(LATYP::text), '^^') 
            , '||', IFNULL(TRIM(LATYPI::text), '^^') 
            , '||', IFNULL(TRIM(ERSDA::text), '^^') 
            , '||', IFNULL(TRIM(USNAM::text), '^^') 
            , '||', IFNULL(TRIM(KSTTY::text), '^^') 
            , '||', IFNULL(TRIM(AUSEH::text), '^^') 
            , '||', IFNULL(TRIM(AUSFK::text), '^^') 
            , '||', IFNULL(TRIM(VKSTA::text), '^^') 
            , '||', IFNULL(TRIM(LARK1::text), '^^') 
            , '||', IFNULL(TRIM(LARK2::text), '^^') 
            , '||', IFNULL(TRIM(SPRKZ::text), '^^') 
            , '||', IFNULL(TRIM(HRKFT::text), '^^') 
            , '||', IFNULL(TRIM(FIXVO::text), '^^') 
            , '||', IFNULL(TRIM(TARKZ::text), '^^') 
            , '||', IFNULL(TRIM(YRATE::text), '^^') 
            , '||', IFNULL(TRIM(TARKZ_I::text), '^^') 
            , '||', IFNULL(TRIM(MANIST::text), '^^') 
            , '||', IFNULL(TRIM(MANPLAN::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

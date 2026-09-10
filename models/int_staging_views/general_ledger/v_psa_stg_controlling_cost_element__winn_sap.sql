---- SRC LAYER ----
WITH
SRC_c              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_cskb') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_c              as ( SELECT * FROM sap_ecc_prd.z_cskb )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_c as (
    SELECT
 CONVERT_TIMEZONE('UTC', IFF(
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
      , to_char(coalesce(KOKRS,'-1'))                                as                                CONTROLLING_AREA_BK
      , to_char(coalesce(KSTAR,'-1'))                                as                                    COST_ELEMENT_BK
      , to_char(coalesce(DATBI,'-1'))                                as                                   VALID_DATE_TO_BK
      , MANDT
      , KOKRS
      , KSTAR
      , DATBI
      , GLREQUEST
      , DATAB
      , KATYP
      , ERSDA
      , USNAM
      , EIGEN
      , PLAZU
      , PLAOR
      , PLAUS
      , KOSTL
      , AUFNR
      , MGEFL
      , MSEHI
      , DEAKT
      , LOEVM
      , RECID
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        ))                                                           as                                  GLCHANGETIME_DTTM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM SRC_c
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_c as (
    SELECT
        LOAD_DTS
      , CONTROLLING_AREA_BK
      , COST_ELEMENT_BK
      , VALID_DATE_TO_BK
      , MANDT
      , KOKRS
      , KSTAR
      , DATBI
      , GLREQUEST
      , DATAB
      , KATYP
      , ERSDA
      , USNAM
      , EIGEN
      , PLAZU
      , PLAOR
      , PLAUS
      , KOSTL
      , AUFNR
      , MGEFL
      , MSEHI
      , DEAKT
      , LOEVM
      , RECID
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , GLCHANGETIME_DTTM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM LOGIC_c
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_c as (
    SELECT *
    FROM RENAME_c
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_CSKB'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_c
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(COST_ELEMENT_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(VALID_DATE_TO_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                   CONTROLLING_AREA_COST_ELEMENT_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                CONTROLLING_AREA_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(COST_ELEMENT_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                    COST_ELEMENT_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(VALID_DATE_TO_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        )))                                                          as                                   VALID_DATE_TO_HK
        , LOAD_DTS
        , CONTROLLING_AREA_BK
        , COST_ELEMENT_BK
        , VALID_DATE_TO_BK
        , MANDT
        , KOKRS
        , KSTAR
        , DATBI
        , GLREQUEST
        , DATAB
        , KATYP
        , ERSDA
        , USNAM
        , EIGEN
        , PLAZU
        , PLAOR
        , PLAUS
        , KOSTL
        , AUFNR
        , MGEFL
        , MSEHI
        , DEAKT
        , LOEVM
        , RECID
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , GLCHANGETIME_DTTM
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(KSTAR::text), '^^') 
            , '||', IFNULL(TRIM(DATBI::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(DATAB::text), '^^') 
            , '||', IFNULL(TRIM(KATYP::text), '^^') 
            , '||', IFNULL(TRIM(ERSDA::text), '^^') 
            , '||', IFNULL(TRIM(USNAM::text), '^^') 
            , '||', IFNULL(TRIM(EIGEN::text), '^^') 
            , '||', IFNULL(TRIM(PLAZU::text), '^^') 
            , '||', IFNULL(TRIM(PLAOR::text), '^^') 
            , '||', IFNULL(TRIM(PLAUS::text), '^^') 
            , '||', IFNULL(TRIM(KOSTL::text), '^^') 
            , '||', IFNULL(TRIM(AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(MGEFL::text), '^^') 
            , '||', IFNULL(TRIM(MSEHI::text), '^^') 
            , '||', IFNULL(TRIM(DEAKT::text), '^^') 
            , '||', IFNULL(TRIM(LOEVM::text), '^^') 
            , '||', IFNULL(TRIM(RECID::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

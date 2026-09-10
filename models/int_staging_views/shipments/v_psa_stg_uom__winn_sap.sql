---- SRC LAYER ----
WITH
SRC_psa            as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_t006') }} as SRC  ),
SRC_bkcc           as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_psa            as ( SELECT * FROM sap_ecc_prd.z_t006 )
, SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_psa as (
    SELECT
        MSEHI                                                        as                                             UOM_BK
      , MANDT
      , MSEHI
      , GLREQUEST
      , KZEX3
      , KZEX6
      , ANDEC
      , KZKEH
      , KZWOB
      , KZ1EH
      , KZ2EH
      , DIMID
      , ZAEHL
      , NENNR
      , EXP10
      , ADDKO
      , EXPON
      , DECAN
      , ISOCODE
      , PRIMARY
      , TEMP_VALUE
      , TEMP_UNIT
      , FAMUNIT
      , PRESS_VAL
      , PRESS_UNIT
      , GLDELFLAG
      , GLSOURCESYSTEM
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
      , MSEHI
      , GLREQUEST
      , KZEX3
      , KZEX6
      , ANDEC
      , KZKEH
      , KZWOB
      , KZ1EH
      , KZ2EH
      , DIMID
      , ZAEHL
      , NENNR
      , EXP10
      , ADDKO
      , EXPON
      , DECAN
      , ISOCODE
      , PRIMARY
      , TEMP_VALUE
      , TEMP_UNIT
      , FAMUNIT
      , PRESS_VAL
      , PRESS_UNIT
      , GLDELFLAG
      , GLSOURCESYSTEM
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T006'
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
        , MSEHI
        , GLREQUEST
        , KZEX3
        , KZEX6
        , ANDEC
        , KZKEH
        , KZWOB
        , KZ1EH
        , KZ2EH
        , DIMID
        , ZAEHL
        , NENNR
        , EXP10
        , ADDKO
        , EXPON
        , DECAN
        , ISOCODE
        , PRIMARY
        , TEMP_VALUE
        , TEMP_UNIT
        , FAMUNIT
        , PRESS_VAL
        , PRESS_UNIT
        , GLDELFLAG
        , GLSOURCESYSTEM
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
            , '||', IFNULL(TRIM(KZEX3::text), '^^') 
            , '||', IFNULL(TRIM(KZEX6::text), '^^') 
            , '||', IFNULL(TRIM(ANDEC::text), '^^') 
            , '||', IFNULL(TRIM(KZKEH::text), '^^') 
            , '||', IFNULL(TRIM(KZWOB::text), '^^') 
            , '||', IFNULL(TRIM(KZ1EH::text), '^^') 
            , '||', IFNULL(TRIM(KZ2EH::text), '^^') 
            , '||', IFNULL(TRIM(DIMID::text), '^^') 
            , '||', IFNULL(TRIM(ZAEHL::text), '^^') 
            , '||', IFNULL(TRIM(NENNR::text), '^^') 
            , '||', IFNULL(TRIM(EXP10::text), '^^') 
            , '||', IFNULL(TRIM(ADDKO::text), '^^') 
            , '||', IFNULL(TRIM(EXPON::text), '^^') 
            , '||', IFNULL(TRIM(DECAN::text), '^^') 
            , '||', IFNULL(TRIM(ISOCODE::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY::text), '^^') 
            , '||', IFNULL(TRIM(TEMP_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(TEMP_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(FAMUNIT::text), '^^') 
            , '||', IFNULL(TRIM(PRESS_VAL::text), '^^') 
            , '||', IFNULL(TRIM(PRESS_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

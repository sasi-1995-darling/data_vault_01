---- SRC LAYER ----
WITH
SRC_S              as ( SELECT AUTHGRP, CREATED_AT, CREATED_BY, CREATED_ON, DATAB, DATBIS, DATE_EXP, FKBER, FNSUB1, FNSUB2, FNSUB3, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, MANDT, MODIFIED_AT, MODIFIED_BY, MODIFIED_ON, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, STR_ID FROM {{ source('sap_ecc_prd', 'z_tfkb') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_tfkb )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        MANDT
      , FKBER
      , GLREQUEST
      , AUTHGRP
      , STR_ID
      , FNSUB1
      , FNSUB2
      , FNSUB3
      , CREATED_BY
      , CREATED_ON
      , CREATED_AT
      , MODIFIED_BY
      , MODIFIED_ON
      , MODIFIED_AT
      , DATAB
      , DATBIS
      , DATE_EXP
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
      , FKBER
      , GLREQUEST
      , AUTHGRP
      , STR_ID
      , FNSUB1
      , FNSUB2
      , FNSUB3
      , CREATED_BY
      , CREATED_ON
      , CREATED_AT
      , MODIFIED_BY
      , MODIFIED_ON
      , MODIFIED_AT
      , DATAB
      , DATBIS
      , DATE_EXP
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_TFKB'
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
          to_char(coalesce(FKBER,'-1'))                                as FUNCTIONAL_AREA_BK
        , MANDT
        , FKBER
        , GLREQUEST
        , AUTHGRP
        , STR_ID
        , FNSUB1
        , FNSUB2
        , FNSUB3
        , CREATED_BY
        , CREATED_ON
        , CREATED_AT
        , MODIFIED_BY
        , MODIFIED_ON
        , MODIFIED_AT
        , DATAB
        , DATBIS
        , DATE_EXP
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
          COALESCE(NULLIF(TRIM(CAST(FUNCTIONAL_AREA_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FUNCTIONAL_AREA_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(FKBER::text), '^^') 
            , '||', IFNULL(TRIM(AUTHGRP::text), '^^') 
            , '||', IFNULL(TRIM(STR_ID::text), '^^') 
            , '||', IFNULL(TRIM(FNSUB1::text), '^^') 
            , '||', IFNULL(TRIM(FNSUB2::text), '^^') 
            , '||', IFNULL(TRIM(FNSUB3::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_ON::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(MODIFIED_BY::text), '^^') 
            , '||', IFNULL(TRIM(MODIFIED_ON::text), '^^') 
            , '||', IFNULL(TRIM(MODIFIED_AT::text), '^^') 
            , '||', IFNULL(TRIM(DATAB::text), '^^') 
            , '||', IFNULL(TRIM(DATBIS::text), '^^') 
            , '||', IFNULL(TRIM(DATE_EXP::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_T              as ( SELECT GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, HRKFT, KOATY, KOKRS, MANDT, PSA_DELETE_IND, PSA_LOAD_DTS FROM {{ source('sap_ecc_prd', 'z_tkkh1') }} as SRC  ),
SRC_A              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_T              as ( SELECT * FROM sap_ecc_prd.z_tkkh1 )
SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_T as (
    SELECT
       to_char(coalesce(nullif(trim(KOKRS), ''), '-1'))                                                         as                                CONTROLLING_AREA_BK
      ,to_char(coalesce(nullif(trim(KOATY), ''), '-1'))                                                         as                                     ORIGIN_TYPE_BK
      , to_char(coalesce(nullif(trim(HRKFT), ''), '-1'))                                                        as                                    ORIGIN_GROUP_BK
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
      , GLREQUEST
      , MANDT
      , KOKRS
      , KOATY
      , HRKFT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM SRC_T
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_T as (
    SELECT
        CONTROLLING_AREA_BK
      , ORIGIN_TYPE_BK
      , ORIGIN_GROUP_BK
      , LOAD_DTS
      , GLREQUEST
      , MANDT
      , KOKRS
      , KOATY
      , HRKFT
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM LOGIC_T
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_T as (
    SELECT *
    FROM RENAME_T
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_TKKH1'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_T
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CONTROLLING_AREA_BK
        , ORIGIN_TYPE_BK
        , ORIGIN_GROUP_BK
        , LOAD_DTS
        , GLREQUEST
        , MANDT
        , KOKRS
        , KOATY
        , HRKFT
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(ORIGIN_TYPE_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORIGIN_TYPE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(ORIGIN_GROUP_BK as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORIGIN_GROUP_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORIGIN_TYPE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORIGIN_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORIGIN_CO_OBJECT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CONTROLLING_AREA_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CONTROLLING_AREA_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CONTROLLING_AREA_BK::text), '^^') 
            , '||', IFNULL(TRIM(ORIGIN_TYPE_BK::text), '^^') 
            , '||', IFNULL(TRIM(ORIGIN_GROUP_BK::text), '^^') 
            , '||', IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(KOATY::text), '^^') 
            , '||', IFNULL(TRIM(HRKFT::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

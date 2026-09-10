---- SRC LAYER ----
WITH
SRC_C1             as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_c519') }} as SRC  ),
SRC_C2             as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_c520') }} as SRC  ),
SRC_C3             as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_c521') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_C1             as ( SELECT * FROM sap_ecc_prd.z_C519 )
, SRC_C2             as ( SELECT * FROM sap_ecc_prd.z_C520 )
, SRC_C3             as ( SELECT * FROM sap_ecc_prd.z_C521 )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_C1 as (
    SELECT
    CONCAT_WS('||',COALESCE(MANDT,''), COALESCE(KAPPL,''), COALESCE(KSCHL,''), COALESCE(KTOPL,''), COALESCE(VKORG,''), COALESCE(VTWEG,''), COALESCE(KVSL1,''), COALESCE(ZZPSTYV,''), COALESCE(ZZAUGRU,'')
    , COALESCE(ZZAUART,''), COALESCE(ZZKUNAG,''), COALESCE(MATNR,'')) as GL_SO_BK
      , MANDT
      , KAPPL
      , KSCHL
      , KTOPL
      , VKORG
      , VTWEG
      , KVSL1
      , ZZPSTYV
      , ZZAUGRU
      , ZZAUART
      , ZZKUNAG
      , MATNR
      , GLREQUEST
      , SAKN1
      , SAKN2
      , PSA_RECORD_SOURCE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM SRC_C1
)

, LOGIC_C2 as (
    SELECT
        CONCAT_WS('||',
        COALESCE(MANDT,''), COALESCE(KAPPL,''), COALESCE(KSCHL,''),
        COALESCE(KTOPL,''), COALESCE(VKORG,''), COALESCE(VTWEG,''),
        COALESCE(KVSL1,''), COALESCE(ZZPSTYV,''), COALESCE(ZZAUGRU,''),
        COALESCE(ZZAUART,''), COALESCE(ZZKUNAG,'')
    ) as GL_SO_BK
      , MANDT
      , KAPPL
      , KSCHL
      , KTOPL
      , VKORG
      , VTWEG
      , KVSL1
      , ZZPSTYV
      , ZZAUGRU
      , ZZAUART
      , ZZKUNAG
      , NULL as MATNR
      , GLREQUEST
      , SAKN1
      , SAKN2
      , PSA_RECORD_SOURCE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM SRC_C2
)

, LOGIC_C3 as (
    SELECT
    CONCAT_WS('||',
        COALESCE(MANDT,''), COALESCE(KAPPL,''), COALESCE(KSCHL,''),
        COALESCE(KTOPL,''), COALESCE(VKORG,''), COALESCE(VTWEG,''),
        COALESCE(KVSL1,''), COALESCE(ZZPSTYV,''), COALESCE(ZZAUGRU,''),
        COALESCE(ZZAUART,'')
    ) as GL_SO_BK
      , MANDT
      , KAPPL
      , KSCHL
      , KTOPL
      , VKORG
      , VTWEG
      , KVSL1
      , ZZPSTYV
      , ZZAUGRU
      , ZZAUART
      , NULL as ZZKUNAG
      , NULL as MATNR
      , GLREQUEST
      , SAKN1
      , SAKN2
      , PSA_RECORD_SOURCE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM SRC_C3
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_C1 as (
    SELECT
        GL_SO_BK
      , MANDT
      , KAPPL
      , KSCHL
      , KTOPL
      , VKORG
      , VTWEG
      , KVSL1
      , ZZPSTYV
      , ZZAUGRU
      , ZZAUART
      , ZZKUNAG
      , MATNR
      , GLREQUEST
      , SAKN1
      , SAKN2
      , PSA_RECORD_SOURCE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM LOGIC_C1
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)

, RENAME_C2 as (
    SELECT
        GL_SO_BK
      , MANDT
      , KAPPL
      , KSCHL
      , KTOPL
      , VKORG
      , VTWEG
      , KVSL1
      , ZZPSTYV
      , ZZAUGRU
      , ZZAUART
      , ZZKUNAG
      , MATNR
      , GLREQUEST
      , SAKN1
      , SAKN2
      , PSA_RECORD_SOURCE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM LOGIC_C2
)

, RENAME_C3 as (
    SELECT
        GL_SO_BK
      , MANDT
      , KAPPL
      , KSCHL
      , KTOPL
      , VKORG
      , VTWEG
      , KVSL1
      , ZZPSTYV
      , ZZAUGRU
      , ZZAUART
      , ZZKUNAG
      , MATNR
      , GLREQUEST
      , SAKN1
      , SAKN2
      , PSA_RECORD_SOURCE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM LOGIC_C3
)
---- FILTER LAYER ----

, FILTER_C1 as (
    SELECT *
    FROM RENAME_C1
)

, FILTER_C2 as (
    SELECT *
    FROM RENAME_C2
)

, FILTER_C3 as (
    SELECT *
    FROM RENAME_C3
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src IN (
'USOHNO.SAP.ECCPRD.Z_C519',
'USOHNO.SAP.ECCPRD.Z_C520',
'USOHNO.SAP.ECCPRD.Z_C521' )
)

---- JOIN LAYER ----
, JOIN_RESULT_1 as (
    SELECT *
    FROM FILTER_C1
    INNER JOIN FILTER_A
        ON '1' = '1' AND FILTER_A.rec_src = 'USOHNO.SAP.ECCPRD.Z_C519'
)
---- JOIN LAYER ----
, JOIN_RESULT_2 as (
    SELECT *
    FROM FILTER_C2
    INNER JOIN FILTER_A
        ON '1' = '1' AND FILTER_A.rec_src = 'USOHNO.SAP.ECCPRD.Z_C520'
)
---- JOIN LAYER ----
, JOIN_RESULT_3 as (
    SELECT *
    FROM FILTER_C3
    INNER JOIN FILTER_A
        ON '1' = '1' AND FILTER_A.rec_src = 'USOHNO.SAP.ECCPRD.Z_C521'
)
, UNION_RESULT as (
    SELECT * FROM JOIN_RESULT_1
    UNION ALL
    SELECT * FROM JOIN_RESULT_2
    UNION ALL
    SELECT * FROM JOIN_RESULT_3
)

---- FINAL LAYER ----
SELECT
         GL_SO_BK
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
        , MANDT
        , KAPPL
        , KSCHL
        , KTOPL
        , VKORG
        , VTWEG
        , KVSL1
        , ZZPSTYV
        , ZZAUGRU
        , ZZAUART
        , ZZKUNAG
        , MATNR
        , GLREQUEST
        , SAKN1
        , SAKN2
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
  )) as GLCHANGETIME_DTTM
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(KAPPL::text), '^^') 
            , '||', IFNULL(TRIM(KSCHL::text), '^^') 
            , '||', IFNULL(TRIM(KTOPL::text), '^^') 
            , '||', IFNULL(TRIM(VKORG::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG::text), '^^') 
            , '||', IFNULL(TRIM(KVSL1::text), '^^') 
            , '||', IFNULL(TRIM(ZZPSTYV::text), '^^') 
            , '||', IFNULL(TRIM(ZZAUGRU::text), '^^') 
            , '||', IFNULL(TRIM(ZZAUART::text), '^^') 
            , '||', IFNULL(TRIM(ZZKUNAG::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(SAKN1::text), '^^') 
            , '||', IFNULL(TRIM(SAKN2::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM UNION_RESULT


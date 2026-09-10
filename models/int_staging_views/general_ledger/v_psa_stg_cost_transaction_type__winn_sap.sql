---- SRC LAYER ----
WITH
SRC_SRC_S          as ( SELECT ACTGRP, ANWST, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, NVVRG, PERSP, PRVRG, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSIKZ, SUBGRP, VRGCO, VRGJV, VRGNG, VRGSV, WTKAT, XCOEJ, XCOEJL, XCOEJR, XCOEJT, XCOEP, XCOEPB, XCOEPL, XCOEPR, XCOEPT, XCOFP, XCOOI, XCOSP, XCOSS, XFMGM FROM {{ source('sap_ecc_prd', 'z_tj01') }} as SRC  ),
SRC_SRC_A          as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_SRC_S          as ( SELECT * FROM sap_ecc_prd.z_tj01 )
SRC_SRC_A          as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC_S as (
    SELECT
        VRGNG
      , GLREQUEST
      , VRGSV
      , ANWST
      , PRVRG
      , VRGJV
      , VRGCO
      , NVVRG
      , PERSP
      , PSIKZ
      , WTKAT
      , ACTGRP
      , SUBGRP
      , XCOEP
      , XCOEJ
      , XCOOI
      , XCOSP
      , XCOSS
      , XCOEPL
      , XCOEJL
      , XCOEPR
      , XCOEJR
      , XCOEPT
      , XCOEJT
      , XCOEPB
      , XCOFP
      , XFMGM
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_SRC_S
)

, LOGIC_SRC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_SRC_A
)
---- RENAME LAYER ----

, RENAME_SRC_S as (
    SELECT
        VRGNG
      , GLREQUEST
      , VRGSV
      , ANWST
      , PRVRG
      , VRGJV
      , VRGCO
      , NVVRG
      , PERSP
      , PSIKZ
      , WTKAT
      , ACTGRP
      , SUBGRP
      , XCOEP
      , XCOEJ
      , XCOOI
      , XCOSP
      , XCOSS
      , XCOEPL
      , XCOEJL
      , XCOEPR
      , XCOEJR
      , XCOEPT
      , XCOEJT
      , XCOEPB
      , XCOFP
      , XFMGM
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_SRC_S
)

, RENAME_SRC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_SRC_A
)
---- FILTER LAYER ----

, FILTER_SRC_S as (
    SELECT *
    FROM RENAME_SRC_S
)

, FILTER_SRC_A as (
    SELECT *
    FROM RENAME_SRC_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_TJ01'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SRC_S
    INNER JOIN FILTER_SRC_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          to_char(coalesce(VRGNG,'-1'))                                as COST_TRANSACTION_TYPE_BK
        , VRGNG
        , GLREQUEST
        , VRGSV
        , ANWST
        , PRVRG
        , VRGJV
        , VRGCO
        , NVVRG
        , PERSP
        , PSIKZ
        , WTKAT
        , ACTGRP
        , SUBGRP
        , XCOEP
        , XCOEJ
        , XCOOI
        , XCOSP
        , XCOSS
        , XCOEPL
        , XCOEJL
        , XCOEPR
        , XCOEJR
        , XCOEPT
        , XCOEJT
        , XCOEPB
        , XCOFP
        , XFMGM
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
          COALESCE(NULLIF(TRIM(CAST(COST_TRANSACTION_TYPE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COST_TRANSACTION_TYPE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(VRGNG::text), '^^') 
            , '||', IFNULL(TRIM(VRGSV::text), '^^') 
            , '||', IFNULL(TRIM(ANWST::text), '^^') 
            , '||', IFNULL(TRIM(PRVRG::text), '^^') 
            , '||', IFNULL(TRIM(VRGJV::text), '^^') 
            , '||', IFNULL(TRIM(VRGCO::text), '^^') 
            , '||', IFNULL(TRIM(NVVRG::text), '^^') 
            , '||', IFNULL(TRIM(PERSP::text), '^^') 
            , '||', IFNULL(TRIM(PSIKZ::text), '^^') 
            , '||', IFNULL(TRIM(WTKAT::text), '^^') 
            , '||', IFNULL(TRIM(ACTGRP::text), '^^') 
            , '||', IFNULL(TRIM(SUBGRP::text), '^^') 
            , '||', IFNULL(TRIM(XCOEP::text), '^^') 
            , '||', IFNULL(TRIM(XCOEJ::text), '^^') 
            , '||', IFNULL(TRIM(XCOOI::text), '^^') 
            , '||', IFNULL(TRIM(XCOSP::text), '^^') 
            , '||', IFNULL(TRIM(XCOSS::text), '^^') 
            , '||', IFNULL(TRIM(XCOEPL::text), '^^') 
            , '||', IFNULL(TRIM(XCOEJL::text), '^^') 
            , '||', IFNULL(TRIM(XCOEPR::text), '^^') 
            , '||', IFNULL(TRIM(XCOEJR::text), '^^') 
            , '||', IFNULL(TRIM(XCOEPT::text), '^^') 
            , '||', IFNULL(TRIM(XCOEJT::text), '^^') 
            , '||', IFNULL(TRIM(XCOEPB::text), '^^') 
            , '||', IFNULL(TRIM(XCOFP::text), '^^') 
            , '||', IFNULL(TRIM(XFMGM::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(GLCHANGETIME::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

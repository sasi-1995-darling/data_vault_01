---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_equz') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'US.SAP_ECC_PRD.Z_EQUZ' )

/*
SRC_SRC            as ( SELECT * FROM sap_ecc_prd.z_equz )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        ILOAN                                                        as                             LOCATION_ASSIGNMENT_BK
      , ILOAN
      , EQUNR                                                        as                                       EQUIPMENT_BK
      , HEQUI                                                        as                                PARENT_EQUIPMENT_BK
      , MANDT
      , EQUNR
      , DATBI
      , EQLFN
      , EQUZN
      , ERDAT
      , ERNAM
      , AEDAT
      , AENAM
      , TIMBI
      , ESTAI
      , ESTAE
      , STNAM
      , LVORM
      , DATAB
      , IWERK
      , IWERKI
      , SUBMT
      , MAPAR
      , HEQUI
      , HEQNR
      , INGRP
      , INGRPI
      , PM_OBJTY
      , GEWRK
      , GEWRKI
      , TIDNR
      , TIDNRI
      , KUND1
      , KUND2
      , KUND3
      , LIZNR
      , RBNR
      , EZDAT
      , EZBER
      , EZNUM
      , RBNR_I
      , IBLNR
      , BLDAT
      , PVS_FOCUS
      , PPEGUID
      , TECHS
      , FUNCID
      , FRCFIT
      , FRCRMV
      , GLREQUEST
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, CONVERT_TIMEZONE('UTC', TO_TIMESTAMP_NTZ(SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16), 'YYYYMMDDHH24MISS.FF9'))) as                                           LOAD_DTS
    FROM SRC_SRC
)

, LOGIC_ref_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_ref_bkcc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
    INNER JOIN LOGIC_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          LOCATION_ASSIGNMENT_BK
        , ILOAN
        , EQUIPMENT_BK
        , PARENT_EQUIPMENT_BK
        , MANDT
        , EQUNR
        , DATBI
        , EQLFN
        , EQUZN
        , ERDAT
        , ERNAM
        , AEDAT
        , AENAM
        , TIMBI
        , ESTAI
        , ESTAE
        , STNAM
        , LVORM
        , DATAB
        , IWERK
        , IWERKI
        , SUBMT
        , MAPAR
        , HEQUI
        , HEQNR
        , INGRP
        , INGRPI
        , PM_OBJTY
        , GEWRK
        , GEWRKI
        , TIDNR
        , TIDNRI
        , KUND1
        , KUND2
        , KUND3
        , LIZNR
        , RBNR
        , EZDAT
        , EZBER
        , EZNUM
        , RBNR_I
        , IBLNR
        , BLDAT
        , PVS_FOCUS
        , PPEGUID
        , TECHS
        , FUNCID
        , FRCFIT
        , FRCRMV
        , GLREQUEST
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , LOAD_DTS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ILOAN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LOCATION_ASSIGNMENT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EQUNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as EQUIPMENT_HK
        , IFF(
            HEQUI IS NULL OR TRIM(CAST(HEQUI AS VARCHAR)) = '',
            MD5_BINARY('-2'),
            MD5_BINARY(UPPER(CONCAT_WS('||',
              COALESCE(NULLIF(TRIM(CAST(HEQUI as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
            )))
          ) as PARENT_EQUIPMENT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EQUNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ILOAN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(HEQUI as VARCHAR)),''), '-2')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_EQUIPMENT_LOCATION_ASSIGNMENT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(DATBI::text), '^^') 
            , '||', IFNULL(TRIM(EQLFN::text), '^^') 
            , '||', IFNULL(TRIM(EQUZN::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(AEDAT::text), '^^') 
            , '||', IFNULL(TRIM(AENAM::text), '^^') 
            , '||', IFNULL(TRIM(TIMBI::text), '^^') 
            , '||', IFNULL(TRIM(ESTAI::text), '^^') 
            , '||', IFNULL(TRIM(ESTAE::text), '^^') 
            , '||', IFNULL(TRIM(STNAM::text), '^^') 
            , '||', IFNULL(TRIM(LVORM::text), '^^') 
            , '||', IFNULL(TRIM(DATAB::text), '^^') 
            , '||', IFNULL(TRIM(IWERK::text), '^^') 
            , '||', IFNULL(TRIM(IWERKI::text), '^^') 
            , '||', IFNULL(TRIM(SUBMT::text), '^^') 
            , '||', IFNULL(TRIM(MAPAR::text), '^^') 
            , '||', IFNULL(TRIM(HEQNR::text), '^^') 
            , '||', IFNULL(TRIM(INGRP::text), '^^') 
            , '||', IFNULL(TRIM(INGRPI::text), '^^') 
            , '||', IFNULL(TRIM(PM_OBJTY::text), '^^') 
            , '||', IFNULL(TRIM(GEWRK::text), '^^') 
            , '||', IFNULL(TRIM(GEWRKI::text), '^^') 
            , '||', IFNULL(TRIM(TIDNR::text), '^^') 
            , '||', IFNULL(TRIM(TIDNRI::text), '^^') 
            , '||', IFNULL(TRIM(KUND1::text), '^^') 
            , '||', IFNULL(TRIM(KUND2::text), '^^') 
            , '||', IFNULL(TRIM(KUND3::text), '^^') 
            , '||', IFNULL(TRIM(LIZNR::text), '^^') 
            , '||', IFNULL(TRIM(RBNR::text), '^^') 
            , '||', IFNULL(TRIM(EZDAT::text), '^^') 
            , '||', IFNULL(TRIM(EZBER::text), '^^') 
            , '||', IFNULL(TRIM(EZNUM::text), '^^') 
            , '||', IFNULL(TRIM(RBNR_I::text), '^^') 
            , '||', IFNULL(TRIM(IBLNR::text), '^^') 
            , '||', IFNULL(TRIM(BLDAT::text), '^^') 
            , '||', IFNULL(TRIM(PVS_FOCUS::text), '^^') 
            , '||', IFNULL(TRIM(PPEGUID::text), '^^') 
            , '||', IFNULL(TRIM(TECHS::text), '^^') 
            , '||', IFNULL(TRIM(FUNCID::text), '^^') 
            , '||', IFNULL(TRIM(FRCFIT::text), '^^') 
            , '||', IFNULL(TRIM(FRCRMV::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

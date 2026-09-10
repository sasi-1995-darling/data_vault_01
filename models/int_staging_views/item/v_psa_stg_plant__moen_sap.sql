---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_t001w') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_t001w )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        WERKS                                                        as                                           PLANT_BK
      , MANDT
      , WERKS
      , GLREQUEST
      , NAME1
      , BWKEY
      , KUNNR
      , LIFNR
      , FABKL
      , NAME2
      , STRAS
      , PFACH
      , PSTLZ
      , ORT01
      , EKORG
      , VKORG
      , CHAZV
      , KKOWK
      , KORDB
      , BEDPL
      , LAND1
      , REGIO
      , COUNC
      , CITYC
      , ADRNR
      , IWERK
      , TXJCD
      , VTWEG
      , SPART
      , SPRAS
      , WKSOP
      , AWSLS
      , CHAZV_OLD
      , VLFKZ
      , BZIRK
      , ZONE1
      , TAXIW
      , BZQHL
      , LET01
      , LET02
      , LET03
      , TXNAM_MA1
      , TXNAM_MA2
      , TXNAM_MA3
      , BETOL
      , J_1BBRANCH
      , VTBFI
      , FPRFW
      , ACHVM
      , DVSART
      , NODETYPE
      , NSCHEMA
      , PKOSA
      , MISCH
      , MGVUPD
      , VSTEL
      , MGVLAUPD
      , MGVLAREVAL
      , SOURCING
      , FSH_MG_ARUN_REQ
      , FSH_SEAIM
      , FSH_BOM_MAINTENANCE
      , OILIVAL
      , OIHVTYPE
      , OIHCREDIPI
      , STORETYPE
      , DEP_STORE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
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
        PLANT_BK
      , MANDT
      , WERKS
      , GLREQUEST
      , NAME1
      , BWKEY
      , KUNNR
      , LIFNR
      , FABKL
      , NAME2
      , STRAS
      , PFACH
      , PSTLZ
      , ORT01
      , EKORG
      , VKORG
      , CHAZV
      , KKOWK
      , KORDB
      , BEDPL
      , LAND1
      , REGIO
      , COUNC
      , CITYC
      , ADRNR
      , IWERK
      , TXJCD
      , VTWEG
      , SPART
      , SPRAS
      , WKSOP
      , AWSLS
      , CHAZV_OLD
      , VLFKZ
      , BZIRK
      , ZONE1
      , TAXIW
      , BZQHL
      , LET01
      , LET02
      , LET03
      , TXNAM_MA1
      , TXNAM_MA2
      , TXNAM_MA3
      , BETOL
      , J_1BBRANCH
      , VTBFI
      , FPRFW
      , ACHVM
      , DVSART
      , NODETYPE
      , NSCHEMA
      , PKOSA
      , MISCH
      , MGVUPD
      , VSTEL
      , MGVLAUPD
      , MGVLAREVAL
      , SOURCING
      , FSH_MG_ARUN_REQ
      , FSH_SEAIM
      , FSH_BOM_MAINTENANCE
      , OILIVAL
      , OIHVTYPE
      , OIHCREDIPI
      , STORETYPE
      , DEP_STORE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_T001W'
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
          PLANT_BK
        , MANDT
        , WERKS
        , GLREQUEST
        , NAME1
        , BWKEY
        , KUNNR
        , LIFNR
        , FABKL
        , NAME2
        , STRAS
        , PFACH
        , PSTLZ
        , ORT01
        , EKORG
        , VKORG
        , CHAZV
        , KKOWK
        , KORDB
        , BEDPL
        , LAND1
        , REGIO
        , COUNC
        , CITYC
        , ADRNR
        , IWERK
        , TXJCD
        , VTWEG
        , SPART
        , SPRAS
        , WKSOP
        , AWSLS
        , CHAZV_OLD
        , VLFKZ
        , BZIRK
        , ZONE1
        , TAXIW
        , BZQHL
        , LET01
        , LET02
        , LET03
        , TXNAM_MA1
        , TXNAM_MA2
        , TXNAM_MA3
        , BETOL
        , J_1BBRANCH
        , VTBFI
        , FPRFW
        , ACHVM
        , DVSART
        , NODETYPE
        , NSCHEMA
        , PKOSA
        , MISCH
        , MGVUPD
        , VSTEL
        , MGVLAUPD
        , MGVLAREVAL
        , SOURCING
        , FSH_MG_ARUN_REQ
        , FSH_SEAIM
        , FSH_BOM_MAINTENANCE
        , OILIVAL
        , OIHVTYPE
        , OIHCREDIPI
        , STORETYPE
        , DEP_STORE
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(NAME1::text), '^^') 
            , '||', IFNULL(TRIM(BWKEY::text), '^^') 
            , '||', IFNULL(TRIM(KUNNR::text), '^^') 
            , '||', IFNULL(TRIM(LIFNR::text), '^^') 
            , '||', IFNULL(TRIM(FABKL::text), '^^') 
            , '||', IFNULL(TRIM(NAME2::text), '^^') 
            , '||', IFNULL(TRIM(STRAS::text), '^^') 
            , '||', IFNULL(TRIM(PFACH::text), '^^') 
            , '||', IFNULL(TRIM(PSTLZ::text), '^^') 
            , '||', IFNULL(TRIM(ORT01::text), '^^') 
            , '||', IFNULL(TRIM(EKORG::text), '^^') 
            , '||', IFNULL(TRIM(VKORG::text), '^^') 
            , '||', IFNULL(TRIM(CHAZV::text), '^^') 
            , '||', IFNULL(TRIM(KKOWK::text), '^^') 
            , '||', IFNULL(TRIM(KORDB::text), '^^') 
            , '||', IFNULL(TRIM(BEDPL::text), '^^') 
            , '||', IFNULL(TRIM(LAND1::text), '^^') 
            , '||', IFNULL(TRIM(REGIO::text), '^^') 
            , '||', IFNULL(TRIM(COUNC::text), '^^') 
            , '||', IFNULL(TRIM(CITYC::text), '^^') 
            , '||', IFNULL(TRIM(ADRNR::text), '^^') 
            , '||', IFNULL(TRIM(IWERK::text), '^^') 
            , '||', IFNULL(TRIM(TXJCD::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(SPRAS::text), '^^') 
            , '||', IFNULL(TRIM(WKSOP::text), '^^') 
            , '||', IFNULL(TRIM(AWSLS::text), '^^') 
            , '||', IFNULL(TRIM(CHAZV_OLD::text), '^^') 
            , '||', IFNULL(TRIM(VLFKZ::text), '^^') 
            , '||', IFNULL(TRIM(BZIRK::text), '^^') 
            , '||', IFNULL(TRIM(ZONE1::text), '^^') 
            , '||', IFNULL(TRIM(TAXIW::text), '^^') 
            , '||', IFNULL(TRIM(BZQHL::text), '^^') 
            , '||', IFNULL(TRIM(LET01::text), '^^') 
            , '||', IFNULL(TRIM(LET02::text), '^^') 
            , '||', IFNULL(TRIM(LET03::text), '^^') 
            , '||', IFNULL(TRIM(TXNAM_MA1::text), '^^') 
            , '||', IFNULL(TRIM(TXNAM_MA2::text), '^^') 
            , '||', IFNULL(TRIM(TXNAM_MA3::text), '^^') 
            , '||', IFNULL(TRIM(BETOL::text), '^^') 
            , '||', IFNULL(TRIM(J_1BBRANCH::text), '^^') 
            , '||', IFNULL(TRIM(VTBFI::text), '^^') 
            , '||', IFNULL(TRIM(FPRFW::text), '^^') 
            , '||', IFNULL(TRIM(ACHVM::text), '^^') 
            , '||', IFNULL(TRIM(DVSART::text), '^^') 
            , '||', IFNULL(TRIM(NODETYPE::text), '^^') 
            , '||', IFNULL(TRIM(NSCHEMA::text), '^^') 
            , '||', IFNULL(TRIM(PKOSA::text), '^^') 
            , '||', IFNULL(TRIM(MISCH::text), '^^') 
            , '||', IFNULL(TRIM(MGVUPD::text), '^^') 
            , '||', IFNULL(TRIM(VSTEL::text), '^^') 
            , '||', IFNULL(TRIM(MGVLAUPD::text), '^^') 
            , '||', IFNULL(TRIM(MGVLAREVAL::text), '^^') 
            , '||', IFNULL(TRIM(SOURCING::text), '^^') 
            , '||', IFNULL(TRIM(FSH_MG_ARUN_REQ::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEAIM::text), '^^') 
            , '||', IFNULL(TRIM(FSH_BOM_MAINTENANCE::text), '^^') 
            , '||', IFNULL(TRIM(OILIVAL::text), '^^') 
            , '||', IFNULL(TRIM(OIHVTYPE::text), '^^') 
            , '||', IFNULL(TRIM(OIHCREDIPI::text), '^^') 
            , '||', IFNULL(TRIM(STORETYPE::text), '^^') 
            , '||', IFNULL(TRIM(DEP_STORE::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

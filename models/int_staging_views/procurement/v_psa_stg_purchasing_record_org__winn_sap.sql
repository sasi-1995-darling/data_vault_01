---- SRC LAYER ----
WITH
SRC_eine           as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_eine') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_eine           as ( SELECT * FROM sap_ecc_prd.z_eine )
, SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_eine as (
    SELECT
        INFNR                                                        as                               PURCHASING_RECORD_BK
      , WERKS                                                        as                                           PLANT_BK
      , EKORG                                                        as                                  PURCHASING_ORG_BK
      , MANDT
      , INFNR
      , EKORG
      , ESOKZ
      , WERKS
      , LOEKZ
      , ERDAT
      , ERNAM
      , EKGRP
      , WAERS
      , BONUS
      , MGBON
      , MINBM
      , NORBM
      , APLFZ
      , UEBTO
      , UEBTK
      , UNTTO
      , ANGNR
      , ANGDT
      , ANFNR
      , ANFPS
      , ABSKZ
      , AMODV
      , AMODB
      , AMOBM
      , AMOBW
      , AMOAM
      , AMOAW
      , AMORS
      , BSTYP
      , EBELN
      , EBELP
      , DATLB
      , NETPR
      , PEINH
      , BPRME
      , PRDAT
      , BPUMZ
      , BPUMN
      , MTXNO
      , WEBRE
      , EFFPR
      , EKKOL
      , SKTOF
      , KZABS
      , MWSKZ
      , BWTAR
      , EBONU
      , EVERS
      , EXPRF
      , BSTAE
      , MEPRF
      , INCO1
      , INCO2
      , XERSN
      , EBON2
      , EBON3
      , EBONF
      , MHDRZ
      , VERID
      , BSTMA
      , RDPRF
      , MEGRU
      , J_1BNBM
      , SPE_CRE_REF_DOC
      , IPRKZ
      , CO_ORDER
      , VENDOR_RMA_REQ
      , DIFF_INVOICE
      , INCOV
      , INCO2_L
      , INCO3_L
      , FSH_DCI_CORR
      , FSH_RLT
      , FSH_MLT
      , FSH_PLT
      , FSH_TLT
      , MRPIND
      , SGT_SSREL
      , TRANSPORT_CHAIN
      , STAGING_TIME
      , ZZMPLFZ
      , ZZTPLFZ
      , ZZOVERRIDE
      , ZZ3TPLFZ
      , ZZ3OVERRIDE
      , ZZEKGRP
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
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
    FROM SRC_eine
)

, LOGIC_ref_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_ref_bkcc
)
---- RENAME LAYER ----

, RENAME_eine as (
    SELECT
        PURCHASING_RECORD_BK
      , PLANT_BK
      , PURCHASING_ORG_BK
      , MANDT
      , INFNR
      , EKORG
      , ESOKZ
      , WERKS
      , LOEKZ
      , ERDAT
      , ERNAM
      , EKGRP
      , WAERS
      , BONUS
      , MGBON
      , MINBM
      , NORBM
      , APLFZ
      , UEBTO
      , UEBTK
      , UNTTO
      , ANGNR
      , ANGDT
      , ANFNR
      , ANFPS
      , ABSKZ
      , AMODV
      , AMODB
      , AMOBM
      , AMOBW
      , AMOAM
      , AMOAW
      , AMORS
      , BSTYP
      , EBELN
      , EBELP
      , DATLB
      , NETPR
      , PEINH
      , BPRME
      , PRDAT
      , BPUMZ
      , BPUMN
      , MTXNO
      , WEBRE
      , EFFPR
      , EKKOL
      , SKTOF
      , KZABS
      , MWSKZ
      , BWTAR
      , EBONU
      , EVERS
      , EXPRF
      , BSTAE
      , MEPRF
      , INCO1
      , INCO2
      , XERSN
      , EBON2
      , EBON3
      , EBONF
      , MHDRZ
      , VERID
      , BSTMA
      , RDPRF
      , MEGRU
      , J_1BNBM
      , SPE_CRE_REF_DOC
      , IPRKZ
      , CO_ORDER
      , VENDOR_RMA_REQ
      , DIFF_INVOICE
      , INCOV
      , INCO2_L
      , INCO3_L
      , FSH_DCI_CORR
      , FSH_RLT
      , FSH_MLT
      , FSH_PLT
      , FSH_TLT
      , MRPIND
      , SGT_SSREL
      , TRANSPORT_CHAIN
      , STAGING_TIME
      , ZZMPLFZ
      , ZZTPLFZ
      , ZZOVERRIDE
      , ZZ3TPLFZ
      , ZZ3OVERRIDE
      , ZZEKGRP
      , GLREQUEST
      , GLSOURCESYSTEM
      , GLDELFLAG
      , GLCHANGETIME
      , GLCHANGETIME_DTTM
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_eine
)

, RENAME_ref_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_ref_bkcc
)
---- FILTER LAYER ----

, FILTER_eine as (
    SELECT *
    FROM RENAME_eine
)

, FILTER_ref_bkcc as (
    SELECT *
    FROM RENAME_ref_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_EINE'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_eine
    INNER JOIN FILTER_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PURCHASING_RECORD_BK
        , PLANT_BK
        , PURCHASING_ORG_BK
        , MANDT
        , INFNR
        , EKORG
        , ESOKZ
        , WERKS
        , LOEKZ
        , ERDAT
        , ERNAM
        , EKGRP
        , WAERS
        , BONUS
        , MGBON
        , MINBM
        , NORBM
        , APLFZ
        , UEBTO
        , UEBTK
        , UNTTO
        , ANGNR
        , ANGDT
        , ANFNR
        , ANFPS
        , ABSKZ
        , AMODV
        , AMODB
        , AMOBM
        , AMOBW
        , AMOAM
        , AMOAW
        , AMORS
        , BSTYP
        , EBELN
        , EBELP
        , DATLB
        , NETPR
        , PEINH
        , BPRME
        , PRDAT
        , BPUMZ
        , BPUMN
        , MTXNO
        , WEBRE
        , EFFPR
        , EKKOL
        , SKTOF
        , KZABS
        , MWSKZ
        , BWTAR
        , EBONU
        , EVERS
        , EXPRF
        , BSTAE
        , MEPRF
        , INCO1
        , INCO2
        , XERSN
        , EBON2
        , EBON3
        , EBONF
        , MHDRZ
        , VERID
        , BSTMA
        , RDPRF
        , MEGRU
        , J_1BNBM
        , SPE_CRE_REF_DOC
        , IPRKZ
        , CO_ORDER
        , VENDOR_RMA_REQ
        , DIFF_INVOICE
        , INCOV
        , INCO2_L
        , INCO3_L
        , FSH_DCI_CORR
        , FSH_RLT
        , FSH_MLT
        , FSH_PLT
        , FSH_TLT
        , MRPIND
        , SGT_SSREL
        , TRANSPORT_CHAIN
        , STAGING_TIME
        , ZZMPLFZ
        , ZZTPLFZ
        , ZZOVERRIDE
        , ZZ3TPLFZ
        , ZZ3OVERRIDE
        , ZZEKGRP
        , GLREQUEST
        , GLSOURCESYSTEM
        , GLDELFLAG
        , GLCHANGETIME
        , GLCHANGETIME_DTTM
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EKORG as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(INFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ESOKZ as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_RECORD_DETAILS_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EKORG as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_ORG_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(INFNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASING_RECORD_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(LOEKZ::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(EKGRP::text), '^^') 
            , '||', IFNULL(TRIM(WAERS::text), '^^') 
            , '||', IFNULL(TRIM(BONUS::text), '^^') 
            , '||', IFNULL(TRIM(MGBON::text), '^^') 
            , '||', IFNULL(TRIM(MINBM::text), '^^') 
            , '||', IFNULL(TRIM(NORBM::text), '^^') 
            , '||', IFNULL(TRIM(APLFZ::text), '^^') 
            , '||', IFNULL(TRIM(UEBTO::text), '^^') 
            , '||', IFNULL(TRIM(UEBTK::text), '^^') 
            , '||', IFNULL(TRIM(UNTTO::text), '^^') 
            , '||', IFNULL(TRIM(ANGNR::text), '^^') 
            , '||', IFNULL(TRIM(ANGDT::text), '^^') 
            , '||', IFNULL(TRIM(ANFNR::text), '^^') 
            , '||', IFNULL(TRIM(ANFPS::text), '^^') 
            , '||', IFNULL(TRIM(ABSKZ::text), '^^') 
            , '||', IFNULL(TRIM(AMODV::text), '^^') 
            , '||', IFNULL(TRIM(AMODB::text), '^^') 
            , '||', IFNULL(TRIM(AMOBM::text), '^^') 
            , '||', IFNULL(TRIM(AMOBW::text), '^^') 
            , '||', IFNULL(TRIM(AMOAM::text), '^^') 
            , '||', IFNULL(TRIM(AMOAW::text), '^^') 
            , '||', IFNULL(TRIM(AMORS::text), '^^') 
            , '||', IFNULL(TRIM(BSTYP::text), '^^') 
            , '||', IFNULL(TRIM(EBELN::text), '^^') 
            , '||', IFNULL(TRIM(EBELP::text), '^^') 
            , '||', IFNULL(TRIM(DATLB::text), '^^') 
            , '||', IFNULL(TRIM(NETPR::text), '^^') 
            , '||', IFNULL(TRIM(PEINH::text), '^^') 
            , '||', IFNULL(TRIM(BPRME::text), '^^') 
            , '||', IFNULL(TRIM(PRDAT::text), '^^') 
            , '||', IFNULL(TRIM(BPUMZ::text), '^^') 
            , '||', IFNULL(TRIM(BPUMN::text), '^^') 
            , '||', IFNULL(TRIM(MTXNO::text), '^^') 
            , '||', IFNULL(TRIM(WEBRE::text), '^^') 
            , '||', IFNULL(TRIM(EFFPR::text), '^^') 
            , '||', IFNULL(TRIM(EKKOL::text), '^^') 
            , '||', IFNULL(TRIM(SKTOF::text), '^^') 
            , '||', IFNULL(TRIM(KZABS::text), '^^') 
            , '||', IFNULL(TRIM(MWSKZ::text), '^^') 
            , '||', IFNULL(TRIM(BWTAR::text), '^^') 
            , '||', IFNULL(TRIM(EBONU::text), '^^') 
            , '||', IFNULL(TRIM(EVERS::text), '^^') 
            , '||', IFNULL(TRIM(EXPRF::text), '^^') 
            , '||', IFNULL(TRIM(BSTAE::text), '^^') 
            , '||', IFNULL(TRIM(MEPRF::text), '^^') 
            , '||', IFNULL(TRIM(INCO1::text), '^^') 
            , '||', IFNULL(TRIM(INCO2::text), '^^') 
            , '||', IFNULL(TRIM(XERSN::text), '^^') 
            , '||', IFNULL(TRIM(EBON2::text), '^^') 
            , '||', IFNULL(TRIM(EBON3::text), '^^') 
            , '||', IFNULL(TRIM(EBONF::text), '^^') 
            , '||', IFNULL(TRIM(MHDRZ::text), '^^') 
            , '||', IFNULL(TRIM(VERID::text), '^^') 
            , '||', IFNULL(TRIM(BSTMA::text), '^^') 
            , '||', IFNULL(TRIM(RDPRF::text), '^^') 
            , '||', IFNULL(TRIM(MEGRU::text), '^^') 
            , '||', IFNULL(TRIM(J_1BNBM::text), '^^') 
            , '||', IFNULL(TRIM(SPE_CRE_REF_DOC::text), '^^') 
            , '||', IFNULL(TRIM(IPRKZ::text), '^^') 
            , '||', IFNULL(TRIM(CO_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_RMA_REQ::text), '^^') 
            , '||', IFNULL(TRIM(DIFF_INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(INCOV::text), '^^') 
            , '||', IFNULL(TRIM(INCO2_L::text), '^^') 
            , '||', IFNULL(TRIM(INCO3_L::text), '^^') 
            , '||', IFNULL(TRIM(FSH_DCI_CORR::text), '^^') 
            , '||', IFNULL(TRIM(FSH_RLT::text), '^^') 
            , '||', IFNULL(TRIM(FSH_MLT::text), '^^') 
            , '||', IFNULL(TRIM(FSH_PLT::text), '^^') 
            , '||', IFNULL(TRIM(FSH_TLT::text), '^^') 
            , '||', IFNULL(TRIM(MRPIND::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SSREL::text), '^^') 
            , '||', IFNULL(TRIM(TRANSPORT_CHAIN::text), '^^') 
            , '||', IFNULL(TRIM(STAGING_TIME::text), '^^') 
            , '||', IFNULL(TRIM(ZZMPLFZ::text), '^^') 
            , '||', IFNULL(TRIM(ZZTPLFZ::text), '^^') 
            , '||', IFNULL(TRIM(ZZOVERRIDE::text), '^^') 
            , '||', IFNULL(TRIM(ZZ3TPLFZ::text), '^^') 
            , '||', IFNULL(TRIM(ZZ3OVERRIDE::text), '^^') 
            , '||', IFNULL(TRIM(ZZEKGRP::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

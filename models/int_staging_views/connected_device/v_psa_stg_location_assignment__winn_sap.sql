---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_iloa') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'US.SAP_ECC_PRD.Z_ILOA' )

/*
SRC_SRC            as ( SELECT * FROM sap_ecc_prd.z_iloa )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        ILOAN                                                        as                             LOCATION_ASSIGNMENT_BK
      , ILOAN
      , MANDT
      , TPLNR
      , ABCKZ
      , ABCKZI
      , EQFNR
      , EQFNRI
      , SWERK                                                       as                              PLANT_BK
      , SWERK
      , SWERKI
      , STORT
      , STORTI
      , MSGRP
      , MSGRPI
      , BEBER
      , BEBERI
      , CR_OBJTY
      , PPSID
      , PPSIDI
      , GSBER
      , GSBERI
      , KOKRS
      , KOKRSI
      , KOSTL                                                       as                              COST_CENTER_BK
      , KOSTL
      , KOSTLI
      , PROID
      , PROIDI
      , BUKRS
      , BUKRSI
      , ANLNR
      , ANLNRI
      , ANLUN
      , ANLUNI
      , DAUFN
      , DAUFNI
      , AUFNR
      , AUFNRI
      , TPLNRI
      , VKORG
      , VKORGI
      , VTWEG
      , VTWEGI
      , SPART
      , SPARTI
      , ADRNR
      , ADRNRI
      , OWNER
      , VKBUR
      , VKGRP
      , GLREQUEST
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
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
        , COST_CENTER_BK
        , PLANT_BK
        , ILOAN
        , MANDT
        , TPLNR
        , ABCKZ
        , ABCKZI
        , EQFNR
        , EQFNRI
        , SWERK
        , SWERKI
        , STORT
        , STORTI
        , MSGRP
        , MSGRPI
        , BEBER
        , BEBERI
        , CR_OBJTY
        , PPSID
        , PPSIDI
        , GSBER
        , GSBERI
        , KOKRS
        , KOKRSI
        , KOSTL
        , KOSTLI
        , PROID
        , PROIDI
        , BUKRS
        , BUKRSI
        , ANLNR
        , ANLNRI
        , ANLUN
        , ANLUNI
        , DAUFN
        , DAUFNI
        , AUFNR
        , AUFNRI
        , TPLNRI
        , VKORG
        , VKORGI
        , VTWEG
        , VTWEGI
        , SPART
        , SPARTI
        , ADRNR
        , ADRNRI
        , OWNER
        , VKBUR
        , VKGRP
        , GLREQUEST
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
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
          COALESCE(NULLIF(TRIM(CAST(KOSTL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as COST_CENTER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SWERK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ILOAN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(KOSTL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SWERK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_LOCATION_ASSIGNMENT_DETAIL_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(TPLNR::text), '^^') 
            , '||', IFNULL(TRIM(ABCKZ::text), '^^') 
            , '||', IFNULL(TRIM(ABCKZI::text), '^^') 
            , '||', IFNULL(TRIM(EQFNR::text), '^^') 
            , '||', IFNULL(TRIM(EQFNRI::text), '^^') 
            , '||', IFNULL(TRIM(SWERKI::text), '^^') 
            , '||', IFNULL(TRIM(STORT::text), '^^') 
            , '||', IFNULL(TRIM(STORTI::text), '^^') 
            , '||', IFNULL(TRIM(MSGRP::text), '^^') 
            , '||', IFNULL(TRIM(MSGRPI::text), '^^') 
            , '||', IFNULL(TRIM(BEBER::text), '^^') 
            , '||', IFNULL(TRIM(BEBERI::text), '^^') 
            , '||', IFNULL(TRIM(CR_OBJTY::text), '^^') 
            , '||', IFNULL(TRIM(PPSID::text), '^^') 
            , '||', IFNULL(TRIM(PPSIDI::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(GSBERI::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(KOKRSI::text), '^^') 
            , '||', IFNULL(TRIM(KOSTLI::text), '^^') 
            , '||', IFNULL(TRIM(PROID::text), '^^') 
            , '||', IFNULL(TRIM(PROIDI::text), '^^') 
            , '||', IFNULL(TRIM(BUKRS::text), '^^') 
            , '||', IFNULL(TRIM(BUKRSI::text), '^^') 
            , '||', IFNULL(TRIM(ANLNR::text), '^^') 
            , '||', IFNULL(TRIM(ANLNRI::text), '^^') 
            , '||', IFNULL(TRIM(ANLUN::text), '^^') 
            , '||', IFNULL(TRIM(ANLUNI::text), '^^') 
            , '||', IFNULL(TRIM(DAUFN::text), '^^') 
            , '||', IFNULL(TRIM(DAUFNI::text), '^^') 
            , '||', IFNULL(TRIM(AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(AUFNRI::text), '^^') 
            , '||', IFNULL(TRIM(TPLNRI::text), '^^') 
            , '||', IFNULL(TRIM(VKORG::text), '^^') 
            , '||', IFNULL(TRIM(VKORGI::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG::text), '^^') 
            , '||', IFNULL(TRIM(VTWEGI::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(SPARTI::text), '^^') 
            , '||', IFNULL(TRIM(ADRNR::text), '^^') 
            , '||', IFNULL(TRIM(ADRNRI::text), '^^') 
            , '||', IFNULL(TRIM(OWNER::text), '^^') 
            , '||', IFNULL(TRIM(VKBUR::text), '^^') 
            , '||', IFNULL(TRIM(VKGRP::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

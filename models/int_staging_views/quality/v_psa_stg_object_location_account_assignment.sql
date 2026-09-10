---- SRC LAYER ----
WITH
SRC_a              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_iloa') }} as SRC  ),
SRC_b              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM SAP_ECC_PRD.Z_ILOA )
, SRC_b              as ( SELECT * FROM RAW_VAULT.REF_BUSINESS_KEY_COLLISION )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(MANDT as VARCHAR)),''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(ILOAN as VARCHAR)),''), '^^')
        )))                                                          as              OBJECT_LOCATION_ACCOUNT_ASSIGNMENT_BK
      , MANDT
      , ILOAN
      , GLREQUEST
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
        )) as                                           LOAD_DTS
      , 'FB WINN'                                                    as                                              BRAND
    FROM SRC_a
)

, LOGIC_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        OBJECT_LOCATION_ACCOUNT_ASSIGNMENT_BK
      , MANDT
      , ILOAN
      , GLREQUEST
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
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , LOAD_DTS
      , BRAND
    FROM LOGIC_a
)

, RENAME_b as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_b as (
    SELECT *
    FROM RENAME_b
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_ILOA'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_b
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          OBJECT_LOCATION_ACCOUNT_ASSIGNMENT_BK
        , MANDT
        , ILOAN
        , GLREQUEST
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
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , LOAD_DTS
        , REC_SRC
        , BRAND
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MANDT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ILOAN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as OBJECT_LOCATION_ACCOUNT_ASSIGNMENT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(OBJECT_LOCATION_ACCOUNT_ASSIGNMENT_BK::text), '^^') 
            , '||', IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(ILOAN::text), '^^') 
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^') 
            , '||', IFNULL(TRIM(TPLNR::text), '^^') 
            , '||', IFNULL(TRIM(ABCKZ::text), '^^') 
            , '||', IFNULL(TRIM(ABCKZI::text), '^^') 
            , '||', IFNULL(TRIM(EQFNR::text), '^^') 
            , '||', IFNULL(TRIM(EQFNRI::text), '^^') 
            , '||', IFNULL(TRIM(SWERK::text), '^^') 
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
            , '||', IFNULL(TRIM(KOSTL::text), '^^') 
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
            , '||', IFNULL(TRIM(GLCHANGETIME::text), '^^') 
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

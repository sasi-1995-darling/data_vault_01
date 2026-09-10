---- SRC LAYER ----
WITH
SRC_polsap         as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_eket') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_polsap         as ( SELECT * FROM sap_ecc_prd.z_eket )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_polsap as (
    SELECT
        CONCAT_WS('||', COALESCE(EBELN, ''), COALESCE(EBELP, ''))    as                                         PO_ITEM_BK
      , EBELN                                                        as                                       PO_HEADER_BK
      , EBELN
      , EBELP
      , ETENR
      , MANDT
      , GLREQUEST
      , GLSOURCESYSTEM
      , EINDT
      , SLFDT
      , LPEIN
      , MENGE
      , AMENG
      , WEMNG
      , WAMNG
      , UZEIT
      , BANFN
      , BNFPO
      , ESTKZ
      , QUNUM
      , QUPOS
      , MAHNZ
      , BEDAT
      , RSNUM
      , SERNR
      , FIXKZ
      , GLMNG
      , DABMG
      , CHARG
      , LICHA
      , CHKOM
      , VERID
      , ABART
      , MNG02
      , DAT01
      , ALTDT
      , AULWE
      , MBDAT
      , MBUHR
      , LDDAT
      , LDUHR
      , TDDAT
      , TDUHR
      , WADAT
      , WAUHR
      , ELDAT
      , ELUHR
      , ANZSN
      , NODISP
      , GEO_ROUTE
      , ROUTE_GTS
      , GTS_IND
      , TSP
      , CD_LOCNO
      , CD_LOCTYPE
      , HANDOVERDATE
      , HANDOVERTIME
      , FSH_RALLOC_QTY
      , FSH_SALLOC_QTY
      , FSH_OS_ID
      , KEY_ID
      , OTB_VALUE
      , OTB_CURR
      , OTB_RES_VALUE
      , OTB_SPEC_VALUE
      , SPR_RSN_PROFILE
      , BUDG_TYPE
      , OTB_STATUS
      , OTB_REASON
      , CHECK_TYPE
      , DL_ID
      , HANDOVER_DATE
      , NO_SCEM
      , DNG_DATE
      , DNG_TIME
      , CNCL_ANCMNT_DONE
      , DATESHIFT_NUMBER
      , ZZSHPDT
      , ZZOVERRIDE
      , ZZFREIGHT
      , ZZCOST
      , ZZASN
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_polsap
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_polsap as (
    SELECT
        PO_ITEM_BK
      , PO_HEADER_BK
      , EBELN
      , EBELP
      , ETENR
      , MANDT
      , GLREQUEST
      , GLSOURCESYSTEM
      , EINDT
      , SLFDT
      , LPEIN
      , MENGE
      , AMENG
      , WEMNG
      , WAMNG
      , UZEIT
      , BANFN
      , BNFPO
      , ESTKZ
      , QUNUM
      , QUPOS
      , MAHNZ
      , BEDAT
      , RSNUM
      , SERNR
      , FIXKZ
      , GLMNG
      , DABMG
      , CHARG
      , LICHA
      , CHKOM
      , VERID
      , ABART
      , MNG02
      , DAT01
      , ALTDT
      , AULWE
      , MBDAT
      , MBUHR
      , LDDAT
      , LDUHR
      , TDDAT
      , TDUHR
      , WADAT
      , WAUHR
      , ELDAT
      , ELUHR
      , ANZSN
      , NODISP
      , GEO_ROUTE
      , ROUTE_GTS
      , GTS_IND
      , TSP
      , CD_LOCNO
      , CD_LOCTYPE
      , HANDOVERDATE
      , HANDOVERTIME
      , FSH_RALLOC_QTY
      , FSH_SALLOC_QTY
      , FSH_OS_ID
      , KEY_ID
      , OTB_VALUE
      , OTB_CURR
      , OTB_RES_VALUE
      , OTB_SPEC_VALUE
      , SPR_RSN_PROFILE
      , BUDG_TYPE
      , OTB_STATUS
      , OTB_REASON
      , CHECK_TYPE
      , DL_ID
      , HANDOVER_DATE
      , NO_SCEM
      , DNG_DATE
      , DNG_TIME
      , CNCL_ANCMNT_DONE
      , DATESHIFT_NUMBER
      , ZZSHPDT
      , ZZOVERRIDE
      , ZZFREIGHT
      , ZZCOST
      , ZZASN
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
    FROM LOGIC_polsap
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_polsap as (
    SELECT *
    FROM RENAME_polsap
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_EKET'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_polsap
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PO_ITEM_BK
        , PO_HEADER_BK
        , EBELN
        , EBELP
        , ETENR
        , MANDT
        , GLREQUEST
        , GLSOURCESYSTEM
        , EINDT
        , SLFDT
        , LPEIN
        , MENGE
        , AMENG
        , WEMNG
        , WAMNG
        , UZEIT
        , BANFN
        , BNFPO
        , ESTKZ
        , QUNUM
        , QUPOS
        , MAHNZ
        , BEDAT
        , RSNUM
        , SERNR
        , FIXKZ
        , GLMNG
        , DABMG
        , CHARG
        , LICHA
        , CHKOM
        , VERID
        , ABART
        , MNG02
        , DAT01
        , ALTDT
        , AULWE
        , MBDAT
        , MBUHR
        , LDDAT
        , LDUHR
        , TDDAT
        , TDUHR
        , WADAT
        , WAUHR
        , ELDAT
        , ELUHR
        , ANZSN
        , NODISP
        , GEO_ROUTE
        , ROUTE_GTS
        , GTS_IND
        , TSP
        , CD_LOCNO
        , CD_LOCTYPE
        , HANDOVERDATE
        , HANDOVERTIME
        , FSH_RALLOC_QTY
        , FSH_SALLOC_QTY
        , FSH_OS_ID
        , KEY_ID
        , OTB_VALUE
        , OTB_CURR
        , OTB_RES_VALUE
        , OTB_SPEC_VALUE
        , SPR_RSN_PROFILE
        , BUDG_TYPE
        , OTB_STATUS
        , OTB_REASON
        , CHECK_TYPE
        , DL_ID
        , HANDOVER_DATE
        , NO_SCEM
        , DNG_DATE
        , DNG_TIME
        , CNCL_ANCMNT_DONE
        , DATESHIFT_NUMBER
        , ZZSHPDT
        , ZZOVERRIDE
        , ZZFREIGHT
        , ZZCOST
        , ZZASN
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(EBELN as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(EBELP as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(EINDT::text), '^^') 
            , '||', IFNULL(TRIM(SLFDT::text), '^^') 
            , '||', IFNULL(TRIM(LPEIN::text), '^^') 
            , '||', IFNULL(TRIM(MENGE::text), '^^') 
            , '||', IFNULL(TRIM(AMENG::text), '^^') 
            , '||', IFNULL(TRIM(WEMNG::text), '^^') 
            , '||', IFNULL(TRIM(WAMNG::text), '^^') 
            , '||', IFNULL(TRIM(UZEIT::text), '^^') 
            , '||', IFNULL(TRIM(BANFN::text), '^^') 
            , '||', IFNULL(TRIM(BNFPO::text), '^^') 
            , '||', IFNULL(TRIM(ESTKZ::text), '^^') 
            , '||', IFNULL(TRIM(QUNUM::text), '^^') 
            , '||', IFNULL(TRIM(QUPOS::text), '^^') 
            , '||', IFNULL(TRIM(MAHNZ::text), '^^') 
            , '||', IFNULL(TRIM(BEDAT::text), '^^') 
            , '||', IFNULL(TRIM(RSNUM::text), '^^') 
            , '||', IFNULL(TRIM(SERNR::text), '^^') 
            , '||', IFNULL(TRIM(FIXKZ::text), '^^') 
            , '||', IFNULL(TRIM(GLMNG::text), '^^') 
            , '||', IFNULL(TRIM(DABMG::text), '^^') 
            , '||', IFNULL(TRIM(CHARG::text), '^^') 
            , '||', IFNULL(TRIM(LICHA::text), '^^') 
            , '||', IFNULL(TRIM(CHKOM::text), '^^') 
            , '||', IFNULL(TRIM(VERID::text), '^^') 
            , '||', IFNULL(TRIM(ABART::text), '^^') 
            , '||', IFNULL(TRIM(MNG02::text), '^^') 
            , '||', IFNULL(TRIM(DAT01::text), '^^') 
            , '||', IFNULL(TRIM(ALTDT::text), '^^') 
            , '||', IFNULL(TRIM(AULWE::text), '^^') 
            , '||', IFNULL(TRIM(MBDAT::text), '^^') 
            , '||', IFNULL(TRIM(MBUHR::text), '^^') 
            , '||', IFNULL(TRIM(LDDAT::text), '^^') 
            , '||', IFNULL(TRIM(LDUHR::text), '^^') 
            , '||', IFNULL(TRIM(TDDAT::text), '^^') 
            , '||', IFNULL(TRIM(TDUHR::text), '^^') 
            , '||', IFNULL(TRIM(WADAT::text), '^^') 
            , '||', IFNULL(TRIM(WAUHR::text), '^^') 
            , '||', IFNULL(TRIM(ELDAT::text), '^^') 
            , '||', IFNULL(TRIM(ELUHR::text), '^^') 
            , '||', IFNULL(TRIM(ANZSN::text), '^^') 
            , '||', IFNULL(TRIM(NODISP::text), '^^') 
            , '||', IFNULL(TRIM(GEO_ROUTE::text), '^^') 
            , '||', IFNULL(TRIM(ROUTE_GTS::text), '^^') 
            , '||', IFNULL(TRIM(GTS_IND::text), '^^') 
            , '||', IFNULL(TRIM(TSP::text), '^^') 
            , '||', IFNULL(TRIM(CD_LOCNO::text), '^^') 
            , '||', IFNULL(TRIM(CD_LOCTYPE::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVERDATE::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVERTIME::text), '^^') 
            , '||', IFNULL(TRIM(FSH_RALLOC_QTY::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SALLOC_QTY::text), '^^') 
            , '||', IFNULL(TRIM(FSH_OS_ID::text), '^^') 
            , '||', IFNULL(TRIM(KEY_ID::text), '^^') 
            , '||', IFNULL(TRIM(OTB_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(OTB_CURR::text), '^^') 
            , '||', IFNULL(TRIM(OTB_RES_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(OTB_SPEC_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(SPR_RSN_PROFILE::text), '^^') 
            , '||', IFNULL(TRIM(BUDG_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(OTB_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(OTB_REASON::text), '^^') 
            , '||', IFNULL(TRIM(CHECK_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(DL_ID::text), '^^') 
            , '||', IFNULL(TRIM(HANDOVER_DATE::text), '^^') 
            , '||', IFNULL(TRIM(NO_SCEM::text), '^^') 
            , '||', IFNULL(TRIM(DNG_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DNG_TIME::text), '^^') 
            , '||', IFNULL(TRIM(CNCL_ANCMNT_DONE::text), '^^') 
            , '||', IFNULL(TRIM(DATESHIFT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ZZSHPDT::text), '^^') 
            , '||', IFNULL(TRIM(ZZOVERRIDE::text), '^^') 
            , '||', IFNULL(TRIM(ZZFREIGHT::text), '^^') 
            , '||', IFNULL(TRIM(ZZCOST::text), '^^') 
            , '||', IFNULL(TRIM(ZZASN::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

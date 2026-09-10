---- SRC LAYER ----
WITH
SRC_KEKO           as ( SELECT AFAKT, ALDAT, ASL, AUFPL, AUFZA, AUSID, AUSSS, BALTKZ, BAPI_CREATED, BDATJ, BEDAT, BESKZ, BIDAM, BIDAT, BTYP, BWDAT, BWKEY, BWSMR, BWTAR, BWVAR, BWVAR_BA, BZOBJ, CFXPR, CMF_NR, CPUDM, CPUDT, CPUTIME, CSPLIT, CUOBJ, CUOBJID, DISST, ELEHK, ELEHKNS, ERFMA, ERFNM, ERZKA, FEH_ANZ, FEH_K_ANZ, FEH_STA, FREIDAT, FREIG, FREIUSR, FWAER_KPF, FXPRU, GSBER, HWAER, KADAM, KADAT, KADKY, KALADAT, KALAID, KALKA, KALNR, KALNR_BA, KALSM, KALST, KKZMA, KLVAR, KOKRS, KOSGR, KURST, KZKUP, KZROH, KZWSO, LOEKZ, LOSAU, LOSGR, MATNR, MAXMSG, MEINH_WS, MEINS, MGTYP, MISCH_VERH, MKALK, MLMAA, OBJNR, OCS_COUNT, OTYP, PART_VRSN, PATNR, PLMNG, PLNAL, PLNCT, PLNNR, PLNTY, PLSCN, POPER, POSNR, PRCTR, PROZESS, PR_VERID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSPNR, REFID, SAPRL, SBDKZ, SGT_SCAT, SOBES, SOBSL, SOBWT, SODIR, SODUM, SOWRK, STALT, STCNT, STKOZ, STLAN, STNUM, SUBSTRAT, SUMZIFFR, TECHS, TEMPLATE, TOPKA, TPVAR, TVERS, TYPE, UEBID, VBELN, VERID, VOCNT, VORMDAT, VORMUSR, WERKS, WRKLT, ZAEHL, ZIFFR, ZSCHL FROM {{ source('sap_ecc_prd', 'z_keko') }} as SRC  ),
SRC_BKCC           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_KEKO           as ( SELECT * FROM sap_ecc_prd.z_keko )
SRC_BKCC           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_KEKO as (
    SELECT
        MATNR
      , BZOBJ
      , KALNR
      , BWVAR
      , KKZMA
      , KADKY
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , KALKA
      , TVERS
      , COALESCE(NULLIF(UPPER(TRIM(MATNR)),'-1'),'UNKNOWN')          as                                            ITEM_BK
      , WERKS
      , COALESCE(NULLIF(UPPER(TRIM(WERKS)),''),'-1')                 as                                           PLANT_BK
      , BWKEY
      , BWTAR
      , KOKRS
      , KADAT
      , BIDAT
      , KADAM
      , BIDAM
      , BWDAT
      , ALDAT
      , BEDAT
      , VERID
      , STNUM
      , STLAN
      , STALT
      , STCNT
      , PLNNR
      , PLNTY
      , PLNAL
      , PLNCT
      , LOEKZ
      , LOSGR
      , MEINS
      , ERFNM
      , ERFMA
      , CPUDT
      , CPUDM
      , CPUTIME
      , FEH_ANZ
      , FEH_K_ANZ
      , FEH_STA
      , MAXMSG
      , FREIG
      , MKALK
      , BALTKZ
      , KALNR_BA
      , BTYP
      , MISCH_VERH
      , BWVAR_BA
      , PLSCN
      , PLMNG
      , SOBSL
      , SOBES
      , SOWRK
      , SOBWT
      , SODIR
      , SODUM
      , KALSM
      , AUFZA
      , BWSMR
      , SUBSTRAT
      , KLVAR
      , KOSGR
      , ZSCHL
      , POPER
      , BDATJ
      , STKOZ
      , ZAEHL
      , TOPKA
      , CMF_NR
      , OCS_COUNT
      , OBJNR
      , ERZKA
      , LOSAU
      , AUSID
      , AUSSS
      , SAPRL
      , KZROH
      , AUFPL
      , CUOBJ
      , CUOBJID
      , TECHS
      , TYPE
      , WRKLT
      , VORMDAT
      , VORMUSR
      , FREIDAT
      , FREIUSR
      , UEBID
      , PROZESS
      , PR_VERID
      , CSPLIT
      , KZKUP
      , FXPRU
      , CFXPR
      , ZIFFR
      , SUMZIFFR
      , AFAKT
      , VBELN
      , POSNR
      , PSPNR
      , SBDKZ
      , MLMAA
      , BESKZ
      , DISST
      , KALST
      , TEMPLATE
      , PATNR
      , PART_VRSN
      , ELEHK
      , ELEHKNS
      , VOCNT
      , GSBER
      , PRCTR
      , TPVAR
      , KURST
      , MGTYP
      , HWAER
      , FWAER_KPF
      , REFID
      , MEINH_WS
      , KZWSO
      , ASL
      , KALAID
      , KALADAT
      , OTYP
      , BAPI_CREATED
      , SGT_SCAT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_KEKO
)

, LOGIC_BKCC as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_BKCC
)
---- RENAME LAYER ----

, RENAME_KEKO as (
    SELECT
        MATNR
      , BZOBJ
      , KALNR
      , BWVAR
      , KKZMA
      , KADKY
      , LOAD_DTS
      , KALKA
      , TVERS
      , ITEM_BK
      , WERKS
      , PLANT_BK
      , BWKEY
      , BWTAR
      , KOKRS
      , KADAT
      , BIDAT
      , KADAM
      , BIDAM
      , BWDAT
      , ALDAT
      , BEDAT
      , VERID
      , STNUM
      , STLAN
      , STALT
      , STCNT
      , PLNNR
      , PLNTY
      , PLNAL
      , PLNCT
      , LOEKZ
      , LOSGR
      , MEINS
      , ERFNM
      , ERFMA
      , CPUDT
      , CPUDM
      , CPUTIME
      , FEH_ANZ
      , FEH_K_ANZ
      , FEH_STA
      , MAXMSG
      , FREIG
      , MKALK
      , BALTKZ
      , KALNR_BA
      , BTYP
      , MISCH_VERH
      , BWVAR_BA
      , PLSCN
      , PLMNG
      , SOBSL
      , SOBES
      , SOWRK
      , SOBWT
      , SODIR
      , SODUM
      , KALSM
      , AUFZA
      , BWSMR
      , SUBSTRAT
      , KLVAR
      , KOSGR
      , ZSCHL
      , POPER
      , BDATJ
      , STKOZ
      , ZAEHL
      , TOPKA
      , CMF_NR
      , OCS_COUNT
      , OBJNR
      , ERZKA
      , LOSAU
      , AUSID
      , AUSSS
      , SAPRL
      , KZROH
      , AUFPL
      , CUOBJ
      , CUOBJID
      , TECHS
      , TYPE
      , WRKLT
      , VORMDAT
      , VORMUSR
      , FREIDAT
      , FREIUSR
      , UEBID
      , PROZESS
      , PR_VERID
      , CSPLIT
      , KZKUP
      , FXPRU
      , CFXPR
      , ZIFFR
      , SUMZIFFR
      , AFAKT
      , VBELN
      , POSNR
      , PSPNR
      , SBDKZ
      , MLMAA
      , BESKZ
      , DISST
      , KALST
      , TEMPLATE
      , PATNR
      , PART_VRSN
      , ELEHK
      , ELEHKNS
      , VOCNT
      , GSBER
      , PRCTR
      , TPVAR
      , KURST
      , MGTYP
      , HWAER
      , FWAER_KPF
      , REFID
      , MEINH_WS
      , KZWSO
      , ASL
      , KALAID
      , KALADAT
      , OTYP
      , BAPI_CREATED
      , SGT_SCAT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_KEKO
)

, RENAME_BKCC as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_BKCC
)
---- FILTER LAYER ----

, FILTER_KEKO as (
    SELECT *
    FROM RENAME_KEKO
    WHERE PSA_DELETE_IND='N'
)

, FILTER_BKCC as (
    SELECT *
    FROM RENAME_BKCC
    WHERE REC_SRC = 'USOHNO.SAP.ECCPRD.KEKO'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_KEKO
    INNER JOIN FILTER_BKCC
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          MATNR
        , BZOBJ
        , KALNR
        , BWVAR
        , KKZMA
        , KADKY
        , LOAD_DTS
        , KALKA
        , TVERS
        , ITEM_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , WERKS
        , PLANT_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , BWKEY
        , BWTAR
        , KOKRS
        , KADAT
        , BIDAT
        , KADAM
        , BIDAM
        , BWDAT
        , ALDAT
        , BEDAT
        , VERID
        , STNUM
        , STLAN
        , STALT
        , STCNT
        , PLNNR
        , PLNTY
        , PLNAL
        , PLNCT
        , LOEKZ
        , LOSGR
        , MEINS
        , ERFNM
        , ERFMA
        , CPUDT
        , CPUDM
        , CPUTIME
        , FEH_ANZ
        , FEH_K_ANZ
        , FEH_STA
        , MAXMSG
        , FREIG
        , MKALK
        , BALTKZ
        , KALNR_BA
        , BTYP
        , MISCH_VERH
        , BWVAR_BA
        , PLSCN
        , PLMNG
        , SOBSL
        , SOBES
        , SOWRK
        , SOBWT
        , SODIR
        , SODUM
        , KALSM
        , AUFZA
        , BWSMR
        , SUBSTRAT
        , KLVAR
        , KOSGR
        , ZSCHL
        , POPER
        , BDATJ
        , STKOZ
        , ZAEHL
        , TOPKA
        , CMF_NR
        , OCS_COUNT
        , OBJNR
        , ERZKA
        , LOSAU
        , AUSID
        , AUSSS
        , SAPRL
        , KZROH
        , AUFPL
        , CUOBJ
        , CUOBJID
        , TECHS
        , TYPE
        , WRKLT
        , VORMDAT
        , VORMUSR
        , FREIDAT
        , FREIUSR
        , UEBID
        , PROZESS
        , PR_VERID
        , CSPLIT
        , KZKUP
        , FXPRU
        , CFXPR
        , ZIFFR
        , SUMZIFFR
        , AFAKT
        , VBELN
        , POSNR
        , PSPNR
        , SBDKZ
        , MLMAA
        , BESKZ
        , DISST
        , KALST
        , TEMPLATE
        , PATNR
        , PART_VRSN
        , ELEHK
        , ELEHKNS
        , VOCNT
        , GSBER
        , PRCTR
        , TPVAR
        , KURST
        , MGTYP
        , HWAER
        , FWAER_KPF
        , REFID
        , MEINH_WS
        , KZWSO
        , ASL
        , KALAID
        , KALADAT
        , OTYP
        , BAPI_CREATED
        , SGT_SCAT
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
		,  COALESCE(NULLIF(TRIM(CAST(WERKS as VARCHAR)),''), '^^')
		,  COALESCE(NULLIF(TRIM(CAST(POPER as VARCHAR)),''), '^^')
		,  COALESCE(NULLIF(TRIM(CAST(BDATJ as VARCHAR)),''), '^^')
		,  COALESCE(NULLIF(TRIM(CAST(KLVAR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_COST_ESTIMATE_HK
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(KALKA::text), '^^') 
            , '||', IFNULL(TRIM(TVERS::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(BWKEY::text), '^^') 
            , '||', IFNULL(TRIM(BWTAR::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(KADAT::text), '^^') 
            , '||', IFNULL(TRIM(BIDAT::text), '^^') 
            , '||', IFNULL(TRIM(KADAM::text), '^^') 
            , '||', IFNULL(TRIM(BIDAM::text), '^^') 
            , '||', IFNULL(TRIM(BWDAT::text), '^^') 
            , '||', IFNULL(TRIM(ALDAT::text), '^^') 
            , '||', IFNULL(TRIM(BEDAT::text), '^^') 
            , '||', IFNULL(TRIM(VERID::text), '^^') 
            , '||', IFNULL(TRIM(STNUM::text), '^^') 
            , '||', IFNULL(TRIM(STLAN::text), '^^') 
            , '||', IFNULL(TRIM(STALT::text), '^^') 
            , '||', IFNULL(TRIM(STCNT::text), '^^') 
            , '||', IFNULL(TRIM(PLNNR::text), '^^') 
            , '||', IFNULL(TRIM(PLNTY::text), '^^') 
            , '||', IFNULL(TRIM(PLNAL::text), '^^') 
            , '||', IFNULL(TRIM(PLNCT::text), '^^') 
            , '||', IFNULL(TRIM(LOEKZ::text), '^^') 
            , '||', IFNULL(TRIM(LOSGR::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(ERFNM::text), '^^') 
            , '||', IFNULL(TRIM(ERFMA::text), '^^') 
            , '||', IFNULL(TRIM(CPUDT::text), '^^') 
            , '||', IFNULL(TRIM(CPUDM::text), '^^') 
            , '||', IFNULL(TRIM(CPUTIME::text), '^^') 
            , '||', IFNULL(TRIM(FEH_ANZ::text), '^^') 
            , '||', IFNULL(TRIM(FEH_K_ANZ::text), '^^') 
            , '||', IFNULL(TRIM(FEH_STA::text), '^^') 
            , '||', IFNULL(TRIM(MAXMSG::text), '^^') 
            , '||', IFNULL(TRIM(FREIG::text), '^^') 
            , '||', IFNULL(TRIM(MKALK::text), '^^') 
            , '||', IFNULL(TRIM(BALTKZ::text), '^^') 
            , '||', IFNULL(TRIM(KALNR_BA::text), '^^') 
            , '||', IFNULL(TRIM(BTYP::text), '^^') 
            , '||', IFNULL(TRIM(MISCH_VERH::text), '^^') 
            , '||', IFNULL(TRIM(BWVAR_BA::text), '^^') 
            , '||', IFNULL(TRIM(PLSCN::text), '^^') 
            , '||', IFNULL(TRIM(PLMNG::text), '^^') 
            , '||', IFNULL(TRIM(SOBSL::text), '^^') 
            , '||', IFNULL(TRIM(SOBES::text), '^^') 
            , '||', IFNULL(TRIM(SOWRK::text), '^^') 
            , '||', IFNULL(TRIM(SOBWT::text), '^^') 
            , '||', IFNULL(TRIM(SODIR::text), '^^') 
            , '||', IFNULL(TRIM(SODUM::text), '^^') 
            , '||', IFNULL(TRIM(KALSM::text), '^^') 
            , '||', IFNULL(TRIM(AUFZA::text), '^^') 
            , '||', IFNULL(TRIM(BWSMR::text), '^^') 
            , '||', IFNULL(TRIM(SUBSTRAT::text), '^^') 
            , '||', IFNULL(TRIM(KLVAR::text), '^^') 
            , '||', IFNULL(TRIM(KOSGR::text), '^^') 
            , '||', IFNULL(TRIM(ZSCHL::text), '^^') 
            , '||', IFNULL(TRIM(POPER::text), '^^') 
            , '||', IFNULL(TRIM(BDATJ::text), '^^') 
            , '||', IFNULL(TRIM(STKOZ::text), '^^') 
            , '||', IFNULL(TRIM(ZAEHL::text), '^^') 
            , '||', IFNULL(TRIM(TOPKA::text), '^^') 
            , '||', IFNULL(TRIM(CMF_NR::text), '^^') 
            , '||', IFNULL(TRIM(OCS_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(OBJNR::text), '^^') 
            , '||', IFNULL(TRIM(ERZKA::text), '^^') 
            , '||', IFNULL(TRIM(LOSAU::text), '^^') 
            , '||', IFNULL(TRIM(AUSID::text), '^^') 
            , '||', IFNULL(TRIM(AUSSS::text), '^^') 
            , '||', IFNULL(TRIM(SAPRL::text), '^^') 
            , '||', IFNULL(TRIM(KZROH::text), '^^') 
            , '||', IFNULL(TRIM(AUFPL::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJID::text), '^^') 
            , '||', IFNULL(TRIM(TECHS::text), '^^') 
            , '||', IFNULL(TRIM(TYPE::text), '^^') 
            , '||', IFNULL(TRIM(WRKLT::text), '^^') 
            , '||', IFNULL(TRIM(VORMDAT::text), '^^') 
            , '||', IFNULL(TRIM(VORMUSR::text), '^^') 
            , '||', IFNULL(TRIM(FREIDAT::text), '^^') 
            , '||', IFNULL(TRIM(FREIUSR::text), '^^') 
            , '||', IFNULL(TRIM(UEBID::text), '^^') 
            , '||', IFNULL(TRIM(PROZESS::text), '^^') 
            , '||', IFNULL(TRIM(PR_VERID::text), '^^') 
            , '||', IFNULL(TRIM(CSPLIT::text), '^^') 
            , '||', IFNULL(TRIM(KZKUP::text), '^^') 
            , '||', IFNULL(TRIM(FXPRU::text), '^^') 
            , '||', IFNULL(TRIM(CFXPR::text), '^^') 
            , '||', IFNULL(TRIM(ZIFFR::text), '^^') 
            , '||', IFNULL(TRIM(SUMZIFFR::text), '^^') 
            , '||', IFNULL(TRIM(AFAKT::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(PSPNR::text), '^^') 
            , '||', IFNULL(TRIM(SBDKZ::text), '^^') 
            , '||', IFNULL(TRIM(MLMAA::text), '^^') 
            , '||', IFNULL(TRIM(BESKZ::text), '^^') 
            , '||', IFNULL(TRIM(DISST::text), '^^') 
            , '||', IFNULL(TRIM(KALST::text), '^^') 
            , '||', IFNULL(TRIM(TEMPLATE::text), '^^') 
            , '||', IFNULL(TRIM(PATNR::text), '^^') 
            , '||', IFNULL(TRIM(PART_VRSN::text), '^^') 
            , '||', IFNULL(TRIM(ELEHK::text), '^^') 
            , '||', IFNULL(TRIM(ELEHKNS::text), '^^') 
            , '||', IFNULL(TRIM(VOCNT::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(PRCTR::text), '^^') 
            , '||', IFNULL(TRIM(TPVAR::text), '^^') 
            , '||', IFNULL(TRIM(KURST::text), '^^') 
            , '||', IFNULL(TRIM(MGTYP::text), '^^') 
            , '||', IFNULL(TRIM(HWAER::text), '^^') 
            , '||', IFNULL(TRIM(FWAER_KPF::text), '^^') 
            , '||', IFNULL(TRIM(REFID::text), '^^') 
            , '||', IFNULL(TRIM(MEINH_WS::text), '^^') 
            , '||', IFNULL(TRIM(KZWSO::text), '^^') 
            , '||', IFNULL(TRIM(ASL::text), '^^') 
            , '||', IFNULL(TRIM(KALAID::text), '^^') 
            , '||', IFNULL(TRIM(KALADAT::text), '^^') 
            , '||', IFNULL(TRIM(OTYP::text), '^^') 
            , '||', IFNULL(TRIM(BAPI_CREATED::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SCAT::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

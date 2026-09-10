---- SRC LAYER ----
WITH
SRC_VBAP           as ( SELECT * FROM {{ ref('v_psa_stg_order_item__winn_sap') }} as SRC
                        {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %} )

/*
SRC_VBAP           as ( SELECT * FROM STAGING.v_psa_stg_order_item__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_VBAP as (
    SELECT
        ORDER_LINE_HK
      , MANDT
      , VBELN
      , POSNR
      , GLREQUEST
      , MATNR
      , MATWA
      , PMATN
      , CHARG
      , MATKL
      , ARKTX
      , PSTYV
      , POSAR
      , LFREL
      , FKREL
      , UEPOS
      , GRPOS
      , ABGRU
      , PRODH
      , ZWERT
      , ZMENG
      , ZIEME
      , UMZIZ
      , UMZIN
      , MEINS
      , SMENG
      , ABLFZ
      , ABDAT
      , ABDAT_DT
      , ABSFZ
      , POSEX
      , KDMAT
      , KBVER
      , KEVER
      , VKGRU
      , VKAUS
      , GRKOR
      , FMENG
      , UEBTK
      , UEBTO
      , UNTTO
      , FAKSP
      , ATPKZ
      , RKFKF
      , SPART
      , GSBER
      , NETWR
      , WAERK
      , ANTLF
      , KZTLF
      , CHSPL
      , KWMENG
      , LSMENG
      , KBMENG
      , KLMENG
      , VRKME
      , UMVKZ
      , UMVKN
      , BRGEW
      , NTGEW
      , GEWEI
      , VOLUM
      , VOLEH
      , VBELV
      , POSNV
      , VGBEL
      , VGPOS
      , VOREF
      , UPFLU
      , ERLRE
      , LPRIO
      , WERKS
      , LGORT
      , VSTEL
      , ROUTE
      , STKEY
      , STDAT
      , STDAT_DT
      , STLNR
      , STPOS
      , AWAHR
      , ERDAT
      , ERNAM
      , ERZET
      , TAXM1
      , TAXM2
      , TAXM3
      , TAXM4
      , TAXM5
      , TAXM6
      , TAXM7
      , TAXM8
      , TAXM9
      , VBEAF
      , VBEAV
      , VGREF
      , NETPR
      , KPEIN
      , KMEIN
      , SHKZG
      , SKTOF
      , MTVFP
      , SUMBD
      , KONDM
      , KTGRM
      , BONUS
      , PROVG
      , EANNR
      , PRSOK
      , BWTAR
      , BWTEX
      , XCHPF
      , XCHAR
      , LFMNG
      , STAFO
      , WAVWR
      , KZWI1
      , KZWI2
      , KZWI3
      , KZWI4
      , KZWI5
      , KZWI6
      , STCUR
      , AEDAT
      , AEDAT_DT
      , EAN11
      , FIXMG
      , PRCTR
      , MVGR1
      , MVGR2
      , MVGR3
      , MVGR4
      , MVGR5
      , KMPMG
      , SUGRD
      , SOBKZ
      , VPZUO
      , PAOBJNR
      , PS_PSP_PNR
      , AUFNR
      , VPMAT
      , VPWRK
      , PRBME
      , UMREF
      , KNTTP
      , KZVBR
      , SERNR
      , OBJNR
      , ABGRS
      , BEDAE
      , CMPRE
      , CMTFG
      , CMPNT
      , CMKUA
      , CUOBJ
      , CUOBJ_CH
      , CEPOK
      , KOUPD
      , SERAIL
      , ANZSN
      , NACHL
      , MAGRV
      , MPROK
      , VGTYP
      , PROSA
      , UEPVW
      , KALNR
      , KLVAR
      , SPOSN
      , KOWRR
      , STADAT
      , STADAT_DT
      , EXART
      , PREFE
      , KNUMH
      , CLINT
      , CHMVS
      , STLTY
      , STLKN
      , STPOZ
      , STMAN
      , ZSCHL_K
      , KALSM_K
      , KALVAR
      , KOSCH
      , UPMAT
      , UKONM
      , MFRGR
      , PLAVO
      , KANNR
      , CMPRE_FLT
      , ABFOR
      , ABGES
      , J_1BCFOP
      , J_1BTAXLW1
      , J_1BTAXLW2
      , J_1BTXSDC
      , WKTNR
      , WKTPS
      , SKOPF
      , KZBWS
      , WGRU1
      , WGRU2
      , KNUMA_PI
      , KNUMA_AG
      , KZFME
      , LSTANR
      , TECHS
      , MWSBP
      , BERID
      , PCTRF
      , LOGSYS_EXT
      , J_1BTAXLW3
      , J_1BTAXLW4
      , J_1BTAXLW5
      , STOCKLOC
      , SLOCTYPE
      , MSR_RET_REASON
      , MSR_REFUND_CODE
      , MSR_APPROV_BLOCK
      , NRAB_KNUMH
      , TRMRISK_RELEVANT
      , SGT_RCAT
      , HANDOVERLOC
      , HANDOVERDATE
      , HANDOVERTIME
      , TC_AUT_DET
      , MANUAL_TC_REASON
      , FISCAL_INCENTIVE
      , TAX_SUBJECT_ST
      , FISCAL_INCENTIVE_ID
      , SPCSTO
      , _DATAAGING
      , REVACC_REFID
      , REVACC_REFTYPE
      , SRFUND
      , AUFPL_OLC
      , APLZL_OLC
      , FERC_IND
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , FSH_CRSD
      , FSH_SEAREF
      , FSH_CANDATE
      , FSH_PSM_PFM_SPLIT
      , FSH_VAS_REL
      , FSH_VAS_PRNT_ID
      , FSH_TRANSACTION
      , FSH_ITEM_GROUP
      , FSH_ITEM
      , FSH_VASREF
      , FSH_GRID_COND_REC
      , FSH_PQR_UEPOS
      , KOSTL
      , FONDS
      , FISTL
      , FKBER
      , GRANT_NBR
      , BUDGET_PD
      , IUID_RELEVANT
      , MILL_SE_GPOSN
      , PRS_OBJNR
      , PRS_SD_SPSNR
      , PRS_WORK_PERIOD
      , TAS
      , BETC
      , MOD_ALLOW
      , CANCEL_ALLOW
      , PAY_METHOD
      , BPN
      , REP_FREQ
      , FMFGUS_KEY
      , PARGB
      , AUFPL_OAA
      , APLZL_OAA
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
      , ARSNUM
      , ARSPOS
      , WTYSC_CLMITEM
      , ZZKNUMA
      , ZZKZWI7
      , ZZKZWI8
      , ZZKZWI9
      , ZZKZWI10
      , ZZKZWI11
      , ZZKZWI12
      , ZZKZWI13
      , ZZKZWI14
      , ZZKZWI15
      , ZZKZWI16
      , ZZKZWI17
      , ZZAUFNR
      , ZZAPRVGRP
      , ZZLOCUSED
      , ZZRECMAN
      , ZZLPSBSRC
      , ZZLPSFRID   
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PAYER_PARVW
      , PARVW
      , BILLTO_PARVW
      , SHIPTO_PARVW
      , INSURANCE_PARVW
      , PAYER_KUNNR
      , BILLTO_KUNNR
      , KUNNR
      , SHIPTO_KUNNR
      , SOLDTO_KUNNR
      , INSURANCE_KUNNR
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , HASHDIFF
    FROM SRC_VBAP
)



{% if is_incremental() %}
/* 
   CURRENT_STATE: latest stored HASHDIFF per key (single pass over target).
   Replaces the old full-history NOT EXISTS gate. Ordering by PSA_LOAD_DTS
   (physical arrival, monotonic) not LOAD_DTS (business time) so late-arriving
   corrections cannot mis-elect "current" state on out-of-order loads.
    */
, CURRENT_STATE as (
    SELECT ORDER_LINE_HK as ORDER_LINE_HK_C, HASHDIFF as HASHDIFF_C
    FROM {{ this }}
    qualify 1 = row_number() over (
        partition by ORDER_LINE_HK
        order by PSA_LOAD_DTS desc
    )
)
{% endif %}


---- FINAL LAYER ----
SELECT
          ORDER_LINE_HK
        , MANDT
        , VBELN
        , POSNR
        , GLREQUEST
        , MATNR
        , MATWA
        , PMATN
        , CHARG
        , MATKL
        , ARKTX
        , PSTYV
        , POSAR
        , LFREL
        , FKREL
        , UEPOS
        , GRPOS
        , ABGRU
        , PRODH
        , ZWERT
        , ZMENG
        , ZIEME
        , UMZIZ
        , UMZIN
        , MEINS
        , SMENG
        , ABLFZ
        , ABDAT
        , ABDAT_DT
        , ABSFZ
        , POSEX
        , KDMAT
        , KBVER
        , KEVER
        , VKGRU
        , VKAUS
        , GRKOR
        , FMENG
        , UEBTK
        , UEBTO
        , UNTTO
        , FAKSP
        , ATPKZ
        , RKFKF
        , SPART
        , GSBER
        , NETWR
        , WAERK
        , ANTLF
        , KZTLF
        , CHSPL
        , KWMENG
        , LSMENG
        , KBMENG
        , KLMENG
        , VRKME
        , UMVKZ
        , UMVKN
        , BRGEW
        , NTGEW
        , GEWEI
        , VOLUM
        , VOLEH
        , VBELV
        , POSNV
        , VGBEL
        , VGPOS
        , VOREF
        , UPFLU
        , ERLRE
        , LPRIO
        , WERKS
        , LGORT
        , VSTEL
        , ROUTE
        , STKEY
        , STDAT
        , STDAT_DT
        , STLNR
        , STPOS
        , AWAHR
        , ERDAT
        , ERNAM
        , ERZET
        , TAXM1
        , TAXM2
        , TAXM3
        , TAXM4
        , TAXM5
        , TAXM6
        , TAXM7
        , TAXM8
        , TAXM9
        , VBEAF
        , VBEAV
        , VGREF
        , NETPR
        , KPEIN
        , KMEIN
        , SHKZG
        , SKTOF
        , MTVFP
        , SUMBD
        , KONDM
        , KTGRM
        , BONUS
        , PROVG
        , EANNR
        , PRSOK
        , BWTAR
        , BWTEX
        , XCHPF
        , XCHAR
        , LFMNG
        , STAFO
        , WAVWR
        , KZWI1
        , KZWI2
        , KZWI3
        , KZWI4
        , KZWI5
        , KZWI6
        , STCUR
        , AEDAT
        , AEDAT_DT
        , EAN11
        , FIXMG
        , PRCTR
        , MVGR1
        , MVGR2
        , MVGR3
        , MVGR4
        , MVGR5
        , KMPMG
        , SUGRD
        , SOBKZ
        , VPZUO
        , PAOBJNR
        , PS_PSP_PNR
        , AUFNR
        , VPMAT
        , VPWRK
        , PRBME
        , UMREF
        , KNTTP
        , KZVBR
        , SERNR
        , OBJNR
        , ABGRS
        , BEDAE
        , CMPRE
        , CMTFG
        , CMPNT
        , CMKUA
        , CUOBJ
        , CUOBJ_CH
        , CEPOK
        , KOUPD
        , SERAIL
        , ANZSN
        , NACHL
        , MAGRV
        , MPROK
        , VGTYP
        , PROSA
        , UEPVW
        , KALNR
        , KLVAR
        , SPOSN
        , KOWRR
        , STADAT
        , STADAT_DT
        , EXART
        , PREFE
        , KNUMH
        , CLINT
        , CHMVS
        , STLTY
        , STLKN
        , STPOZ
        , STMAN
        , ZSCHL_K
        , KALSM_K
        , KALVAR
        , KOSCH
        , UPMAT
        , UKONM
        , MFRGR
        , PLAVO
        , KANNR
        , CMPRE_FLT
        , ABFOR
        , ABGES
        , J_1BCFOP
        , J_1BTAXLW1
        , J_1BTAXLW2
        , J_1BTXSDC
        , WKTNR
        , WKTPS
        , SKOPF
        , KZBWS
        , WGRU1
        , WGRU2
        , KNUMA_PI
        , KNUMA_AG
        , KZFME
        , LSTANR
        , TECHS
        , MWSBP
        , BERID
        , PCTRF
        , LOGSYS_EXT
        , J_1BTAXLW3
        , J_1BTAXLW4
        , J_1BTAXLW5
        , STOCKLOC
        , SLOCTYPE
        , MSR_RET_REASON
        , MSR_REFUND_CODE
        , MSR_APPROV_BLOCK
        , NRAB_KNUMH
        , TRMRISK_RELEVANT
        , SGT_RCAT
        , HANDOVERLOC
        , HANDOVERDATE
        , HANDOVERTIME
        , TC_AUT_DET
        , MANUAL_TC_REASON
        , FISCAL_INCENTIVE
        , TAX_SUBJECT_ST
        , FISCAL_INCENTIVE_ID
        , SPCSTO
        , _DATAAGING
        , REVACC_REFID
        , REVACC_REFTYPE
        , SRFUND
        , AUFPL_OLC
        , APLZL_OLC
        , FERC_IND
        , FSH_SEASON_YEAR
        , FSH_SEASON
        , FSH_COLLECTION
        , FSH_THEME
        , FSH_CRSD
        , FSH_SEAREF
        , FSH_CANDATE
        , FSH_PSM_PFM_SPLIT
        , FSH_VAS_REL
        , FSH_VAS_PRNT_ID
        , FSH_TRANSACTION
        , FSH_ITEM_GROUP
        , FSH_ITEM
        , FSH_VASREF
        , FSH_GRID_COND_REC
        , FSH_PQR_UEPOS
        , KOSTL
        , FONDS
        , FISTL
        , FKBER
        , GRANT_NBR
        , BUDGET_PD
        , IUID_RELEVANT
        , MILL_SE_GPOSN
        , PRS_OBJNR
        , PRS_SD_SPSNR
        , PRS_WORK_PERIOD
        , TAS
        , BETC
        , MOD_ALLOW
        , CANCEL_ALLOW
        , PAY_METHOD
        , BPN
        , REP_FREQ
        , FMFGUS_KEY
        , PARGB
        , AUFPL_OAA
        , APLZL_OAA
        , WRF_CHARSTC1
        , WRF_CHARSTC2
        , WRF_CHARSTC3
        , ARSNUM
        , ARSPOS
        , WTYSC_CLMITEM
        , ZZKNUMA
        , ZZKZWI7
        , ZZKZWI8
        , ZZKZWI9
        , ZZKZWI10
        , ZZKZWI11
        , ZZKZWI12
        , ZZKZWI13
        , ZZKZWI14
        , ZZKZWI15
        , ZZKZWI16
        , ZZKZWI17
        , ZZAUFNR
        , ZZAPRVGRP
        , ZZLOCUSED
        , ZZRECMAN
        , ZZLPSBSRC
        , ZZLPSFRID  
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PAYER_PARVW
        , PARVW
        , BILLTO_PARVW
        , SHIPTO_PARVW
        , INSURANCE_PARVW
        , PAYER_KUNNR
        , BILLTO_KUNNR
        , KUNNR
        , SHIPTO_KUNNR
        , SOLDTO_KUNNR
        , INSURANCE_KUNNR
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , HASHDIFF
FROM LOGIC_VBAP src
{% if is_incremental() %}
/* Insert when the incoming payload differs from the key's CURRENT state,
   not from any historical state. This lands same-state reversions
   (abc -> xyz -> abc: day-3 differs from day-2 current) while still
   suppressing touched-records where state is unchanged.
   EQUAL_NULL is null-safe so a NULL/empty HASHDIFF (e.g. ghost rows) does
   not collapse the comparison to NULL and wrongly drop a real change.      */
LEFT JOIN CURRENT_STATE cur
    ON cur.ORDER_LINE_HK_C = src.ORDER_LINE_HK
WHERE cur.ORDER_LINE_HK_C IS NULL                      -- brand-new key
   OR NOT EQUAL_NULL(cur.HASHDIFF_C, src.HASHDIFF)          -- state changed vs current
{% else %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by ORDER_LINE_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ORDER_LINE_HK,
NULL AS MANDT,
GR.VALUE::text AS VBELN,
GR.VALUE::text AS POSNR,
NULL AS GLREQUEST,
NULL AS MATNR,
NULL AS MATWA,
NULL AS PMATN,
NULL AS CHARG,
NULL AS MATKL,
NULL AS ARKTX,
NULL AS PSTYV,
NULL AS POSAR,
NULL AS LFREL,
NULL AS FKREL,
NULL AS UEPOS,
NULL AS GRPOS,
NULL AS ABGRU,
NULL AS PRODH,
NULL AS ZWERT,
NULL AS ZMENG,
NULL AS ZIEME,
NULL AS UMZIZ,
NULL AS UMZIN,
NULL AS MEINS,
NULL AS SMENG,
NULL AS ABLFZ,
NULL AS ABDAT,
NULL AS ABDAT_DT,
NULL AS ABSFZ,
NULL AS POSEX,
NULL AS KDMAT,
NULL AS KBVER,
NULL AS KEVER,
NULL AS VKGRU,
NULL AS VKAUS,
NULL AS GRKOR,
NULL AS FMENG,
NULL AS UEBTK,
NULL AS UEBTO,
NULL AS UNTTO,
NULL AS FAKSP,
NULL AS ATPKZ,
NULL AS RKFKF,
NULL AS SPART,
NULL AS GSBER,
NULL AS NETWR,
NULL AS WAERK,
NULL AS ANTLF,
NULL AS KZTLF,
NULL AS CHSPL,
NULL AS KWMENG,
NULL AS LSMENG,
NULL AS KBMENG,
NULL AS KLMENG,
NULL AS VRKME,
NULL AS UMVKZ,
NULL AS UMVKN,
NULL AS BRGEW,
NULL AS NTGEW,
NULL AS GEWEI,
NULL AS VOLUM,
NULL AS VOLEH,
NULL AS VBELV,
NULL AS POSNV,
NULL AS VGBEL,
NULL AS VGPOS,
NULL AS VOREF,
NULL AS UPFLU,
NULL AS ERLRE,
NULL AS LPRIO,
NULL AS WERKS,
NULL AS LGORT,
NULL AS VSTEL,
NULL AS ROUTE,
NULL AS STKEY,
NULL AS STDAT,
NULL AS STDAT_DT,
NULL AS STLNR,
NULL AS STPOS,
NULL AS AWAHR,
NULL AS ERDAT,
NULL AS ERNAM,
NULL AS ERZET,
NULL AS TAXM1,
NULL AS TAXM2,
NULL AS TAXM3,
NULL AS TAXM4,
NULL AS TAXM5,
NULL AS TAXM6,
NULL AS TAXM7,
NULL AS TAXM8,
NULL AS TAXM9,
NULL AS VBEAF,
NULL AS VBEAV,
NULL AS VGREF,
NULL AS NETPR,
NULL AS KPEIN,
NULL AS KMEIN,
NULL AS SHKZG,
NULL AS SKTOF,
NULL AS MTVFP,
NULL AS SUMBD,
NULL AS KONDM,
NULL AS KTGRM,
NULL AS BONUS,
NULL AS PROVG,
NULL AS EANNR,
NULL AS PRSOK,
NULL AS BWTAR,
NULL AS BWTEX,
NULL AS XCHPF,
NULL AS XCHAR,
NULL AS LFMNG,
NULL AS STAFO,
NULL AS WAVWR,
NULL AS KZWI1,
NULL AS KZWI2,
NULL AS KZWI3,
NULL AS KZWI4,
NULL AS KZWI5,
NULL AS KZWI6,
NULL AS STCUR,
NULL AS AEDAT,
NULL AS AEDAT_DT,
NULL AS EAN11,
NULL AS FIXMG,
NULL AS PRCTR,
NULL AS MVGR1,
NULL AS MVGR2,
NULL AS MVGR3,
NULL AS MVGR4,
NULL AS MVGR5,
NULL AS KMPMG,
NULL AS SUGRD,
NULL AS SOBKZ,
NULL AS VPZUO,
NULL AS PAOBJNR,
NULL AS PS_PSP_PNR,
NULL AS AUFNR,
NULL AS VPMAT,
NULL AS VPWRK,
NULL AS PRBME,
NULL AS UMREF,
NULL AS KNTTP,
NULL AS KZVBR,
NULL AS SERNR,
NULL AS OBJNR,
NULL AS ABGRS,
NULL AS BEDAE,
NULL AS CMPRE,
NULL AS CMTFG,
NULL AS CMPNT,
NULL AS CMKUA,
NULL AS CUOBJ,
NULL AS CUOBJ_CH,
NULL AS CEPOK,
NULL AS KOUPD,
NULL AS SERAIL,
NULL AS ANZSN,
NULL AS NACHL,
NULL AS MAGRV,
NULL AS MPROK,
NULL AS VGTYP,
NULL AS PROSA,
NULL AS UEPVW,
NULL AS KALNR,
NULL AS KLVAR,
NULL AS SPOSN,
NULL AS KOWRR,
NULL AS STADAT,
NULL AS STADAT_DT,
NULL AS EXART,
NULL AS PREFE,
NULL AS KNUMH,
NULL AS CLINT,
NULL AS CHMVS,
NULL AS STLTY,
NULL AS STLKN,
NULL AS STPOZ,
NULL AS STMAN,
NULL AS ZSCHL_K,
NULL AS KALSM_K,
NULL AS KALVAR,
NULL AS KOSCH,
NULL AS UPMAT,
NULL AS UKONM,
NULL AS MFRGR,
NULL AS PLAVO,
NULL AS KANNR,
NULL AS CMPRE_FLT,
NULL AS ABFOR,
NULL AS ABGES,
NULL AS J_1BCFOP,
NULL AS J_1BTAXLW1,
NULL AS J_1BTAXLW2,
NULL AS J_1BTXSDC,
NULL AS WKTNR,
NULL AS WKTPS,
NULL AS SKOPF,
NULL AS KZBWS,
NULL AS WGRU1,
NULL AS WGRU2,
NULL AS KNUMA_PI,
NULL AS KNUMA_AG,
NULL AS KZFME,
NULL AS LSTANR,
NULL AS TECHS,
NULL AS MWSBP,
NULL AS BERID,
NULL AS PCTRF,
NULL AS LOGSYS_EXT,
NULL AS J_1BTAXLW3,
NULL AS J_1BTAXLW4,
NULL AS J_1BTAXLW5,
NULL AS STOCKLOC,
NULL AS SLOCTYPE,
NULL AS MSR_RET_REASON,
NULL AS MSR_REFUND_CODE,
NULL AS MSR_APPROV_BLOCK,
NULL AS NRAB_KNUMH,
NULL AS TRMRISK_RELEVANT,
NULL AS SGT_RCAT,
NULL AS HANDOVERLOC,
NULL AS HANDOVERDATE,
NULL AS HANDOVERTIME,
NULL AS TC_AUT_DET,
NULL AS MANUAL_TC_REASON,
NULL AS FISCAL_INCENTIVE,
NULL AS TAX_SUBJECT_ST,
NULL AS FISCAL_INCENTIVE_ID,
NULL AS SPCSTO,
NULL AS _DATAAGING,
NULL AS REVACC_REFID,
NULL AS REVACC_REFTYPE,
NULL AS SRFUND,
NULL AS AUFPL_OLC,
NULL AS APLZL_OLC,
NULL AS FERC_IND,
NULL AS FSH_SEASON_YEAR,
NULL AS FSH_SEASON,
NULL AS FSH_COLLECTION,
NULL AS FSH_THEME,
NULL AS FSH_CRSD,
NULL AS FSH_SEAREF,
NULL AS FSH_CANDATE,
NULL AS FSH_PSM_PFM_SPLIT,
NULL AS FSH_VAS_REL,
NULL AS FSH_VAS_PRNT_ID,
NULL AS FSH_TRANSACTION,
NULL AS FSH_ITEM_GROUP,
NULL AS FSH_ITEM,
NULL AS FSH_VASREF,
NULL AS FSH_GRID_COND_REC,
NULL AS FSH_PQR_UEPOS,
NULL AS KOSTL,
NULL AS FONDS,
NULL AS FISTL,
NULL AS FKBER,
NULL AS GRANT_NBR,
NULL AS BUDGET_PD,
NULL AS IUID_RELEVANT,
NULL AS MILL_SE_GPOSN,
NULL AS PRS_OBJNR,
NULL AS PRS_SD_SPSNR,
NULL AS PRS_WORK_PERIOD,
NULL AS TAS,
NULL AS BETC,
NULL AS MOD_ALLOW,
NULL AS CANCEL_ALLOW,
NULL AS PAY_METHOD,
NULL AS BPN,
NULL AS REP_FREQ,
NULL AS FMFGUS_KEY,
NULL AS PARGB,
NULL AS AUFPL_OAA,
NULL AS APLZL_OAA,
NULL AS WRF_CHARSTC1,
NULL AS WRF_CHARSTC2,
NULL AS WRF_CHARSTC3,
NULL AS ARSNUM,
NULL AS ARSPOS,
NULL AS WTYSC_CLMITEM,
NULL AS ZZKNUMA,
NULL AS ZZKZWI7,
NULL AS ZZKZWI8,
NULL AS ZZKZWI9,
NULL AS ZZKZWI10,
NULL AS ZZKZWI11,
NULL AS ZZKZWI12,
NULL AS ZZKZWI13,
NULL AS ZZKZWI14,
NULL AS ZZKZWI15,
NULL AS ZZKZWI16,
NULL AS ZZKZWI17,
NULL AS ZZAUFNR,
NULL AS ZZAPRVGRP,
NULL AS ZZLOCUSED,
NULL AS ZZRECMAN,
NULL AS ZZLPSBSRC,
NULL AS ZZLPSFRID,  
NULL AS GLDELFLAG,
NULL AS GLCHANGETIME,
NULL AS GLSOURCESYSTEM,
NULL AS PAYER_PARVW,
NULL AS PARVW,
NULL AS BILLTO_PARVW,
NULL AS SHIPTO_PARVW,
NULL AS INSURANCE_PARVW,
NULL AS PAYER_KUNNR,
NULL AS BILLTO_KUNNR,
NULL AS KUNNR,
NULL AS SHIPTO_KUNNR,
NULL AS SOLDTO_KUNNR,
NULL AS INSURANCE_KUNNR,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
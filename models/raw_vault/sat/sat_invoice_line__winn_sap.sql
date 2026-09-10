---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_sales_invoice_line__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                          WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                          {% endif %} )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_sales_invoice_line__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        SALES_INVOICE_LINE_HK AS INVOICE_LINE_HK
      , POSNR
      , VBELN
      , GLREQUEST
      , UEPOS
      , FKIMG
      , VRKME
      , UMVKZ
      , UMVKN
      , MEINS
      , SMENG
      , FKLMG
      , LMENG
      , NTGEW
      , BRGEW
      , GEWEI
      , VOLUM
      , VOLEH
      , GSBER
      , PRSDT
      , FBUDA
      , KURSK
      , NETWR
      , VBELV
      , POSNV
      , VGBEL
      , VGPOS
      , VGTYP
      , AUBEL
      , AUPOS
      , AUREF
      , MATNR
      , ARKTX
      , PMATN
      , CHARG
      , MATKL
      , PSTYV
      , POSAR
      , PRODH
      , VSTEL
      , ATPKZ
      , SPART
      , POSPA
      , WERKS
      , ALAND
      , WKREG
      , WKCOU
      , WKCTY
      , TAXM1
      , TAXM2
      , TAXM3
      , TAXM4
      , TAXM5
      , TAXM6
      , TAXM7
      , TAXM8
      , TAXM9
      , KOWRR
      , PRSFD
      , SKTOF
      , SKFBP
      , KONDM
      , KTGRM
      , KOSTL
      , BONUS
      , PROVG
      , EANNR
      , VKGRP
      , VKBUR
      , SPARA
      , SHKZG
      , ERNAM
      , ERDAT
      , ERZET
      , BWTAR
      , LGORT
      , STAFO
      , WAVWR
      , KZWI1
      , KZWI2
      , KZWI3
      , KZWI4
      , KZWI5
      , KZWI6
      , STCUR
      , UVPRS
      , UVALL
      , EAN11
      , PRCTR
      , KVGR1
      , KVGR2
      , KVGR3
      , KVGR4
      , KVGR5
      , MVGR1
      , MVGR2
      , MVGR3
      , MVGR4
      , MVGR5
      , MATWA
      , BONBA
      , KOKRS
      , PAOBJNR
      , PS_PSP_PNR
      , AUFNR
      , TXJCD
      , CMPRE
      , CMPNT
      , CUOBJ
      , CUOBJ_CH
      , KOUPD
      , UECHA
      , XCHAR
      , ABRVW
      , SERNR
      , BZIRK_AUFT
      , KDGRP_AUFT
      , KONDA_AUFT
      , LLAND_AUFT
      , MPROK
      , PLTYP_AUFT
      , REGIO_AUFT
      , VKORG_AUFT
      , VTWEG_AUFT
      , ABRBG
      , PROSA
      , UEPVW
      , AUTYP
      , STADAT
      , FPLNR
      , FPLTR
      , AKTNR
      , KNUMA_PI
      , KNUMA_AG
      , PREFE
      , MWSBP
      , AUGRU_AUFT
      , FAREG
      , UPMAT
      , UKONM
      , CMPRE_FLT
      , ABFOR
      , ABGES
      , J_1ARFZ
      , J_1AREGIO
      , J_1AGICD
      , J_1ADTYP
      , J_1ATXREL
      , J_1BCFOP
      , J_1BTAXLW1
      , J_1BTAXLW2
      , J_1BTXSDC
      , BRTWR
      , WKTNR
      , WKTPS
      , RPLNR
      , KURSK_DAT
      , WGRU1
      , WGRU2
      , KDKG1
      , KDKG2
      , KDKG3
      , KDKG4
      , KDKG5
      , VKAUS
      , J_1AINDXP
      , J_1AIDATEP
      , KZFME
      , MWSKZ
      , VERTT
      , VERTN
      , SGTXT
      , DELCO
      , BEMOT
      , RRREL
      , AKKUR
      , WMINR
      , VGBEL_EX
      , VGPOS_EX
      , LOGSYS
      , VGTYP_EX
      , J_1BTAXLW3
      , J_1BTAXLW4
      , J_1BTAXLW5
      , MSR_ID
      , MSR_REFUND_CODE
      , MSR_RET_REASON
      , NRAB_KNUMH
      , NRAB_VALUE
      , DISPUTE_CASE
      , FUND_USAGE_ITEM
      , FARR_RELTYPE
      , CLAIMS_TAXATION
      , KURRF_DAT_ORIG
      , VGTYP_EXT
      , SGT_RCAT
      , SGT_SCAT
      , AUFPL
      , APLZL
      , DPCNR
      , DCPNR
      , DPNRB
      , PEROP_BEG
      , PEROP_END
      , FMFGUS_KEY
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , FONDS
      , FISTL
      , FKBER
      , GRANT_NBR
      , BUDGET_PD
      , PRS_WORK_PERIOD
      , PPRCTR
      , PARGB
      , AUFPL_OAA
      , APLZL_OAA
      , CAMPAIGN
      , COMPREAS
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
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
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , GLCHANGETIME_DTTM
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_SWINN
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        INVOICE_LINE_HK
      , POSNR
      , VBELN
      , GLREQUEST
      , UEPOS
      , FKIMG
      , VRKME
      , UMVKZ
      , UMVKN
      , MEINS
      , SMENG
      , FKLMG
      , LMENG
      , NTGEW
      , BRGEW
      , GEWEI
      , VOLUM
      , VOLEH
      , GSBER
      , PRSDT
      , FBUDA
      , KURSK
      , NETWR
      , VBELV
      , POSNV
      , VGBEL
      , VGPOS
      , VGTYP
      , AUBEL
      , AUPOS
      , AUREF
      , MATNR
      , ARKTX
      , PMATN
      , CHARG
      , MATKL
      , PSTYV
      , POSAR
      , PRODH
      , VSTEL
      , ATPKZ
      , SPART
      , POSPA
      , WERKS
      , ALAND
      , WKREG
      , WKCOU
      , WKCTY
      , TAXM1
      , TAXM2
      , TAXM3
      , TAXM4
      , TAXM5
      , TAXM6
      , TAXM7
      , TAXM8
      , TAXM9
      , KOWRR
      , PRSFD
      , SKTOF
      , SKFBP
      , KONDM
      , KTGRM
      , KOSTL
      , BONUS
      , PROVG
      , EANNR
      , VKGRP
      , VKBUR
      , SPARA
      , SHKZG
      , ERNAM
      , ERDAT
      , ERZET
      , BWTAR
      , LGORT
      , STAFO
      , WAVWR
      , KZWI1
      , KZWI2
      , KZWI3
      , KZWI4
      , KZWI5
      , KZWI6
      , STCUR
      , UVPRS
      , UVALL
      , EAN11
      , PRCTR
      , KVGR1
      , KVGR2
      , KVGR3
      , KVGR4
      , KVGR5
      , MVGR1
      , MVGR2
      , MVGR3
      , MVGR4
      , MVGR5
      , MATWA
      , BONBA
      , KOKRS
      , PAOBJNR
      , PS_PSP_PNR
      , AUFNR
      , TXJCD
      , CMPRE
      , CMPNT
      , CUOBJ
      , CUOBJ_CH
      , KOUPD
      , UECHA
      , XCHAR
      , ABRVW
      , SERNR
      , BZIRK_AUFT
      , KDGRP_AUFT
      , KONDA_AUFT
      , LLAND_AUFT
      , MPROK
      , PLTYP_AUFT
      , REGIO_AUFT
      , VKORG_AUFT
      , VTWEG_AUFT
      , ABRBG
      , PROSA
      , UEPVW
      , AUTYP
      , STADAT
      , FPLNR
      , FPLTR
      , AKTNR
      , KNUMA_PI
      , KNUMA_AG
      , PREFE
      , MWSBP
      , AUGRU_AUFT
      , FAREG
      , UPMAT
      , UKONM
      , CMPRE_FLT
      , ABFOR
      , ABGES
      , J_1ARFZ
      , J_1AREGIO
      , J_1AGICD
      , J_1ADTYP
      , J_1ATXREL
      , J_1BCFOP
      , J_1BTAXLW1
      , J_1BTAXLW2
      , J_1BTXSDC
      , BRTWR
      , WKTNR
      , WKTPS
      , RPLNR
      , KURSK_DAT
      , WGRU1
      , WGRU2
      , KDKG1
      , KDKG2
      , KDKG3
      , KDKG4
      , KDKG5
      , VKAUS
      , J_1AINDXP
      , J_1AIDATEP
      , KZFME
      , MWSKZ
      , VERTT
      , VERTN
      , SGTXT
      , DELCO
      , BEMOT
      , RRREL
      , AKKUR
      , WMINR
      , VGBEL_EX
      , VGPOS_EX
      , LOGSYS
      , VGTYP_EX
      , J_1BTAXLW3
      , J_1BTAXLW4
      , J_1BTAXLW5
      , MSR_ID
      , MSR_REFUND_CODE
      , MSR_RET_REASON
      , NRAB_KNUMH
      , NRAB_VALUE
      , DISPUTE_CASE
      , FUND_USAGE_ITEM
      , FARR_RELTYPE
      , CLAIMS_TAXATION
      , KURRF_DAT_ORIG
      , VGTYP_EXT
      , SGT_RCAT
      , SGT_SCAT
      , AUFPL
      , APLZL
      , DPCNR
      , DCPNR
      , DPNRB
      , PEROP_BEG
      , PEROP_END
      , FMFGUS_KEY
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , FONDS
      , FISTL
      , FKBER
      , GRANT_NBR
      , BUDGET_PD
      , PRS_WORK_PERIOD
      , PPRCTR
      , PARGB
      , AUFPL_OAA
      , APLZL_OAA
      , CAMPAIGN
      , COMPREAS
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
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
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , GLCHANGETIME_DTTM
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_SWINN
)
---- FILTER LAYER ----

, FILTER_SWINN as (
    SELECT *
    FROM RENAME_SWINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SWINN
)

---- FINAL LAYER ----
SELECT
        INVOICE_LINE_HK
      , POSNR
      , VBELN
      , GLREQUEST
      , UEPOS
      , FKIMG
      , VRKME
      , UMVKZ
      , UMVKN
      , MEINS
      , SMENG
      , FKLMG
      , LMENG
      , NTGEW
      , BRGEW
      , GEWEI
      , VOLUM
      , VOLEH
      , GSBER
      , PRSDT
      , FBUDA
      , KURSK
      , NETWR
      , VBELV
      , POSNV
      , VGBEL
      , VGPOS
      , VGTYP
      , AUBEL
      , AUPOS
      , AUREF
      , MATNR
      , ARKTX
      , PMATN
      , CHARG
      , MATKL
      , PSTYV
      , POSAR
      , PRODH
      , VSTEL
      , ATPKZ
      , SPART
      , POSPA
      , WERKS
      , ALAND
      , WKREG
      , WKCOU
      , WKCTY
      , TAXM1
      , TAXM2
      , TAXM3
      , TAXM4
      , TAXM5
      , TAXM6
      , TAXM7
      , TAXM8
      , TAXM9
      , KOWRR
      , PRSFD
      , SKTOF
      , SKFBP
      , KONDM
      , KTGRM
      , KOSTL
      , BONUS
      , PROVG
      , EANNR
      , VKGRP
      , VKBUR
      , SPARA
      , SHKZG
      , ERNAM
      , ERDAT
      , ERZET
      , BWTAR
      , LGORT
      , STAFO
      , WAVWR
      , KZWI1
      , KZWI2
      , KZWI3
      , KZWI4
      , KZWI5
      , KZWI6
      , STCUR
      , UVPRS
      , UVALL
      , EAN11
      , PRCTR
      , KVGR1
      , KVGR2
      , KVGR3
      , KVGR4
      , KVGR5
      , MVGR1
      , MVGR2
      , MVGR3
      , MVGR4
      , MVGR5
      , MATWA
      , BONBA
      , KOKRS
      , PAOBJNR
      , PS_PSP_PNR
      , AUFNR
      , TXJCD
      , CMPRE
      , CMPNT
      , CUOBJ
      , CUOBJ_CH
      , KOUPD
      , UECHA
      , XCHAR
      , ABRVW
      , SERNR
      , BZIRK_AUFT
      , KDGRP_AUFT
      , KONDA_AUFT
      , LLAND_AUFT
      , MPROK
      , PLTYP_AUFT
      , REGIO_AUFT
      , VKORG_AUFT
      , VTWEG_AUFT
      , ABRBG
      , PROSA
      , UEPVW
      , AUTYP
      , STADAT
      , FPLNR
      , FPLTR
      , AKTNR
      , KNUMA_PI
      , KNUMA_AG
      , PREFE
      , MWSBP
      , AUGRU_AUFT
      , FAREG
      , UPMAT
      , UKONM
      , CMPRE_FLT
      , ABFOR
      , ABGES
      , J_1ARFZ
      , J_1AREGIO
      , J_1AGICD
      , J_1ADTYP
      , J_1ATXREL
      , J_1BCFOP
      , J_1BTAXLW1
      , J_1BTAXLW2
      , J_1BTXSDC
      , BRTWR
      , WKTNR
      , WKTPS
      , RPLNR
      , KURSK_DAT
      , WGRU1
      , WGRU2
      , KDKG1
      , KDKG2
      , KDKG3
      , KDKG4
      , KDKG5
      , VKAUS
      , J_1AINDXP
      , J_1AIDATEP
      , KZFME
      , MWSKZ
      , VERTT
      , VERTN
      , SGTXT
      , DELCO
      , BEMOT
      , RRREL
      , AKKUR
      , WMINR
      , VGBEL_EX
      , VGPOS_EX
      , LOGSYS
      , VGTYP_EX
      , J_1BTAXLW3
      , J_1BTAXLW4
      , J_1BTAXLW5
      , MSR_ID
      , MSR_REFUND_CODE
      , MSR_RET_REASON
      , NRAB_KNUMH
      , NRAB_VALUE
      , DISPUTE_CASE
      , FUND_USAGE_ITEM
      , FARR_RELTYPE
      , CLAIMS_TAXATION
      , KURRF_DAT_ORIG
      , VGTYP_EXT
      , SGT_RCAT
      , SGT_SCAT
      , AUFPL
      , APLZL
      , DPCNR
      , DCPNR
      , DPNRB
      , PEROP_BEG
      , PEROP_END
      , FMFGUS_KEY
      , FSH_SEASON_YEAR
      , FSH_SEASON
      , FSH_COLLECTION
      , FSH_THEME
      , FONDS
      , FISTL
      , FKBER
      , GRANT_NBR
      , BUDGET_PD
      , PRS_WORK_PERIOD
      , PPRCTR
      , PARGB
      , AUFPL_OAA
      , APLZL_OAA
      , CAMPAIGN
      , COMPREAS
      , WRF_CHARSTC1
      , WRF_CHARSTC2
      , WRF_CHARSTC3
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
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , GLCHANGETIME_DTTM
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.INVOICE_LINE_HK = JOIN_RESULT.INVOICE_LINE_HK
      AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1= row_number()over(partition by INVOICE_LINE_HK, HASHDIFF order by LOAD_DTS)

UNION ALL
SELECT 
  MD5_BINARY(GR.VALUE) AS INVOICE_LINE_HK
, NULL AS POSNR
, NULL AS VBELN
, NULL AS GLREQUEST
, NULL AS UEPOS
, NULL AS FKIMG
, NULL AS VRKME
, NULL AS UMVKZ
, NULL AS UMVKN
, NULL AS MEINS
, NULL AS SMENG
, NULL AS FKLMG
, NULL AS LMENG
, NULL AS NTGEW
, NULL AS BRGEW
, NULL AS GEWEI
, NULL AS VOLUM
, NULL AS VOLEH
, NULL AS GSBER
, NULL AS PRSDT
, NULL AS FBUDA
, NULL AS KURSK
, NULL AS NETWR
, NULL AS VBELV
, NULL AS POSNV
, NULL AS VGBEL
, NULL AS VGPOS
, NULL AS VGTYP
, NULL AS AUBEL
, NULL AS AUPOS
, NULL AS AUREF
, NULL AS MATNR
, NULL AS ARKTX
, NULL AS PMATN
, NULL AS CHARG
, NULL AS MATKL
, NULL AS PSTYV
, NULL AS POSAR
, NULL AS PRODH
, NULL AS VSTEL
, NULL AS ATPKZ
, NULL AS SPART
, NULL AS POSPA
, NULL AS WERKS
, NULL AS ALAND
, NULL AS WKREG
, NULL AS WKCOU
, NULL AS WKCTY
, NULL AS TAXM1
, NULL AS TAXM2
, NULL AS TAXM3
, NULL AS TAXM4
, NULL AS TAXM5
, NULL AS TAXM6
, NULL AS TAXM7
, NULL AS TAXM8
, NULL AS TAXM9
, NULL AS KOWRR
, NULL AS PRSFD
, NULL AS SKTOF
, NULL AS SKFBP
, NULL AS KONDM
, NULL AS KTGRM
, NULL AS KOSTL
, NULL AS BONUS
, NULL AS PROVG
, NULL AS EANNR
, NULL AS VKGRP
, NULL AS VKBUR
, NULL AS SPARA
, NULL AS SHKZG
, NULL AS ERNAM
, NULL AS ERDAT
, NULL AS ERZET
, NULL AS BWTAR
, NULL AS LGORT
, NULL AS STAFO
, NULL AS WAVWR
, NULL AS KZWI1
, NULL AS KZWI2
, NULL AS KZWI3
, NULL AS KZWI4
, NULL AS KZWI5
, NULL AS KZWI6
, NULL AS STCUR
, NULL AS UVPRS
, NULL AS UVALL
, NULL AS EAN11
, NULL AS PRCTR
, NULL AS KVGR1
, NULL AS KVGR2
, NULL AS KVGR3
, NULL AS KVGR4
, NULL AS KVGR5
, NULL AS MVGR1
, NULL AS MVGR2
, NULL AS MVGR3
, NULL AS MVGR4
, NULL AS MVGR5
, NULL AS MATWA
, NULL AS BONBA
, NULL AS KOKRS
, NULL AS PAOBJNR
, NULL AS PS_PSP_PNR
, NULL AS AUFNR
, NULL AS TXJCD
, NULL AS CMPRE
, NULL AS CMPNT
, NULL AS CUOBJ
, NULL AS CUOBJ_CH
, NULL AS KOUPD
, NULL AS UECHA
, NULL AS XCHAR
, NULL AS ABRVW
, NULL AS SERNR
, NULL AS BZIRK_AUFT
, NULL AS KDGRP_AUFT
, NULL AS KONDA_AUFT
, NULL AS LLAND_AUFT
, NULL AS MPROK
, NULL AS PLTYP_AUFT
, NULL AS REGIO_AUFT
, NULL AS VKORG_AUFT
, NULL AS VTWEG_AUFT
, NULL AS ABRBG
, NULL AS PROSA
, NULL AS UEPVW
, NULL AS AUTYP
, NULL AS STADAT
, NULL AS FPLNR
, NULL AS FPLTR
, NULL AS AKTNR
, NULL AS KNUMA_PI
, NULL AS KNUMA_AG
, NULL AS PREFE
, NULL AS MWSBP
, NULL AS AUGRU_AUFT
, NULL AS FAREG
, NULL AS UPMAT
, NULL AS UKONM
, NULL AS CMPRE_FLT
, NULL AS ABFOR
, NULL AS ABGES
, NULL AS J_1ARFZ
, NULL AS J_1AREGIO
, NULL AS J_1AGICD
, NULL AS J_1ADTYP
, NULL AS J_1ATXREL
, NULL AS J_1BCFOP
, NULL AS J_1BTAXLW1
, NULL AS J_1BTAXLW2
, NULL AS J_1BTXSDC
, NULL AS BRTWR
, NULL AS WKTNR
, NULL AS WKTPS
, NULL AS RPLNR
, NULL AS KURSK_DAT
, NULL AS WGRU1
, NULL AS WGRU2
, NULL AS KDKG1
, NULL AS KDKG2
, NULL AS KDKG3
, NULL AS KDKG4
, NULL AS KDKG5
, NULL AS VKAUS
, NULL AS J_1AINDXP
, NULL AS J_1AIDATEP
, NULL AS KZFME
, NULL AS MWSKZ
, NULL AS VERTT
, NULL AS VERTN
, NULL AS SGTXT
, NULL AS DELCO
, NULL AS BEMOT
, NULL AS RRREL
, NULL AS AKKUR
, NULL AS WMINR
, NULL AS VGBEL_EX
, NULL AS VGPOS_EX
, NULL AS LOGSYS
, NULL AS VGTYP_EX
, NULL AS J_1BTAXLW3
, NULL AS J_1BTAXLW4
, NULL AS J_1BTAXLW5
, NULL AS MSR_ID
, NULL AS MSR_REFUND_CODE
, NULL AS MSR_RET_REASON
, NULL AS NRAB_KNUMH
, NULL AS NRAB_VALUE
, NULL AS DISPUTE_CASE
, NULL AS FUND_USAGE_ITEM
, NULL AS FARR_RELTYPE
, NULL AS CLAIMS_TAXATION
, NULL AS KURRF_DAT_ORIG
, NULL AS VGTYP_EXT
, NULL AS SGT_RCAT
, NULL AS SGT_SCAT
, NULL AS AUFPL
, NULL AS APLZL
, NULL AS DPCNR
, NULL AS DCPNR
, NULL AS DPNRB
, NULL AS PEROP_BEG
, NULL AS PEROP_END
, NULL AS FMFGUS_KEY
, NULL AS FSH_SEASON_YEAR
, NULL AS FSH_SEASON
, NULL AS FSH_COLLECTION
, NULL AS FSH_THEME
, NULL AS FONDS
, NULL AS FISTL
, NULL AS FKBER
, NULL AS GRANT_NBR
, NULL AS BUDGET_PD
, NULL AS PRS_WORK_PERIOD
, NULL AS PPRCTR
, NULL AS PARGB
, NULL AS AUFPL_OAA
, NULL AS APLZL_OAA
, NULL AS CAMPAIGN
, NULL AS COMPREAS
, NULL AS WRF_CHARSTC1
, NULL AS WRF_CHARSTC2
, NULL AS WRF_CHARSTC3
, NULL AS ZZKZWI7
, NULL AS ZZKZWI8
, NULL AS ZZKZWI9
, NULL AS ZZKZWI10
, NULL AS ZZKZWI11
, NULL AS ZZKZWI12
, NULL AS ZZKZWI13
, NULL AS ZZKZWI14
, NULL AS ZZKZWI15
, NULL AS ZZKZWI16
, NULL AS ZZKZWI17
, NULL AS GLDELFLAG
, NULL AS GLCHANGETIME
, NULL AS GLSOURCESYSTEM
, NULL AS GLCHANGETIME_DTTM
, NULL AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
, MD5_BINARY('GHOST') AS HASHDIFF
FROM
  TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_vbrp') }} as SRC  ),
SRC_VBRK           as ( SELECT
                          VBELN
                        , KUNAG
                        , PSA_LOAD_DTS
                      FROM {{ source('sap_ecc_prd', 'z_vbrk') }} as SRC
                      QUALIFY ROW_NUMBER() OVER (PARTITION BY VBELN ORDER BY PSA_LOAD_DTS DESC) = 1 ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM sap_ecc_prd.z_vbrp )
, SRC_VBRK           as ( SELECT * FROM sap_ecc_prd.z_vbrk )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        to_char(coalesce(nullif(trim(VBELN), ''), '-1'))                 as                             SALES_INVOICE_BK
      , CONCAT_WS('||', coalesce(POSNR,'-1'), coalesce(VBELN,'-1'))as                              SALES_INVOICE_LINE_BK
      , to_char(coalesce(nullif(trim(MATNR), ''), '-1'))                as                                       ITEM_BK
      , to_char(coalesce(nullif(trim(SPART), ''), '-1'))                as                                   DIVISION_BK
      , to_char(coalesce(nullif(trim(WERKS), ''), '-1'))                as                                      PLANT_BK
      , to_char(coalesce(nullif(trim(VKORG_AUFT), ''), '-1'))           as                         SALES_ORGANIZATION_BK
      , to_char(coalesce(nullif(trim(VTWEG_AUFT), ''), '-1'))           as                       DISTRIBUTION_CHANNEL_BK
      , POSNR
      , VBELN
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
      ))   as                                    LOAD_DTS
      , MANDT
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
      , CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
        ))                                                           as                                  GLCHANGETIME_DTTM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)

, LOGIC_VBRK as (
    SELECT
        VBELN
      , KUNAG
    FROM SRC_VBRK
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
     SALES_INVOICE_BK
      , SALES_INVOICE_LINE_BK
      , ITEM_BK
      , DIVISION_BK
      , PLANT_BK
      , SALES_ORGANIZATION_BK
      , DISTRIBUTION_CHANNEL_BK
      , POSNR
      , VBELN
      , LOAD_DTS
      , MANDT
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
      , PSA_LOAD_DTS
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)

, RENAME_VBRK as (
    SELECT
        VBELN
      , KUNAG
    FROM LOGIC_VBRK
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_VBRP'
)

, FILTER_VBRK as (
    SELECT *
    FROM RENAME_VBRK
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT FILTER_S.*, FILTER_VBRK.KUNAG, FILTER_A.REC_SRC, FILTER_A.BKCC
    FROM FILTER_S
    LEFT JOIN FILTER_VBRK ON FILTER_S.VBELN = FILTER_VBRK.VBELN
    INNER JOIN FILTER_A ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
       SALES_INVOICE_BK
        , SALES_INVOICE_LINE_BK
        , ITEM_BK
        , DIVISION_BK
        , PLANT_BK
        , SALES_ORGANIZATION_BK
        , DISTRIBUTION_CHANNEL_BK
        , POSNR
        , VBELN
        , LOAD_DTS
        , MANDT
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
        , PSA_LOAD_DTS
        , KUNAG
        , to_char(coalesce(KUNAG, '-1'))                           as                                        CUSTOMER_BK
        , REC_SRC
        , BKCC
        , IFF(MATNR IS NULL, '-1', CONCAT_WS('||', MATNR, BKCC)) as drvd_item_bkcc
        , IFF(VBELN IS NULL, '-1', CONCAT_WS('||', VBELN, BKCC)) as drvd_sales_invoice_bkcc 
        , IFF(UEPOS IS NULL, '-1', CONCAT_WS('||', UEPOS, BKCC)) as drvd_sales_order_status_bkcc
        , IFF(SPART IS NULL, '-1', CONCAT_WS('||', SPART, BKCC))     as drvd_division_bkcc
        , IFF(WERKS IS NULL, '-1', CONCAT_WS('||', WERKS, BKCC))     as drvd_plant_bkcc
        , IFF(VKORG_AUFT IS NULL, '-1', CONCAT_WS('||', VKORG_AUFT, BKCC)) as drvd_sales_organization_bkcc
        , IFF(VTWEG_AUFT IS NULL, '-1', CONCAT_WS('||', VTWEG_AUFT, BKCC)) as drvd_distribution_channel_bkcc
        , IFF(KUNAG IS NULL, '-1', CONCAT_WS('||', KUNAG, BKCC))     as drvd_customer_bkcc
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(SALES_INVOICE_BK as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(SALES_INVOICE_LINE_BK as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as INVOICE_LINE_PACING_LHK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(drvd_item_bkcc as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(drvd_sales_invoice_bkcc as VARCHAR)),''), '^^')
        ))) as SALES_INVOICE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(drvd_sales_order_status_bkcc as VARCHAR)),''), '^^')
        ))) as SALES_ORDER_STATUS_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(VBELN as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(POSNR as VARCHAR)),''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')            
        ))) as SALES_INVOICE_LINE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(drvd_division_bkcc as VARCHAR)),''), '^^')
        ))) as DIVISION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(drvd_plant_bkcc as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(drvd_sales_organization_bkcc as VARCHAR)),''), '^^')
        ))) as SALES_ORGANIZATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(drvd_distribution_channel_bkcc as VARCHAR)),''), '^^')
        ))) as DISTRIBUTION_CHANNEL_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(drvd_customer_bkcc as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(POSNR::text), '^^') 
            , '||', IFNULL(TRIM(VBELN::text), '^^') 
            , '||', IFNULL(TRIM(UEPOS::text), '^^') 
            , '||', IFNULL(TRIM(FKIMG::text), '^^') 
            , '||', IFNULL(TRIM(VRKME::text), '^^') 
            , '||', IFNULL(TRIM(UMVKZ::text), '^^') 
            , '||', IFNULL(TRIM(UMVKN::text), '^^') 
            , '||', IFNULL(TRIM(MEINS::text), '^^') 
            , '||', IFNULL(TRIM(SMENG::text), '^^') 
            , '||', IFNULL(TRIM(FKLMG::text), '^^') 
            , '||', IFNULL(TRIM(LMENG::text), '^^') 
            , '||', IFNULL(TRIM(NTGEW::text), '^^') 
            , '||', IFNULL(TRIM(BRGEW::text), '^^') 
            , '||', IFNULL(TRIM(GEWEI::text), '^^') 
            , '||', IFNULL(TRIM(VOLUM::text), '^^') 
            , '||', IFNULL(TRIM(VOLEH::text), '^^') 
            , '||', IFNULL(TRIM(GSBER::text), '^^') 
            , '||', IFNULL(TRIM(PRSDT::text), '^^') 
            , '||', IFNULL(TRIM(FBUDA::text), '^^') 
            , '||', IFNULL(TRIM(KURSK::text), '^^') 
            , '||', IFNULL(TRIM(NETWR::text), '^^') 
            , '||', IFNULL(TRIM(VBELV::text), '^^') 
            , '||', IFNULL(TRIM(POSNV::text), '^^') 
            , '||', IFNULL(TRIM(VGBEL::text), '^^') 
            , '||', IFNULL(TRIM(VGPOS::text), '^^') 
            , '||', IFNULL(TRIM(VGTYP::text), '^^') 
            , '||', IFNULL(TRIM(AUBEL::text), '^^') 
            , '||', IFNULL(TRIM(AUPOS::text), '^^') 
            , '||', IFNULL(TRIM(AUREF::text), '^^') 
            , '||', IFNULL(TRIM(MATNR::text), '^^') 
            , '||', IFNULL(TRIM(ARKTX::text), '^^') 
            , '||', IFNULL(TRIM(PMATN::text), '^^') 
            , '||', IFNULL(TRIM(CHARG::text), '^^') 
            , '||', IFNULL(TRIM(MATKL::text), '^^') 
            , '||', IFNULL(TRIM(PSTYV::text), '^^') 
            , '||', IFNULL(TRIM(POSAR::text), '^^') 
            , '||', IFNULL(TRIM(PRODH::text), '^^') 
            , '||', IFNULL(TRIM(VSTEL::text), '^^') 
            , '||', IFNULL(TRIM(ATPKZ::text), '^^') 
            , '||', IFNULL(TRIM(SPART::text), '^^') 
            , '||', IFNULL(TRIM(POSPA::text), '^^') 
            , '||', IFNULL(TRIM(WERKS::text), '^^') 
            , '||', IFNULL(TRIM(ALAND::text), '^^') 
            , '||', IFNULL(TRIM(WKREG::text), '^^') 
            , '||', IFNULL(TRIM(WKCOU::text), '^^') 
            , '||', IFNULL(TRIM(WKCTY::text), '^^') 
            , '||', IFNULL(TRIM(TAXM1::text), '^^') 
            , '||', IFNULL(TRIM(TAXM2::text), '^^') 
            , '||', IFNULL(TRIM(TAXM3::text), '^^') 
            , '||', IFNULL(TRIM(TAXM4::text), '^^') 
            , '||', IFNULL(TRIM(TAXM5::text), '^^') 
            , '||', IFNULL(TRIM(TAXM6::text), '^^') 
            , '||', IFNULL(TRIM(TAXM7::text), '^^') 
            , '||', IFNULL(TRIM(TAXM8::text), '^^') 
            , '||', IFNULL(TRIM(TAXM9::text), '^^') 
            , '||', IFNULL(TRIM(KOWRR::text), '^^') 
            , '||', IFNULL(TRIM(PRSFD::text), '^^') 
            , '||', IFNULL(TRIM(SKTOF::text), '^^') 
            , '||', IFNULL(TRIM(SKFBP::text), '^^') 
            , '||', IFNULL(TRIM(KONDM::text), '^^') 
            , '||', IFNULL(TRIM(KTGRM::text), '^^') 
            , '||', IFNULL(TRIM(KOSTL::text), '^^') 
            , '||', IFNULL(TRIM(BONUS::text), '^^') 
            , '||', IFNULL(TRIM(PROVG::text), '^^') 
            , '||', IFNULL(TRIM(EANNR::text), '^^') 
            , '||', IFNULL(TRIM(VKGRP::text), '^^') 
            , '||', IFNULL(TRIM(VKBUR::text), '^^') 
            , '||', IFNULL(TRIM(SPARA::text), '^^') 
            , '||', IFNULL(TRIM(SHKZG::text), '^^') 
            , '||', IFNULL(TRIM(ERNAM::text), '^^') 
            , '||', IFNULL(TRIM(ERDAT::text), '^^') 
            , '||', IFNULL(TRIM(ERZET::text), '^^') 
            , '||', IFNULL(TRIM(BWTAR::text), '^^') 
            , '||', IFNULL(TRIM(LGORT::text), '^^') 
            , '||', IFNULL(TRIM(STAFO::text), '^^') 
            , '||', IFNULL(TRIM(WAVWR::text), '^^') 
            , '||', IFNULL(TRIM(KZWI1::text), '^^') 
            , '||', IFNULL(TRIM(KZWI2::text), '^^') 
            , '||', IFNULL(TRIM(KZWI3::text), '^^') 
            , '||', IFNULL(TRIM(KZWI4::text), '^^') 
            , '||', IFNULL(TRIM(KZWI5::text), '^^') 
            , '||', IFNULL(TRIM(KZWI6::text), '^^') 
            , '||', IFNULL(TRIM(STCUR::text), '^^') 
            , '||', IFNULL(TRIM(UVPRS::text), '^^') 
            , '||', IFNULL(TRIM(UVALL::text), '^^') 
            , '||', IFNULL(TRIM(EAN11::text), '^^') 
            , '||', IFNULL(TRIM(PRCTR::text), '^^') 
            , '||', IFNULL(TRIM(KVGR1::text), '^^') 
            , '||', IFNULL(TRIM(KVGR2::text), '^^') 
            , '||', IFNULL(TRIM(KVGR3::text), '^^') 
            , '||', IFNULL(TRIM(KVGR4::text), '^^') 
            , '||', IFNULL(TRIM(KVGR5::text), '^^') 
            , '||', IFNULL(TRIM(MVGR1::text), '^^') 
            , '||', IFNULL(TRIM(MVGR2::text), '^^') 
            , '||', IFNULL(TRIM(MVGR3::text), '^^') 
            , '||', IFNULL(TRIM(MVGR4::text), '^^') 
            , '||', IFNULL(TRIM(MVGR5::text), '^^') 
            , '||', IFNULL(TRIM(MATWA::text), '^^') 
            , '||', IFNULL(TRIM(BONBA::text), '^^') 
            , '||', IFNULL(TRIM(KOKRS::text), '^^') 
            , '||', IFNULL(TRIM(PAOBJNR::text), '^^') 
            , '||', IFNULL(TRIM(PS_PSP_PNR::text), '^^') 
            , '||', IFNULL(TRIM(AUFNR::text), '^^') 
            , '||', IFNULL(TRIM(TXJCD::text), '^^') 
            , '||', IFNULL(TRIM(CMPRE::text), '^^') 
            , '||', IFNULL(TRIM(CMPNT::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ::text), '^^') 
            , '||', IFNULL(TRIM(CUOBJ_CH::text), '^^') 
            , '||', IFNULL(TRIM(KOUPD::text), '^^') 
            , '||', IFNULL(TRIM(UECHA::text), '^^') 
            , '||', IFNULL(TRIM(XCHAR::text), '^^') 
            , '||', IFNULL(TRIM(ABRVW::text), '^^') 
            , '||', IFNULL(TRIM(SERNR::text), '^^') 
            , '||', IFNULL(TRIM(BZIRK_AUFT::text), '^^') 
            , '||', IFNULL(TRIM(KDGRP_AUFT::text), '^^') 
            , '||', IFNULL(TRIM(KONDA_AUFT::text), '^^') 
            , '||', IFNULL(TRIM(LLAND_AUFT::text), '^^') 
            , '||', IFNULL(TRIM(MPROK::text), '^^') 
            , '||', IFNULL(TRIM(PLTYP_AUFT::text), '^^') 
            , '||', IFNULL(TRIM(REGIO_AUFT::text), '^^') 
            , '||', IFNULL(TRIM(VKORG_AUFT::text), '^^') 
            , '||', IFNULL(TRIM(VTWEG_AUFT::text), '^^') 
            , '||', IFNULL(TRIM(ABRBG::text), '^^') 
            , '||', IFNULL(TRIM(PROSA::text), '^^') 
            , '||', IFNULL(TRIM(UEPVW::text), '^^') 
            , '||', IFNULL(TRIM(AUTYP::text), '^^') 
            , '||', IFNULL(TRIM(STADAT::text), '^^') 
            , '||', IFNULL(TRIM(FPLNR::text), '^^') 
            , '||', IFNULL(TRIM(FPLTR::text), '^^') 
            , '||', IFNULL(TRIM(AKTNR::text), '^^') 
            , '||', IFNULL(TRIM(KNUMA_PI::text), '^^') 
            , '||', IFNULL(TRIM(KNUMA_AG::text), '^^') 
            , '||', IFNULL(TRIM(PREFE::text), '^^') 
            , '||', IFNULL(TRIM(MWSBP::text), '^^') 
            , '||', IFNULL(TRIM(AUGRU_AUFT::text), '^^') 
            , '||', IFNULL(TRIM(FAREG::text), '^^') 
            , '||', IFNULL(TRIM(UPMAT::text), '^^') 
            , '||', IFNULL(TRIM(UKONM::text), '^^') 
            , '||', IFNULL(TRIM(CMPRE_FLT::text), '^^') 
            , '||', IFNULL(TRIM(ABFOR::text), '^^') 
            , '||', IFNULL(TRIM(ABGES::text), '^^') 
            , '||', IFNULL(TRIM(J_1ARFZ::text), '^^') 
            , '||', IFNULL(TRIM(J_1AREGIO::text), '^^') 
            , '||', IFNULL(TRIM(J_1AGICD::text), '^^') 
            , '||', IFNULL(TRIM(J_1ADTYP::text), '^^') 
            , '||', IFNULL(TRIM(J_1ATXREL::text), '^^') 
            , '||', IFNULL(TRIM(J_1BCFOP::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW1::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW2::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTXSDC::text), '^^') 
            , '||', IFNULL(TRIM(BRTWR::text), '^^') 
            , '||', IFNULL(TRIM(WKTNR::text), '^^') 
            , '||', IFNULL(TRIM(WKTPS::text), '^^') 
            , '||', IFNULL(TRIM(RPLNR::text), '^^') 
            , '||', IFNULL(TRIM(KURSK_DAT::text), '^^') 
            , '||', IFNULL(TRIM(WGRU1::text), '^^') 
            , '||', IFNULL(TRIM(WGRU2::text), '^^') 
            , '||', IFNULL(TRIM(KDKG1::text), '^^') 
            , '||', IFNULL(TRIM(KDKG2::text), '^^') 
            , '||', IFNULL(TRIM(KDKG3::text), '^^') 
            , '||', IFNULL(TRIM(KDKG4::text), '^^') 
            , '||', IFNULL(TRIM(KDKG5::text), '^^') 
            , '||', IFNULL(TRIM(VKAUS::text), '^^') 
            , '||', IFNULL(TRIM(J_1AINDXP::text), '^^') 
            , '||', IFNULL(TRIM(J_1AIDATEP::text), '^^') 
            , '||', IFNULL(TRIM(KZFME::text), '^^') 
            , '||', IFNULL(TRIM(MWSKZ::text), '^^') 
            , '||', IFNULL(TRIM(VERTT::text), '^^') 
            , '||', IFNULL(TRIM(VERTN::text), '^^') 
            , '||', IFNULL(TRIM(SGTXT::text), '^^') 
            , '||', IFNULL(TRIM(DELCO::text), '^^') 
            , '||', IFNULL(TRIM(BEMOT::text), '^^') 
            , '||', IFNULL(TRIM(RRREL::text), '^^') 
            , '||', IFNULL(TRIM(AKKUR::text), '^^') 
            , '||', IFNULL(TRIM(WMINR::text), '^^') 
            , '||', IFNULL(TRIM(VGBEL_EX::text), '^^') 
            , '||', IFNULL(TRIM(VGPOS_EX::text), '^^') 
            , '||', IFNULL(TRIM(LOGSYS::text), '^^') 
            , '||', IFNULL(TRIM(VGTYP_EX::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW3::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW4::text), '^^') 
            , '||', IFNULL(TRIM(J_1BTAXLW5::text), '^^') 
            , '||', IFNULL(TRIM(MSR_ID::text), '^^') 
            , '||', IFNULL(TRIM(MSR_REFUND_CODE::text), '^^') 
            , '||', IFNULL(TRIM(MSR_RET_REASON::text), '^^') 
            , '||', IFNULL(TRIM(NRAB_KNUMH::text), '^^') 
            , '||', IFNULL(TRIM(NRAB_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(DISPUTE_CASE::text), '^^') 
            , '||', IFNULL(TRIM(FUND_USAGE_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(FARR_RELTYPE::text), '^^') 
            , '||', IFNULL(TRIM(CLAIMS_TAXATION::text), '^^') 
            , '||', IFNULL(TRIM(KURRF_DAT_ORIG::text), '^^') 
            , '||', IFNULL(TRIM(VGTYP_EXT::text), '^^') 
            , '||', IFNULL(TRIM(SGT_RCAT::text), '^^') 
            , '||', IFNULL(TRIM(SGT_SCAT::text), '^^') 
            , '||', IFNULL(TRIM(AUFPL::text), '^^') 
            , '||', IFNULL(TRIM(APLZL::text), '^^') 
            , '||', IFNULL(TRIM(DPCNR::text), '^^') 
            , '||', IFNULL(TRIM(DCPNR::text), '^^') 
            , '||', IFNULL(TRIM(DPNRB::text), '^^') 
            , '||', IFNULL(TRIM(PEROP_BEG::text), '^^') 
            , '||', IFNULL(TRIM(PEROP_END::text), '^^') 
            , '||', IFNULL(TRIM(FMFGUS_KEY::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON_YEAR::text), '^^') 
            , '||', IFNULL(TRIM(FSH_SEASON::text), '^^') 
            , '||', IFNULL(TRIM(FSH_COLLECTION::text), '^^') 
            , '||', IFNULL(TRIM(FSH_THEME::text), '^^') 
            , '||', IFNULL(TRIM(FONDS::text), '^^') 
            , '||', IFNULL(TRIM(FISTL::text), '^^') 
            , '||', IFNULL(TRIM(FKBER::text), '^^') 
            , '||', IFNULL(TRIM(GRANT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_PD::text), '^^') 
            , '||', IFNULL(TRIM(PRS_WORK_PERIOD::text), '^^') 
            , '||', IFNULL(TRIM(PPRCTR::text), '^^') 
            , '||', IFNULL(TRIM(PARGB::text), '^^') 
            , '||', IFNULL(TRIM(AUFPL_OAA::text), '^^') 
            , '||', IFNULL(TRIM(APLZL_OAA::text), '^^') 
            , '||', IFNULL(TRIM(CAMPAIGN::text), '^^') 
            , '||', IFNULL(TRIM(COMPREAS::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC1::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC2::text), '^^') 
            , '||', IFNULL(TRIM(WRF_CHARSTC3::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI7::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI8::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI9::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI10::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI11::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI12::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI13::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI14::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI15::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI16::text), '^^') 
            , '||', IFNULL(TRIM(ZZKZWI17::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

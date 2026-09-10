---- SRC LAYER ----
WITH
SRC_L              as ( SELECT LOAD_DTS, REC_SRC, COPA_HK, CUSTOMER_HK, ITEM_HK, LNK_COPA_SALES_HK FROM {{ ref('lnk_copa_sales') }} as SRC  ),
SRC_H              as ( SELECT BKCC, REC_SRC, COPA_HK, COPA_HEADER_BK, COPA_LINE_BK FROM {{ ref('hub_copa') }} as SRC  ),
SRC_LS             as ( SELECT * EXCLUDE (
                          -- Exclude pre-calculated fields from lsat that we'll recalculate
                          VVGBP, VVNET, VVGRI, VVANS, VVNSA, VVGMG, VVAGM, VVCMG
                        )
                        FROM {{ ref('lsat_copa_sales__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY LNK_COPA_SALES_HK ORDER BY LOAD_DTS DESC) ),
SRC_FM             AS ( SELECT DISTINCT
                            FISCAL_445_CAL_YEAR,
                            FISCAL_445_CAL_MONTH,
                            FISCAL_445_CAL_QUARTER,
                            FISCAL_445_CAL_MONTH_YYYYMM
                        FROM {{ ref('ref_sat_date_fiscal_445') }} ),
SRC_CMR            as ( SELECT * FROM {{ ref('ref_cmrcat__winn_sap') }} as SRC )

/*
SRC_L              as ( SELECT * FROM RAW_VAULT.LNK_COPA_SALES ),
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_COPA ),
SRC_LS             as ( SELECT * EXCLUDE (VVGBP, VVNET, VVGRI, VVANS, VVNSA, VVGMG, VVAGM, VVCMG) FROM RAW_VAULT.LSAT_COPA_SALES__WINN_SAP),
SRC_CMR            as ( SELECT * FROM RAW_VAULT.REF_CMRCAT__WINN_SAP )
*/

---- LOGIC LAYER ----

, LOGIC_L as (
    SELECT
        REC_SRC                                                     as                                          PB_REC_SRC
      , CASE WHEN CURRENT_DATE is null then '-1' 
            WHEN CURRENT_DATE < '1901-01-01' then '-2'
            WHEN CURRENT_DATE > '2099-12-31' then '-3'
            ELSE regexp_replace(CURRENT_DATE, '[^0-9]+', '')
        END :: INTEGER                                               as                                       SNAPSHOTDATE
      , LOAD_DTS                                                    as                                      PB_LOAD_DTS
      , LNK_COPA_SALES_HK                                           as                                L_LNK_COPA_SALES_HK
      , COPA_HK                                                     as                                        L_COPA_HK
      , ITEM_HK
      , CUSTOMER_HK
    FROM SRC_L
)

, LOGIC_H as (
    SELECT
        COPA_HEADER_BK
      , COPA_LINE_BK
      , COPA_HK
      , BKCC
      , REC_SRC
    FROM SRC_H
)

, LOGIC_LS_BASE as (
    SELECT
        *
      , VRGAR as rec_type
      , PERIO as fiscper
      , BELNR as co_doc_no
      , POSNR as co_item_no
      , GJAHR as fiscyear
      , WADAT as gi_date
      , FADAT as bill_date
      , BUDAT as calday
      , KNDNR as customer
      , ARTNR as material
      , FKART as bill_type
      , KURSF as exchg_rate
      , REC_WAERS as currency
      , KAUFN as doc_number
      , KDPOS as s_ord_item
      , RKAUFNR as coorder
      , SKOST as send_cctr
      , PRZNR as ba_prznr
      , BUKRS as comp_code
      , KOKRS as co_area
      , WERKS as plant
      , GSBER as bus_area
      , VKORG as salesorg
      , VTWEG as distr_chan
      , SPART as division
      , KSTAR as costelmnt
      , PSPNR as wbs_elemt
      , KSTRG as costobj
      , RBELN as refer_doc
      , RPOSN as rfer_itm
      , RPOSN as bill_item
      , STO_BELNR as ba_cncldoc
      , STO_POSNR as ba_cnclitm
      , PRCTR as profit_ctr
      , PPRCTR as part_prctr
      , 'EA' as sales_unit
      , 3 as tctvaprctpm
      , 1 as ord_items
      , AUGRU as ord_reason
      , PSTYV as item_categ
      , WWKNU as salesdeal
      , KVGR1 as cust_grp1
      , KVGR3 as buy_grp
      , WWSTP as dealtype
      , AUART as doc_type
      , VKBUR as sales_off
      , BZIRK as sales_dist
      , VKGRP as sales_grp
      , WWPFA as forwagent
      , WWPPY as payer
      , WWPSH as ship_to
      , WWPSL as sold_to
      , WWPSR as salesemply
      , WWPBT as billtoprty
      , QMNUM as notificatn
      , VVQTY_ME as base_uom
      , LOAD_DTS as LSAT_LOAD_DTS
      , REC_SRC as LSAT_REC_SRC
      -- Flag calculations
      , CASE WHEN WWSTP in ('SAL') THEN VVQTY ELSE 0 END as bill_qty
      , CASE WHEN ARTNR in ('ACMISC','SPMISC','CFMISC') THEN 1 ELSE 0 END as fMaterial
      , CASE WHEN ARTNR in ('CQCLAIM','CSCLAIM','FSDAMAGE','FSLABOR') THEN 1 ELSE 0 END as fMaterial2
      , CASE WHEN WWSTP in ('NCH') THEN 1 ELSE 0 END as fNoCharge
      , CASE WHEN WWSTP in ('RTN') THEN 1 ELSE 0 END as fReturn
      , CASE WHEN WWSTP in ('ALW') THEN 1 ELSE 0 END as fAllowance
      , CASE WHEN WWSTP in ('SAL','CDM') THEN 1 ELSE 0 END as fSL_TOS_2
      , CASE WHEN WWSTP in ('SAL','NCH','PRM','I/C','ACT','CCA') THEN 1 ELSE 0 END as fSL_TOS_6
      , CASE WHEN WWSTP in ('SAL','CDM','NCH','PRM','I/C','ACT','CCA') THEN 1 ELSE 0 END as fSL_TOS_7a
      , CASE WHEN WWSTP in ('SAL','RTN','ALW','NCH','PRM','I/C','ACT','CCA') THEN 1 ELSE 0 END as fSL_TOS_8
      , CASE WHEN WWSTP in ('SAL','RTN','ALW','CDM','NCH','PRM','I/C','ACT','CCA') THEN 1 ELSE 0 END as fSL_TOS_9
      , CASE WHEN WWSTP in ('CDM') THEN 1 ELSE 0 END as fCDM
      , CASE WHEN try_to_number(WWRSN) not between 300 and 599 THEN 1 ELSE 0 END as fWWRSNa
      , CASE WHEN try_to_number(WWRSN) between 100 and 299 THEN 1 ELSE 0 END as fWWRSNb
      , CASE WHEN try_to_number(WWRSN) not between 300 and 499 and try_to_number(WWRSN) not between 501 and 599 THEN 1 ELSE 0 END as fWWRSNc
      , CASE WHEN WWRSN in ('423','432') THEN 1 ELSE 0 END as fWWRSNd
      , CASE WHEN WWRSN in ('504','430') THEN 1 ELSE 0 END as fWWRSNe
      , CASE WHEN WWRSN in ('500','501','502','503','504','507') THEN 1 ELSE 0 END as fWWRSN6
      -- Key creation for ZCMRCAT lookups
      , CASE WHEN len(trim(VKORG))>0 THEN 1 ELSE 0 END as fVKORG
      , CASE WHEN len(trim(SPART))>0 THEN 1 ELSE 0 END as fSPART
      , CASE WHEN len(trim(BUKRS))>0 THEN 1 ELSE 0 END as fBUKRS
    FROM SRC_LS
)

, LOGIC_LS_FLAGS as (
    SELECT
        *
      , CASE
          WHEN fVKORG=1 and fSPART=1 and fBUKRS=1 then 1
          WHEN fVKORG+fSPART+fBUKRS<3 and fVKORG=1 and fBUKRS=1 then 2
          WHEN fVKORG=1 and fSPART=1 and fBUKRS=0 then 3
          WHEN fVKORG=1 and fSPART=0 and fBUKRS=0 then 4
          WHEN fBUKRS=1 then 5
          else 0
        END as fZCMRCAT
    FROM LOGIC_LS_BASE
)

, LOGIC_LS_QTY as (
    SELECT
        LS.*
      -- Quantity calculations
      , CASE WHEN fMaterial=0 and fNoCharge=1 THEN VVQTY ELSE 0 END as ZNCHGQTY
      , CASE WHEN fMaterial=0 and fReturn=1 THEN VVQTY ELSE 0 END as ZRETRNQTY
      , CASE WHEN fAllowance=1 THEN VVQTY ELSE 0 END as ZALWQTY
    FROM LOGIC_LS_FLAGS LS
)

, LOGIC_LS as (
    SELECT
        LS.*
      , bill_qty+ZNCHGQTY as ZSHIPQTY
      
      -- Conditional VV field calculations following z_cpsls1 logic
      , CASE WHEN (fReturn=1 or fAllowance=1) and fWWRSNb=1 THEN VVGRS ELSE 0 END as ZACTRET
      , CASE WHEN fSL_TOS_6=1 THEN VVCRL WHEN fCDM=1 and fWWRSNa=1 THEN VVCRL ELSE 0 END as VVCRL_ADJ
      , CASE WHEN fSL_TOS_6=1 THEN VVSBK WHEN fCDM=1 and fWWRSNa=1 THEN VVSBK ELSE 0 END as VVSBK_ADJ
      , CASE WHEN fSL_TOS_6=1 THEN VVSBD WHEN fCDM=1 and fWWRSNa=1 THEN VVSBD ELSE 0 END as VVSBD_ADJ
      , CASE WHEN fSL_TOS_6=1 THEN VVACL WHEN fCDM=1 and fWWRSNa=1 THEN VVACL ELSE 0 END as VVACL_ADJ
      , CASE WHEN fSL_TOS_6=1 THEN VVIND WHEN fCDM=1 and fWWRSNa=1 THEN VVCRL ELSE 0 END as VVIND_ADJ
      , CASE WHEN fSL_TOS_6=1 THEN VVSDP WHEN fCDM=1 and fWWRSNa=1 THEN VVSDP ELSE 0 END as VVSDP_ADJ
      , CASE WHEN fSL_TOS_6=1 THEN VVSIP WHEN fCDM=1 and fWWRSNa=1 THEN VVSIP ELSE 0 END as VVSIP_ADJ
      , CASE WHEN fSL_TOS_6=1 THEN VVSPD WHEN fCDM=1 and fWWRSNa=1 THEN VVSPD ELSE 0 END as VVSPD_ADJ
      , CASE WHEN fSL_TOS_6=1 THEN VVOIP WHEN fCDM=1 and fWWRSNa=1 THEN VVOIP ELSE 0 END as VVOIP_ADJ
      , CASE WHEN fSL_TOS_6=1 THEN VVCJP WHEN fCDM=1 and fWWRSNa=1 THEN VVCJP ELSE 0 END as VVCJP_ADJ
      , CASE WHEN fSL_TOS_6=1 THEN VVDIP WHEN fCDM=1 and fWWRSNa=1 THEN VVDIP ELSE 0 END as VVDIP_ADJ
      , CASE WHEN fSL_TOS_6=1 THEN VVDCI WHEN fCDM=1 and fWWRSNa=1 THEN VVDCI ELSE 0 END as VVDCI_ADJ
      , CASE WHEN fSL_TOS_6=1 THEN VVMOD WHEN fCDM=1 and fWWRSNa=1 THEN VVMOD ELSE 0 END as VVMOD_ADJ
      , CASE WHEN fSL_TOS_6=1 THEN VVGRS WHEN fCDM=1 and fWWRSNc=1 THEN VVGRS ELSE 0 END as VVGRS_ADJ
      
      -- VVTSD calculation
      , CASE 
          WHEN fCDM=1 and WWRSN='422' THEN VVGRS
          WHEN fNoCharge=1 and WWRSN='422' THEN VVCST
          ELSE 0
        END as VVTSD_ADJ
      
      -- VVRCD calculation  
      , CASE
          WHEN fCDM=1 and WWRSN='425' THEN VVGRS
          WHEN fNoCharge=1 and WWRSN='425' THEN VVCST
          ELSE 0
        END as VVRCD_ADJ
      
      -- VVTRK calculation
      , CASE
          WHEN fCDM=1 and WWRSN in ('429','550') THEN VVGRS
          WHEN fNoCharge=1 and WWRSN='422' THEN VVCST
          ELSE 0
        END as VVTRK_ADJ
      
      -- VVFPP calculation
      , CASE
          WHEN fCDM=1 and WWRSN='431' THEN VVGRS
          WHEN fNoCharge=1 and WWRSN='431' THEN VVCST
          ELSE 0
        END as VVFPP_ADJ
      
      , CASE WHEN fSL_TOS_8=1 THEN VVACQ ELSE 0 END as VVACQ_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVFRM+VVFRC ELSE 0 END as VVFRM_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVFRA ELSE 0 END as VVFRA_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVRST+VVHDL+VVMIN+VVVPP ELSE 0 END as ZHDLREV
      , CASE WHEN fSL_TOS_9=1 THEN VVCES ELSE 0 END as VVCES_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVCDR ELSE 0 END as VVCDR_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVGRR ELSE 0 END as VVGRR_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVPRV ELSE 0 END as VVPRV_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVSUP ELSE 0 END as VVSUP_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVVLR ELSE 0 END as VVVLR_ADJ
      , CASE WHEN fSL_TOS_9=1 and comp_code='MCAN' THEN VVERR ELSE 0 END as VVERR_ADJ
      , CASE WHEN fSL_TOS_9=1 and comp_code='MCAN' THEN VVERW ELSE 0 END as VVERW_ADJ
      , CASE WHEN fSL_TOS_9=1 and comp_code='MCAN' THEN VVVBR ELSE 0 END as VVVBR_ADJ
      , CASE WHEN fSL_TOS_9=1 and comp_code='MCAN' THEN VVVBW ELSE 0 END as VVVBW_ADJ
      , CASE WHEN fSL_TOS_9=1 and comp_code='MCAN' THEN VVVMW ELSE 0 END as VVVMW_ADJ
      , CASE WHEN fSL_TOS_9=1 and comp_code='MCAN' THEN VVHFR ELSE 0 END as VVHFR_ADJ
      
      -- VVWHS calculation
      , CASE
          WHEN fSL_TOS_9=1 and fSL_TOS_2=1 and WWRSN='403' and WWSTP='SAL' and bill_type=' ' THEN VVWHS+VVGRS+VVCST
          WHEN fSL_TOS_9=1 and fSL_TOS_2=1 and WWRSN='403' and WWSTP='SAL' and bill_type<>' ' THEN VVWHS+VVGRS-VVCST
          WHEN fSL_TOS_9=1 and fSL_TOS_2=1 and WWRSN='403' THEN VVWHS+VVGRS
          WHEN fSL_TOS_9=1 and fSL_TOS_2<>1 and WWSTP='NCH' THEN VVWHS-VVCST
          WHEN fSL_TOS_9=1 THEN VVWHS
          ELSE 0
        END as VVWHS_ADJ
      
      -- VVBLD calculation
      , CASE
          WHEN fSL_TOS_9=1 and fWWRSNd=1 and WWSTP='SAL' and WWRSN='423' and bill_type=' ' THEN VVBLD+VVCST
          WHEN fSL_TOS_9=1 and fWWRSNd=1 and WWSTP='SAL' and WWRSN='423' and bill_type<>' ' THEN VVBLD-VVCST
          WHEN fSL_TOS_9=1 and fSL_TOS_2=1 and fWWRSNd=1 THEN VVBLD+VVGRS
          WHEN fSL_TOS_9=1 and WWSTP='NCH' and fWWRSNd=1 THEN VVBLD-VVCST
          WHEN fSL_TOS_9=1 THEN VVBLD
          ELSE 0
        END as VVBLD_ADJ
      
      -- VVVIP calculation
      , CASE
          WHEN fSL_TOS_9=1 and WWRSN='414' and fSL_TOS_2=1 and WWSTP='SAL' THEN VVVIP+VVGRS+VVCST
          WHEN fSL_TOS_9=1 and WWRSN='414' and fSL_TOS_2=1 THEN VVVIP+VVGRS
          WHEN fSL_TOS_9=1 and WWSTP='NCH' THEN VVVIP-VVCST
          WHEN fSL_TOS_9=1 THEN VVVIP
          ELSE 0
        END as VVVIP_ADJ
      
      , CASE WHEN fSL_TOS_9=1 THEN VVSOD ELSE 0 END as VVSOD_ADJ
      , CASE WHEN fSL_TOS_9=1 and comp_code='MCAN' THEN VVCRR ELSE 0 END as VVCRR_ADJ
      , CASE WHEN fSL_TOS_9=1 and comp_code<>'MCAN' THEN VVCOP ELSE 0 END as VVCOP_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVMWP ELSE 0 END as VVMWP_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVSSA+VVDSA ELSE 0 END as VVSSA_ADJ
      
      -- VVPRO calculation
      , CASE
          WHEN fSL_TOS_9=1 and WWRSN='406' and fSL_TOS_2=1 and WWSTP='SAL' THEN VVPRO+VVGRS+VVCST
          WHEN fSL_TOS_9=1 and WWRSN='406' and fSL_TOS_2=1 THEN VVPRO+VVGRS
          WHEN fSL_TOS_9=1 and WWRSN='406' and WWSTP='NCH' THEN VVPRO-VVCST
          WHEN fSL_TOS_9=1 THEN VVPRO
          ELSE 0
        END as VVPRO_ADJ
      
      , CASE WHEN fSL_TOS_9=1 THEN VVCMB ELSE 0 END as VVCMB_ADJ
      
      -- VVPRD calculation
      , CASE
          WHEN fSL_TOS_9=1 and WWRSN='314' and fSL_TOS_2=1 and WWSTP='SAL' THEN VVPRD+VVGRS+VVCST
          WHEN fSL_TOS_9=1 and WWRSN='314' and fSL_TOS_2=1 THEN VVPRD+VVGRS
          WHEN fSL_TOS_9=1 and WWRSN='314' and WWSTP='NCH' THEN VVPRD-VVCST
          WHEN fSL_TOS_9=1 THEN VVPRD
          ELSE 0
        END as VVPRD_ADJ
      
      , CASE WHEN fSL_TOS_9=1 THEN VVSBN ELSE 0 END as VVSBN_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVMKF ELSE 0 END as VVMKF_ADJ
      
      -- VVVPO calculation
      , CASE
          WHEN WWSTP in ('CDM','NCH','SAL') and WWRSN='318' THEN VVVPO+VVGRS
          WHEN fSL_TOS_9=1 THEN VVVPO
          ELSE 0
        END as VVVPO_ADJ
      
      , CASE WHEN fSL_TOS_9=1 THEN VVDSP ELSE 0 END as VVDSP_FL
      , CASE WHEN fSL_TOS_9=1 THEN VVEDI ELSE 0 END as VVEDI_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVHCD ELSE 0 END as VVHCD_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVOPN ELSE 0 END as VVOPN_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVPRP ELSE 0 END as VVPRP_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN 0 ELSE 0 END as VVPRT_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVPRT ELSE 0 END as ZVPRT
      , CASE WHEN fSL_TOS_9=1 THEN VVSHW ELSE 0 END as VVSHW_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVSPC ELSE 0 END as VVSPC_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVSPS ELSE 0 END as VVSPS_ADJ
      , CASE WHEN fSL_TOS_9=1 THEN VVRET ELSE 0 END as VVRET_ADJ
      
      -- VVCJA calculation
      , CASE
          WHEN fSL_TOS_7a=1 and WWRSN='522' and fSL_TOS_2=1 THEN VVCJA+VVGRS
          WHEN fSL_TOS_7a=1 and WWRSN='522' and WWSTP='NCH' THEN VVCJA-VVCST
          WHEN fSL_TOS_7a=1 and WWRSN='522' and WWSTP='SAL' THEN VVCJA+VVCST
          ELSE 0
        END as VVCJA_ADJ
      
      -- VVCST calculation
      , CASE
          WHEN WWSTP<>'NCH' THEN VVCST
          WHEN WWSTP='NCH' and fWWRSNa=1 THEN VVCST
          ELSE 0
        END as VVCST_ADJ
      
      -- VVICP calculation
      , CASE
          WHEN WWSTP<>'NCH' THEN VVICP
          WHEN WWSTP='NCH' and fWWRSNa=1 THEN VVICP
          ELSE 0
        END as VVICP_ADJ
      
      -- VVSTS calculation
      , CASE
          WHEN WWSTP='CDM' and WWRSN='427' THEN VVCST+VVGRS
          WHEN WWRSN='427' THEN VVCST
          ELSE 0
        END as VVSTS_ADJ
      
      -- ZPOSVOE calculation
      , CASE
          WHEN WWSTP='CDM' and WWRSN='411' THEN VVCST+VVGRS
          WHEN WWRSN='411' THEN VVCST
          ELSE 0
        END as ZPOSVOE
      
      -- ZNCHCOST calculation
      , CASE WHEN fWWRSN6=1 THEN VVCST ELSE 0 END as ZNCHCOST
      
      -- VVNCD calculation
      , CASE
          WHEN fWWRSN6=1 and WWRSN='504' THEN -VVCST
          WHEN WWRSN='430' THEN -VVCST
          WHEN WWSTP='CDM' and fWWRSNe=1 THEN VVGRS
          ELSE 0
        END as VVNCD_ADJ
      
      , VVAFC as VVAFC_ADJ
      , VVFRO as VVFRO_ADJ
      , VVCMR+VVCMW as ZAGNTCOMM
      , VVBON as VVBON_ADJ
      , VVOTC as VVOTC_ADJ
      , 0 as VVFRC_ADJ
      
    FROM LOGIC_LS_QTY LS
)

-- Calculate derived fields like in z_cpsls1 - Step 1: Base calculations
, LOGIC_LS_CALCS_1 as (
    SELECT
        *
      , VVGRS_ADJ+VVFRC_ADJ+VVFRA_ADJ+VVFRM_ADJ+ZHDLREV+VVCES_ADJ+VVACQ_ADJ as VVGBP
      , VVVPO_ADJ+VVPRT_ADJ+ZVPRT+VVPRP_ADJ+VVEDI_ADJ+VVHCD_ADJ+VVOPN_ADJ+VVDSP_FL+VVSHW_ADJ+VVSPS_ADJ+VVRET_ADJ as ZOIDS
      , VVTSD_ADJ+VVTRK_ADJ+VVRCD_ADJ+VVFPP_ADJ as ZREBOID
      , VVGRR_ADJ+VVPRD_ADJ+VVPRV_ADJ+VVSUP_ADJ+VVVLR_ADJ+VVERR_ADJ+VVERW_ADJ+VVVBR_ADJ+VVVBW_ADJ+VVVMW_ADJ+VVHFR_ADJ+VVWHS_ADJ+VVBLD_ADJ+VVVIP_ADJ as ZEIT22SAL
      , VVSOD_ADJ as ZEIT22MKT
      , VVCRR_ADJ+VVCOP_ADJ+VVMWP_ADJ+VVSSA_ADJ+VVTSD_ADJ+VVPRO_ADJ+VVCMB_ADJ+VVCJA_ADJ as ZEIT25SAL
      , ZPOSVOE as ZVOEMKT
      , VVSBN_ADJ+VVNCD_ADJ+VVSTS_ADJ+VVMKF_ADJ as ZVOESALES
    FROM LOGIC_LS
)

-- Step 2: Second level calculations
, LOGIC_LS_CALCS_2 as (
    SELECT
        *
      , VVGBP+ZOIDS as VVGRI
      , ZEIT22SAL+ZEIT22MKT as ZEIT22
      , ZEIT25SAL as ZEIT25
      , ZVOESALES+ZVOEMKT as ZACCVOES
    FROM LOGIC_LS_CALCS_1
)

-- Step 3: Third level calculations
, LOGIC_LS_CALCS_3 as (
    SELECT
        *
      , VVGRI+ZACTRET+VVCDR_ADJ as VVANS
      , ZEIT22+ZEIT25 as ZACRCUSRB
    FROM LOGIC_LS_CALCS_2
)

-- Step 4: Final calculations
, LOGIC_LS_CALCS as (
    SELECT
        *
      , VVANS+ZREBOID as VVNET
      , VVANS+VVRCD_ADJ+VVTSD_ADJ as ZREBBASIS
    FROM LOGIC_LS_CALCS_3
)

-- Step 5: Dependent calculations
, LOGIC_LS_CALCS_FINAL as (
    SELECT
        *
      , VVNET+ZACRCUSRB as VVNSA
    FROM LOGIC_LS_CALCS
)

-- Step 6: Final dependent calculations
, LOGIC_LS_CALCS_COMPLETE as (
    SELECT
        *
      , VVNSA-VVCST_ADJ as VVGMG
    FROM LOGIC_LS_CALCS_FINAL
)

-- Step 7: Last calculations
, LOGIC_LS_CALCS_FINAL2 as (
    SELECT
        *
      , VVGMG+VVICP_ADJ as VVAGM
    FROM LOGIC_LS_CALCS_COMPLETE
)

-- Step 8: Ultimate finale
, LOGIC_LS_CALCS_FINAL3 as (
    SELECT
        *
      , VVAGM+ZACCVOES+VVAFC_ADJ+VVFRO_ADJ as VVCMG
    FROM LOGIC_LS_CALCS_FINAL2
)

, LOGIC_FM AS (
    SELECT
        FISCAL_445_CAL_YEAR                                                  AS FISCAL_YEAR
      , FISCAL_445_CAL_MONTH                                                 AS FISCAL_MONTH
      , FISCAL_445_CAL_QUARTER                                               AS FISCAL_QUARTER
      , FISCAL_445_CAL_MONTH_YYYYMM                                         AS FISCAL_YEAR_PERIOD
    FROM SRC_FM
)

, LOGIC_CMR as (
    SELECT
        VKORG
      , SPART
      , BUKRS
      , ZCMRCAT
    FROM SRC_CMR
)

---- RENAME LAYER ----

, RENAME_L as (
    SELECT
        PB_REC_SRC
      , SNAPSHOTDATE
      , PB_LOAD_DTS
      , L_LNK_COPA_SALES_HK
      , L_COPA_HK
      , ITEM_HK
      , CUSTOMER_HK
    FROM LOGIC_L
)

, RENAME_H as (
    SELECT
        COPA_HEADER_BK
      , COPA_LINE_BK
      , COPA_HK
      , BKCC
      , REC_SRC
    FROM LOGIC_H
)

, RENAME_LS as (
    SELECT
        *
    FROM LOGIC_LS_CALCS_FINAL3
)

, RENAME_FM AS (
    SELECT *
    FROM LOGIC_FM
)

, RENAME_CMR as (
    SELECT *
    FROM LOGIC_CMR
)

---- FILTER LAYER ----

, FILTER_L as (
    SELECT *
    FROM RENAME_L
    WHERE PB_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'
)

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_LS as (
    SELECT *
    FROM RENAME_LS
    WHERE fMaterial2=0  -- Only filter from z_cpsls1.sql line 751
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT
        FILTER_L.*
      , FILTER_H.COPA_HEADER_BK
      , FILTER_H.COPA_LINE_BK
      , FILTER_H.BKCC
      , FILTER_LS.material as ITEM_ID
      , FILTER_LS.customer as CUSTOMER_ID
      , FILTER_LS.co_doc_no as DOCUMENT_NUMBER
      , FILTER_LS.co_item_no as LINE_NUMBER
      , FILTER_LS.ZZSEG as PRODUCT_SEGMENT_ID
      , TO_CHAR(FILTER_LS.WADAT_DT, 'YYYYMMDD')::INTEGER as GI_DATE__YYYYMMDD
      , TO_CHAR(FILTER_LS.FADAT_DT, 'YYYYMMDD')::INTEGER as INVOICE_DATE__YYYYMMDD
      , TO_CHAR(FILTER_LS.BUDAT_DT, 'YYYYMMDD')::INTEGER as POSTED_DATE__YYYYMMDD
      , FILTER_LS.fiscper as PERIO
      , TRY_CAST(SUBSTRING(FILTER_LS.fiscper, 1, 4) AS INT) as COPA_FISCAL_YEAR
      , TRY_CAST(SUBSTRING(FILTER_LS.fiscper, 5, 3) AS INT) as COPA_FISCAL_MONTH
      , RENAME_FM.FISCAL_YEAR
      , RENAME_FM.FISCAL_MONTH
      , RENAME_FM.FISCAL_QUARTER
      , RENAME_FM.FISCAL_YEAR_PERIOD
      , FILTER_LS.bill_qty as INVOICE_QTY
      , FILTER_LS.base_uom as UOM
      
      -- All calculated fields from z_cpsls1
      , FILTER_LS.VVGBP as GROSS_BILLING_PRICE
      , FILTER_LS.VVGRS_ADJ as GROSS_SALES
      , FILTER_LS.VVNET as NET_SALES
      , FILTER_LS.VVCST_ADJ as COGS
      , FILTER_LS.VVCDR_ADJ as CASH_DISCOUNT
      , FILTER_LS.VVBON_ADJ as BONUS
      , FILTER_LS.VVSPC_ADJ as MARKDOWNS
      , FILTER_LS.VVBLD_ADJ as BUILDER_SINGLE_FAMILY
      , 0 as BUILDER_NSF  -- VVLTS not in source
      , FILTER_LS.VVPRD_ADJ as BUILDER_PP
      , FILTER_LS.VVVIP_ADJ as PLUMBER_INSTALLER_REBATES
      , 0 as DIRECT_VOLUME_REBATE_DFR  -- VVDFR not in source
      , FILTER_LS.VVDSA as DIRECT_VOLUME_REBATE_DSA
      , FILTER_LS.VVHFR_ADJ as DIRECT_VOLUME_REBATE_HFR
      , FILTER_LS.VVVLR_ADJ as DIRECT_VOLUME_REBATE_VLR
      , 0 as DIRECT_VOLUME_REBATE_DEV  -- VVDEV not in source
      , FILTER_LS.VVWHS_ADJ as CV_SHOWROOM
      , FILTER_LS.VVCOP_ADJ as COOP_ADVERTISING
      , FILTER_LS.VVSUP_ADJ as OTHER_FIXED_REBATES
      , FILTER_LS.VVPRO_ADJ as PROMOTION_EXPENSE
      , FILTER_LS.VVSOD_ADJ as CASH_FLOW_REBATES
      , 0 as ACCRUED_RETURNS  -- VVART not in source
      , FILTER_LS.VVCJA_ADJ as REBATED_CJQ
      , FILTER_LS.VVDSP_FL as POLICY_INCENTIVE_DSP
      , FILTER_LS.VVEDI_ADJ as POLICY_INCENTIVE_EDI
      , FILTER_LS.VVHCD_ADJ as POLICY_INCENTIVE_HCD
      , FILTER_LS.VVOPN_ADJ as POLICY_INCENTIVE_OPN
      , FILTER_LS.VVPRP_ADJ as POLICY_INCENTIVE_PRP
      , FILTER_LS.VVPRT_ADJ as POLICY_INCENTIVE_PRT
      , FILTER_LS.VVRCD_ADJ as POLICY_INCENTIVE_RCD
      , FILTER_LS.VVRET_ADJ as POLICY_INCENTIVE_RET
      , FILTER_LS.VVSHW_ADJ as POLICY_INCENTIVE_SHW
      , FILTER_LS.VVSPS_ADJ as POLICY_INCENTIVE_SPS
      , FILTER_LS.VVVPO_ADJ as POLICY_INCENTIVE_VPO
      , FILTER_LS.VVVPP as PURCHASE_PRICE_VARIANCE
      , FILTER_LS.VVACQ_ADJ as ACQUISITION
      , FILTER_LS.VVHDL as HANDLING
      , FILTER_LS.VVAFC_ADJ as FREIGHT
      
      -- Additional derived fields from z_cpsls1 that are now available
      , FILTER_LS.ZSHIPQTY
      , FILTER_LS.ZNCHGQTY
      , FILTER_LS.ZRETRNQTY
      , FILTER_LS.ZALWQTY
      , FILTER_LS.ZACTRET
      , FILTER_LS.VVGRI
      , FILTER_LS.VVANS
      , FILTER_LS.ZREBOID
      , FILTER_LS.ZEIT22SAL
      , FILTER_LS.ZEIT22MKT
      , FILTER_LS.ZEIT22
      , FILTER_LS.ZEIT25SAL
      , FILTER_LS.ZEIT25
      , FILTER_LS.ZACRCUSRB
      , FILTER_LS.VVNSA
      , FILTER_LS.VVGMG
      , FILTER_LS.VVAGM
      , FILTER_LS.ZVOEMKT
      , FILTER_LS.ZVOESALES
      , FILTER_LS.ZACCVOES
      , FILTER_LS.VVCMG
      , FILTER_LS.ZREBBASIS
      
      , FILTER_LS.salesorg as SALES_ORG
      , FILTER_LS.distr_chan as CHANNEL
      , FILTER_LS.division as DIVISION
      , FILTER_LS.plant as PLANT
      , FILTER_LS.currency as CURRENCY
      
      -- ZCMRCAT lookup logic from z_cpsls1
      , CASE
          WHEN FILTER_LS.fZCMRCAT=1 THEN coalesce(CMR1a.ZCMRCAT, CMR1b.ZCMRCAT, CMR1c.ZCMRCAT, '0099')
          WHEN FILTER_LS.fZCMRCAT=2 THEN coalesce(CMR1b.ZCMRCAT, CMR1c.ZCMRCAT, '0099')
          WHEN FILTER_LS.fZCMRCAT=3 THEN coalesce(CMR1a.ZCMRCAT, CMR1b.ZCMRCAT, '0099')
          WHEN FILTER_LS.fZCMRCAT=4 THEN coalesce(CMR1b.ZCMRCAT, '0099')
          WHEN FILTER_LS.fZCMRCAT=5 THEN coalesce(CMR1c.ZCMRCAT, '0099')
          ELSE '0099'
        END as ZCMRCAT
      
      , FILTER_LS.LSAT_LOAD_DTS
      , FILTER_LS.LSAT_REC_SRC
      
      -- Per unit calculations
      , CASE WHEN FILTER_LS.bill_qty != 0 THEN FILTER_LS.VVGRS_ADJ / FILTER_LS.bill_qty ELSE 0 END as PER_UNIT_GROSS_SALES
      , CASE WHEN FILTER_LS.bill_qty != 0 THEN FILTER_LS.VVNET / FILTER_LS.bill_qty ELSE 0 END as PER_UNIT_NET_SALES
      , CASE WHEN FILTER_LS.bill_qty != 0 THEN FILTER_LS.VVCST_ADJ / FILTER_LS.bill_qty ELSE 0 END as PER_UNIT_COGS
      , CASE WHEN FILTER_LS.bill_qty != 0 THEN (COALESCE(FILTER_LS.VVNET, 0) - COALESCE(FILTER_LS.VVCST_ADJ, 0)) / FILTER_LS.bill_qty ELSE 0 END as PER_UNIT_PRODUCT_MARGIN
      
    FROM FILTER_L
    INNER JOIN FILTER_H
        ON FILTER_L.L_COPA_HK = FILTER_H.COPA_HK
    INNER JOIN FILTER_LS
        ON FILTER_L.L_LNK_COPA_SALES_HK = FILTER_LS.LNK_COPA_SALES_HK
    LEFT JOIN RENAME_FM
        ON TRY_CAST(SUBSTRING(FILTER_LS.fiscper, 1, 4) AS INT) = RENAME_FM.FISCAL_YEAR
        AND TRY_CAST(SUBSTRING(FILTER_LS.fiscper, 5, 3) AS INT) = RENAME_FM.FISCAL_MONTH
    -- Three ZCMRCAT lookups following z_cpsls1 pattern
    LEFT JOIN RENAME_CMR as CMR1a
        ON FILTER_LS.fZCMRCAT in (1,3)
        AND len(trim(CMR1a.VKORG))>0
        AND len(trim(CMR1a.SPART))>0  
        AND len(trim(CMR1a.BUKRS))=0
        AND FILTER_LS.salesorg = CMR1a.VKORG
        AND FILTER_LS.division = CMR1a.SPART
    LEFT JOIN RENAME_CMR as CMR1b
        ON FILTER_LS.fZCMRCAT in (1,2,3,4)
        AND len(trim(CMR1b.VKORG))>0
        AND len(trim(CMR1b.SPART))=0
        AND len(trim(CMR1b.BUKRS))=0
        AND FILTER_LS.salesorg = CMR1b.VKORG
    LEFT JOIN RENAME_CMR as CMR1c
        ON FILTER_LS.fZCMRCAT in (1,2,5)
        AND len(trim(CMR1c.BUKRS))>0
        AND len(trim(CMR1c.SPART))=0
        AND len(trim(CMR1c.VKORG))=0
        AND FILTER_LS.comp_code = CMR1c.BUKRS
)

---- FINAL LAYER ----
SELECT
          PB_REC_SRC
        , SNAPSHOTDATE
        , PB_LOAD_DTS
        , L_LNK_COPA_SALES_HK
        , L_COPA_HK
        , ITEM_HK
        , CUSTOMER_HK
        , COPA_HEADER_BK
        , COPA_LINE_BK
        , BKCC
        , ITEM_ID
        , CUSTOMER_ID
        , DOCUMENT_NUMBER
        , LINE_NUMBER
        , PRODUCT_SEGMENT_ID
        , GI_DATE__YYYYMMDD
        , INVOICE_DATE__YYYYMMDD
        , POSTED_DATE__YYYYMMDD
        , PERIO
        , COPA_FISCAL_YEAR
        , COPA_FISCAL_MONTH
        , FISCAL_YEAR
        , FISCAL_MONTH
        , FISCAL_QUARTER
        , FISCAL_YEAR_PERIOD
        , INVOICE_QTY
        , UOM
        , GROSS_BILLING_PRICE
        , GROSS_SALES
        , NET_SALES
        , COGS
        , CASH_DISCOUNT
        , BONUS
        , MARKDOWNS
        , BUILDER_SINGLE_FAMILY
        , BUILDER_NSF
        , BUILDER_PP
        , PLUMBER_INSTALLER_REBATES
        , DIRECT_VOLUME_REBATE_DFR
        , DIRECT_VOLUME_REBATE_DSA
        , DIRECT_VOLUME_REBATE_HFR
        , DIRECT_VOLUME_REBATE_VLR
        , DIRECT_VOLUME_REBATE_DEV
        , CV_SHOWROOM
        , COOP_ADVERTISING
        , OTHER_FIXED_REBATES
        , PROMOTION_EXPENSE
        , CASH_FLOW_REBATES
        , ACCRUED_RETURNS
        , REBATED_CJQ
        , POLICY_INCENTIVE_DSP
        , POLICY_INCENTIVE_EDI
        , POLICY_INCENTIVE_HCD
        , POLICY_INCENTIVE_OPN
        , POLICY_INCENTIVE_PRP
        , POLICY_INCENTIVE_PRT
        , POLICY_INCENTIVE_RCD
        , POLICY_INCENTIVE_RET
        , POLICY_INCENTIVE_SHW
        , POLICY_INCENTIVE_SPS
        , POLICY_INCENTIVE_VPO
        , PURCHASE_PRICE_VARIANCE
        , ACQUISITION
        , HANDLING
        , FREIGHT
        , ZSHIPQTY
        , ZNCHGQTY
        , ZRETRNQTY
        , ZALWQTY
        , ZACTRET
        , VVGRI
        , VVANS
        , ZREBOID
        , ZEIT22SAL
        , ZEIT22MKT
        , ZEIT22
        , ZEIT25SAL
        , ZEIT25
        , ZACRCUSRB
        , VVNSA
        , VVGMG
        , VVAGM
        , ZVOEMKT
        , ZVOESALES
        , ZACCVOES
        , VVCMG
        , ZREBBASIS
        , SALES_ORG
        , CHANNEL
        , DIVISION
        , PLANT
        , CURRENCY
        , ZCMRCAT
        , PER_UNIT_GROSS_SALES
        , PER_UNIT_NET_SALES
        , PER_UNIT_COGS
        , PER_UNIT_PRODUCT_MARGIN
        , LSAT_LOAD_DTS
        , LSAT_REC_SRC
FROM JOIN_RESULT

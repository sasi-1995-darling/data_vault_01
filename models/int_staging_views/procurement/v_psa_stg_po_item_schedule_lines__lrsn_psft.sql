---- SRC LAYER ----
WITH
SRC_pssch          as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_po_line_ship') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_pssch          as ( SELECT * FROM lrsn_psft_sysadm.ps_po_line_ship )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_pssch as (
    SELECT
        CONCAT_WS('||', COALESCE(BUSINESS_UNIT, ''), COALESCE(PO_ID, ''), COALESCE(LINE_NBR, '')) as                                         PO_ITEM_BK
      , CONCAT_WS('||', COALESCE(BUSINESS_UNIT, ''), COALESCE(PO_ID, '')) as                                       PO_HEADER_BK
      , BUSINESS_UNIT
      , PO_ID
      , LINE_NBR
      , SCHED_NBR
      , CANCEL_STATUS
      , BAL_STATUS
      , CHANGE_STATUS
      , CHNG_ORD_SEQ
      , PRICE_PO
      , PRICE_PO_BSE
      , CUSTOM_PRICE
      , ZERO_PRICE_IND
      , DUE_DT
      , DUE_TIME
      , SHIPTO_SETID
      , SHIPTO_ID
      , ORIG_PROM_DT
      , QTY_PO
      , CURRENCY_CD
      , MERCHANDISE_AMT
      , CURRENCY_CD_BASE
      , MERCH_AMT_BSE
      , CONVERSION_RATE
      , FREIGHT_TERMS
      , SHIP_TYPE_ID
      , DISTRIB_MTHD_FLG
      , LIQUIDATE_METHOD
      , UNIT_PRC_TOL
      , UNIT_PRC_TOL_BSE
      , PCT_UNIT_PRC_TOL
      , EXT_PRC_TOL
      , EXT_PRC_TOL_BSE
      , PCT_EXT_PRC_TOL
      , QTY_RECV_TOL_PCT
      , PCT_UNDER_QTY
      , MATCH_STATUS_LN_PO
      , MATCH_LINE_OPT
      , BUSINESS_UNIT_OM
      , ORDER_NO
      , ORDER_INT_LINE_NO
      , SCHED_LINE_NBR
      , SHIP_TO_CUST_ID
      , BUSINESS_UNIT_IN
      , PRODUCTION_ID
      , OP_SEQUENCE
      , FROZEN_FLG
      , PLAN_CHANGE_FLG
      , NET_CHANGE_EP
      , WORK_ORDER_ID
      , CARRIER_ID
      , SUT_BASE_ID
      , TAX_CD_SUT
      , ULTIMATE_USE_CD
      , SUT_EXCPTN_TYPE
      , SUT_EXCPTN_CERTIF
      , SUT_APPLICABILITY
      , VAT_RCRD_INPT_FLG
      , VAT_RCRD_OUTPT_FLG
      , VAT_DCLRTN_POINT
      , VAT_CALC_GROSS_NET
      , VAT_CALC_FRGHT_FLG
      , VAT_CALC_MISC_FLG
      , VAT_RECALC_FLG
      , VAT_TREATMENT_GRP
      , VAT_TREATMENT
      , COUNTRY_LOC_BUYER
      , STATE_LOC_BUYER
      , COUNTRY_LOC_SELLER
      , STATE_LOC_SELLER
      , VAT_SVC_SUPPLY_FLG
      , VAT_SERVICE_TYPE
      , COUNTRY_VAT_PERFRM
      , STATE_VAT_PERFRM
      , COUNTRY_VAT_SUPPLY
      , STATE_VAT_SUPPLY
      , STATE_VAT_DEFAULT
      , STATE_SHIP_FROM
      , STATE_SHIP_TO
      , VAT_EXCPTN_TYPE
      , VAT_EXCPTN_CERTIF
      , COUNTRY_SHIP_TO
      , COUNTRY_SHIP_FROM
      , COUNTRY_VAT_SHIPTO
      , COUNTRY_VAT_BILLTO
      , COUNTRY_VAT_BILLFR
      , VAT_RGSTRN_SELLER
      , VAT_TXN_TYPE_CD
      , VAT_APPLICABILITY
      , TAX_CD_VAT
      , VAT_USE_ID
      , IST_TXN_FLG
      , VAT_CALC_TYPE
      , BUSINESS_UNIT_RTV
      , RTV_ID
      , RTV_LN_NBR
      , RTV_VERIFIED
      , SHIP_DATE
      , UNIT_PRC_TOL_L
      , PCT_UNIT_PRC_TOL_L
      , EXT_PRC_TOL_L
      , PCT_EXT_PRC_TOL_L
      , UNIT_PRC_TOL_BSE_L
      , EXT_PRC_TOL_BSE_L
      , RJCT_OVER_TOL_FLAG
      , REJECT_DAYS
      , TAX_VAT_FLG
      , TAX_FRGHT_FLG
      , TAX_MISC_FLG
      , TRFT_RULE_CD
      , QTY_RFQ
      , SHIP_ID_EST
      , X_VENDOR_SETID
      , X_VENDOR_ID
      , X_VNDR_LOC
      , FRT_CHRG_METHOD
      , FRT_CHRG_OVERRIDE
      , VAT_ROUND_RULE
      , REVISION
      , PUBLISHED_SHIPTO
      , BCKORD_ORG_SCHED
      , BUSINESS_UNIT_SS
      , AUC_ID
      , AUC_LINE_NBR
      , AUC_SCHED_NBR
      , USER_SCHED_CHAR1
      , CUSTOM_C100_C1
      , CUSTOM_C100_C2
      , CUSTOM_C100_C3
      , CUSTOM_DATE_C1
      , CUSTOM_DATE_C2
      , CUSTOM_C1_C
      , VAT_RVRSE_CHG_GDS
      , PRICE_INITIAL
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_RECORD_SOURCE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_pssch
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_pssch as (
    SELECT
        PO_ITEM_BK
      , PO_HEADER_BK
      , BUSINESS_UNIT
      , PO_ID
      , LINE_NBR
      , SCHED_NBR
      , CANCEL_STATUS
      , BAL_STATUS
      , CHANGE_STATUS
      , CHNG_ORD_SEQ
      , PRICE_PO
      , PRICE_PO_BSE
      , CUSTOM_PRICE
      , ZERO_PRICE_IND
      , DUE_DT
      , DUE_TIME
      , SHIPTO_SETID
      , SHIPTO_ID
      , ORIG_PROM_DT
      , QTY_PO
      , CURRENCY_CD
      , MERCHANDISE_AMT
      , CURRENCY_CD_BASE
      , MERCH_AMT_BSE
      , CONVERSION_RATE
      , FREIGHT_TERMS
      , SHIP_TYPE_ID
      , DISTRIB_MTHD_FLG
      , LIQUIDATE_METHOD
      , UNIT_PRC_TOL
      , UNIT_PRC_TOL_BSE
      , PCT_UNIT_PRC_TOL
      , EXT_PRC_TOL
      , EXT_PRC_TOL_BSE
      , PCT_EXT_PRC_TOL
      , QTY_RECV_TOL_PCT
      , PCT_UNDER_QTY
      , MATCH_STATUS_LN_PO
      , MATCH_LINE_OPT
      , BUSINESS_UNIT_OM
      , ORDER_NO
      , ORDER_INT_LINE_NO
      , SCHED_LINE_NBR
      , SHIP_TO_CUST_ID
      , BUSINESS_UNIT_IN
      , PRODUCTION_ID
      , OP_SEQUENCE
      , FROZEN_FLG
      , PLAN_CHANGE_FLG
      , NET_CHANGE_EP
      , WORK_ORDER_ID
      , CARRIER_ID
      , SUT_BASE_ID
      , TAX_CD_SUT
      , ULTIMATE_USE_CD
      , SUT_EXCPTN_TYPE
      , SUT_EXCPTN_CERTIF
      , SUT_APPLICABILITY
      , VAT_RCRD_INPT_FLG
      , VAT_RCRD_OUTPT_FLG
      , VAT_DCLRTN_POINT
      , VAT_CALC_GROSS_NET
      , VAT_CALC_FRGHT_FLG
      , VAT_CALC_MISC_FLG
      , VAT_RECALC_FLG
      , VAT_TREATMENT_GRP
      , VAT_TREATMENT
      , COUNTRY_LOC_BUYER
      , STATE_LOC_BUYER
      , COUNTRY_LOC_SELLER
      , STATE_LOC_SELLER
      , VAT_SVC_SUPPLY_FLG
      , VAT_SERVICE_TYPE
      , COUNTRY_VAT_PERFRM
      , STATE_VAT_PERFRM
      , COUNTRY_VAT_SUPPLY
      , STATE_VAT_SUPPLY
      , STATE_VAT_DEFAULT
      , STATE_SHIP_FROM
      , STATE_SHIP_TO
      , VAT_EXCPTN_TYPE
      , VAT_EXCPTN_CERTIF
      , COUNTRY_SHIP_TO
      , COUNTRY_SHIP_FROM
      , COUNTRY_VAT_SHIPTO
      , COUNTRY_VAT_BILLTO
      , COUNTRY_VAT_BILLFR
      , VAT_RGSTRN_SELLER
      , VAT_TXN_TYPE_CD
      , VAT_APPLICABILITY
      , TAX_CD_VAT
      , VAT_USE_ID
      , IST_TXN_FLG
      , VAT_CALC_TYPE
      , BUSINESS_UNIT_RTV
      , RTV_ID
      , RTV_LN_NBR
      , RTV_VERIFIED
      , SHIP_DATE
      , UNIT_PRC_TOL_L
      , PCT_UNIT_PRC_TOL_L
      , EXT_PRC_TOL_L
      , PCT_EXT_PRC_TOL_L
      , UNIT_PRC_TOL_BSE_L
      , EXT_PRC_TOL_BSE_L
      , RJCT_OVER_TOL_FLAG
      , REJECT_DAYS
      , TAX_VAT_FLG
      , TAX_FRGHT_FLG
      , TAX_MISC_FLG
      , TRFT_RULE_CD
      , QTY_RFQ
      , SHIP_ID_EST
      , X_VENDOR_SETID
      , X_VENDOR_ID
      , X_VNDR_LOC
      , FRT_CHRG_METHOD
      , FRT_CHRG_OVERRIDE
      , VAT_ROUND_RULE
      , REVISION
      , PUBLISHED_SHIPTO
      , BCKORD_ORG_SCHED
      , BUSINESS_UNIT_SS
      , AUC_ID
      , AUC_LINE_NBR
      , AUC_SCHED_NBR
      , USER_SCHED_CHAR1
      , CUSTOM_C100_C1
      , CUSTOM_C100_C2
      , CUSTOM_C100_C3
      , CUSTOM_DATE_C1
      , CUSTOM_DATE_C2
      , CUSTOM_C1_C
      , VAT_RVRSE_CHG_GDS
      , PRICE_INITIAL
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_RECORD_SOURCE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_pssch
)

, RENAME_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_pssch as (
    SELECT *
    FROM RENAME_pssch
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_PO_LINE_SHIP'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_pssch
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PO_ITEM_BK
        , PO_HEADER_BK
        , BUSINESS_UNIT
        , PO_ID
        , LINE_NBR
        , SCHED_NBR
        , CANCEL_STATUS
        , BAL_STATUS
        , CHANGE_STATUS
        , CHNG_ORD_SEQ
        , PRICE_PO
        , PRICE_PO_BSE
        , CUSTOM_PRICE
        , ZERO_PRICE_IND
        , DUE_DT
        , DUE_TIME
        , SHIPTO_SETID
        , SHIPTO_ID
        , ORIG_PROM_DT
        , QTY_PO
        , CURRENCY_CD
        , MERCHANDISE_AMT
        , CURRENCY_CD_BASE
        , MERCH_AMT_BSE
        , CONVERSION_RATE
        , FREIGHT_TERMS
        , SHIP_TYPE_ID
        , DISTRIB_MTHD_FLG
        , LIQUIDATE_METHOD
        , UNIT_PRC_TOL
        , UNIT_PRC_TOL_BSE
        , PCT_UNIT_PRC_TOL
        , EXT_PRC_TOL
        , EXT_PRC_TOL_BSE
        , PCT_EXT_PRC_TOL
        , QTY_RECV_TOL_PCT
        , PCT_UNDER_QTY
        , MATCH_STATUS_LN_PO
        , MATCH_LINE_OPT
        , BUSINESS_UNIT_OM
        , ORDER_NO
        , ORDER_INT_LINE_NO
        , SCHED_LINE_NBR
        , SHIP_TO_CUST_ID
        , BUSINESS_UNIT_IN
        , PRODUCTION_ID
        , OP_SEQUENCE
        , FROZEN_FLG
        , PLAN_CHANGE_FLG
        , NET_CHANGE_EP
        , WORK_ORDER_ID
        , CARRIER_ID
        , SUT_BASE_ID
        , TAX_CD_SUT
        , ULTIMATE_USE_CD
        , SUT_EXCPTN_TYPE
        , SUT_EXCPTN_CERTIF
        , SUT_APPLICABILITY
        , VAT_RCRD_INPT_FLG
        , VAT_RCRD_OUTPT_FLG
        , VAT_DCLRTN_POINT
        , VAT_CALC_GROSS_NET
        , VAT_CALC_FRGHT_FLG
        , VAT_CALC_MISC_FLG
        , VAT_RECALC_FLG
        , VAT_TREATMENT_GRP
        , VAT_TREATMENT
        , COUNTRY_LOC_BUYER
        , STATE_LOC_BUYER
        , COUNTRY_LOC_SELLER
        , STATE_LOC_SELLER
        , VAT_SVC_SUPPLY_FLG
        , VAT_SERVICE_TYPE
        , COUNTRY_VAT_PERFRM
        , STATE_VAT_PERFRM
        , COUNTRY_VAT_SUPPLY
        , STATE_VAT_SUPPLY
        , STATE_VAT_DEFAULT
        , STATE_SHIP_FROM
        , STATE_SHIP_TO
        , VAT_EXCPTN_TYPE
        , VAT_EXCPTN_CERTIF
        , COUNTRY_SHIP_TO
        , COUNTRY_SHIP_FROM
        , COUNTRY_VAT_SHIPTO
        , COUNTRY_VAT_BILLTO
        , COUNTRY_VAT_BILLFR
        , VAT_RGSTRN_SELLER
        , VAT_TXN_TYPE_CD
        , VAT_APPLICABILITY
        , TAX_CD_VAT
        , VAT_USE_ID
        , IST_TXN_FLG
        , VAT_CALC_TYPE
        , BUSINESS_UNIT_RTV
        , RTV_ID
        , RTV_LN_NBR
        , RTV_VERIFIED
        , SHIP_DATE
        , UNIT_PRC_TOL_L
        , PCT_UNIT_PRC_TOL_L
        , EXT_PRC_TOL_L
        , PCT_EXT_PRC_TOL_L
        , UNIT_PRC_TOL_BSE_L
        , EXT_PRC_TOL_BSE_L
        , RJCT_OVER_TOL_FLAG
        , REJECT_DAYS
        , TAX_VAT_FLG
        , TAX_FRGHT_FLG
        , TAX_MISC_FLG
        , TRFT_RULE_CD
        , QTY_RFQ
        , SHIP_ID_EST
        , X_VENDOR_SETID
        , X_VENDOR_ID
        , X_VNDR_LOC
        , FRT_CHRG_METHOD
        , FRT_CHRG_OVERRIDE
        , VAT_ROUND_RULE
        , REVISION
        , PUBLISHED_SHIPTO
        , BCKORD_ORG_SCHED
        , BUSINESS_UNIT_SS
        , AUC_ID
        , AUC_LINE_NBR
        , AUC_SCHED_NBR
        , USER_SCHED_CHAR1
        , CUSTOM_C100_C1
        , CUSTOM_C100_C2
        , CUSTOM_C100_C3
        , CUSTOM_DATE_C1
        , CUSTOM_DATE_C2
        , CUSTOM_C1_C
        , VAT_RVRSE_CHG_GDS
        , PRICE_INITIAL
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_RECORD_SOURCE
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_UNIT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PO_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LINE_NBR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CANCEL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(BAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(CHNG_ORD_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_PO::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_PO_BSE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(ZERO_PRICE_IND::text), '^^') 
            , '||', IFNULL(TRIM(DUE_DT::text), '^^') 
            , '||', IFNULL(TRIM(DUE_TIME::text), '^^') 
            , '||', IFNULL(TRIM(SHIPTO_SETID::text), '^^') 
            , '||', IFNULL(TRIM(SHIPTO_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_PROM_DT::text), '^^') 
            , '||', IFNULL(TRIM(QTY_PO::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CD::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANDISE_AMT::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CD_BASE::text), '^^') 
            , '||', IFNULL(TRIM(MERCH_AMT_BSE::text), '^^') 
            , '||', IFNULL(TRIM(CONVERSION_RATE::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_TERMS::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(DISTRIB_MTHD_FLG::text), '^^') 
            , '||', IFNULL(TRIM(LIQUIDATE_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_PRC_TOL::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_PRC_TOL_BSE::text), '^^') 
            , '||', IFNULL(TRIM(PCT_UNIT_PRC_TOL::text), '^^') 
            , '||', IFNULL(TRIM(EXT_PRC_TOL::text), '^^') 
            , '||', IFNULL(TRIM(EXT_PRC_TOL_BSE::text), '^^') 
            , '||', IFNULL(TRIM(PCT_EXT_PRC_TOL::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RECV_TOL_PCT::text), '^^') 
            , '||', IFNULL(TRIM(PCT_UNDER_QTY::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_STATUS_LN_PO::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_LINE_OPT::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_OM::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_NO::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_INT_LINE_NO::text), '^^') 
            , '||', IFNULL(TRIM(SCHED_LINE_NBR::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_CUST_ID::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_IN::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(OP_SEQUENCE::text), '^^') 
            , '||', IFNULL(TRIM(FROZEN_FLG::text), '^^') 
            , '||', IFNULL(TRIM(PLAN_CHANGE_FLG::text), '^^') 
            , '||', IFNULL(TRIM(NET_CHANGE_EP::text), '^^') 
            , '||', IFNULL(TRIM(WORK_ORDER_ID::text), '^^') 
            , '||', IFNULL(TRIM(CARRIER_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUT_BASE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CD_SUT::text), '^^') 
            , '||', IFNULL(TRIM(ULTIMATE_USE_CD::text), '^^') 
            , '||', IFNULL(TRIM(SUT_EXCPTN_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SUT_EXCPTN_CERTIF::text), '^^') 
            , '||', IFNULL(TRIM(SUT_APPLICABILITY::text), '^^') 
            , '||', IFNULL(TRIM(VAT_RCRD_INPT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VAT_RCRD_OUTPT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VAT_DCLRTN_POINT::text), '^^') 
            , '||', IFNULL(TRIM(VAT_CALC_GROSS_NET::text), '^^') 
            , '||', IFNULL(TRIM(VAT_CALC_FRGHT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VAT_CALC_MISC_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VAT_RECALC_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VAT_TREATMENT_GRP::text), '^^') 
            , '||', IFNULL(TRIM(VAT_TREATMENT::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_LOC_BUYER::text), '^^') 
            , '||', IFNULL(TRIM(STATE_LOC_BUYER::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_LOC_SELLER::text), '^^') 
            , '||', IFNULL(TRIM(STATE_LOC_SELLER::text), '^^') 
            , '||', IFNULL(TRIM(VAT_SVC_SUPPLY_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VAT_SERVICE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_VAT_PERFRM::text), '^^') 
            , '||', IFNULL(TRIM(STATE_VAT_PERFRM::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_VAT_SUPPLY::text), '^^') 
            , '||', IFNULL(TRIM(STATE_VAT_SUPPLY::text), '^^') 
            , '||', IFNULL(TRIM(STATE_VAT_DEFAULT::text), '^^') 
            , '||', IFNULL(TRIM(STATE_SHIP_FROM::text), '^^') 
            , '||', IFNULL(TRIM(STATE_SHIP_TO::text), '^^') 
            , '||', IFNULL(TRIM(VAT_EXCPTN_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_EXCPTN_CERTIF::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_SHIP_TO::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_SHIP_FROM::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_VAT_SHIPTO::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_VAT_BILLTO::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_VAT_BILLFR::text), '^^') 
            , '||', IFNULL(TRIM(VAT_RGSTRN_SELLER::text), '^^') 
            , '||', IFNULL(TRIM(VAT_TXN_TYPE_CD::text), '^^') 
            , '||', IFNULL(TRIM(VAT_APPLICABILITY::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CD_VAT::text), '^^') 
            , '||', IFNULL(TRIM(VAT_USE_ID::text), '^^') 
            , '||', IFNULL(TRIM(IST_TXN_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VAT_CALC_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_RTV::text), '^^') 
            , '||', IFNULL(TRIM(RTV_ID::text), '^^') 
            , '||', IFNULL(TRIM(RTV_LN_NBR::text), '^^') 
            , '||', IFNULL(TRIM(RTV_VERIFIED::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_DATE::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_PRC_TOL_L::text), '^^') 
            , '||', IFNULL(TRIM(PCT_UNIT_PRC_TOL_L::text), '^^') 
            , '||', IFNULL(TRIM(EXT_PRC_TOL_L::text), '^^') 
            , '||', IFNULL(TRIM(PCT_EXT_PRC_TOL_L::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_PRC_TOL_BSE_L::text), '^^') 
            , '||', IFNULL(TRIM(EXT_PRC_TOL_BSE_L::text), '^^') 
            , '||', IFNULL(TRIM(RJCT_OVER_TOL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(REJECT_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(TAX_VAT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(TAX_FRGHT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(TAX_MISC_FLG::text), '^^') 
            , '||', IFNULL(TRIM(TRFT_RULE_CD::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RFQ::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_ID_EST::text), '^^') 
            , '||', IFNULL(TRIM(X_VENDOR_SETID::text), '^^') 
            , '||', IFNULL(TRIM(X_VENDOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(X_VNDR_LOC::text), '^^') 
            , '||', IFNULL(TRIM(FRT_CHRG_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(FRT_CHRG_OVERRIDE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_ROUND_RULE::text), '^^') 
            , '||', IFNULL(TRIM(REVISION::text), '^^') 
            , '||', IFNULL(TRIM(PUBLISHED_SHIPTO::text), '^^') 
            , '||', IFNULL(TRIM(BCKORD_ORG_SCHED::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_SS::text), '^^') 
            , '||', IFNULL(TRIM(AUC_ID::text), '^^') 
            , '||', IFNULL(TRIM(AUC_LINE_NBR::text), '^^') 
            , '||', IFNULL(TRIM(AUC_SCHED_NBR::text), '^^') 
            , '||', IFNULL(TRIM(USER_SCHED_CHAR1::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_C1::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_C2::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_C3::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_DATE_C1::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_DATE_C2::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C1_C::text), '^^') 
            , '||', IFNULL(TRIM(VAT_RVRSE_CHG_GDS::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_INITIAL::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_RECORD_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_vendor_loc') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_VENDOR_LOC' )

/*
SRC_SRC            as ( SELECT * FROM lrsn_psft_sysadm.ps_vendor_loc )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        VNDR_LOC                                                     as                                   SUPPLIER_SITE_BK
      , VNDR_LOC
      , SETID
      , VENDOR_ID
      , VENDOR_ID                                                    as                                        SUPPLIER_BK
      , EFFDT
      , EFF_STATUS
      , CURRENCY_CD
      , CUR_RT_TYPE
      , FREIGHT_TERMS
      , SHIP_TYPE_ID
      , DISP_METHOD
      , PYMNT_TERMS_CD
      , PYMNT_TERMS_CD                                               as                                        PAYMENT_TERM_BK
      , MATCH_OPT_FLG
      , MATCH_CNTRL_ID
      , MATCH_OPT
      , ERS_ACTION
      , ERS_FLAG
      , VCHR_APPRVL_FLG
      , BUSPROCNAME
      , APPR_RULE_SET
      , BUYER_ID
      , REMIT_SETID
      , REMIT_VENDOR
      , REMIT_LOC
      , REMIT_ADDR_SEQ_NUM
      , ADDR_SEQ_NUM_ORDR
      , PRICE_SETID
      , PRICE_VENDOR
      , PRICE_LOC
      , RETURN_VENDOR
      , RET_ADDR_SEQ_NUM
      , DST_CNTRL_ID
      , PREFERRED_LANGUAGE
      , RFQ_DISP_MTHD
      , CNTRCT_DISP_MTHD
      , PRIMARY_VENDOR
      , PRIM_ADDR_SEQ_NUM
      , SHIPTO_ID
      , SUT_BASE_ID
      , SALETX_TOL_AMT
      , SALETX_TOL_CUR_CD
      , SALETX_TOL_PCT
      , SALETX_TOL_RT_TYPE
      , SALETX_CD_ERS
      , SALES_USE_TX_FLG
      , AUTO_ASN_FLG
      , SALETX_TOL_FLG
      , SHIP_LOC_FLG
      , WTHD_CD
      , WTHD_SW
      , DOC_TYPE
      , DOC_TYPE_FLG
      , RTV_DISPATCH_METH
      , RTV_NOTIFY_METH
      , RTV_DEBIT_OPT
      , VNDR_SBI_FLG
      , SBI_APPROVAL_FLG
      , ACCOUNT
      , ALTACCT
      , DEPTID
      , OPERATING_UNIT
      , PRODUCT
      , FUND_CODE
      , CLASS_FLD
      , PROGRAM_CODE
      , BUDGET_REF
      , AFFILIATE
      , AFFILIATE_INTRA1
      , AFFILIATE_INTRA2
      , CHARTFIELD1
      , CHARTFIELD2
      , CHARTFIELD3
      , PROJECT_ID
      , CONSIGNED_FLAG
      , VCHR_CONSIGN_OPT
      , BANK_ACCT_SEQ_NBR
      , ACCT_TEMPL_FLG
      , PAY_TRM_BSE_DT_DFT
      , RECV_ONLY_MTCH_FLG
      , VCHR_MTCH_ADJ_DFLT
      , ERS_INV_DT_OPT
      , ERS_INV_DT_DFLT
      , ERS_TAX_TYPE_DFLT
      , ERS_TAX_CD_OPT
      , LAST_SBI_NUM
      , SBI_DOC_DFLT
      , SBI_PRINT_OPT
      , VCHR_TAX_ADJ_DFT
      , RTV_VCHR_ADJ_DFLT
      , VAT_SUSPENSION_FLG
      , VAT_ROUND_RULE
      , REPL_DISP_METHOD
      , VNDR_UPN_FLG
      , DISP_CO_FLAG
      , DATE_CALC_BASIS
      , PAY_SCHEDULE_TYPE
      , FEDERAL_INDICATOR
      , TRADING_PARTNER
      , ALC
      , WORKFLOW_OPT
      , PHYSICAL_NATURE
      , VAT_SVC_PERFRM_FLG
      , ULTIMATE_USE_CD
      , ADDR_SEQ_NUM_SHFR
      , POA_REQUIRED
      , ACK_ALERT_DISP
      , ACK_ALERT_SHIP
      , POA_CO_REQUIRED
      , POA_TOL_FLAG
      , POA_SCHED_EARLY
      , POA_SCHED_LATE
      , POA_QTY_OVER
      , POA_QTY_UNDER
      , POA_PRICE_OVER
      , POA_PRICE_UNDER
      , CC_ACCEPT_CC
      , CC_DISP_OPTION
      , CC_ALLOW_OVERRIDE
      , CC_SECURITY_ID
      , CC_USE_FLAG
      , MATCH_DELAY_FLG
      , MATCH_DELAY_DAYS
      , DISBURSING_OFFICE
      , GEN_1099_RPT
      , SPLIT_PO_BY_SHIPTO
      , SPEEDCHART_KEY
      , ACCOUNT_CODE
      , UPN_TYPE_CD
      , DAYS_HRS_AFTER
      , DAYS_HRS_BEFORE
      , COMMENTS_2000
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
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
          SUPPLIER_SITE_BK
        , VNDR_LOC
        , SETID
        , VENDOR_ID
        , SUPPLIER_BK
        , EFFDT
        , EFF_STATUS
        , CURRENCY_CD
        , CUR_RT_TYPE
        , FREIGHT_TERMS
        , SHIP_TYPE_ID
        , DISP_METHOD
        , PYMNT_TERMS_CD
        , PAYMENT_TERM_BK
        , MATCH_OPT_FLG
        , MATCH_CNTRL_ID
        , MATCH_OPT
        , ERS_ACTION
        , ERS_FLAG
        , VCHR_APPRVL_FLG
        , BUSPROCNAME
        , APPR_RULE_SET
        , BUYER_ID
        , REMIT_SETID
        , REMIT_VENDOR
        , REMIT_LOC
        , REMIT_ADDR_SEQ_NUM
        , ADDR_SEQ_NUM_ORDR
        , PRICE_SETID
        , PRICE_VENDOR
        , PRICE_LOC
        , RETURN_VENDOR
        , RET_ADDR_SEQ_NUM
        , DST_CNTRL_ID
        , PREFERRED_LANGUAGE
        , RFQ_DISP_MTHD
        , CNTRCT_DISP_MTHD
        , PRIMARY_VENDOR
        , PRIM_ADDR_SEQ_NUM
        , SHIPTO_ID
        , SUT_BASE_ID
        , SALETX_TOL_AMT
        , SALETX_TOL_CUR_CD
        , SALETX_TOL_PCT
        , SALETX_TOL_RT_TYPE
        , SALETX_CD_ERS
        , SALES_USE_TX_FLG
        , AUTO_ASN_FLG
        , SALETX_TOL_FLG
        , SHIP_LOC_FLG
        , WTHD_CD
        , WTHD_SW
        , DOC_TYPE
        , DOC_TYPE_FLG
        , RTV_DISPATCH_METH
        , RTV_NOTIFY_METH
        , RTV_DEBIT_OPT
        , VNDR_SBI_FLG
        , SBI_APPROVAL_FLG
        , ACCOUNT
        , ALTACCT
        , DEPTID
        , OPERATING_UNIT
        , PRODUCT
        , FUND_CODE
        , CLASS_FLD
        , PROGRAM_CODE
        , BUDGET_REF
        , AFFILIATE
        , AFFILIATE_INTRA1
        , AFFILIATE_INTRA2
        , CHARTFIELD1
        , CHARTFIELD2
        , CHARTFIELD3
        , PROJECT_ID
        , CONSIGNED_FLAG
        , VCHR_CONSIGN_OPT
        , BANK_ACCT_SEQ_NBR
        , ACCT_TEMPL_FLG
        , PAY_TRM_BSE_DT_DFT
        , RECV_ONLY_MTCH_FLG
        , VCHR_MTCH_ADJ_DFLT
        , ERS_INV_DT_OPT
        , ERS_INV_DT_DFLT
        , ERS_TAX_TYPE_DFLT
        , ERS_TAX_CD_OPT
        , LAST_SBI_NUM
        , SBI_DOC_DFLT
        , SBI_PRINT_OPT
        , VCHR_TAX_ADJ_DFT
        , RTV_VCHR_ADJ_DFLT
        , VAT_SUSPENSION_FLG
        , VAT_ROUND_RULE
        , REPL_DISP_METHOD
        , VNDR_UPN_FLG
        , DISP_CO_FLAG
        , DATE_CALC_BASIS
        , PAY_SCHEDULE_TYPE
        , FEDERAL_INDICATOR
        , TRADING_PARTNER
        , ALC
        , WORKFLOW_OPT
        , PHYSICAL_NATURE
        , VAT_SVC_PERFRM_FLG
        , ULTIMATE_USE_CD
        , ADDR_SEQ_NUM_SHFR
        , POA_REQUIRED
        , ACK_ALERT_DISP
        , ACK_ALERT_SHIP
        , POA_CO_REQUIRED
        , POA_TOL_FLAG
        , POA_SCHED_EARLY
        , POA_SCHED_LATE
        , POA_QTY_OVER
        , POA_QTY_UNDER
        , POA_PRICE_OVER
        , POA_PRICE_UNDER
        , CC_ACCEPT_CC
        , CC_DISP_OPTION
        , CC_ALLOW_OVERRIDE
        , CC_SECURITY_ID
        , CC_USE_FLAG
        , MATCH_DELAY_FLG
        , MATCH_DELAY_DAYS
        , DISBURSING_OFFICE
        , GEN_1099_RPT
        , SPLIT_PO_BY_SHIPTO
        , SPEEDCHART_KEY
        , ACCOUNT_CODE
        , UPN_TYPE_CD
        , DAYS_HRS_AFTER
        , DAYS_HRS_BEFORE
        , COMMENTS_2000
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , LOAD_DTS
        , IFF(pymnt_terms_cd = '', '-2', CONCAT_WS('||', pymnt_terms_cd, BKCC)) AS DRVD_PAYMENT_TERM_BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VNDR_LOC as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_SITE_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_PAYMENT_TERM_BKCC as VARCHAR)),''), '^^')
        ))) as PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VENDOR_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VNDR_LOC as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PYMNT_TERMS_CD as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SUPPLIER_SITE_PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(SETID::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(EFFDT::text), '^^') 
            , '||', IFNULL(TRIM(EFF_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CD::text), '^^') 
            , '||', IFNULL(TRIM(CUR_RT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_TERMS::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(DISP_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(PYMNT_TERMS_CD::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_OPT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_CNTRL_ID::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_OPT::text), '^^') 
            , '||', IFNULL(TRIM(ERS_ACTION::text), '^^') 
            , '||', IFNULL(TRIM(ERS_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(VCHR_APPRVL_FLG::text), '^^') 
            , '||', IFNULL(TRIM(BUSPROCNAME::text), '^^') 
            , '||', IFNULL(TRIM(APPR_RULE_SET::text), '^^') 
            , '||', IFNULL(TRIM(BUYER_ID::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_SETID::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_VENDOR::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_LOC::text), '^^') 
            , '||', IFNULL(TRIM(REMIT_ADDR_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(ADDR_SEQ_NUM_ORDR::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_SETID::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_VENDOR::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_LOC::text), '^^') 
            , '||', IFNULL(TRIM(RETURN_VENDOR::text), '^^') 
            , '||', IFNULL(TRIM(RET_ADDR_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(DST_CNTRL_ID::text), '^^') 
            , '||', IFNULL(TRIM(PREFERRED_LANGUAGE::text), '^^') 
            , '||', IFNULL(TRIM(RFQ_DISP_MTHD::text), '^^') 
            , '||', IFNULL(TRIM(CNTRCT_DISP_MTHD::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_VENDOR::text), '^^') 
            , '||', IFNULL(TRIM(PRIM_ADDR_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(SHIPTO_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUT_BASE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SALETX_TOL_AMT::text), '^^') 
            , '||', IFNULL(TRIM(SALETX_TOL_CUR_CD::text), '^^') 
            , '||', IFNULL(TRIM(SALETX_TOL_PCT::text), '^^') 
            , '||', IFNULL(TRIM(SALETX_TOL_RT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SALETX_CD_ERS::text), '^^') 
            , '||', IFNULL(TRIM(SALES_USE_TX_FLG::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_ASN_FLG::text), '^^') 
            , '||', IFNULL(TRIM(SALETX_TOL_FLG::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_LOC_FLG::text), '^^') 
            , '||', IFNULL(TRIM(WTHD_CD::text), '^^') 
            , '||', IFNULL(TRIM(WTHD_SW::text), '^^') 
            , '||', IFNULL(TRIM(DOC_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(DOC_TYPE_FLG::text), '^^') 
            , '||', IFNULL(TRIM(RTV_DISPATCH_METH::text), '^^') 
            , '||', IFNULL(TRIM(RTV_NOTIFY_METH::text), '^^') 
            , '||', IFNULL(TRIM(RTV_DEBIT_OPT::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_SBI_FLG::text), '^^') 
            , '||', IFNULL(TRIM(SBI_APPROVAL_FLG::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ALTACCT::text), '^^') 
            , '||', IFNULL(TRIM(DEPTID::text), '^^') 
            , '||', IFNULL(TRIM(OPERATING_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT::text), '^^') 
            , '||', IFNULL(TRIM(FUND_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CLASS_FLD::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_CODE::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_REF::text), '^^') 
            , '||', IFNULL(TRIM(AFFILIATE::text), '^^') 
            , '||', IFNULL(TRIM(AFFILIATE_INTRA1::text), '^^') 
            , '||', IFNULL(TRIM(AFFILIATE_INTRA2::text), '^^') 
            , '||', IFNULL(TRIM(CHARTFIELD1::text), '^^') 
            , '||', IFNULL(TRIM(CHARTFIELD2::text), '^^') 
            , '||', IFNULL(TRIM(CHARTFIELD3::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CONSIGNED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(VCHR_CONSIGN_OPT::text), '^^') 
            , '||', IFNULL(TRIM(BANK_ACCT_SEQ_NBR::text), '^^') 
            , '||', IFNULL(TRIM(ACCT_TEMPL_FLG::text), '^^') 
            , '||', IFNULL(TRIM(PAY_TRM_BSE_DT_DFT::text), '^^') 
            , '||', IFNULL(TRIM(RECV_ONLY_MTCH_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VCHR_MTCH_ADJ_DFLT::text), '^^') 
            , '||', IFNULL(TRIM(ERS_INV_DT_OPT::text), '^^') 
            , '||', IFNULL(TRIM(ERS_INV_DT_DFLT::text), '^^') 
            , '||', IFNULL(TRIM(ERS_TAX_TYPE_DFLT::text), '^^') 
            , '||', IFNULL(TRIM(ERS_TAX_CD_OPT::text), '^^') 
            , '||', IFNULL(TRIM(LAST_SBI_NUM::text), '^^') 
            , '||', IFNULL(TRIM(SBI_DOC_DFLT::text), '^^') 
            , '||', IFNULL(TRIM(SBI_PRINT_OPT::text), '^^') 
            , '||', IFNULL(TRIM(VCHR_TAX_ADJ_DFT::text), '^^') 
            , '||', IFNULL(TRIM(RTV_VCHR_ADJ_DFLT::text), '^^') 
            , '||', IFNULL(TRIM(VAT_SUSPENSION_FLG::text), '^^') 
            , '||', IFNULL(TRIM(VAT_ROUND_RULE::text), '^^') 
            , '||', IFNULL(TRIM(REPL_DISP_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_UPN_FLG::text), '^^') 
            , '||', IFNULL(TRIM(DISP_CO_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DATE_CALC_BASIS::text), '^^') 
            , '||', IFNULL(TRIM(PAY_SCHEDULE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(FEDERAL_INDICATOR::text), '^^') 
            , '||', IFNULL(TRIM(TRADING_PARTNER::text), '^^') 
            , '||', IFNULL(TRIM(ALC::text), '^^') 
            , '||', IFNULL(TRIM(WORKFLOW_OPT::text), '^^') 
            , '||', IFNULL(TRIM(PHYSICAL_NATURE::text), '^^') 
            , '||', IFNULL(TRIM(VAT_SVC_PERFRM_FLG::text), '^^') 
            , '||', IFNULL(TRIM(ULTIMATE_USE_CD::text), '^^') 
            , '||', IFNULL(TRIM(ADDR_SEQ_NUM_SHFR::text), '^^') 
            , '||', IFNULL(TRIM(POA_REQUIRED::text), '^^') 
            , '||', IFNULL(TRIM(ACK_ALERT_DISP::text), '^^') 
            , '||', IFNULL(TRIM(ACK_ALERT_SHIP::text), '^^') 
            , '||', IFNULL(TRIM(POA_CO_REQUIRED::text), '^^') 
            , '||', IFNULL(TRIM(POA_TOL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(POA_SCHED_EARLY::text), '^^') 
            , '||', IFNULL(TRIM(POA_SCHED_LATE::text), '^^') 
            , '||', IFNULL(TRIM(POA_QTY_OVER::text), '^^') 
            , '||', IFNULL(TRIM(POA_QTY_UNDER::text), '^^') 
            , '||', IFNULL(TRIM(POA_PRICE_OVER::text), '^^') 
            , '||', IFNULL(TRIM(POA_PRICE_UNDER::text), '^^') 
            , '||', IFNULL(TRIM(CC_ACCEPT_CC::text), '^^') 
            , '||', IFNULL(TRIM(CC_DISP_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(CC_ALLOW_OVERRIDE::text), '^^') 
            , '||', IFNULL(TRIM(CC_SECURITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(CC_USE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_DELAY_FLG::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_DELAY_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(DISBURSING_OFFICE::text), '^^') 
            , '||', IFNULL(TRIM(GEN_1099_RPT::text), '^^') 
            , '||', IFNULL(TRIM(SPLIT_PO_BY_SHIPTO::text), '^^') 
            , '||', IFNULL(TRIM(SPEEDCHART_KEY::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(UPN_TYPE_CD::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_HRS_AFTER::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_HRS_BEFORE::text), '^^') 
            , '||', IFNULL(TRIM(COMMENTS_2000::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

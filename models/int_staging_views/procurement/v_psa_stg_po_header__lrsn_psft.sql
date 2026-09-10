---- SRC LAYER ----
WITH
SRC_ps_po_hdr      as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_po_hdr') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_ps_po_hdr      as ( SELECT * FROM lrsn_psft_sysadm.ps_po_hdr )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_ps_po_hdr as (
    SELECT
        CONCAT_WS('||', BUSINESS_UNIT,PO_ID)                         as                                       PO_HEADER_BK
      , BUSINESS_UNIT
      , PO_ID
      , CHNG_ORD_BATCH
      , PO_TYPE
      , PO_STATUS
      , HOLD_STATUS
      , RECV_STATUS
      , DISP_ACTION
      , DISP_METHOD
      , CHANGE_STATUS
      , PO_DT
      , PO_REF
      , VENDOR_SETID
      , VENDOR_ID
      , VNDR_LOC
      , PRICE_SETID
      , PRICE_VENDOR
      , PRICE_LOC
      , PYMNT_TERMS_CD
      , BUYER_ID
      , ORIGIN
      , CHNG_ORD_SEQ
      , ADDRESS_SEQ_NUM
      , CNTCT_SEQ_NUM
      , SALES_CNTCT_SEQ_N
      , BILL_LOCATION
      , TAX_EXEMPT
      , TAX_EXEMPT_ID
      , CURRENCY_CD
      , RT_TYPE
      , MATCH_ACTION
      , MATCH_CNTRL_ID
      , MATCH_STATUS_PO
      , MATCH_PROCESS_FLG
      , PROCESS_INSTANCE
      , APPL_JRNL_ID_ENC
      , POST_DOC
      , DST_CNTRL_ID
      , OPRID_ENTERED_BY
      , ENTERED_DT
      , OPRID_APPROVED_BY
      , APPROVAL_DT
      , OPRID_MODIFIED_BY
      , LAST_DTTM_UPDATE
      , ACCOUNTING_DT
      , BUSINESS_UNIT_GL
      , IN_PROCESS_FLG
      , ACTIVITY_DATE
      , PO_POST_STATUS
      , NEXT_MOD_SEQ_NBR
      , ERS_ACTION
      , ACCRUE_USE_TAX
      , CURRENCY_CD_BASE
      , RATE_DATE
      , RATE_MULT
      , RATE_DIV
      , VAT_ENTITY
      , BUDGET_HDR_STATUS
      , KK_AMOUNT_TYPE
      , KK_TRAN_OVER_FLAG
      , KK_TRAN_OVER_OPRID
      , KK_TRAN_OVER_DTTM
      , LC_ID
      , BUDGET_HDR_STS_NP
      , PREPAID_PO_FLG
      , PREPAID_AMT
      , PREPAID_AUTH_STAT
      , PREPAID_STATUS_PO
      , PAY_TRM_BSE_DT_OPT
      , TERMS_BASIS_DT
      , BACKORDER_STATUS
      , DOC_TOL_HDR_STATUS
      , MID_ROLL_STATUS
      , USER_HDR_CHAR1
      , CUSTOM_C100_A1
      , CUSTOM_C100_A2
      , CUSTOM_C100_A3
      , CUSTOM_C100_A4
      , CUSTOM_DATE_A
      , CUSTOM_C1_A
      , BUDGET_CHECK
      , POA_STATUS
      , POA_REQS
      , CC_SECURITY_ID
      , CC_USE_FLAG
      , CC_DISP_OPTION
      , CONTACT_NAME
      , CONTACT_PHONE
      , TEXT254_CC2
      , TMPLDEFN_ID
      , SPLIT_PO_BY_SHIPTO
      , EE_SEQ_NUM
      , PROCURE_INSTRUM_ID
      , PI_ID_PARENT
      , UNIVERSAL_REC_ID
      , FEDERAL_AWARD_ID
      , EXCLUDE_REPORTING
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_ps_po_hdr
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_ps_po_hdr as (
    SELECT
        PO_HEADER_BK
      , BUSINESS_UNIT
      , PO_ID
      , CHNG_ORD_BATCH
      , PO_TYPE
      , PO_STATUS
      , HOLD_STATUS
      , RECV_STATUS
      , DISP_ACTION
      , DISP_METHOD
      , CHANGE_STATUS
      , PO_DT
      , PO_REF
      , VENDOR_SETID
      , VENDOR_ID
      , VNDR_LOC
      , PRICE_SETID
      , PRICE_VENDOR
      , PRICE_LOC
      , PYMNT_TERMS_CD
      , BUYER_ID
      , ORIGIN
      , CHNG_ORD_SEQ
      , ADDRESS_SEQ_NUM
      , CNTCT_SEQ_NUM
      , SALES_CNTCT_SEQ_N
      , BILL_LOCATION
      , TAX_EXEMPT
      , TAX_EXEMPT_ID
      , CURRENCY_CD
      , RT_TYPE
      , MATCH_ACTION
      , MATCH_CNTRL_ID
      , MATCH_STATUS_PO
      , MATCH_PROCESS_FLG
      , PROCESS_INSTANCE
      , APPL_JRNL_ID_ENC
      , POST_DOC
      , DST_CNTRL_ID
      , OPRID_ENTERED_BY
      , ENTERED_DT
      , OPRID_APPROVED_BY
      , APPROVAL_DT
      , OPRID_MODIFIED_BY
      , LAST_DTTM_UPDATE
      , ACCOUNTING_DT
      , BUSINESS_UNIT_GL
      , IN_PROCESS_FLG
      , ACTIVITY_DATE
      , PO_POST_STATUS
      , NEXT_MOD_SEQ_NBR
      , ERS_ACTION
      , ACCRUE_USE_TAX
      , CURRENCY_CD_BASE
      , RATE_DATE
      , RATE_MULT
      , RATE_DIV
      , VAT_ENTITY
      , BUDGET_HDR_STATUS
      , KK_AMOUNT_TYPE
      , KK_TRAN_OVER_FLAG
      , KK_TRAN_OVER_OPRID
      , KK_TRAN_OVER_DTTM
      , LC_ID
      , BUDGET_HDR_STS_NP
      , PREPAID_PO_FLG
      , PREPAID_AMT
      , PREPAID_AUTH_STAT
      , PREPAID_STATUS_PO
      , PAY_TRM_BSE_DT_OPT
      , TERMS_BASIS_DT
      , BACKORDER_STATUS
      , DOC_TOL_HDR_STATUS
      , MID_ROLL_STATUS
      , USER_HDR_CHAR1
      , CUSTOM_C100_A1
      , CUSTOM_C100_A2
      , CUSTOM_C100_A3
      , CUSTOM_C100_A4
      , CUSTOM_DATE_A
      , CUSTOM_C1_A
      , BUDGET_CHECK
      , POA_STATUS
      , POA_REQS
      , CC_SECURITY_ID
      , CC_USE_FLAG
      , CC_DISP_OPTION
      , CONTACT_NAME
      , CONTACT_PHONE
      , TEXT254_CC2
      , TMPLDEFN_ID
      , SPLIT_PO_BY_SHIPTO
      , EE_SEQ_NUM
      , PROCURE_INSTRUM_ID
      , PI_ID_PARENT
      , UNIVERSAL_REC_ID
      , FEDERAL_AWARD_ID
      , EXCLUDE_REPORTING
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_ps_po_hdr
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_ps_po_hdr as (
    SELECT *
    FROM RENAME_ps_po_hdr
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_PO_HDR'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_ps_po_hdr
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PO_HEADER_BK
        , BUSINESS_UNIT
        , PO_ID
        , CHNG_ORD_BATCH
        , PO_TYPE
        , PO_STATUS
        , HOLD_STATUS
        , RECV_STATUS
        , DISP_ACTION
        , DISP_METHOD
        , CHANGE_STATUS
        , PO_DT
        , PO_REF
        , VENDOR_SETID
        , VENDOR_ID
        , VNDR_LOC
        , PRICE_SETID
        , PRICE_VENDOR
        , PRICE_LOC
        , PYMNT_TERMS_CD
        , BUYER_ID
        , ORIGIN
        , CHNG_ORD_SEQ
        , ADDRESS_SEQ_NUM
        , CNTCT_SEQ_NUM
        , SALES_CNTCT_SEQ_N
        , BILL_LOCATION
        , TAX_EXEMPT
        , TAX_EXEMPT_ID
        , CURRENCY_CD
        , RT_TYPE
        , MATCH_ACTION
        , MATCH_CNTRL_ID
        , MATCH_STATUS_PO
        , MATCH_PROCESS_FLG
        , PROCESS_INSTANCE
        , APPL_JRNL_ID_ENC
        , POST_DOC
        , DST_CNTRL_ID
        , OPRID_ENTERED_BY
        , ENTERED_DT
        , OPRID_APPROVED_BY
        , APPROVAL_DT
        , OPRID_MODIFIED_BY
        , LAST_DTTM_UPDATE
        , ACCOUNTING_DT
        , BUSINESS_UNIT_GL
        , IN_PROCESS_FLG
        , ACTIVITY_DATE
        , PO_POST_STATUS
        , NEXT_MOD_SEQ_NBR
        , ERS_ACTION
        , ACCRUE_USE_TAX
        , CURRENCY_CD_BASE
        , RATE_DATE
        , RATE_MULT
        , RATE_DIV
        , VAT_ENTITY
        , BUDGET_HDR_STATUS
        , KK_AMOUNT_TYPE
        , KK_TRAN_OVER_FLAG
        , KK_TRAN_OVER_OPRID
        , KK_TRAN_OVER_DTTM
        , LC_ID
        , BUDGET_HDR_STS_NP
        , PREPAID_PO_FLG
        , PREPAID_AMT
        , PREPAID_AUTH_STAT
        , PREPAID_STATUS_PO
        , PAY_TRM_BSE_DT_OPT
        , TERMS_BASIS_DT
        , BACKORDER_STATUS
        , DOC_TOL_HDR_STATUS
        , MID_ROLL_STATUS
        , USER_HDR_CHAR1
        , CUSTOM_C100_A1
        , CUSTOM_C100_A2
        , CUSTOM_C100_A3
        , CUSTOM_C100_A4
        , CUSTOM_DATE_A
        , CUSTOM_C1_A
        , BUDGET_CHECK
        , POA_STATUS
        , POA_REQS
        , CC_SECURITY_ID
        , CC_USE_FLAG
        , CC_DISP_OPTION
        , CONTACT_NAME
        , CONTACT_PHONE
        , TEXT254_CC2
        , TMPLDEFN_ID
        , SPLIT_PO_BY_SHIPTO
        , EE_SEQ_NUM
        , PROCURE_INSTRUM_ID
        , PI_ID_PARENT
        , UNIVERSAL_REC_ID
        , FEDERAL_AWARD_ID
        , EXCLUDE_REPORTING
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_UNIT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PO_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CHNG_ORD_BATCH::text), '^^') 
            , '||', IFNULL(TRIM(PO_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PO_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(RECV_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(DISP_ACTION::text), '^^') 
            , '||', IFNULL(TRIM(DISP_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PO_DT::text), '^^') 
            , '||', IFNULL(TRIM(PO_REF::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_SETID::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(VNDR_LOC::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_SETID::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_VENDOR::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_LOC::text), '^^') 
            , '||', IFNULL(TRIM(PYMNT_TERMS_CD::text), '^^') 
            , '||', IFNULL(TRIM(BUYER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORIGIN::text), '^^') 
            , '||', IFNULL(TRIM(CHNG_ORD_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(CNTCT_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(SALES_CNTCT_SEQ_N::text), '^^') 
            , '||', IFNULL(TRIM(BILL_LOCATION::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPT::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPT_ID::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CD::text), '^^') 
            , '||', IFNULL(TRIM(RT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_ACTION::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_CNTRL_ID::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_STATUS_PO::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_PROCESS_FLG::text), '^^') 
            , '||', IFNULL(TRIM(PROCESS_INSTANCE::text), '^^') 
            , '||', IFNULL(TRIM(APPL_JRNL_ID_ENC::text), '^^') 
            , '||', IFNULL(TRIM(POST_DOC::text), '^^') 
            , '||', IFNULL(TRIM(DST_CNTRL_ID::text), '^^') 
            , '||', IFNULL(TRIM(OPRID_ENTERED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ENTERED_DT::text), '^^') 
            , '||', IFNULL(TRIM(OPRID_APPROVED_BY::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_DT::text), '^^') 
            , '||', IFNULL(TRIM(OPRID_MODIFIED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_DTTM_UPDATE::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNTING_DT::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_GL::text), '^^') 
            , '||', IFNULL(TRIM(IN_PROCESS_FLG::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVITY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PO_POST_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(NEXT_MOD_SEQ_NBR::text), '^^') 
            , '||', IFNULL(TRIM(ERS_ACTION::text), '^^') 
            , '||', IFNULL(TRIM(ACCRUE_USE_TAX::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CD_BASE::text), '^^') 
            , '||', IFNULL(TRIM(RATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(RATE_MULT::text), '^^') 
            , '||', IFNULL(TRIM(RATE_DIV::text), '^^') 
            , '||', IFNULL(TRIM(VAT_ENTITY::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_HDR_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(KK_AMOUNT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(KK_TRAN_OVER_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(KK_TRAN_OVER_OPRID::text), '^^') 
            , '||', IFNULL(TRIM(KK_TRAN_OVER_DTTM::text), '^^') 
            , '||', IFNULL(TRIM(LC_ID::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_HDR_STS_NP::text), '^^') 
            , '||', IFNULL(TRIM(PREPAID_PO_FLG::text), '^^') 
            , '||', IFNULL(TRIM(PREPAID_AMT::text), '^^') 
            , '||', IFNULL(TRIM(PREPAID_AUTH_STAT::text), '^^') 
            , '||', IFNULL(TRIM(PREPAID_STATUS_PO::text), '^^') 
            , '||', IFNULL(TRIM(PAY_TRM_BSE_DT_OPT::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_BASIS_DT::text), '^^') 
            , '||', IFNULL(TRIM(BACKORDER_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(DOC_TOL_HDR_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(MID_ROLL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(USER_HDR_CHAR1::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_A1::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_A2::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_A3::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_A4::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_DATE_A::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C1_A::text), '^^') 
            , '||', IFNULL(TRIM(BUDGET_CHECK::text), '^^') 
            , '||', IFNULL(TRIM(POA_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(POA_REQS::text), '^^') 
            , '||', IFNULL(TRIM(CC_SECURITY_ID::text), '^^') 
            , '||', IFNULL(TRIM(CC_USE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CC_DISP_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(CONTACT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CONTACT_PHONE::text), '^^') 
            , '||', IFNULL(TRIM(TEXT254_CC2::text), '^^') 
            , '||', IFNULL(TRIM(TMPLDEFN_ID::text), '^^') 
            , '||', IFNULL(TRIM(SPLIT_PO_BY_SHIPTO::text), '^^') 
            , '||', IFNULL(TRIM(EE_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(PROCURE_INSTRUM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PI_ID_PARENT::text), '^^') 
            , '||', IFNULL(TRIM(UNIVERSAL_REC_ID::text), '^^') 
            , '||', IFNULL(TRIM(FEDERAL_AWARD_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXCLUDE_REPORTING::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

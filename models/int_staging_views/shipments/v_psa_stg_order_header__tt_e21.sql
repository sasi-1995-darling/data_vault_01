---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('tt_e21prd_e21trubis', 'ordhead') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT 
           _FIVETRAN_ID           
        , CONCAT_WS('||', COALESCE(ORDER_NUMB, ''), COALESCE(REL_NUMB, ''))    as                                      ORDER_HEADER_BK 
        , ORIG_GEOCODE
        , PRICEID
        , CUSTV2
        , CUSTV1
        , ORDER_STAT
        , CARD_TRANS_ID
        , REGREL_USER
        , SHIPCNTRY
        , FRT_PAY_MTH
        , CONSOL_NUMB
        , INVOICE_DATE
        , SHIPTO_CODE
        , PROJID
        , HOLD_CODE
        , TAX_EXEMPT_ID
        , CUSTF2
        , CUSTF1
        , SHIPNAME
        , RET_INST_FLAG
        , ORDFRMGEOCODE
        , DIVISION_CODE
        , ORDER_CALLER
        , LCHFLD2
       ,  HANDLING_CHRG
        , LCHFLD1
        , LCHFLD4
        , SHIPGEOCODE
        , LCHFLD3
        , BO_RULE
        , TRANSINS_FLAG
        , SHIPST
        , ORDFRMPHONE
        , SHIPCOUNTRY
        , DUEOUT_TIME
        , NOTES1
        , DEPARTMENT
        , BILLMI
        , NOTES2
        , LCHFLD5
        , ACK_PRNT_METH
        , DISCNT
        , ORDER_BY
        , DATE_INV_PRINT
        , CANCEL_DATE
        , STOPCHG
        , CUST_NAME_QUAL
        , BILLCITY
        , REL_CREDIT
        , ACK_FLAG
       ,  ORDFRMST
        , REP2_PCT
        , CARD_TYPE
        , VOLDIS_SO
        , FOB_CODE
        , CARD_APPROVAL
        , JOB_CODE
        , DATE_INV
        , TOTDISC
        , USER_SO
        , CUST_CODE
        , MET_OF_SHIP
        , CARD_USER_NAME
        , BILLST
        , SHIPMI
        , CHGUSER
        , VTXCITY
        , TOTTAX
        , ORDFRMCOUNTRY
        , REGREL_DATE
        , BANK_ABA_CODE
        , ORDER_TYPE
        , SHIPCHG
        , CUST_PO
        , ORIG_REL_NUMB
        , CARR_CODE
       ,  REP1
        , REP2
        , ORDFRMMI
        , BILLCOUNTRY
        , SHIPCITY
        , BANK_ACCT
        , STEP_CODE
        , DATE_INVOICE
        , DATE_ENTERED
        , ORDFRMNAME
        , QUOTE_NUMB
        , ORDER_TERMS
        , PAY_TYPE
        , UPDATE_DATE
        , DUETIME
        , EFFDATE
        , DTFLD1
        , NUMFLD1
        , NUMFLD2
        , PRIORITY
        , NUMFLD3
        , DTFLD4
        , BILLTO_CODE
        , NUMFLD4
        , NUMFLD5
        , NUMFLD6
       ,  DTFLD2
        , DTFLD3
        , CARD_RESP_TEXT
        , SOURCE_CODE
        , MISCCHG
        , CUST_REQ_DATE
        , PHASE_NO
        , ALLOC_LOCK
        , DUEDATE
        , EXPIRE_DATE
        , TAXRATE
        , SHIPQUALIFIER
        , ORDER_CLASS
        , SCHFLD6
        , ORDER_DATE
        , BILLZIP
        , TOTSALES
        , BID_NO
        , ORDFRMCITY
        , BILLNAME
        , SHIPPHONE
        , ALLOC_STAT
        , ACK_PRNT_DATE
        , UTILCHG
        , REQ_NUMBER
       ,  DATE_CUST
        , SCHFLD1
        , SHIPFNAME
        , BILLQUALIFIER
        , SCHFLD3
        , SCHFLD2
        , BANK_ACCT_TYPE
        , SCHFLD5
        , CARD_EXP_DATE
        , SCHFLD4
        , TAXFLG
        , BILTYPE_SO
        , ORDFRMQUALIFIER
        , REP1_PCT
        , DOC_IMAGE_NUMB
        , DUEOUT_DATE
        , BILLPHONE
        , ORIG_ORDER_NUMB
        , GIFT_FLAG
        , CONTRACT_NO
        , CARD_NUMBER
        , ORDFRMADD3
        , ORDFRMADD1
        , ORDFRMADD2
        , SHIPADD2
       ,  SHIPADD1
        , SHIPADD3
        , VTXST
        , TAXDIST
        , CHARGED_FRT
        , ORDFRMZIP
        , DATE_ALLOC
        , BO_DATE
        , BILLADD1
        , COST_CTR
        , SHIPZIP
        , BILLADD2
        , MID_INITAL
        , BILLADD3
        , SHIPTO_PO
        , ORDER_SOURCE
        , AUTO_CONSOL
        , PROMO_CODE
        , SPDRCHG
        , DOC_IMAGE_FOLDER
        , CHGSTAT
        , DOC_IMAGE_PAGE
        , VTXCOUNTY
        , CUST_NAME
        , BANK_NAME
        , _FIVETRAN_DELETED
        , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
    FROM  SRC_S 
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
          _FIVETRAN_ID  
        , ORDER_HEADER_BK
        , ORIG_GEOCODE
        , PRICEID
        , CUSTV2
        , CUSTV1
        , ORDER_STAT
        , CARD_TRANS_ID
        , REGREL_USER
        , SHIPCNTRY
        , FRT_PAY_MTH
        , CONSOL_NUMB
        , INVOICE_DATE
        , SHIPTO_CODE
        , PROJID
        , HOLD_CODE
        , TAX_EXEMPT_ID
        , CUSTF2
        , CUSTF1
        , SHIPNAME
        , RET_INST_FLAG
        , ORDFRMGEOCODE
        , DIVISION_CODE
        , ORDER_CALLER
        , LCHFLD2
       ,  HANDLING_CHRG
        , LCHFLD1
        , LCHFLD4
        , SHIPGEOCODE
        , LCHFLD3
        , BO_RULE
        , TRANSINS_FLAG
        , SHIPST
        , ORDFRMPHONE
        , SHIPCOUNTRY
        , DUEOUT_TIME
        , NOTES1
        , DEPARTMENT
        , BILLMI
        , NOTES2
        , LCHFLD5
        , ACK_PRNT_METH
        , DISCNT
        , ORDER_BY
        , DATE_INV_PRINT
        , CANCEL_DATE
        , STOPCHG
        , CUST_NAME_QUAL
        , BILLCITY
        , REL_CREDIT
        , ACK_FLAG
       ,  ORDFRMST
        , REP2_PCT
        , CARD_TYPE
        , VOLDIS_SO
        , FOB_CODE
        , CARD_APPROVAL
        , JOB_CODE
        , DATE_INV
        , TOTDISC
        , USER_SO
        , CUST_CODE
        , MET_OF_SHIP
        , CARD_USER_NAME
        , BILLST
        , SHIPMI
        , CHGUSER
        , VTXCITY
        , TOTTAX
        , ORDFRMCOUNTRY
        , REGREL_DATE
        , BANK_ABA_CODE
        , ORDER_TYPE
        , SHIPCHG
        , CUST_PO
        , ORIG_REL_NUMB
        , CARR_CODE
       ,  REP1
        , REP2
        , ORDFRMMI
        , BILLCOUNTRY
        , SHIPCITY
        , BANK_ACCT
        , STEP_CODE
        , DATE_INVOICE
        , DATE_ENTERED
        , ORDFRMNAME
        , QUOTE_NUMB
        , ORDER_TERMS
        , PAY_TYPE
        , UPDATE_DATE
        , DUETIME
        , EFFDATE
        , DTFLD1
        , NUMFLD1
        , NUMFLD2
        , PRIORITY
        , NUMFLD3
        , DTFLD4
        , BILLTO_CODE
        , NUMFLD4
        , NUMFLD5
        , NUMFLD6
       ,  DTFLD2
        , DTFLD3
        , CARD_RESP_TEXT
        , SOURCE_CODE
        , MISCCHG
        , CUST_REQ_DATE
        , PHASE_NO
        , ALLOC_LOCK
        , DUEDATE
        , EXPIRE_DATE
        , TAXRATE
        , SHIPQUALIFIER
        , ORDER_CLASS
        , SCHFLD6
        , ORDER_DATE
        , BILLZIP
        , TOTSALES
        , BID_NO
        , ORDFRMCITY
        , BILLNAME
        , SHIPPHONE
        , ALLOC_STAT
        , ACK_PRNT_DATE
        , UTILCHG
        , REQ_NUMBER
       ,  DATE_CUST
        , SCHFLD1
        , SHIPFNAME
        , BILLQUALIFIER
        , SCHFLD3
        , SCHFLD2
        , BANK_ACCT_TYPE
        , SCHFLD5
        , CARD_EXP_DATE
        , SCHFLD4
        , TAXFLG
        , BILTYPE_SO
        , ORDFRMQUALIFIER
        , REP1_PCT
        , DOC_IMAGE_NUMB
        , DUEOUT_DATE
        , BILLPHONE
        , ORIG_ORDER_NUMB
        , GIFT_FLAG
        , CONTRACT_NO
        , CARD_NUMBER
        , ORDFRMADD3
        , ORDFRMADD1
        , ORDFRMADD2
        , SHIPADD2
       ,  SHIPADD1
        , SHIPADD3
        , VTXST
        , TAXDIST
        , CHARGED_FRT
        , ORDFRMZIP
        , DATE_ALLOC
        , BO_DATE
        , BILLADD1
        , COST_CTR
        , SHIPZIP
        , BILLADD2
        , MID_INITAL
        , BILLADD3
        , SHIPTO_PO
        , ORDER_SOURCE
        , AUTO_CONSOL
        , PROMO_CODE
        , SPDRCHG
        , DOC_IMAGE_FOLDER
        , CHGSTAT
        , DOC_IMAGE_PAGE
        , VTXCOUNTY
        , CUST_NAME
        , BANK_NAME
        , _FIVETRAN_DELETED
        , LOAD_DTS 
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USWIOC.ORCL.E21PRD.ORDHEAD'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          _FIVETRAN_ID
        , ORDER_HEADER_BK
        , ORIG_GEOCODE
        , PRICEID
        , CUSTV2
        , CUSTV1
        , ORDER_STAT
        , CARD_TRANS_ID
        , REGREL_USER
        , SHIPCNTRY
        , FRT_PAY_MTH
        , CONSOL_NUMB
        , INVOICE_DATE
        , SHIPTO_CODE
        , PROJID
        , HOLD_CODE
        , TAX_EXEMPT_ID
        , CUSTF2
        , CUSTF1
        , SHIPNAME
        , RET_INST_FLAG
        , ORDFRMGEOCODE
        , DIVISION_CODE
        , ORDER_CALLER
        , LCHFLD2
       ,  HANDLING_CHRG
        , LCHFLD1
        , LCHFLD4
        , SHIPGEOCODE
        , LCHFLD3
        , BO_RULE
        , TRANSINS_FLAG
        , SHIPST
        , ORDFRMPHONE
        , SHIPCOUNTRY
        , DUEOUT_TIME
        , NOTES1
        , DEPARTMENT
        , BILLMI
        , NOTES2
        , LCHFLD5
        , ACK_PRNT_METH
        , DISCNT
        , ORDER_BY
        , DATE_INV_PRINT
        , CANCEL_DATE
        , STOPCHG
        , CUST_NAME_QUAL
        , BILLCITY
        , REL_CREDIT
        , ACK_FLAG
       ,  ORDFRMST
        , REP2_PCT
        , CARD_TYPE
        , VOLDIS_SO
        , FOB_CODE
        , CARD_APPROVAL
        , JOB_CODE
        , DATE_INV
        , TOTDISC
        , USER_SO
        , CUST_CODE
        , MET_OF_SHIP
        , CARD_USER_NAME
        , BILLST
        , SHIPMI
        , CHGUSER
        , VTXCITY
        , TOTTAX
        , ORDFRMCOUNTRY
        , REGREL_DATE
        , BANK_ABA_CODE
        , ORDER_TYPE
        , SHIPCHG
        , CUST_PO
        , ORIG_REL_NUMB
        , CARR_CODE
       ,  REP1
        , REP2
        , ORDFRMMI
        , BILLCOUNTRY
        , SHIPCITY
        , BANK_ACCT
        , STEP_CODE
        , DATE_INVOICE
        , DATE_ENTERED
        , ORDFRMNAME
        , QUOTE_NUMB
        , ORDER_TERMS
        , PAY_TYPE
        , UPDATE_DATE
        , DUETIME
        , EFFDATE
        , DTFLD1
        , NUMFLD1
        , NUMFLD2
        , PRIORITY
        , NUMFLD3
        , DTFLD4
        , BILLTO_CODE
        , NUMFLD4
        , NUMFLD5
        , NUMFLD6
       ,  DTFLD2
        , DTFLD3
        , CARD_RESP_TEXT
        , SOURCE_CODE
        , MISCCHG
        , CUST_REQ_DATE
        , PHASE_NO
        , ALLOC_LOCK
        , DUEDATE
        , EXPIRE_DATE
        , TAXRATE
        , SHIPQUALIFIER
        , ORDER_CLASS
        , SCHFLD6
        , ORDER_DATE
        , BILLZIP
        , TOTSALES
        , BID_NO
        , ORDFRMCITY
        , BILLNAME
        , SHIPPHONE
        , ALLOC_STAT
        , ACK_PRNT_DATE
        , UTILCHG
        , REQ_NUMBER
       ,  DATE_CUST
        , SCHFLD1
        , SHIPFNAME
        , BILLQUALIFIER
        , SCHFLD3
        , SCHFLD2
        , BANK_ACCT_TYPE
        , SCHFLD5
        , CARD_EXP_DATE
        , SCHFLD4
        , TAXFLG
        , BILTYPE_SO
        , ORDFRMQUALIFIER
        , REP1_PCT
        , DOC_IMAGE_NUMB
        , DUEOUT_DATE
        , BILLPHONE
        , ORIG_ORDER_NUMB
        , GIFT_FLAG
        , CONTRACT_NO
        , CARD_NUMBER
        , ORDFRMADD3
        , ORDFRMADD1
        , ORDFRMADD2
        , SHIPADD2
       ,  SHIPADD1
        , SHIPADD3
        , VTXST
        , TAXDIST
        , CHARGED_FRT
        , ORDFRMZIP
        , DATE_ALLOC
        , BO_DATE
        , BILLADD1
        , COST_CTR
        , SHIPZIP
        , BILLADD2
        , MID_INITAL
        , BILLADD3
        , SHIPTO_PO
        , ORDER_SOURCE
        , AUTO_CONSOL
        , PROMO_CODE
        , SPDRCHG
        , DOC_IMAGE_FOLDER
        , CHGSTAT
        , DOC_IMAGE_PAGE
        , VTXCOUNTY
        , CUST_NAME
        , BANK_NAME
        , _FIVETRAN_DELETED
        , LOAD_DTS
        , REC_SRC
        , BKCC 
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_HEADER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_HEADER_HK
            , MD5_BINARY(UPPER(NULLIF(CONCAT(
           IFNULL(TRIM(ORDER_HEADER_BK::text), '^^')
,'||', IFNULL(TRIM(ORIG_GEOCODE::text), '^^')
,'||', IFNULL(TRIM(PRICEID::text), '^^')
,'||', IFNULL(TRIM(CUSTV2::text), '^^')
,'||', IFNULL(TRIM(CUSTV1::text), '^^')
,'||', IFNULL(TRIM(ORDER_STAT::text), '^^')
,'||', IFNULL(TRIM(CARD_TRANS_ID::text), '^^')
,'||', IFNULL(TRIM(REGREL_USER::text), '^^')
,'||', IFNULL(TRIM(SHIPCNTRY::text), '^^')
,'||', IFNULL(TRIM(FRT_PAY_MTH::text), '^^')
,'||', IFNULL(TRIM(CONSOL_NUMB::text), '^^')
,'||', IFNULL(TRIM(INVOICE_DATE::text), '^^')
,'||', IFNULL(TRIM(SHIPTO_CODE::text), '^^')
,'||', IFNULL(TRIM(PROJID::text), '^^')
,'||', IFNULL(TRIM(HOLD_CODE::text), '^^')
,'||', IFNULL(TRIM(TAX_EXEMPT_ID::text), '^^')
,'||', IFNULL(TRIM(CUSTF2::text), '^^')
,'||', IFNULL(TRIM(CUSTF1::text), '^^')
,'||', IFNULL(TRIM(SHIPNAME::text), '^^')
,'||', IFNULL(TRIM(RET_INST_FLAG::text), '^^')
,'||', IFNULL(TRIM(ORDFRMGEOCODE::text), '^^')
,'||', IFNULL(TRIM(DIVISION_CODE::text), '^^')
,'||', IFNULL(TRIM(ORDER_CALLER::text), '^^')
,'||', IFNULL(TRIM(LCHFLD2::text), '^^')
,'||', IFNULL(TRIM(HANDLING_CHRG::text), '^^')
,'||', IFNULL(TRIM(LCHFLD1::text), '^^')
,'||', IFNULL(TRIM(LCHFLD4::text), '^^')
,'||', IFNULL(TRIM(SHIPGEOCODE::text), '^^')
,'||', IFNULL(TRIM(LCHFLD3::text), '^^')
,'||', IFNULL(TRIM(BO_RULE::text), '^^')
,'||', IFNULL(TRIM(TRANSINS_FLAG::text), '^^')
,'||', IFNULL(TRIM(SHIPST::text), '^^')
,'||', IFNULL(TRIM(ORDFRMPHONE::text), '^^')
,'||', IFNULL(TRIM(SHIPCOUNTRY::text), '^^')
,'||', IFNULL(TRIM(DUEOUT_TIME::text), '^^')
,'||', IFNULL(TRIM(NOTES1::text), '^^')
,'||', IFNULL(TRIM(DEPARTMENT::text), '^^')
,'||', IFNULL(TRIM(BILLMI::text), '^^')
,'||', IFNULL(TRIM(NOTES2::text), '^^')
,'||', IFNULL(TRIM(LCHFLD5::text), '^^')
,'||', IFNULL(TRIM(ACK_PRNT_METH::text), '^^')
,'||', IFNULL(TRIM(DISCNT::text), '^^')
,'||', IFNULL(TRIM(ORDER_BY::text), '^^')
,'||', IFNULL(TRIM(DATE_INV_PRINT::text), '^^')
,'||', IFNULL(TRIM(CANCEL_DATE::text), '^^')
,'||', IFNULL(TRIM(STOPCHG::text), '^^')
,'||', IFNULL(TRIM(CUST_NAME_QUAL::text), '^^')
,'||', IFNULL(TRIM(BILLCITY::text), '^^')
,'||', IFNULL(TRIM(REL_CREDIT::text), '^^')
,'||', IFNULL(TRIM(ACK_FLAG::text), '^^')
,'||', IFNULL(TRIM(ORDFRMST::text), '^^')
,'||', IFNULL(TRIM(REP2_PCT::text), '^^')
,'||', IFNULL(TRIM(CARD_TYPE::text), '^^')
,'||', IFNULL(TRIM(VOLDIS_SO::text), '^^')
,'||', IFNULL(TRIM(FOB_CODE::text), '^^')
,'||', IFNULL(TRIM(CARD_APPROVAL::text), '^^')
,'||', IFNULL(TRIM(JOB_CODE::text), '^^')
,'||', IFNULL(TRIM(DATE_INV::text), '^^')
,'||', IFNULL(TRIM(TOTDISC::text), '^^')
,'||', IFNULL(TRIM(USER_SO::text), '^^')
,'||', IFNULL(TRIM(CUST_CODE::text), '^^')
,'||', IFNULL(TRIM(MET_OF_SHIP::text), '^^')
,'||', IFNULL(TRIM(CARD_USER_NAME::text), '^^')
,'||', IFNULL(TRIM(BILLST::text), '^^')
,'||', IFNULL(TRIM(SHIPMI::text), '^^')
,'||', IFNULL(TRIM(CHGUSER::text), '^^')
,'||', IFNULL(TRIM(VTXCITY::text), '^^')
,'||', IFNULL(TRIM(TOTTAX::text), '^^')
,'||', IFNULL(TRIM(ORDFRMCOUNTRY::text), '^^')
,'||', IFNULL(TRIM(REGREL_DATE::text), '^^')
,'||', IFNULL(TRIM(BANK_ABA_CODE::text), '^^')
,'||', IFNULL(TRIM(ORDER_TYPE::text), '^^')
,'||', IFNULL(TRIM(SHIPCHG::text), '^^')
,'||', IFNULL(TRIM(CUST_PO::text), '^^')
,'||', IFNULL(TRIM(ORIG_REL_NUMB::text), '^^')
,'||', IFNULL(TRIM(CARR_CODE::text), '^^')
,'||', IFNULL(TRIM(REP1::text), '^^')
,'||', IFNULL(TRIM(REP2::text), '^^')
,'||', IFNULL(TRIM(ORDFRMMI::text), '^^')
,'||', IFNULL(TRIM(BILLCOUNTRY::text), '^^')
,'||', IFNULL(TRIM(SHIPCITY::text), '^^')
,'||', IFNULL(TRIM(BANK_ACCT::text), '^^')
,'||', IFNULL(TRIM(STEP_CODE::text), '^^')
,'||', IFNULL(TRIM(DATE_INVOICE::text), '^^')
,'||', IFNULL(TRIM(DATE_ENTERED::text), '^^')
,'||', IFNULL(TRIM(ORDFRMNAME::text), '^^')
,'||', IFNULL(TRIM(QUOTE_NUMB::text), '^^')
,'||', IFNULL(TRIM(ORDER_TERMS::text), '^^')
,'||', IFNULL(TRIM(PAY_TYPE::text), '^^')
,'||', IFNULL(TRIM(UPDATE_DATE::text), '^^')
,'||', IFNULL(TRIM(DUETIME::text), '^^')
,'||', IFNULL(TRIM(EFFDATE::text), '^^')
,'||', IFNULL(TRIM(DTFLD1::text), '^^')
,'||', IFNULL(TRIM(NUMFLD1::text), '^^')
,'||', IFNULL(TRIM(NUMFLD2::text), '^^')
,'||', IFNULL(TRIM(PRIORITY::text), '^^')
,'||', IFNULL(TRIM(NUMFLD3::text), '^^')
,'||', IFNULL(TRIM(DTFLD4::text), '^^')
,'||', IFNULL(TRIM(BILLTO_CODE::text), '^^')
,'||', IFNULL(TRIM(NUMFLD4::text), '^^')
,'||', IFNULL(TRIM(NUMFLD5::text), '^^')
,'||', IFNULL(TRIM(NUMFLD6::text), '^^')
,'||', IFNULL(TRIM(DTFLD2::text), '^^')
,'||', IFNULL(TRIM(DTFLD3::text), '^^')
,'||', IFNULL(TRIM(CARD_RESP_TEXT::text), '^^')
,'||', IFNULL(TRIM(SOURCE_CODE::text), '^^')
,'||', IFNULL(TRIM(MISCCHG::text), '^^')
,'||', IFNULL(TRIM(CUST_REQ_DATE::text), '^^')
,'||', IFNULL(TRIM(PHASE_NO::text), '^^')
,'||', IFNULL(TRIM(ALLOC_LOCK::text), '^^')
,'||', IFNULL(TRIM(DUEDATE::text), '^^')
,'||', IFNULL(TRIM(EXPIRE_DATE::text), '^^')
,'||', IFNULL(TRIM(TAXRATE::text), '^^')
,'||', IFNULL(TRIM(SHIPQUALIFIER::text), '^^')
,'||', IFNULL(TRIM(ORDER_CLASS::text), '^^')
,'||', IFNULL(TRIM(SCHFLD6::text), '^^')
,'||', IFNULL(TRIM(ORDER_DATE::text), '^^')
,'||', IFNULL(TRIM(BILLZIP::text), '^^')
,'||', IFNULL(TRIM(TOTSALES::text), '^^')
,'||', IFNULL(TRIM(BID_NO::text), '^^')
,'||', IFNULL(TRIM(ORDFRMCITY::text), '^^')
,'||', IFNULL(TRIM(BILLNAME::text), '^^')
,'||', IFNULL(TRIM(SHIPPHONE::text), '^^')
,'||', IFNULL(TRIM(ALLOC_STAT::text), '^^')
,'||', IFNULL(TRIM(ACK_PRNT_DATE::text), '^^')
,'||', IFNULL(TRIM(UTILCHG::text), '^^')
,'||', IFNULL(TRIM(REQ_NUMBER::text), '^^')
,'||', IFNULL(TRIM(DATE_CUST::text), '^^')
,'||', IFNULL(TRIM(SCHFLD1::text), '^^')
,'||', IFNULL(TRIM(SHIPFNAME::text), '^^')
,'||', IFNULL(TRIM(BILLQUALIFIER::text), '^^')
,'||', IFNULL(TRIM(SCHFLD3::text), '^^')
,'||', IFNULL(TRIM(SCHFLD2::text), '^^')
,'||', IFNULL(TRIM(BANK_ACCT_TYPE::text), '^^')
,'||', IFNULL(TRIM(SCHFLD5::text), '^^')
,'||', IFNULL(TRIM(CARD_EXP_DATE::text), '^^')
,'||', IFNULL(TRIM(SCHFLD4::text), '^^')
,'||', IFNULL(TRIM(TAXFLG::text), '^^')
,'||', IFNULL(TRIM(BILTYPE_SO::text), '^^')
,'||', IFNULL(TRIM(ORDFRMQUALIFIER::text), '^^')
,'||', IFNULL(TRIM(REP1_PCT::text), '^^')
,'||', IFNULL(TRIM(DOC_IMAGE_NUMB::text), '^^')
,'||', IFNULL(TRIM(DUEOUT_DATE::text), '^^')
,'||', IFNULL(TRIM(BILLPHONE::text), '^^')
,'||', IFNULL(TRIM(ORIG_ORDER_NUMB::text), '^^')
,'||', IFNULL(TRIM(GIFT_FLAG::text), '^^')
,'||', IFNULL(TRIM(CONTRACT_NO::text), '^^')
,'||', IFNULL(TRIM(CARD_NUMBER::text), '^^')
,'||', IFNULL(TRIM(ORDFRMADD3::text), '^^')
,'||', IFNULL(TRIM(ORDFRMADD1::text), '^^')
,'||', IFNULL(TRIM(ORDFRMADD2::text), '^^')
,'||', IFNULL(TRIM(SHIPADD2::text), '^^')
,'||', IFNULL(TRIM(SHIPADD1::text), '^^')
,'||', IFNULL(TRIM(SHIPADD3::text), '^^')
,'||', IFNULL(TRIM(VTXST::text), '^^')
,'||', IFNULL(TRIM(TAXDIST::text), '^^')
,'||', IFNULL(TRIM(CHARGED_FRT::text), '^^')
,'||', IFNULL(TRIM(ORDFRMZIP::text), '^^')
,'||', IFNULL(TRIM(DATE_ALLOC::text), '^^')
,'||', IFNULL(TRIM(BO_DATE::text), '^^')
,'||', IFNULL(TRIM(BILLADD1::text), '^^')
,'||', IFNULL(TRIM(COST_CTR::text), '^^')
,'||', IFNULL(TRIM(SHIPZIP::text), '^^')
,'||', IFNULL(TRIM(BILLADD2::text), '^^')
,'||', IFNULL(TRIM(MID_INITAL::text), '^^')
,'||', IFNULL(TRIM(BILLADD3::text), '^^')
,'||', IFNULL(TRIM(SHIPTO_PO::text), '^^')
,'||', IFNULL(TRIM(ORDER_SOURCE::text), '^^')
,'||', IFNULL(TRIM(AUTO_CONSOL::text), '^^')
,'||', IFNULL(TRIM(PROMO_CODE::text), '^^')
,'||', IFNULL(TRIM(SPDRCHG::text), '^^')
,'||', IFNULL(TRIM(DOC_IMAGE_FOLDER::text), '^^')
,'||', IFNULL(TRIM(CHGSTAT::text), '^^')
,'||', IFNULL(TRIM(DOC_IMAGE_PAGE::text), '^^')
,'||', IFNULL(TRIM(VTXCOUNTY::text), '^^')
,'||', IFNULL(TRIM(CUST_NAME::text), '^^')
,'||', IFNULL(TRIM(BANK_NAME::text), '^^')
,'||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^')), ''))) 
        as HASHDIFF
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_ap             as ( SELECT * FROM {{ source('tt_e21prd_e21trubis', 'apvndmstr') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_ap             as ( SELECT * FROM tt_e21prd_e21trubis.apvndmstr )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_ap as (
    SELECT
        VEND_CODE                                                    as                                        SUPPLIER_BK
      , TERMS_CODE                                                   as                                    PAYMENT_TERM_BK
      , ZIP
      , MAIL_CITY
      , BO_ALLOWED
      , FRT_ACCT_NO
      , CONTACT
      , PO_LIMIT
      , UPDATE_DATE
      , PRIORITY_CODE
      , ADD_USER
      , VEND_NAME2
      , CODE_1099
      , MAIL_ADDR3
      , DELIVERY_TIME
      , MAIL_ADDR1
      , MAIL_ADDR2
      , FRT_PAY_MTH
      , LINK_CODE
      , PO_MSG_ID
      , CNTRY_CODE
      , VEND_CATG
      , ADD_DATE
      , ORD_CYCLE
      , BANK_ACCT_NO
      , LATE_WINDOW
      , CURNCY_CODE
      , HOLD_PAYMENT
      , CURR_BAL
      , ON_SITE
      , TERMS_CODE
      , ABA_ROUTE_NO
      , AP_DAY_BAL
      , RECEIVE_1099
      , MAIL_CONTACT
      , DB_RATING
      , INTEXT_FLAG
      , DB_ACCT_NBR
      , CUR_VAR_ACCT
      , CANCEL_ALERT_DAYS
      , MAIL_ST
      , WHSE_ID
      , CHK_DATE_TYPE
      , LAST_PAY_DATE
      , TAKE_DISCOUNT
      , DISC_TAKEN_ACCT
      , PHONE
      , AUTO_PO
      , STATE
      , PREF_COST_CTR
      , EDI_PO
      , ALT_CODE
      , VEND_TYPE
      , PO_PRNT_METH
      , VEND_STATUS
      , PREF_PRNT_METH
      , VEND_NAME
      , MAIL_COUNTRY
      , TAX_ID
      , MET_OF_SHIP
      , BANK_CODE
      , MINORITY_CODE
      , ADDRESS1
      , YTD_PURCH
      , EXP_ACCT_NO
      , ADDRESS3
      , TAX_ACCT_NO
      , BUYER_CODE
      , ADDRESS2
      , INACTIVE_DATE
      , AP_ACCT_NO
      , APCR_ACCT_NO
      , MAIL_ZIP
      , COMP_MAX
      , UPDATE_USER
      , MAIL_FAX
      , MAIL_PHONE
      , MAIL_NAME
      , ELEC_PAY
      , EXPEDITE_FEE
      , COMP_MIN
      , CARR_CODE
      , SHIP_TO
      , MAIL_NAME2
      , BILL_TO
      , CITY
      , PYTD_PURCH
      , CHECK_TYPE
      , FAX
      , CORE_IND
      , VEND_CODE
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
    FROM SRC_ap
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_ap as (
    SELECT
        SUPPLIER_BK
      , PAYMENT_TERM_BK
      , ZIP
      , MAIL_CITY
      , BO_ALLOWED
      , FRT_ACCT_NO
      , CONTACT
      , PO_LIMIT
      , UPDATE_DATE
      , PRIORITY_CODE
      , ADD_USER
      , VEND_NAME2
      , CODE_1099
      , MAIL_ADDR3
      , DELIVERY_TIME
      , MAIL_ADDR1
      , MAIL_ADDR2
      , FRT_PAY_MTH
      , LINK_CODE
      , PO_MSG_ID
      , CNTRY_CODE
      , VEND_CATG
      , ADD_DATE
      , ORD_CYCLE
      , BANK_ACCT_NO
      , LATE_WINDOW
      , CURNCY_CODE
      , HOLD_PAYMENT
      , CURR_BAL
      , ON_SITE
      , TERMS_CODE
      , ABA_ROUTE_NO
      , AP_DAY_BAL
      , RECEIVE_1099
      , MAIL_CONTACT
      , DB_RATING
      , INTEXT_FLAG
      , DB_ACCT_NBR
      , CUR_VAR_ACCT
      , CANCEL_ALERT_DAYS
      , MAIL_ST
      , WHSE_ID
      , CHK_DATE_TYPE
      , LAST_PAY_DATE
      , TAKE_DISCOUNT
      , DISC_TAKEN_ACCT
      , PHONE
      , AUTO_PO
      , STATE
      , PREF_COST_CTR
      , EDI_PO
      , ALT_CODE
      , VEND_TYPE
      , PO_PRNT_METH
      , VEND_STATUS
      , PREF_PRNT_METH
      , VEND_NAME
      , MAIL_COUNTRY
      , TAX_ID
      , MET_OF_SHIP
      , BANK_CODE
      , MINORITY_CODE
      , ADDRESS1
      , YTD_PURCH
      , EXP_ACCT_NO
      , ADDRESS3
      , TAX_ACCT_NO
      , BUYER_CODE
      , ADDRESS2
      , INACTIVE_DATE
      , AP_ACCT_NO
      , APCR_ACCT_NO
      , MAIL_ZIP
      , COMP_MAX
      , UPDATE_USER
      , MAIL_FAX
      , MAIL_PHONE
      , MAIL_NAME
      , ELEC_PAY
      , EXPEDITE_FEE
      , COMP_MIN
      , CARR_CODE
      , SHIP_TO
      , MAIL_NAME2
      , BILL_TO
      , CITY
      , PYTD_PURCH
      , CHECK_TYPE
      , FAX
      , CORE_IND
      , VEND_CODE
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_ap
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_ap as (
    SELECT *
    FROM RENAME_ap
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHMA.ORCL.E21PRD.APVNDMSTR'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_ap
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_BK
        , PAYMENT_TERM_BK
        , ZIP
        , MAIL_CITY
        , BO_ALLOWED
        , FRT_ACCT_NO
        , CONTACT
        , PO_LIMIT
        , UPDATE_DATE
        , PRIORITY_CODE
        , ADD_USER
        , VEND_NAME2
        , CODE_1099
        , MAIL_ADDR3
        , DELIVERY_TIME
        , MAIL_ADDR1
        , MAIL_ADDR2
        , FRT_PAY_MTH
        , LINK_CODE
        , PO_MSG_ID
        , CNTRY_CODE
        , VEND_CATG
        , ADD_DATE
        , ORD_CYCLE
        , BANK_ACCT_NO
        , LATE_WINDOW
        , CURNCY_CODE
        , HOLD_PAYMENT
        , CURR_BAL
        , ON_SITE
        , TERMS_CODE
        , ABA_ROUTE_NO
        , AP_DAY_BAL
        , RECEIVE_1099
        , MAIL_CONTACT
        , DB_RATING
        , INTEXT_FLAG
        , DB_ACCT_NBR
        , CUR_VAR_ACCT
        , CANCEL_ALERT_DAYS
        , MAIL_ST
        , WHSE_ID
        , CHK_DATE_TYPE
        , LAST_PAY_DATE
        , TAKE_DISCOUNT
        , DISC_TAKEN_ACCT
        , PHONE
        , AUTO_PO
        , STATE
        , PREF_COST_CTR
        , EDI_PO
        , ALT_CODE
        , VEND_TYPE
        , PO_PRNT_METH
        , VEND_STATUS
        , PREF_PRNT_METH
        , VEND_NAME
        , MAIL_COUNTRY
        , TAX_ID
        , MET_OF_SHIP
        , BANK_CODE
        , MINORITY_CODE
        , ADDRESS1
        , YTD_PURCH
        , EXP_ACCT_NO
        , ADDRESS3
        , TAX_ACCT_NO
        , BUYER_CODE
        , ADDRESS2
        , INACTIVE_DATE
        , AP_ACCT_NO
        , APCR_ACCT_NO
        , MAIL_ZIP
        , COMP_MAX
        , UPDATE_USER
        , MAIL_FAX
        , MAIL_PHONE
        , MAIL_NAME
        , ELEC_PAY
        , EXPEDITE_FEE
        , COMP_MIN
        , CARR_CODE
        , SHIP_TO
        , MAIL_NAME2
        , BILL_TO
        , CITY
        , PYTD_PURCH
        , CHECK_TYPE
        , FAX
        , CORE_IND
        , VEND_CODE
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VEND_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(TERMS_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(VEND_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(TERMS_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_SUPPLIER_PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ZIP::text), '^^') 
            , '||', IFNULL(TRIM(MAIL_CITY::text), '^^') 
            , '||', IFNULL(TRIM(BO_ALLOWED::text), '^^') 
            , '||', IFNULL(TRIM(FRT_ACCT_NO::text), '^^') 
            , '||', IFNULL(TRIM(CONTACT::text), '^^') 
            , '||', IFNULL(TRIM(PO_LIMIT::text), '^^') 
            , '||', IFNULL(TRIM(UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PRIORITY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ADD_USER::text), '^^') 
            , '||', IFNULL(TRIM(VEND_NAME2::text), '^^') 
            , '||', IFNULL(TRIM(CODE_1099::text), '^^') 
            , '||', IFNULL(TRIM(MAIL_ADDR3::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_TIME::text), '^^') 
            , '||', IFNULL(TRIM(MAIL_ADDR1::text), '^^') 
            , '||', IFNULL(TRIM(MAIL_ADDR2::text), '^^') 
            , '||', IFNULL(TRIM(FRT_PAY_MTH::text), '^^') 
            , '||', IFNULL(TRIM(LINK_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PO_MSG_ID::text), '^^') 
            , '||', IFNULL(TRIM(CNTRY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(VEND_CATG::text), '^^') 
            , '||', IFNULL(TRIM(ADD_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ORD_CYCLE::text), '^^') 
            , '||', IFNULL(TRIM(BANK_ACCT_NO::text), '^^') 
            , '||', IFNULL(TRIM(LATE_WINDOW::text), '^^') 
            , '||', IFNULL(TRIM(CURNCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_PAYMENT::text), '^^') 
            , '||', IFNULL(TRIM(CURR_BAL::text), '^^') 
            , '||', IFNULL(TRIM(ON_SITE::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ABA_ROUTE_NO::text), '^^') 
            , '||', IFNULL(TRIM(AP_DAY_BAL::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVE_1099::text), '^^') 
            , '||', IFNULL(TRIM(MAIL_CONTACT::text), '^^') 
            , '||', IFNULL(TRIM(DB_RATING::text), '^^') 
            , '||', IFNULL(TRIM(INTEXT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(DB_ACCT_NBR::text), '^^') 
            , '||', IFNULL(TRIM(CUR_VAR_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_ALERT_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(MAIL_ST::text), '^^') 
            , '||', IFNULL(TRIM(WHSE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CHK_DATE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_PAY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TAKE_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(DISC_TAKEN_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(PHONE::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_PO::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(PREF_COST_CTR::text), '^^') 
            , '||', IFNULL(TRIM(EDI_PO::text), '^^') 
            , '||', IFNULL(TRIM(ALT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(VEND_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PO_PRNT_METH::text), '^^') 
            , '||', IFNULL(TRIM(VEND_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PREF_PRNT_METH::text), '^^') 
            , '||', IFNULL(TRIM(VEND_NAME::text), '^^') 
            , '||', IFNULL(TRIM(MAIL_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ID::text), '^^') 
            , '||', IFNULL(TRIM(MET_OF_SHIP::text), '^^') 
            , '||', IFNULL(TRIM(BANK_CODE::text), '^^') 
            , '||', IFNULL(TRIM(MINORITY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS1::text), '^^') 
            , '||', IFNULL(TRIM(YTD_PURCH::text), '^^') 
            , '||', IFNULL(TRIM(EXP_ACCT_NO::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS3::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ACCT_NO::text), '^^') 
            , '||', IFNULL(TRIM(BUYER_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS2::text), '^^') 
            , '||', IFNULL(TRIM(INACTIVE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(AP_ACCT_NO::text), '^^') 
            , '||', IFNULL(TRIM(APCR_ACCT_NO::text), '^^') 
            , '||', IFNULL(TRIM(MAIL_ZIP::text), '^^') 
            , '||', IFNULL(TRIM(COMP_MAX::text), '^^') 
            , '||', IFNULL(TRIM(UPDATE_USER::text), '^^') 
            , '||', IFNULL(TRIM(MAIL_FAX::text), '^^') 
            , '||', IFNULL(TRIM(MAIL_PHONE::text), '^^') 
            , '||', IFNULL(TRIM(MAIL_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ELEC_PAY::text), '^^') 
            , '||', IFNULL(TRIM(EXPEDITE_FEE::text), '^^') 
            , '||', IFNULL(TRIM(COMP_MIN::text), '^^') 
            , '||', IFNULL(TRIM(CARR_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO::text), '^^') 
            , '||', IFNULL(TRIM(MAIL_NAME2::text), '^^') 
            , '||', IFNULL(TRIM(BILL_TO::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(PYTD_PURCH::text), '^^') 
            , '||', IFNULL(TRIM(CHECK_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(FAX::text), '^^') 
            , '||', IFNULL(TRIM(CORE_IND::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

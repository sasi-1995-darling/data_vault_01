---- SRC LAYER ----
WITH
SRC_E21            as ( SELECT * FROM {{ ref('v_psa_stg_supplier__tt_e21') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_E21            as ( SELECT * FROM STAGING.v_psa_stg_supplier__tt_e21 )
*/
---- LOGIC LAYER ----

, LOGIC_E21 as (
    SELECT
        SUPPLIER_HK
      , VEND_CODE
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
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_E21
)
---- RENAME LAYER ----

, RENAME_E21 as (
    SELECT
        SUPPLIER_HK
      , VEND_CODE
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
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_E21
)
---- FILTER LAYER ----

, FILTER_E21 as (
    SELECT *
    FROM RENAME_E21
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_E21
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_HK
        , VEND_CODE
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
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , _FIVETRAN_ID
        , PSA_LOAD_DTS
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
    WHERE existing.SUPPLIER_HK = JOIN_RESULT.SUPPLIER_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 

{% if not is_incremental() %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1= row_number()over(partition by SUPPLIER_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
    SELECT MD5_BINARY(GR.VALUE)  SUPPLIER_HK
, GR.VALUE AS VEND_CODE
, NULL AS ZIP
, NULL AS MAIL_CITY
, NULL AS BO_ALLOWED
, NULL AS FRT_ACCT_NO
, NULL AS CONTACT
, NULL AS PO_LIMIT
, NULL AS UPDATE_DATE
, NULL AS PRIORITY_CODE
, NULL AS ADD_USER
, NULL AS VEND_NAME2
, NULL AS CODE_1099
, NULL AS MAIL_ADDR3
, NULL AS DELIVERY_TIME
, NULL AS MAIL_ADDR1
, NULL AS MAIL_ADDR2
, NULL AS FRT_PAY_MTH
, NULL AS LINK_CODE
, NULL AS PO_MSG_ID
, NULL AS CNTRY_CODE
, NULL AS VEND_CATG
, NULL AS ADD_DATE
, NULL AS ORD_CYCLE
, NULL AS BANK_ACCT_NO
, NULL AS LATE_WINDOW
, NULL AS CURNCY_CODE
, NULL AS HOLD_PAYMENT
, NULL AS CURR_BAL
, NULL AS ON_SITE
, NULL AS TERMS_CODE
, NULL AS ABA_ROUTE_NO
, NULL AS AP_DAY_BAL
, NULL AS RECEIVE_1099
, NULL AS MAIL_CONTACT
, NULL AS DB_RATING
, NULL AS INTEXT_FLAG
, NULL AS DB_ACCT_NBR
, NULL AS CUR_VAR_ACCT
, NULL AS CANCEL_ALERT_DAYS
, NULL AS MAIL_ST
, NULL AS WHSE_ID
, NULL AS CHK_DATE_TYPE
, NULL AS LAST_PAY_DATE
, NULL AS TAKE_DISCOUNT
, NULL AS DISC_TAKEN_ACCT
, NULL AS PHONE
, NULL AS AUTO_PO
, NULL AS STATE
, NULL AS PREF_COST_CTR
, NULL AS EDI_PO
, NULL AS ALT_CODE
, NULL AS VEND_TYPE
, NULL AS PO_PRNT_METH
, NULL AS VEND_STATUS
, NULL AS PREF_PRNT_METH
, NULL AS VEND_NAME
, NULL AS MAIL_COUNTRY
, NULL AS TAX_ID
, NULL AS MET_OF_SHIP
, NULL AS BANK_CODE
, NULL AS MINORITY_CODE
, NULL AS ADDRESS1
, NULL AS YTD_PURCH
, NULL AS EXP_ACCT_NO
, NULL AS ADDRESS3
, NULL AS TAX_ACCT_NO
, NULL AS BUYER_CODE
, NULL AS ADDRESS2
, NULL AS INACTIVE_DATE
, NULL AS AP_ACCT_NO
, NULL AS APCR_ACCT_NO
, NULL AS MAIL_ZIP
, NULL AS COMP_MAX
, NULL AS UPDATE_USER
, NULL AS MAIL_FAX
, NULL AS MAIL_PHONE
, NULL AS MAIL_NAME
, NULL AS ELEC_PAY
, NULL AS EXPEDITE_FEE
, NULL AS COMP_MIN
, NULL AS CARR_CODE
, NULL AS SHIP_TO
, NULL AS MAIL_NAME2
, NULL AS BILL_TO
, NULL AS CITY
, NULL AS PYTD_PURCH
, NULL AS CHECK_TYPE
, NULL AS FAX
, NULL AS CORE_IND
, NULL AS _FIVETRAN_DELETED
, NULL AS _FIVETRAN_SYNCED
, NULL AS _FIVETRAN_ID
, '1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS
, 'N' AS PSA_DELETE_IND
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
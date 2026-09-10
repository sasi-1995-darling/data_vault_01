---- SRC LAYER ----
WITH
SRC_tte21          as ( SELECT * FROM {{ ref('v_psa_stg_po_header__tt_e21') }} as SRC 
                        {% if is_incremental() %}
                         where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_tte21          as ( SELECT * FROM STAGING.v_psa_stg_po_header__tt_e21 )
*/
---- LOGIC LAYER ----

, LOGIC_tte21 as (
    SELECT
        PO_HEADER_HK
      , PO_NUMBER
      , REL_NUMB
      , PAY_DATE
      , INV_VALUE
      , FRT_PAY_MTH
      , SHIPTO_CODE
      , BUYER_ID
      , TRACKING_NO
      , JOB_NO
      , DIVISION_CODE
      , INVTAX
      , TERMS_CODE
      , APPROVAL_DATE
      , INV_DATE
      , PO_PRINT_METH
      , DISCNT
      , SO_REL
      , CANCEL_DATE
      , LOCATION
      , BILLCITY
      , PAYTAX
      , FULL_PART
      , PAY_VALUE
      , FOB_CODE
      , PHASE_CODE
      , TOTDISC
      , SHIP_PHONE
      , PO_TYPE
      , TAX_ID
      , MET_OF_SHIP
      , BILLST
      , DUE_DATE
      , TOTTAX
      , REQ_BY
      , VEND_ORDER
      , SHIPCHG
      , PRODUCT_REQ
      , PO_VALUE
      , CARR_CODE
      , PAYSHIPCHG
      , INVDISC
      , BILLCOUNTRY
      , MARKS
      , TAX_FLAG
      , STEP_CODE
      , VEND_CODE
      , PO_REL_VAL
      , DATE_ENTERED
      , PO_STATUS
      , SO_NUMBER
      , QUOTE_NUMB
      , DUETIME
      , SHIP_CITY
      , BILLTO_CODE
      , CLOSE_TYPE
      , PO_PRINT_FLAG
      , FRT_APP_MTH
      , VEND_CONTACT
      , SHIP_ADDR3
      , SHIP_ADDR2
      , SHIP_ZIP
      , SHIP_ADDR1
      , APPROVAL_ID
      , SHIP_FAX
      , VEND_SITE
      , TAXRATE
      , BILTYPE_PO
      , SHIP_NAME
      , SHIP_STATE
      , BILLZIP
      , BILLNAME
      , SHIP_CONTACT
      , VEND_PHONE
      , PRINT_CODE
      , RELEASE_DATE
      , DEL_TO
      , REQ_NUMBER
      , INV_NUMBER
      , SHIP_COUNTRY
      , DOC_IMAGE_NUMB
      , INVSHIPCHG
      , BILLPHONE
      , MARKS2
      , VEND_FAX
      , VEND_NAME
      , BILLADD1
      , COST_CTR
      , VOLDIS_PO
      , BILLADD2
      , BILLADD3
      , VENDOR_STATUS
      , PO_PRINT_DATE
      , SHIPTO_PO
      , JOB_OR_LOC
      , USER_PO
      , DOC_IMAGE_FOLDER
      , DOC_IMAGE_PAGE
      , BUS_NAME2
      , PAYDISC
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_tte21
)
---- RENAME LAYER ----

, RENAME_tte21 as (
    SELECT
        PO_HEADER_HK
      , PO_NUMBER
      , REL_NUMB
      , PAY_DATE
      , INV_VALUE
      , FRT_PAY_MTH
      , SHIPTO_CODE
      , BUYER_ID
      , TRACKING_NO
      , JOB_NO
      , DIVISION_CODE
      , INVTAX
      , TERMS_CODE
      , APPROVAL_DATE
      , INV_DATE
      , PO_PRINT_METH
      , DISCNT
      , SO_REL
      , CANCEL_DATE
      , LOCATION
      , BILLCITY
      , PAYTAX
      , FULL_PART
      , PAY_VALUE
      , FOB_CODE
      , PHASE_CODE
      , TOTDISC
      , SHIP_PHONE
      , PO_TYPE
      , TAX_ID
      , MET_OF_SHIP
      , BILLST
      , DUE_DATE
      , TOTTAX
      , REQ_BY
      , VEND_ORDER
      , SHIPCHG
      , PRODUCT_REQ
      , PO_VALUE
      , CARR_CODE
      , PAYSHIPCHG
      , INVDISC
      , BILLCOUNTRY
      , MARKS
      , TAX_FLAG
      , STEP_CODE
      , VEND_CODE
      , PO_REL_VAL
      , DATE_ENTERED
      , PO_STATUS
      , SO_NUMBER
      , QUOTE_NUMB
      , DUETIME
      , SHIP_CITY
      , BILLTO_CODE
      , CLOSE_TYPE
      , PO_PRINT_FLAG
      , FRT_APP_MTH
      , VEND_CONTACT
      , SHIP_ADDR3
      , SHIP_ADDR2
      , SHIP_ZIP
      , SHIP_ADDR1
      , APPROVAL_ID
      , SHIP_FAX
      , VEND_SITE
      , TAXRATE
      , BILTYPE_PO
      , SHIP_NAME
      , SHIP_STATE
      , BILLZIP
      , BILLNAME
      , SHIP_CONTACT
      , VEND_PHONE
      , PRINT_CODE
      , RELEASE_DATE
      , DEL_TO
      , REQ_NUMBER
      , INV_NUMBER
      , SHIP_COUNTRY
      , DOC_IMAGE_NUMB
      , INVSHIPCHG
      , BILLPHONE
      , MARKS2
      , VEND_FAX
      , VEND_NAME
      , BILLADD1
      , COST_CTR
      , VOLDIS_PO
      , BILLADD2
      , BILLADD3
      , VENDOR_STATUS
      , PO_PRINT_DATE
      , SHIPTO_PO
      , JOB_OR_LOC
      , USER_PO
      , DOC_IMAGE_FOLDER
      , DOC_IMAGE_PAGE
      , BUS_NAME2
      , PAYDISC
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_tte21
)
---- FILTER LAYER ----

, FILTER_tte21 as (
    SELECT *
    FROM RENAME_tte21
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_tte21
)

---- FINAL LAYER ----
SELECT
          PO_HEADER_HK
        , PO_NUMBER
        , REL_NUMB
        , PAY_DATE
        , INV_VALUE
        , FRT_PAY_MTH
        , SHIPTO_CODE
        , BUYER_ID
        , TRACKING_NO
        , JOB_NO
        , DIVISION_CODE
        , INVTAX
        , TERMS_CODE
        , APPROVAL_DATE
        , INV_DATE
        , PO_PRINT_METH
        , DISCNT
        , SO_REL
        , CANCEL_DATE
        , LOCATION
        , BILLCITY
        , PAYTAX
        , FULL_PART
        , PAY_VALUE
        , FOB_CODE
        , PHASE_CODE
        , TOTDISC
        , SHIP_PHONE
        , PO_TYPE
        , TAX_ID
        , MET_OF_SHIP
        , BILLST
        , DUE_DATE
        , TOTTAX
        , REQ_BY
        , VEND_ORDER
        , SHIPCHG
        , PRODUCT_REQ
        , PO_VALUE
        , CARR_CODE
        , PAYSHIPCHG
        , INVDISC
        , BILLCOUNTRY
        , MARKS
        , TAX_FLAG
        , STEP_CODE
        , VEND_CODE
        , PO_REL_VAL
        , DATE_ENTERED
        , PO_STATUS
        , SO_NUMBER
        , QUOTE_NUMB
        , DUETIME
        , SHIP_CITY
        , BILLTO_CODE
        , CLOSE_TYPE
        , PO_PRINT_FLAG
        , FRT_APP_MTH
        , VEND_CONTACT
        , SHIP_ADDR3
        , SHIP_ADDR2
        , SHIP_ZIP
        , SHIP_ADDR1
        , APPROVAL_ID
        , SHIP_FAX
        , VEND_SITE
        , TAXRATE
        , BILTYPE_PO
        , SHIP_NAME
        , SHIP_STATE
        , BILLZIP
        , BILLNAME
        , SHIP_CONTACT
        , VEND_PHONE
        , PRINT_CODE
        , RELEASE_DATE
        , DEL_TO
        , REQ_NUMBER
        , INV_NUMBER
        , SHIP_COUNTRY
        , DOC_IMAGE_NUMB
        , INVSHIPCHG
        , BILLPHONE
        , MARKS2
        , VEND_FAX
        , VEND_NAME
        , BILLADD1
        , COST_CTR
        , VOLDIS_PO
        , BILLADD2
        , BILLADD3
        , VENDOR_STATUS
        , PO_PRINT_DATE
        , SHIPTO_PO
        , JOB_OR_LOC
        , USER_PO
        , DOC_IMAGE_FOLDER
        , DOC_IMAGE_PAGE
        , BUS_NAME2
        , PAYDISC
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
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
    WHERE existing.PO_HEADER_HK = JOIN_RESULT.PO_HEADER_HK 
and existing.REL_NUMB = JOIN_RESULT.REL_NUMB 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PO_HEADER_HK,REL_NUMB, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PO_HEADER_HK,
GR.VALUE::text AS PO_NUMBER,
GR.VALUE::text AS REL_NUMB,
NULL AS PAY_DATE,
NULL AS INV_VALUE,
NULL AS FRT_PAY_MTH,
NULL AS SHIPTO_CODE,
NULL AS BUYER_ID,
NULL AS TRACKING_NO,
NULL AS JOB_NO,
NULL AS DIVISION_CODE,
NULL AS INVTAX,
NULL AS TERMS_CODE,
NULL AS APPROVAL_DATE,
NULL AS INV_DATE,
NULL AS PO_PRINT_METH,
NULL AS DISCNT,
NULL AS SO_REL,
NULL AS CANCEL_DATE,
NULL AS LOCATION,
NULL AS BILLCITY,
NULL AS PAYTAX,
NULL AS FULL_PART,
NULL AS PAY_VALUE,
NULL AS FOB_CODE,
NULL AS PHASE_CODE,
NULL AS TOTDISC,
NULL AS SHIP_PHONE,
NULL AS PO_TYPE,
NULL AS TAX_ID,
NULL AS MET_OF_SHIP,
NULL AS BILLST,
NULL AS DUE_DATE,
NULL AS TOTTAX,
NULL AS REQ_BY,
NULL AS VEND_ORDER,
NULL AS SHIPCHG,
NULL AS PRODUCT_REQ,
NULL AS PO_VALUE,
NULL AS CARR_CODE,
NULL AS PAYSHIPCHG,
NULL AS INVDISC,
NULL AS BILLCOUNTRY,
NULL AS MARKS,
NULL AS TAX_FLAG,
NULL AS STEP_CODE,
NULL AS VEND_CODE,
NULL AS PO_REL_VAL,
NULL AS DATE_ENTERED,
NULL AS PO_STATUS,
NULL AS SO_NUMBER,
NULL AS QUOTE_NUMB,
NULL AS DUETIME,
NULL AS SHIP_CITY,
NULL AS BILLTO_CODE,
NULL AS CLOSE_TYPE,
NULL AS PO_PRINT_FLAG,
NULL AS FRT_APP_MTH,
NULL AS VEND_CONTACT,
NULL AS SHIP_ADDR3,
NULL AS SHIP_ADDR2,
NULL AS SHIP_ZIP,
NULL AS SHIP_ADDR1,
NULL AS APPROVAL_ID,
NULL AS SHIP_FAX,
NULL AS VEND_SITE,
NULL AS TAXRATE,
NULL AS BILTYPE_PO,
NULL AS SHIP_NAME,
NULL AS SHIP_STATE,
NULL AS BILLZIP,
NULL AS BILLNAME,
NULL AS SHIP_CONTACT,
NULL AS VEND_PHONE,
NULL AS PRINT_CODE,
NULL AS RELEASE_DATE,
NULL AS DEL_TO,
NULL AS REQ_NUMBER,
NULL AS INV_NUMBER,
NULL AS SHIP_COUNTRY,
NULL AS DOC_IMAGE_NUMB,
NULL AS INVSHIPCHG,
NULL AS BILLPHONE,
NULL AS MARKS2,
NULL AS VEND_FAX,
NULL AS VEND_NAME,
NULL AS BILLADD1,
NULL AS COST_CTR,
NULL AS VOLDIS_PO,
NULL AS BILLADD2,
NULL AS BILLADD3,
NULL AS VENDOR_STATUS,
NULL AS PO_PRINT_DATE,
NULL AS SHIPTO_PO,
NULL AS JOB_OR_LOC,
NULL AS USER_PO,
NULL AS DOC_IMAGE_FOLDER,
NULL AS DOC_IMAGE_PAGE,
NULL AS BUS_NAME2,
NULL AS PAYDISC,
NULL AS _FIVETRAN_ID,
NULL AS _FIVETRAN_DELETED,
NULL AS _FIVETRAN_SYNCED,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
NULL AS PSA_RECORD_SOURCE,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

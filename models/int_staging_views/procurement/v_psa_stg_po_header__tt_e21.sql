---- SRC LAYER ----
WITH
SRC_ph             as ( SELECT * FROM {{ source('tt_e21prd_e21trubis', 'pohead') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_ph             as ( SELECT * FROM tt_e21prd_e21trubis.pohead )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_ph as (
    SELECT
        PO_NUMBER                                                    as                                       PO_HEADER_BK
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
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_ph
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_ph as (
    SELECT
        PO_HEADER_BK
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
    FROM LOGIC_ph
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_ph as (
    SELECT *
    FROM RENAME_ph
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USOHMA.ORCL.E21PRD.POHEAD'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_ph
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PO_HEADER_BK
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
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PAY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(INV_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(FRT_PAY_MTH::text), '^^') 
            , '||', IFNULL(TRIM(SHIPTO_CODE::text), '^^') 
            , '||', IFNULL(TRIM(BUYER_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRACKING_NO::text), '^^') 
            , '||', IFNULL(TRIM(JOB_NO::text), '^^') 
            , '||', IFNULL(TRIM(DIVISION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(INVTAX::text), '^^') 
            , '||', IFNULL(TRIM(TERMS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(INV_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PO_PRINT_METH::text), '^^') 
            , '||', IFNULL(TRIM(DISCNT::text), '^^') 
            , '||', IFNULL(TRIM(SO_REL::text), '^^') 
            , '||', IFNULL(TRIM(CANCEL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION::text), '^^') 
            , '||', IFNULL(TRIM(BILLCITY::text), '^^') 
            , '||', IFNULL(TRIM(PAYTAX::text), '^^') 
            , '||', IFNULL(TRIM(FULL_PART::text), '^^') 
            , '||', IFNULL(TRIM(PAY_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(FOB_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PHASE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TOTDISC::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_PHONE::text), '^^') 
            , '||', IFNULL(TRIM(PO_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ID::text), '^^') 
            , '||', IFNULL(TRIM(MET_OF_SHIP::text), '^^') 
            , '||', IFNULL(TRIM(BILLST::text), '^^') 
            , '||', IFNULL(TRIM(DUE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(TOTTAX::text), '^^') 
            , '||', IFNULL(TRIM(REQ_BY::text), '^^') 
            , '||', IFNULL(TRIM(VEND_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(SHIPCHG::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_REQ::text), '^^') 
            , '||', IFNULL(TRIM(PO_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(CARR_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PAYSHIPCHG::text), '^^') 
            , '||', IFNULL(TRIM(INVDISC::text), '^^') 
            , '||', IFNULL(TRIM(BILLCOUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(MARKS::text), '^^') 
            , '||', IFNULL(TRIM(TAX_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(STEP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(VEND_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PO_REL_VAL::text), '^^') 
            , '||', IFNULL(TRIM(DATE_ENTERED::text), '^^') 
            , '||', IFNULL(TRIM(PO_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(SO_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(QUOTE_NUMB::text), '^^') 
            , '||', IFNULL(TRIM(DUETIME::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_CITY::text), '^^') 
            , '||', IFNULL(TRIM(BILLTO_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CLOSE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PO_PRINT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(FRT_APP_MTH::text), '^^') 
            , '||', IFNULL(TRIM(VEND_CONTACT::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_ADDR3::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_ADDR2::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_ZIP::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_ADDR1::text), '^^') 
            , '||', IFNULL(TRIM(APPROVAL_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_FAX::text), '^^') 
            , '||', IFNULL(TRIM(VEND_SITE::text), '^^') 
            , '||', IFNULL(TRIM(TAXRATE::text), '^^') 
            , '||', IFNULL(TRIM(BILTYPE_PO::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_STATE::text), '^^') 
            , '||', IFNULL(TRIM(BILLZIP::text), '^^') 
            , '||', IFNULL(TRIM(BILLNAME::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_CONTACT::text), '^^') 
            , '||', IFNULL(TRIM(VEND_PHONE::text), '^^') 
            , '||', IFNULL(TRIM(PRINT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(RELEASE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DEL_TO::text), '^^') 
            , '||', IFNULL(TRIM(REQ_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(INV_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(DOC_IMAGE_NUMB::text), '^^') 
            , '||', IFNULL(TRIM(INVSHIPCHG::text), '^^') 
            , '||', IFNULL(TRIM(BILLPHONE::text), '^^') 
            , '||', IFNULL(TRIM(MARKS2::text), '^^') 
            , '||', IFNULL(TRIM(VEND_FAX::text), '^^') 
            , '||', IFNULL(TRIM(VEND_NAME::text), '^^') 
            , '||', IFNULL(TRIM(BILLADD1::text), '^^') 
            , '||', IFNULL(TRIM(COST_CTR::text), '^^') 
            , '||', IFNULL(TRIM(VOLDIS_PO::text), '^^') 
            , '||', IFNULL(TRIM(BILLADD2::text), '^^') 
            , '||', IFNULL(TRIM(BILLADD3::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PO_PRINT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPTO_PO::text), '^^') 
            , '||', IFNULL(TRIM(JOB_OR_LOC::text), '^^') 
            , '||', IFNULL(TRIM(USER_PO::text), '^^') 
            , '||', IFNULL(TRIM(DOC_IMAGE_FOLDER::text), '^^') 
            , '||', IFNULL(TRIM(DOC_IMAGE_PAGE::text), '^^') 
            , '||', IFNULL(TRIM(BUS_NAME2::text), '^^') 
            , '||', IFNULL(TRIM(PAYDISC::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

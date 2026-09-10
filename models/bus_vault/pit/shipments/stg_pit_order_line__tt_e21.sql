{{
    config(
        materialized='ephemeral'
    )
}}
---- SRC LAYER ----
WITH
SRC_HUB            as ( SELECT 
                            ORDER_LINE_HK
                          , ORDER_LINE_BK
                          , REC_SRC
                          , BKCC 
                        FROM {{ ref('hub_order_line') }}
                        WHERE BKCC = 'Kicking_Panda' ),

SRC_SAT_OH         as ( SELECT 
                            ORDER_LINE_HK
                    , _FIVETRAN_ID
                    , ORDER_NUMB
                    , REL_NUMB
                    , ITEM_NO
                    , ORIG_GEOCODE
                    , PACK_QTY
                    , ITEM_TERMS
                    , ITEM_LOAD_NO
                    , SHIPTO_CODE
                    , CONSOL_NUMB
                    , ORIG_ITEM_NO
                    , TAX_EXEMPT_ID
                    , ITEM_PSDISC_TY
                    , PART_ATTRIBUTE1
                    , ITEM_DISCOUNT_TY
                    , PART_ATTRIBUTE3
                    , PART_ATTRIBUTE2
                    , DISC_TYPE
                    , PART_ATTRIBUTE5
                    , PART_ATTRIBUTE4
                    , CONFIG_ID
                    , DIVISION_CODE
                    , PART_ATTRIBUTE6
                    , LCHFLD2
                    , COMMIT_QTY
                    , LCHFLD1
                    , MAINT_PART_CODE
                    , ITEM_TAXABLE
                    , VOL_DISC_TY
                    , ACK_PRNT_METH
                    , PO_REL
                    , DATE_INV_PRINT
                    , CANCEL_DATE
                    , ITEM_ALOW1
                    , CUST_PO_ITEM
                    , ITEM_ALOW2
                    , PACK_CHARGE
                    , PART_CODE
                    , ITEM_COST
                    , PO_ITEM
                    , ITEM_OUTTIME
                    , ITEM_SALETYPE
                    , DATE_INV
                    , ITEM_DISCOUNT
                    , ITEM_NTPRICE
                    , QTY_RECVD
                    , VOL_DISC_AMT
                    , EXT_PRICE
                    , XCUR_CONV
                    , TOT_QTY_ORD
                    , CUST_PO
                    , ORIG_REL_NUMB
                    , MSTRKIT_ITEM_NO
                    , CARR_CODE
                    , KIT_REQ_FLAG
                    , BCUR_CONV
                    , ITEM_PRICEID
                    , DATE_INVOICE
                    , DATE_ENTERED
                    , UPDATE_DATE
                    , ITEM_LIST_PRICE
                    , DTFLD1
                    , NUMFLD1
                    , NUMFLD2
                    , ITEM_ALOW2T
                    , NUMFLD3
                    , QTY_ALLOCATED
                    , DTFLD2
                    , UOM_CONV
                    , BALDUE
                    , TOT_QTY_INVOICE
                    , MSTRKIT_CODE
                    , PO_VEND_CODE
                    , QTY
                    , CUST_REQ_DATE
                    , XCUR_UOM
                    , ORDER_DISC_TY
                    , DISP_PART
                    , EXPIRE_DATE
                    , DUEDATE
                    , ITEM_PSDISC_AMT
                    , PART_DESC
                    , PO_UNIT_PRICE
                    , ITEM_ALOW1T
                    , SHIPTO_GEOCODE
                    , ACK_PRNT_DATE
                    , ITEM_WGT
                    , PO_NUMBER
                    , ITEM_REP
                    , PACK_UOM
                    ,REQ_NUMBER
                    ,SCHFLD1
                    ,DATE_CUST
                    ,SCHFLD3
                    ,ITEM_GWGT
                    ,SCHFLD2
                    ,ITEM_PPV
                    ,ORIG_ORDER_NUMB
                    ,ITEM_OUTDATE
                    ,GIFT_FLAG
                    ,ITEM_STATUS
                    ,BCUR_UOM
                    ,ITEM_MSG
                    ,ITEM_TYPE
                    ,DATE_RECVD
                    ,DATE_ALLOC
                    ,COST_CTR
                    ,TOT_QTY_SHIP
                    ,ORDER_DISC_AMT
                    , UOM
                    ,QTY_SHIPPED
                    ,ITEM_PRICE
                    ,CART_CHG
                    , _FIVETRAN_DELETED
                    , LOAD_DTS
                    ,_FIVETRAN_SYNCED
                    ,PSA_RECORD_SOURCE
                    ,PSA_DELETE_IND
                        FROM {{ ref('sat_order_line__tt_e21') }}
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY ORDER_LINE_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_HUB            as ( SELECT * FROM RAW_VAULT.HUB_ORDER_LINE ),
SRC_SAT_OH         as ( SELECT * FROM RAW_VAULT.SAT_ORDER_LINE__TT_E21 )
*/
---- LOGIC LAYER ----

, LOGIC_HUB as (
    SELECT
        ORDER_LINE_HK                                                
      , ORDER_LINE_BK                                                
      , REC_SRC
      , BKCC                             
    FROM SRC_HUB
)

, LOGIC_SAT_OH as (
    SELECT
        ORDER_LINE_HK
                    , _FIVETRAN_ID
                    , ORDER_NUMB
                    , REL_NUMB
                    , ITEM_NO
                    , ORIG_GEOCODE
                    , PACK_QTY :: NUMBER AS PACK_QTY
                    , ITEM_TERMS
                    , ITEM_LOAD_NO
                    , SHIPTO_CODE
                    , CONSOL_NUMB
                    , ORIG_ITEM_NO
                    , TAX_EXEMPT_ID
                    , ITEM_PSDISC_TY
                    , PART_ATTRIBUTE1
                    , ITEM_DISCOUNT_TY
                    , PART_ATTRIBUTE3
                    , PART_ATTRIBUTE2
                    , DISC_TYPE
                    , PART_ATTRIBUTE5
                    , PART_ATTRIBUTE4
                    , CONFIG_ID
                    , DIVISION_CODE
                    , PART_ATTRIBUTE6
                    , LCHFLD2
                    , COMMIT_QTY :: NUMBER AS COMMIT_QTY
                    , LCHFLD1
                    , MAINT_PART_CODE
                    , ITEM_TAXABLE
                    , VOL_DISC_TY
                    , ACK_PRNT_METH
                    , PO_REL
                    , DATE_INV_PRINT
                    , CANCEL_DATE
                    , ITEM_ALOW1 :: VARCHAR AS ITEM_ALOW1
                    , CUST_PO_ITEM :: VARCHAR AS CUST_PO_ITEM
                    , ITEM_ALOW2
                    , PACK_CHARGE
                    , PART_CODE
                    , ITEM_COST
                    , PO_ITEM :: VARCHAR  AS PO_ITEM
                    , ITEM_OUTTIME
                    , ITEM_SALETYPE
                    , DATE_INV
                    , ITEM_DISCOUNT
                    , ITEM_NTPRICE
                    , QTY_RECVD
                    , VOL_DISC_AMT
                    , EXT_PRICE :: NUMBER  AS EXT_PRICE
                    , XCUR_CONV
                    , TOT_QTY_ORD :: NUMBER AS TOT_QTY_ORD
                    , CUST_PO
                    , ORIG_REL_NUMB
                    , MSTRKIT_ITEM_NO
                    , CARR_CODE
                    , KIT_REQ_FLAG
                    , BCUR_CONV
                    , ITEM_PRICEID
                    , DATE_INVOICE
                    , DATE_ENTERED
                    , UPDATE_DATE
                    , ITEM_LIST_PRICE
                    , DTFLD1
                    , NUMFLD1 :: VARCHAR  AS NUMFLD1
                    , NUMFLD2 :: NUMBER  AS NUMFLD2
                    , ITEM_ALOW2T
                    , NUMFLD3
                    , QTY_ALLOCATED :: NUMBER AS QTY_ALLOCATED
                    , DTFLD2
                    , UOM_CONV
                    , BALDUE
                    , TOT_QTY_INVOICE
                    , MSTRKIT_CODE
                    , PO_VEND_CODE
                    , QTY
                    , CUST_REQ_DATE
                    , XCUR_UOM
                    , ORDER_DISC_TY
                    , DISP_PART
                    , EXPIRE_DATE
                    , DUEDATE
                    , ITEM_PSDISC_AMT
                    , PART_DESC
                    , PO_UNIT_PRICE
                    , ITEM_ALOW1T
                    , SHIPTO_GEOCODE
                    , ACK_PRNT_DATE
                    , ITEM_WGT
                    , PO_NUMBER
                    , ITEM_REP
                    , PACK_UOM
                    ,REQ_NUMBER
                    ,SCHFLD1
                    ,DATE_CUST
                    ,SCHFLD3
                    ,ITEM_GWGT
                    ,SCHFLD2
                    ,ITEM_PPV
                    ,ORIG_ORDER_NUMB
                    ,ITEM_OUTDATE
                    ,GIFT_FLAG
                    ,ITEM_STATUS
                    ,BCUR_UOM
                    ,ITEM_MSG
                    ,ITEM_TYPE
                    ,DATE_RECVD
                    ,DATE_ALLOC
                    ,COST_CTR
                    ,TOT_QTY_SHIP
                    ,ORDER_DISC_AMT
                    , UOM
                    ,QTY_SHIPPED
                    ,ITEM_PRICE
                    ,CART_CHG
                    , _FIVETRAN_DELETED :: VARCHAR AS _FIVETRAN_DELETED
                    , LOAD_DTS
                    ,_FIVETRAN_SYNCED
                    ,PSA_RECORD_SOURCE
                    ,PSA_DELETE_IND
    FROM SRC_SAT_OH
)

---- RENAME LAYER ----

, RENAME_HUB as (
    SELECT
        ORDER_LINE_HK                                              as SALES_ORDER_LINE_HK
      , ORDER_LINE_BK                                              as SALES_ORDER_LINE_BK
      , REC_SRC           
      , BKCC                                                   
    FROM LOGIC_HUB
)

, RENAME_SAT_OH as (
    SELECT
        ORDER_LINE_HK
                    , _FIVETRAN_ID
                    , ORDER_NUMB
                    , REL_NUMB
                    , ITEM_NO
                    , ORIG_GEOCODE
                    , PACK_QTY
                    , ITEM_TERMS
                    , ITEM_LOAD_NO
                    , SHIPTO_CODE
                    , CONSOL_NUMB
                    , ORIG_ITEM_NO
                    , TAX_EXEMPT_ID
                    , ITEM_PSDISC_TY
                    , PART_ATTRIBUTE1
                    , ITEM_DISCOUNT_TY
                    , PART_ATTRIBUTE3
                    , PART_ATTRIBUTE2
                    , DISC_TYPE
                    , PART_ATTRIBUTE5
                    , PART_ATTRIBUTE4
                    , CONFIG_ID
                    , DIVISION_CODE
                    , PART_ATTRIBUTE6
                    , LCHFLD2
                    , COMMIT_QTY
                    , LCHFLD1
                    , MAINT_PART_CODE
                    , ITEM_TAXABLE
                    , VOL_DISC_TY
                    , ACK_PRNT_METH
                    , PO_REL
                    , DATE_INV_PRINT
                    , CANCEL_DATE
                    , ITEM_ALOW1
                    , CUST_PO_ITEM
                    , ITEM_ALOW2
                    , PACK_CHARGE
                    , PART_CODE
                    , ITEM_COST
                    , PO_ITEM
                    , ITEM_OUTTIME
                    , ITEM_SALETYPE
                    , DATE_INV
                    , ITEM_DISCOUNT
                    , ITEM_NTPRICE
                    , QTY_RECVD
                    , VOL_DISC_AMT
                    , EXT_PRICE
                    , XCUR_CONV
                    , TOT_QTY_ORD
                    , CUST_PO
                    , ORIG_REL_NUMB
                    , MSTRKIT_ITEM_NO
                    , CARR_CODE
                    , KIT_REQ_FLAG
                    , BCUR_CONV
                    , ITEM_PRICEID
                    , DATE_INVOICE
                    , DATE_ENTERED
                    , UPDATE_DATE
                    , ITEM_LIST_PRICE
                    , DTFLD1
                    , NUMFLD1
                    , NUMFLD2
                    , ITEM_ALOW2T
                    , NUMFLD3
                    , QTY_ALLOCATED
                    , DTFLD2
                    , UOM_CONV
                    , BALDUE
                    , TOT_QTY_INVOICE
                    , MSTRKIT_CODE
                    , PO_VEND_CODE
                    , QTY
                    , CUST_REQ_DATE
                    , XCUR_UOM
                    , ORDER_DISC_TY
                    , DISP_PART
                    , EXPIRE_DATE
                    , DUEDATE
                    , ITEM_PSDISC_AMT
                    , PART_DESC
                    , PO_UNIT_PRICE
                    , ITEM_ALOW1T
                    , SHIPTO_GEOCODE
                    , ACK_PRNT_DATE
                    , ITEM_WGT
                    , PO_NUMBER
                    , ITEM_REP
                    , PACK_UOM
                    ,REQ_NUMBER
                    ,SCHFLD1
                    ,DATE_CUST
                    ,SCHFLD3
                    ,ITEM_GWGT
                    ,SCHFLD2
                    ,ITEM_PPV
                    ,ORIG_ORDER_NUMB
                    ,ITEM_OUTDATE
                    ,GIFT_FLAG
                    ,ITEM_STATUS
                    ,BCUR_UOM
                    ,ITEM_MSG
                    ,ITEM_TYPE
                    ,DATE_RECVD
                    ,DATE_ALLOC
                    ,COST_CTR
                    ,TOT_QTY_SHIP
                    ,ORDER_DISC_AMT
                    , UOM
                    ,QTY_SHIPPED
                    ,ITEM_PRICE
                    ,CART_CHG
                    , _FIVETRAN_DELETED
                    , LOAD_DTS
                    ,_FIVETRAN_SYNCED
                    ,PSA_RECORD_SOURCE
                    ,PSA_DELETE_IND
    FROM LOGIC_SAT_OH
)

---- FILTER LAYER ----

, FILTER_HUB as (
    SELECT *
    FROM RENAME_HUB
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'
)

, FILTER_SAT_OH as (
    SELECT *
    FROM RENAME_SAT_OH
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT 
        FILTER_HUB.SALES_ORDER_LINE_HK
      , FILTER_HUB.SALES_ORDER_LINE_BK
      , FILTER_HUB.REC_SRC
      , FILTER_HUB.BKCC
, FILTER_SAT_OH._FIVETRAN_ID
, FILTER_SAT_OH.ORDER_NUMB
, FILTER_SAT_OH.REL_NUMB
, FILTER_SAT_OH.ITEM_NO
, FILTER_SAT_OH.ORIG_GEOCODE
, FILTER_SAT_OH.PACK_QTY
, FILTER_SAT_OH.ITEM_TERMS
, FILTER_SAT_OH.ITEM_LOAD_NO
, FILTER_SAT_OH.SHIPTO_CODE
, FILTER_SAT_OH.CONSOL_NUMB
, FILTER_SAT_OH.ORIG_ITEM_NO
, FILTER_SAT_OH.TAX_EXEMPT_ID
, FILTER_SAT_OH.ITEM_PSDISC_TY
, FILTER_SAT_OH.PART_ATTRIBUTE1
, FILTER_SAT_OH.ITEM_DISCOUNT_TY
, FILTER_SAT_OH.PART_ATTRIBUTE3
, FILTER_SAT_OH.PART_ATTRIBUTE2
, FILTER_SAT_OH.DISC_TYPE
, FILTER_SAT_OH.PART_ATTRIBUTE5
, FILTER_SAT_OH.PART_ATTRIBUTE4
, FILTER_SAT_OH.CONFIG_ID
, FILTER_SAT_OH.DIVISION_CODE
, FILTER_SAT_OH.PART_ATTRIBUTE6
, FILTER_SAT_OH.LCHFLD2
, FILTER_SAT_OH.COMMIT_QTY
, FILTER_SAT_OH.LCHFLD1
, FILTER_SAT_OH.MAINT_PART_CODE
, FILTER_SAT_OH.ITEM_TAXABLE
, FILTER_SAT_OH.VOL_DISC_TY
, FILTER_SAT_OH.ACK_PRNT_METH
, FILTER_SAT_OH.PO_REL
, FILTER_SAT_OH.DATE_INV_PRINT
, FILTER_SAT_OH.CANCEL_DATE
, FILTER_SAT_OH.ITEM_ALOW1
, FILTER_SAT_OH.CUST_PO_ITEM
, FILTER_SAT_OH.ITEM_ALOW2
, FILTER_SAT_OH.PACK_CHARGE
, FILTER_SAT_OH.PART_CODE
, FILTER_SAT_OH.ITEM_COST
, FILTER_SAT_OH.PO_ITEM
, FILTER_SAT_OH.ITEM_OUTTIME
, FILTER_SAT_OH.ITEM_SALETYPE
, FILTER_SAT_OH.DATE_INV
, FILTER_SAT_OH.ITEM_DISCOUNT
, FILTER_SAT_OH.ITEM_NTPRICE
, FILTER_SAT_OH.QTY_RECVD
, FILTER_SAT_OH.VOL_DISC_AMT
, FILTER_SAT_OH.EXT_PRICE
, FILTER_SAT_OH.XCUR_CONV
, FILTER_SAT_OH.TOT_QTY_ORD
, FILTER_SAT_OH.CUST_PO
, FILTER_SAT_OH.ORIG_REL_NUMB
, FILTER_SAT_OH.MSTRKIT_ITEM_NO
, FILTER_SAT_OH.CARR_CODE
, FILTER_SAT_OH.KIT_REQ_FLAG
, FILTER_SAT_OH.BCUR_CONV
, FILTER_SAT_OH.ITEM_PRICEID
, FILTER_SAT_OH.DATE_INVOICE
, FILTER_SAT_OH.DATE_ENTERED
, FILTER_SAT_OH.UPDATE_DATE
, FILTER_SAT_OH.ITEM_LIST_PRICE
, FILTER_SAT_OH.DTFLD1
, FILTER_SAT_OH.NUMFLD1
, FILTER_SAT_OH.NUMFLD2
, FILTER_SAT_OH.ITEM_ALOW2T
, FILTER_SAT_OH.NUMFLD3
, FILTER_SAT_OH.QTY_ALLOCATED
, FILTER_SAT_OH.DTFLD2
, FILTER_SAT_OH.UOM_CONV
, FILTER_SAT_OH.BALDUE
, FILTER_SAT_OH.TOT_QTY_INVOICE
, FILTER_SAT_OH.MSTRKIT_CODE
, FILTER_SAT_OH.PO_VEND_CODE
, FILTER_SAT_OH.QTY
, FILTER_SAT_OH.CUST_REQ_DATE
, FILTER_SAT_OH.XCUR_UOM
, FILTER_SAT_OH.ORDER_DISC_TY
, FILTER_SAT_OH.DISP_PART
, FILTER_SAT_OH.EXPIRE_DATE
, FILTER_SAT_OH.DUEDATE
, FILTER_SAT_OH.ITEM_PSDISC_AMT
, FILTER_SAT_OH.PART_DESC
, FILTER_SAT_OH.PO_UNIT_PRICE
, FILTER_SAT_OH.ITEM_ALOW1T
, FILTER_SAT_OH.SHIPTO_GEOCODE
, FILTER_SAT_OH.ACK_PRNT_DATE
, FILTER_SAT_OH.ITEM_WGT
, FILTER_SAT_OH.PO_NUMBER
, FILTER_SAT_OH.ITEM_REP
, FILTER_SAT_OH.PACK_UOM
, FILTER_SAT_OH.REQ_NUMBER
, FILTER_SAT_OH.SCHFLD1
, FILTER_SAT_OH.DATE_CUST
, FILTER_SAT_OH.SCHFLD3
, FILTER_SAT_OH.ITEM_GWGT
, FILTER_SAT_OH.SCHFLD2
, FILTER_SAT_OH.ITEM_PPV
, FILTER_SAT_OH.ORIG_ORDER_NUMB
, FILTER_SAT_OH.ITEM_OUTDATE
, FILTER_SAT_OH.GIFT_FLAG
, FILTER_SAT_OH.ITEM_STATUS
, FILTER_SAT_OH.BCUR_UOM
, FILTER_SAT_OH.ITEM_MSG
, FILTER_SAT_OH.ITEM_TYPE
, FILTER_SAT_OH.DATE_RECVD
, FILTER_SAT_OH.DATE_ALLOC
, FILTER_SAT_OH.COST_CTR
, FILTER_SAT_OH.TOT_QTY_SHIP
, FILTER_SAT_OH.ORDER_DISC_AMT
, FILTER_SAT_OH.UOM
, FILTER_SAT_OH.QTY_SHIPPED
, FILTER_SAT_OH.ITEM_PRICE
, FILTER_SAT_OH.CART_CHG
, FILTER_SAT_OH._FIVETRAN_DELETED
, FILTER_SAT_OH.LOAD_DTS
, FILTER_SAT_OH._FIVETRAN_SYNCED
, FILTER_SAT_OH.PSA_RECORD_SOURCE
, FILTER_SAT_OH.PSA_DELETE_IND
        FROM FILTER_HUB
    INNER JOIN FILTER_SAT_OH
        ON FILTER_HUB.SALES_ORDER_LINE_HK = FILTER_SAT_OH.ORDER_LINE_HK
)

---- FINAL LAYER ----
SELECT
        'E21'                                                       as SOURCE
      , SALES_ORDER_LINE_HK
      , SALES_ORDER_LINE_BK
    , ORIG_ORDER_NUMB AS SALES_ORDER_NUMBER,
    PO_ITEM AS SALES_ORDER_LINE_NUMBER,
    ITEM_REP AS PARTNER_FUNCTION,
    TRY_TO_NUMBER(NULLIF(TRIM(DATE_ENTERED, 'YYYYMMDD'), ''))         AS SALES_ORDER_CREATION_DATE_KEY,
    ITEM_STATUS AS SALES_ORDER_DELIVERY_IND,
    PO_VEND_CODE AS CUSTOMER_BK,
    PART_CODE AS ITEM_BK,
    PART_DESC AS SALES_ORDER_ITEM_DESC,
    ITEM_TYPE AS SALES_ORDER_DOCUMENT_TYPE,
    DISP_PART AS SALES_ORDER_LINE_RETURN_IND,
    QTY AS QUANTITY,
    ITEM_NTPRICE AS NET_PRICE,
    EXT_PRICE AS NET_VALUE,
    ITEM_MSG AS RETURN_REASON_CODE,
    DIVISION_CODE AS PLANT,
    ITEM_SALETYPE AS SALES_ORDER_ITEM_CATEGORY,
    ITEM_ALOW1 AS REJECTION_REASON,
    TOT_QTY_ORD AS CUMULATIVE_ORDER_QUANTITY,
    QTY_ALLOCATED AS CUMULATIVE_REQUIRED_QUANTITY,
    COMMIT_QTY AS CUMULATIVE_CONFIRMED_QUANTITY,
    NUMFLD1 AS DELIVERY_PRIORITY,
    PACK_QTY AS MINIMUM_DELIVERY_QUANTITY,
    TRY_TO_NUMBER(NULLIF(TRIM(UPDATE_DATE, 'YYYYMMDD'), ''))               AS LAST_CHANGE_DATE_LINE__YYYYMMDD,
    KIT_REQ_FLAG AS REQUIREMENTS_TYPE,
    COST_CTR AS BUSINESS_AREA,
    NUMFLD2 AS MAX_NUMBER_OF_PARTIAL_DELIVERIES,
    ITEM_PRICEID AS PRICING_GROUP,
    CUST_PO_ITEM AS CUSTOMER_MATERIAL_NUMBER,
    ORDER_DISC_TY AS SALES_DEAL
    , REC_SRC
    , BKCC
    , _FIVETRAN_DELETED         AS  IS_DELETED
FROM JOIN_RESULT
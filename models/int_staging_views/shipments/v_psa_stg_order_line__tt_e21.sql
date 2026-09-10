---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('tt_e21prd_e21trubis', 'orditem') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT                 
        CONCAT_WS('||', COALESCE(ORDER_NUMB, ''), COALESCE(REL_NUMB, ''), COALESCE(ITEM_NO::TEXT, ''))    as                                    ORDER_LINE_BK
       , _FIVETRAN_ID
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
      ,  PART_ATTRIBUTE4
       , CONFIG_ID
       , DIVISION_CODE
      ,  PART_ATTRIBUTE6
       , LCHFLD2
      ,  COMMIT_QTY
      ,  LCHFLD1
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
      ,  ITEM_SALETYPE
       , DATE_INV
       , ITEM_DISCOUNT
      ,  ITEM_NTPRICE
       , QTY_RECVD
      ,  VOL_DISC_AMT
      ,  EXT_PRICE
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
      ,  NUMFLD1
       , NUMFLD2
       , ITEM_ALOW2T
      ,  NUMFLD3
       , QTY_ALLOCATED
      ,  DTFLD2
      ,  UOM_CONV
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
      ,  ITEM_ALOW1T
       , SHIPTO_GEOCODE
       , ACK_PRNT_DATE
      ,  ITEM_WGT
       , PO_NUMBER
      ,  ITEM_REP
      ,  PACK_UOM
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
      , DATE_RECVD
       ,DATE_ALLOC
       ,COST_CTR
      , TOT_QTY_SHIP
       ,ORDER_DISC_AMT
      , UOM
      , QTY_SHIPPED
       ,ITEM_PRICE
       ,CART_CHG
       , _FIVETRAN_DELETED
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS    
    FROM SRC_S
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
            ORDER_LINE_BK
       , _FIVETRAN_ID
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
      ,  PART_ATTRIBUTE4
       , CONFIG_ID
       , DIVISION_CODE
      ,  PART_ATTRIBUTE6
       , LCHFLD2
      ,  COMMIT_QTY
      ,  LCHFLD1
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
      ,  ITEM_SALETYPE
       , DATE_INV
       , ITEM_DISCOUNT
      ,  ITEM_NTPRICE
       , QTY_RECVD
      ,  VOL_DISC_AMT
      ,  EXT_PRICE
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
      ,  NUMFLD1
       , NUMFLD2
       , ITEM_ALOW2T
      ,  NUMFLD3
       , QTY_ALLOCATED
      ,  DTFLD2
      ,  UOM_CONV
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
      ,  ITEM_ALOW1T
       , SHIPTO_GEOCODE
       , ACK_PRNT_DATE
      ,  ITEM_WGT
       , PO_NUMBER
      ,  ITEM_REP
      ,  PACK_UOM
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
      , DATE_RECVD
       ,DATE_ALLOC
       ,COST_CTR
      , TOT_QTY_SHIP
       ,ORDER_DISC_AMT
      , UOM
      , QTY_SHIPPED
       ,ITEM_PRICE
       ,CART_CHG
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
    WHERE rec_src = 'USWIOC.ORCL.E21PRD.ORDITEM'
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
         ORDER_LINE_BK
       , _FIVETRAN_ID
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
      ,  PART_ATTRIBUTE4
       , CONFIG_ID
       , DIVISION_CODE
      ,  PART_ATTRIBUTE6
       , LCHFLD2
      ,  COMMIT_QTY
      ,  LCHFLD1
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
      ,  ITEM_SALETYPE
       , DATE_INV
       , ITEM_DISCOUNT
      ,  ITEM_NTPRICE
       , QTY_RECVD
      ,  VOL_DISC_AMT
      ,  EXT_PRICE
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
      ,  NUMFLD1
       , NUMFLD2
       , ITEM_ALOW2T
      ,  NUMFLD3
       , QTY_ALLOCATED
      ,  DTFLD2
      ,  UOM_CONV
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
      ,  ITEM_ALOW1T
       , SHIPTO_GEOCODE
       , ACK_PRNT_DATE
      ,  ITEM_WGT
       , PO_NUMBER
      ,  ITEM_REP
      ,  PACK_UOM
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
      , DATE_RECVD
       ,DATE_ALLOC
       ,COST_CTR
      , TOT_QTY_SHIP
       ,ORDER_DISC_AMT
      , UOM
      , QTY_SHIPPED
       ,ITEM_PRICE
       ,CART_CHG
       , _FIVETRAN_DELETED
       , LOAD_DTS
       , REC_SRC
       , BKCC 
       , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_LINE_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ORDER_LINE_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ORIG_GEOCODE::text), '^^')
        ,'||', IFNULL(TRIM(PACK_QTY::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_TERMS::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_LOAD_NO::text), '^^')
        ,'||', IFNULL(TRIM(SHIPTO_CODE::text), '^^')
        ,'||', IFNULL(TRIM(CONSOL_NUMB::text), '^^')
        ,'||', IFNULL(TRIM(ORIG_ITEM_NO::text), '^^')
        ,'||', IFNULL(TRIM(TAX_EXEMPT_ID::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_PSDISC_TY::text), '^^')
        ,'||', IFNULL(TRIM(PART_ATTRIBUTE1::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_DISCOUNT_TY::text), '^^')
        ,'||', IFNULL(TRIM(PART_ATTRIBUTE3::text), '^^')
        ,'||', IFNULL(TRIM(PART_ATTRIBUTE2::text), '^^')
        ,'||', IFNULL(TRIM(DISC_TYPE::text), '^^')
        ,'||', IFNULL(TRIM(PART_ATTRIBUTE5::text), '^^')
        ,'||', IFNULL(TRIM(PART_ATTRIBUTE4::text), '^^')
        ,'||', IFNULL(TRIM(CONFIG_ID::text), '^^')
        ,'||', IFNULL(TRIM(DIVISION_CODE::text), '^^')
        ,'||', IFNULL(TRIM(PART_ATTRIBUTE6::text), '^^')
        ,'||', IFNULL(TRIM(LCHFLD2::text), '^^')
        ,'||', IFNULL(TRIM(COMMIT_QTY::text), '^^')
        ,'||', IFNULL(TRIM(LCHFLD1::text), '^^')
        ,'||', IFNULL(TRIM(MAINT_PART_CODE::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_TAXABLE::text), '^^')
        ,'||', IFNULL(TRIM(VOL_DISC_TY::text), '^^')
        ,'||', IFNULL(TRIM(ACK_PRNT_METH::text), '^^')
        ,'||', IFNULL(TRIM(PO_REL::text), '^^')
        ,'||', IFNULL(TRIM(DATE_INV_PRINT::text), '^^')
        ,'||', IFNULL(TRIM(CANCEL_DATE::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_ALOW1::text), '^^')
        ,'||', IFNULL(TRIM(CUST_PO_ITEM::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_ALOW2::text), '^^')
        ,'||', IFNULL(TRIM(PACK_CHARGE::text), '^^')
        ,'||', IFNULL(TRIM(PART_CODE::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_COST::text), '^^')
        ,'||', IFNULL(TRIM(PO_ITEM::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_OUTTIME::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_SALETYPE::text), '^^')
        ,'||', IFNULL(TRIM(DATE_INV::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_DISCOUNT::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_NTPRICE::text), '^^')
        ,'||', IFNULL(TRIM(QTY_RECVD::text), '^^')
        ,'||', IFNULL(TRIM(VOL_DISC_AMT::text), '^^')
        ,'||', IFNULL(TRIM(EXT_PRICE::text), '^^')
        ,'||', IFNULL(TRIM(XCUR_CONV::text), '^^')
        ,'||', IFNULL(TRIM(TOT_QTY_ORD::text), '^^')
        ,'||', IFNULL(TRIM(CUST_PO::text), '^^')
        ,'||', IFNULL(TRIM(ORIG_REL_NUMB::text), '^^')
        ,'||', IFNULL(TRIM(MSTRKIT_ITEM_NO::text), '^^')
        ,'||', IFNULL(TRIM(CARR_CODE::text), '^^')
        ,'||', IFNULL(TRIM(KIT_REQ_FLAG::text), '^^')
        ,'||', IFNULL(TRIM(BCUR_CONV::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_PRICEID::text), '^^')
        ,'||', IFNULL(TRIM(DATE_INVOICE::text), '^^')
        ,'||', IFNULL(TRIM(DATE_ENTERED::text), '^^')
        ,'||', IFNULL(TRIM(UPDATE_DATE::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_LIST_PRICE::text), '^^')
        ,'||', IFNULL(TRIM(DTFLD1::text), '^^')
        ,'||', IFNULL(TRIM(NUMFLD1::text), '^^')
        ,'||', IFNULL(TRIM(NUMFLD2::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_ALOW2T::text), '^^')
        ,'||', IFNULL(TRIM(NUMFLD3::text), '^^')
        ,'||', IFNULL(TRIM(QTY_ALLOCATED::text), '^^')
        ,'||', IFNULL(TRIM(DTFLD2::text), '^^')
        ,'||', IFNULL(TRIM(UOM_CONV::text), '^^')
        ,'||', IFNULL(TRIM(BALDUE::text), '^^')
        ,'||', IFNULL(TRIM(TOT_QTY_INVOICE::text), '^^')
        ,'||', IFNULL(TRIM(MSTRKIT_CODE::text), '^^')
        ,'||', IFNULL(TRIM(PO_VEND_CODE::text), '^^')
        ,'||', IFNULL(TRIM(QTY::text), '^^')
        ,'||', IFNULL(TRIM(CUST_REQ_DATE::text), '^^')
        ,'||', IFNULL(TRIM(XCUR_UOM::text), '^^')
        ,'||', IFNULL(TRIM(ORDER_DISC_TY::text), '^^')
        ,'||', IFNULL(TRIM(DISP_PART::text), '^^')
        ,'||', IFNULL(TRIM(EXPIRE_DATE::text), '^^')
        ,'||', IFNULL(TRIM(DUEDATE::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_PSDISC_AMT::text), '^^')
        ,'||', IFNULL(TRIM(PART_DESC::text), '^^')
        ,'||', IFNULL(TRIM(PO_UNIT_PRICE::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_ALOW1T::text), '^^')
        ,'||', IFNULL(TRIM(SHIPTO_GEOCODE::text), '^^')
        ,'||', IFNULL(TRIM(ACK_PRNT_DATE::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_WGT::text), '^^')
        ,'||', IFNULL(TRIM(PO_NUMBER::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_REP::text), '^^')
        ,'||', IFNULL(TRIM(PACK_UOM::text), '^^')
        ,'||', IFNULL(TRIM(REQ_NUMBER::text), '^^')
        ,'||', IFNULL(TRIM(SCHFLD1::text), '^^')
        ,'||', IFNULL(TRIM(DATE_CUST::text), '^^')
        ,'||', IFNULL(TRIM(SCHFLD3::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_GWGT::text), '^^')
        ,'||', IFNULL(TRIM(SCHFLD2::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_PPV::text), '^^')
        ,'||', IFNULL(TRIM(ORIG_ORDER_NUMB::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_OUTDATE::text), '^^')
        ,'||', IFNULL(TRIM(GIFT_FLAG::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_STATUS::text), '^^')
        ,'||', IFNULL(TRIM(BCUR_UOM::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_MSG::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_TYPE::text), '^^')
        ,'||', IFNULL(TRIM(DATE_RECVD::text), '^^')
        ,'||', IFNULL(TRIM(DATE_ALLOC::text), '^^')
        ,'||', IFNULL(TRIM(COST_CTR::text), '^^')
        ,'||', IFNULL(TRIM(TOT_QTY_SHIP::text), '^^')
        ,'||', IFNULL(TRIM(ORDER_DISC_AMT::text), '^^')
        ,'||', IFNULL(TRIM(UOM::text), '^^')
        ,'||', IFNULL(TRIM(QTY_SHIPPED::text), '^^')
        ,'||', IFNULL(TRIM(ITEM_PRICE::text), '^^')
        ,'||', IFNULL(TRIM(CART_CHG::text), '^^')
        ,'||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^')), '^^||^^'))) 
        as HASHDIFF
FROM JOIN_RESULT
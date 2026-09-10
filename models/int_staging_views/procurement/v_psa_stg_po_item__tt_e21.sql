---- SRC LAYER ----
WITH
SRC_pitm           as ( SELECT ACCT_NO, ASSIGN_FLAG, BALDUE, BCUR_CONV, BCUR_UOM, BILLED_FLAG, BILL_STATUS, CLOSE_FLAG, COMMODITY_CODE, COST_CTR, DATE_CLOSED, DATE_ORDERD, DATE_PROMISED, DATE_PROM_DATE, DATE_PROM_USER, DATE_RCV, DATE_REQD, DISP_PART, FIXED_ASSET, FLG_1099, INVOICED_BILL, INVOICED_COST, INV_EXT_COST, ITEM_DISCOUNT, ITEM_GWGT, ITEM_NO, ITEM_NTPRICE, ITEM_PPV, ITEM_SHIPCHG, ITEM_STATUS, ITEM_TERMS, ITEM_WGT, JOB_NO, JOB_STATUS, LIST_PRICE, LOCATION, NOTES_FLAG, ORDERED_BILL, ORDERED_COST, ORD_EXT_COST, ORD_UN_BILL, ORD_UN_COST, ORIG_DATE_PROMISED, PART_ATTRIBUTE1, PART_ATTRIBUTE2, PART_ATTRIBUTE3, PART_ATTRIBUTE4, PART_ATTRIBUTE5, PART_ATTRIBUTE6, PART_CODE, PART_DESC, PART_TYPE, PHASE_CODE, POLIN_SERIAL, PO_NUMBER, PO_PRINT_DATE, PO_PRINT_FLAG, PO_PRINT_METH, PRICE_CHGD, PRODUCT_CODE, PRODUCT_REQ, PROJID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, QTY_BILLED, QTY_INVOICE, QTY_INVOICED, QTY_ORD, QTY_ORDERED, QTY_RECEIVED, QTY_RECVD, QTY_TO_BILL, QTY_VOUCHED, RCV_CONV, RCV_UOM, REASON_CODE, REL_NUMB, REQ_NUMBER, ROYALTY_OWED, ROYALTY_PAID, SEQUENCE_ID, SHIP_TO, SO_ITEM, SO_NUMBER, SO_REL, STEP_CODE, TASK_NO, TRACKING_NO, UNIT_BILL, UNIT_COST, UNIT_MEASURE, UNIT_PRICE, UOM, UOM_CONV, VENDOR_STATUS, VEND_CODE, VEND_NAME, VEND_SITE, VNDRET_BIN, VNDRET_LOC, VNDRET_LOT, VOL_DISC_AMT, VOL_DISC_TY, VOUCHED_COST, VPM_SERIAL, V_PART_NUMBER, XCUR_CONV, XCUR_UOM, _FIVETRAN_DELETED, _FIVETRAN_ID, _FIVETRAN_SYNCED FROM {{ source('tt_e21prd_e21trubis', 'poitem') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_phd            as ( SELECT BILLTO_CODE, PO_NUMBER, REL_NUMB FROM {{ source('tt_e21prd_e21trubis', 'pohead') }} as SRC 
                        qualify 1 = row_number()over (partition by po_number,rel_numb order by psa_load_dts desc) )

/*
SRC_pitm           as ( SELECT * FROM tt_e21prd_e21trubis.poitem )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_phd            as ( SELECT * FROM tt_e21prd_e21trubis.pohead )
*/
---- LOGIC LAYER ----

, LOGIC_pitm as (
    SELECT
        PO_NUMBER                                                    as                                       PO_HEADER_BK
      , CONCAT_WS('||', COALESCE(PO_NUMBER, ''), COALESCE(ITEM_NO::TEXT, '')) as                                         PO_ITEM_BK
      , PO_NUMBER
      , ITEM_NO
      , REL_NUMB
      , PART_TYPE
      , ORIG_DATE_PROMISED
      , UNIT_COST
      , RCV_UOM
      , ITEM_TERMS
      , UNIT_PRICE
      , SEQUENCE_ID
      , QTY_ORDERED
      , PRODUCT_CODE
      , QTY_VOUCHED
      , PROJID
      , QTY_INVOICE
      , INV_EXT_COST
      , PART_ATTRIBUTE1
      , TRACKING_NO
      , PART_ATTRIBUTE3
      , PART_ATTRIBUTE2
      , PART_ATTRIBUTE5
      , JOB_NO
      , PART_ATTRIBUTE4
      , PART_ATTRIBUTE6
      , ORDERED_BILL
      , QTY_TO_BILL
      , NOTES_FLAG
      , VOL_DISC_TY
      , ASSIGN_FLAG
      , PO_PRINT_METH
      , VPM_SERIAL
      , SO_REL
      , PRICE_CHGD
      , ROYALTY_OWED
      , LOCATION
      , PART_CODE
      , PHASE_CODE
      , DATE_PROM_USER
      , UNIT_BILL
      , ITEM_DISCOUNT
      , ITEM_NTPRICE
      , COMMODITY_CODE
      , QTY_RECVD
      , VOL_DISC_AMT
      , XCUR_CONV
      , PRODUCT_REQ
      , DATE_PROM_DATE
      , DATE_REQD
      , DATE_PROMISED
      , BCUR_CONV
      , ROYALTY_PAID
      , STEP_CODE
      , VOUCHED_COST
      , VEND_CODE
      , VNDRET_BIN
      , SO_NUMBER
      , ORD_EXT_COST
      , ORD_UN_COST
      , UOM_CONV
      , BALDUE
      , TASK_NO
      , PO_PRINT_FLAG
      , RCV_CONV
      , V_PART_NUMBER
      , FIXED_ASSET
      , XCUR_UOM
      , DISP_PART
      , QTY_BILLED
      , VEND_SITE
      , DATE_RCV
      , BILLED_FLAG
      , PART_DESC
      , QTY_INVOICED
      , ITEM_WGT
      , INVOICED_BILL
      , CLOSE_FLAG
      , REQ_NUMBER
      , ITEM_GWGT
      , DATE_CLOSED
      , LIST_PRICE
      , ITEM_PPV
      , SO_ITEM
      , BILL_STATUS
      , VNDRET_LOC
      , POLIN_SERIAL
      , ACCT_NO
      , ITEM_STATUS
      , ORD_UN_BILL
      , ITEM_SHIPCHG
      , VEND_NAME
      , FLG_1099
      , BCUR_UOM
      , QTY_ORD
      , UNIT_MEASURE
      , JOB_STATUS
      , ORDERED_COST
      , COST_CTR
      , REASON_CODE
      , DATE_ORDERD
      , INVOICED_COST
      , VENDOR_STATUS
      , PO_PRINT_DATE
      , UOM
      , SHIP_TO
      , QTY_RECEIVED
      , VNDRET_LOT
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_pitm
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_phd as (
    SELECT
        PO_NUMBER                                                    as                                      PHD_PO_NUMBER
      , REL_NUMB                                                     as                                       PHD_REL_NUMB
      , BILLTO_CODE
    FROM SRC_phd
)
---- RENAME LAYER ----

, RENAME_pitm as (
    SELECT
        PO_HEADER_BK
      , PO_ITEM_BK
      , PO_NUMBER
      , ITEM_NO
      , REL_NUMB
      , PART_TYPE
      , ORIG_DATE_PROMISED
      , UNIT_COST
      , RCV_UOM
      , ITEM_TERMS
      , UNIT_PRICE
      , SEQUENCE_ID
      , QTY_ORDERED
      , PRODUCT_CODE
      , QTY_VOUCHED
      , PROJID
      , QTY_INVOICE
      , INV_EXT_COST
      , PART_ATTRIBUTE1
      , TRACKING_NO
      , PART_ATTRIBUTE3
      , PART_ATTRIBUTE2
      , PART_ATTRIBUTE5
      , JOB_NO
      , PART_ATTRIBUTE4
      , PART_ATTRIBUTE6
      , ORDERED_BILL
      , QTY_TO_BILL
      , NOTES_FLAG
      , VOL_DISC_TY
      , ASSIGN_FLAG
      , PO_PRINT_METH
      , VPM_SERIAL
      , SO_REL
      , PRICE_CHGD
      , ROYALTY_OWED
      , LOCATION
      , PART_CODE
      , PHASE_CODE
      , DATE_PROM_USER
      , UNIT_BILL
      , ITEM_DISCOUNT
      , ITEM_NTPRICE
      , COMMODITY_CODE
      , QTY_RECVD
      , VOL_DISC_AMT
      , XCUR_CONV
      , PRODUCT_REQ
      , DATE_PROM_DATE
      , DATE_REQD
      , DATE_PROMISED
      , BCUR_CONV
      , ROYALTY_PAID
      , STEP_CODE
      , VOUCHED_COST
      , VEND_CODE
      , VNDRET_BIN
      , SO_NUMBER
      , ORD_EXT_COST
      , ORD_UN_COST
      , UOM_CONV
      , BALDUE
      , TASK_NO
      , PO_PRINT_FLAG
      , RCV_CONV
      , V_PART_NUMBER
      , FIXED_ASSET
      , XCUR_UOM
      , DISP_PART
      , QTY_BILLED
      , VEND_SITE
      , DATE_RCV
      , BILLED_FLAG
      , PART_DESC
      , QTY_INVOICED
      , ITEM_WGT
      , INVOICED_BILL
      , CLOSE_FLAG
      , REQ_NUMBER
      , ITEM_GWGT
      , DATE_CLOSED
      , LIST_PRICE
      , ITEM_PPV
      , SO_ITEM
      , BILL_STATUS
      , VNDRET_LOC
      , POLIN_SERIAL
      , ACCT_NO
      , ITEM_STATUS
      , ORD_UN_BILL
      , ITEM_SHIPCHG
      , VEND_NAME
      , FLG_1099
      , BCUR_UOM
      , QTY_ORD
      , UNIT_MEASURE
      , JOB_STATUS
      , ORDERED_COST
      , COST_CTR
      , REASON_CODE
      , DATE_ORDERD
      , INVOICED_COST
      , VENDOR_STATUS
      , PO_PRINT_DATE
      , UOM
      , SHIP_TO
      , QTY_RECEIVED
      , VNDRET_LOT
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_pitm
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)

, RENAME_phd as (
    SELECT
        PHD_PO_NUMBER
      , PHD_REL_NUMB
      , BILLTO_CODE
    FROM LOGIC_phd
)
---- FILTER LAYER ----

, FILTER_pitm as (
    SELECT *
    FROM RENAME_pitm
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USOHMA.ORCL.E21PRD.POITEM'
)

, FILTER_phd as (
    SELECT *
    FROM RENAME_phd
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_pitm
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_phd
        ON FILTER_pitm.PO_NUMBER = FILTER_phd.PHD_PO_NUMBER  and
FILTER_pitm.REL_NUMB = FILTER_phd.PHD_REL_NUMB
)

---- FINAL LAYER ----
SELECT
          PO_HEADER_BK
        , PO_ITEM_BK
        , PO_NUMBER
        , ITEM_NO
        , REL_NUMB
        , PART_TYPE
        , ORIG_DATE_PROMISED
        , UNIT_COST
        , RCV_UOM
        , ITEM_TERMS
        , UNIT_PRICE
        , SEQUENCE_ID
        , QTY_ORDERED
        , PRODUCT_CODE
        , QTY_VOUCHED
        , PROJID
        , QTY_INVOICE
        , INV_EXT_COST
        , PART_ATTRIBUTE1
        , TRACKING_NO
        , PART_ATTRIBUTE3
        , PART_ATTRIBUTE2
        , PART_ATTRIBUTE5
        , JOB_NO
        , PART_ATTRIBUTE4
        , PART_ATTRIBUTE6
        , ORDERED_BILL
        , QTY_TO_BILL
        , NOTES_FLAG
        , VOL_DISC_TY
        , ASSIGN_FLAG
        , PO_PRINT_METH
        , VPM_SERIAL
        , SO_REL
        , PRICE_CHGD
        , ROYALTY_OWED
        , LOCATION
        , PART_CODE
        , PHASE_CODE
        , DATE_PROM_USER
        , UNIT_BILL
        , ITEM_DISCOUNT
        , ITEM_NTPRICE
        , COMMODITY_CODE
        , QTY_RECVD
        , VOL_DISC_AMT
        , XCUR_CONV
        , PRODUCT_REQ
        , DATE_PROM_DATE
        , DATE_REQD
        , DATE_PROMISED
        , BCUR_CONV
        , ROYALTY_PAID
        , STEP_CODE
        , VOUCHED_COST
        , VEND_CODE
        , VNDRET_BIN
        , SO_NUMBER
        , ORD_EXT_COST
        , ORD_UN_COST
        , UOM_CONV
        , BALDUE
        , TASK_NO
        , PO_PRINT_FLAG
        , RCV_CONV
        , V_PART_NUMBER
        , FIXED_ASSET
        , XCUR_UOM
        , DISP_PART
        , QTY_BILLED
        , VEND_SITE
        , DATE_RCV
        , BILLED_FLAG
        , PART_DESC
        , QTY_INVOICED
        , ITEM_WGT
        , INVOICED_BILL
        , CLOSE_FLAG
        , REQ_NUMBER
        , ITEM_GWGT
        , DATE_CLOSED
        , LIST_PRICE
        , ITEM_PPV
        , SO_ITEM
        , BILL_STATUS
        , VNDRET_LOC
        , POLIN_SERIAL
        , ACCT_NO
        , ITEM_STATUS
        , ORD_UN_BILL
        , ITEM_SHIPCHG
        , VEND_NAME
        , FLG_1099
        , BCUR_UOM
        , QTY_ORD
        , UNIT_MEASURE
        , JOB_STATUS
        , ORDERED_COST
        , COST_CTR
        , REASON_CODE
        , DATE_ORDERD
        , INVOICED_COST
        , VENDOR_STATUS
        , PO_PRINT_DATE
        , UOM
        , SHIP_TO
        , QTY_RECEIVED
        , VNDRET_LOT
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , _FIVETRAN_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , /* The supplier HK values are modified to handle the optional null default for the Hash key generation.
          This derived field prevents BKCC being included in the HK generation when the Supplier key is null/Blank */
            IFF(VEND_CODE IS NULL, '-2', CONCAT_WS('||', VEND_CODE, BKCC)) as DRVD_SUPPLIER_BKCC
        , REC_SRC
        , BKCC
        ,  IFF(BILLTO_CODE IS NULL, '-2', CONCAT_WS('||', BILLTO_CODE, BKCC)) as DRVD_LEGAL_ENTITY_BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_NO as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_SUPPLIER_BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PART_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_LEGAL_ENTITY_BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        ))) as PURCHASING_RECORD_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        ))) as PURCHASING_ORG_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_NO as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(REL_NUMB as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_RECEIPT_DK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_NO as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VEND_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PART_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BILLTO_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        ))) as LNK_PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_NO as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(REL_NUMB as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(VEND_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PART_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(COST_CTR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BILLTO_CODE as VARCHAR)),''), '^^')
        ))) as LNK_PO_RECEIPT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(COST_CTR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PART_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_DATE_PROMISED::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_COST::text), '^^') 
            , '||', IFNULL(TRIM(RCV_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_TERMS::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(QTY_ORDERED::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(QTY_VOUCHED::text), '^^') 
            , '||', IFNULL(TRIM(PROJID::text), '^^') 
            , '||', IFNULL(TRIM(QTY_INVOICE::text), '^^') 
            , '||', IFNULL(TRIM(INV_EXT_COST::text), '^^') 
            , '||', IFNULL(TRIM(PART_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(TRACKING_NO::text), '^^') 
            , '||', IFNULL(TRIM(PART_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(PART_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(PART_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(JOB_NO::text), '^^') 
            , '||', IFNULL(TRIM(PART_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(PART_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(ORDERED_BILL::text), '^^') 
            , '||', IFNULL(TRIM(QTY_TO_BILL::text), '^^') 
            , '||', IFNULL(TRIM(NOTES_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(VOL_DISC_TY::text), '^^') 
            , '||', IFNULL(TRIM(ASSIGN_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PO_PRINT_METH::text), '^^') 
            , '||', IFNULL(TRIM(VPM_SERIAL::text), '^^') 
            , '||', IFNULL(TRIM(SO_REL::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_CHGD::text), '^^') 
            , '||', IFNULL(TRIM(ROYALTY_OWED::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION::text), '^^') 
            , '||', IFNULL(TRIM(PART_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PHASE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DATE_PROM_USER::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_BILL::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_NTPRICE::text), '^^') 
            , '||', IFNULL(TRIM(COMMODITY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RECVD::text), '^^') 
            , '||', IFNULL(TRIM(VOL_DISC_AMT::text), '^^') 
            , '||', IFNULL(TRIM(XCUR_CONV::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_REQ::text), '^^') 
            , '||', IFNULL(TRIM(DATE_PROM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DATE_REQD::text), '^^') 
            , '||', IFNULL(TRIM(DATE_PROMISED::text), '^^') 
            , '||', IFNULL(TRIM(BCUR_CONV::text), '^^') 
            , '||', IFNULL(TRIM(ROYALTY_PAID::text), '^^') 
            , '||', IFNULL(TRIM(STEP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(VOUCHED_COST::text), '^^') 
            , '||', IFNULL(TRIM(VEND_CODE::text), '^^') 
            , '||', IFNULL(TRIM(VNDRET_BIN::text), '^^') 
            , '||', IFNULL(TRIM(SO_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ORD_EXT_COST::text), '^^') 
            , '||', IFNULL(TRIM(ORD_UN_COST::text), '^^') 
            , '||', IFNULL(TRIM(UOM_CONV::text), '^^') 
            , '||', IFNULL(TRIM(BALDUE::text), '^^') 
            , '||', IFNULL(TRIM(TASK_NO::text), '^^') 
            , '||', IFNULL(TRIM(PO_PRINT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(RCV_CONV::text), '^^') 
            , '||', IFNULL(TRIM(V_PART_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(FIXED_ASSET::text), '^^') 
            , '||', IFNULL(TRIM(XCUR_UOM::text), '^^') 
            , '||', IFNULL(TRIM(DISP_PART::text), '^^') 
            , '||', IFNULL(TRIM(QTY_BILLED::text), '^^') 
            , '||', IFNULL(TRIM(VEND_SITE::text), '^^') 
            , '||', IFNULL(TRIM(DATE_RCV::text), '^^') 
            , '||', IFNULL(TRIM(BILLED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PART_DESC::text), '^^') 
            , '||', IFNULL(TRIM(QTY_INVOICED::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_WGT::text), '^^') 
            , '||', IFNULL(TRIM(INVOICED_BILL::text), '^^') 
            , '||', IFNULL(TRIM(CLOSE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(REQ_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_GWGT::text), '^^') 
            , '||', IFNULL(TRIM(DATE_CLOSED::text), '^^') 
            , '||', IFNULL(TRIM(LIST_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_PPV::text), '^^') 
            , '||', IFNULL(TRIM(SO_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(BILL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(VNDRET_LOC::text), '^^') 
            , '||', IFNULL(TRIM(POLIN_SERIAL::text), '^^') 
            , '||', IFNULL(TRIM(ACCT_NO::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ORD_UN_BILL::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_SHIPCHG::text), '^^') 
            , '||', IFNULL(TRIM(VEND_NAME::text), '^^') 
            , '||', IFNULL(TRIM(FLG_1099::text), '^^') 
            , '||', IFNULL(TRIM(BCUR_UOM::text), '^^') 
            , '||', IFNULL(TRIM(QTY_ORD::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEASURE::text), '^^') 
            , '||', IFNULL(TRIM(JOB_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ORDERED_COST::text), '^^') 
            , '||', IFNULL(TRIM(COST_CTR::text), '^^') 
            , '||', IFNULL(TRIM(REASON_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DATE_ORDERD::text), '^^') 
            , '||', IFNULL(TRIM(INVOICED_COST::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PO_PRINT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(UOM::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO::text), '^^') 
            , '||', IFNULL(TRIM(QTY_RECEIVED::text), '^^') 
            , '||', IFNULL(TRIM(VNDRET_LOT::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^')
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

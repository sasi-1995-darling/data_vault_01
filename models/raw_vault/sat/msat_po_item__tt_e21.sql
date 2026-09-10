---- SRC LAYER ----
WITH
SRC_po_line        as ( 
    SELECT 
        PO_ITEM_HK,
        PO_NUMBER,
        ITEM_NO,
        REL_NUMB,
        PART_TYPE,
        ORIG_DATE_PROMISED,
        UNIT_COST,
        RCV_UOM,
        ITEM_TERMS,
        UNIT_PRICE,
        SEQUENCE_ID,
        QTY_ORDERED,
        PRODUCT_CODE,
        QTY_VOUCHED,
        PROJID,
        QTY_INVOICE,
        INV_EXT_COST,
        PART_ATTRIBUTE1,
        TRACKING_NO,
        PART_ATTRIBUTE3,
        PART_ATTRIBUTE2,
        PART_ATTRIBUTE5,
        JOB_NO,
        PART_ATTRIBUTE4,
        PART_ATTRIBUTE6,
        ORDERED_BILL,
        QTY_TO_BILL,
        NOTES_FLAG,
        VOL_DISC_TY,
        ASSIGN_FLAG,
        PO_PRINT_METH,
        VPM_SERIAL,
        SO_REL,
        PRICE_CHGD,
        ROYALTY_OWED,
        LOCATION,
        PART_CODE,
        PHASE_CODE,
        DATE_PROM_USER,
        UNIT_BILL,
        ITEM_DISCOUNT,
        ITEM_NTPRICE,
        COMMODITY_CODE,
        QTY_RECVD,
        VOL_DISC_AMT,
        XCUR_CONV,
        PRODUCT_REQ,
        DATE_PROM_DATE,
        DATE_REQD,
        DATE_PROMISED,
        BCUR_CONV,
        ROYALTY_PAID,
        STEP_CODE,
        VOUCHED_COST,
        VEND_CODE,
        VNDRET_BIN,
        SO_NUMBER,
        ORD_EXT_COST,
        ORD_UN_COST,
        UOM_CONV,
        BALDUE,
        TASK_NO,
        PO_PRINT_FLAG,
        RCV_CONV,
        V_PART_NUMBER,
        FIXED_ASSET,
        XCUR_UOM,
        DISP_PART,
        QTY_BILLED,
        VEND_SITE,
        DATE_RCV,
        BILLED_FLAG,
        PART_DESC,
        QTY_INVOICED,
        ITEM_WGT,
        INVOICED_BILL,
        CLOSE_FLAG,
        REQ_NUMBER,
        ITEM_GWGT,
        DATE_CLOSED,
        LIST_PRICE,
        ITEM_PPV,
        SO_ITEM,
        BILL_STATUS,
        VNDRET_LOC,
        POLIN_SERIAL,
        ACCT_NO,
        ITEM_STATUS,
        ORD_UN_BILL,
        ITEM_SHIPCHG,
        VEND_NAME,
        FLG_1099,
        BCUR_UOM,
        QTY_ORD,
        UNIT_MEASURE,
        JOB_STATUS,
        ORDERED_COST,
        COST_CTR,
        REASON_CODE,
        DATE_ORDERD,
        INVOICED_COST,
        VENDOR_STATUS,
        PO_PRINT_DATE,
        UOM,
        SHIP_TO,
        QTY_RECEIVED,
        VNDRET_LOT,
        _FIVETRAN_DELETED,
        _FIVETRAN_SYNCED,
        _FIVETRAN_ID,
        PSA_RECORD_SOURCE,
        PSA_LOAD_DTS,
        PSA_DELETE_IND,
        LOAD_DTS,
        REC_SRC,
        BKCC,
        HASHDIFF
    FROM {{ ref('v_psa_stg_po_item__tt_e21') }} as SRC 
    {% if is_incremental() %}
        WHERE src.load_dts > (SELECT dateadd('HOUR', -1, max(load_dts)) FROM {{ this }})
    {% endif %}
)
/*
SRC_po_line        as ( SELECT * FROM staging.v_psa_stg_po_item__tt_e21 )
*/
---- LOGIC LAYER ----

, LOGIC_po_line as (
    SELECT
        PO_ITEM_HK
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
      , PSA_RECORD_SOURCE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_po_line
)
---- RENAME LAYER ----

, RENAME_po_line as (
    SELECT
        PO_ITEM_HK
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
      , PSA_RECORD_SOURCE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
      , hash(* exclude(HASHDIFF,LOAD_DTS,_FIVETRAN_ID, _FIVETRAN_SYNCED, PO_ITEM_HK)) as rec_hash
    FROM LOGIC_po_line
)
---- FILTER LAYER ----

, FILTER_po_line as (
    SELECT *
    FROM RENAME_po_line
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_po_line
)

---- FINAL LAYER ----
SELECT
          PO_ITEM_HK
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
        , PSA_RECORD_SOURCE
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
    WHERE existing.PO_ITEM_HK = JOIN_RESULT.PO_ITEM_HK
and existing.REL_NUMB = JOIN_RESULT.REL_NUMB
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %}
{% if not is_incremental() %}

/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1 = row_number() over (partition by PO_NUMBER, ITEM_NO, REL_NUMB, rec_hash order by PSA_LOAD_DTS)

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PO_ITEM_HK,
GR.VALUE::text AS PO_NUMBER,
GR.VALUE::number AS ITEM_NO,
GR.VALUE::text AS REL_NUMB,
NULL AS PART_TYPE,
NULL AS ORIG_DATE_PROMISED,
NULL AS UNIT_COST,
NULL AS RCV_UOM,
NULL AS ITEM_TERMS,
NULL AS UNIT_PRICE,
NULL AS SEQUENCE_ID,
NULL AS QTY_ORDERED,
NULL AS PRODUCT_CODE,
NULL AS QTY_VOUCHED,
NULL AS PROJID,
NULL AS QTY_INVOICE,
NULL AS INV_EXT_COST,
NULL AS PART_ATTRIBUTE1,
NULL AS TRACKING_NO,
NULL AS PART_ATTRIBUTE3,
NULL AS PART_ATTRIBUTE2,
NULL AS PART_ATTRIBUTE5,
NULL AS JOB_NO,
NULL AS PART_ATTRIBUTE4,
NULL AS PART_ATTRIBUTE6,
NULL AS ORDERED_BILL,
NULL AS QTY_TO_BILL,
NULL AS NOTES_FLAG,
NULL AS VOL_DISC_TY,
NULL AS ASSIGN_FLAG,
NULL AS PO_PRINT_METH,
NULL AS VPM_SERIAL,
NULL AS SO_REL,
NULL AS PRICE_CHGD,
NULL AS ROYALTY_OWED,
NULL AS LOCATION,
NULL AS PART_CODE,
NULL AS PHASE_CODE,
NULL AS DATE_PROM_USER,
NULL AS UNIT_BILL,
NULL AS ITEM_DISCOUNT,
NULL AS ITEM_NTPRICE,
NULL AS COMMODITY_CODE,
NULL AS QTY_RECVD,
NULL AS VOL_DISC_AMT,
NULL AS XCUR_CONV,
NULL AS PRODUCT_REQ,
NULL AS DATE_PROM_DATE,
NULL AS DATE_REQD,
NULL AS DATE_PROMISED,
NULL AS BCUR_CONV,
NULL AS ROYALTY_PAID,
NULL AS STEP_CODE,
NULL AS VOUCHED_COST,
NULL AS VEND_CODE,
NULL AS VNDRET_BIN,
NULL AS SO_NUMBER,
NULL AS ORD_EXT_COST,
NULL AS ORD_UN_COST,
NULL AS UOM_CONV,
NULL AS BALDUE,
NULL AS TASK_NO,
NULL AS PO_PRINT_FLAG,
NULL AS RCV_CONV,
NULL AS V_PART_NUMBER,
NULL AS FIXED_ASSET,
NULL AS XCUR_UOM,
NULL AS DISP_PART,
NULL AS QTY_BILLED,
NULL AS VEND_SITE,
NULL AS DATE_RCV,
NULL AS BILLED_FLAG,
NULL AS PART_DESC,
NULL AS QTY_INVOICED,
NULL AS ITEM_WGT,
NULL AS INVOICED_BILL,
NULL AS CLOSE_FLAG,
NULL AS REQ_NUMBER,
NULL AS ITEM_GWGT,
NULL AS DATE_CLOSED,
NULL AS LIST_PRICE,
NULL AS ITEM_PPV,
NULL AS SO_ITEM,
NULL AS BILL_STATUS,
NULL AS VNDRET_LOC,
NULL AS POLIN_SERIAL,
NULL AS ACCT_NO,
NULL AS ITEM_STATUS,
NULL AS ORD_UN_BILL,
NULL AS ITEM_SHIPCHG,
NULL AS VEND_NAME,
NULL AS FLG_1099,
NULL AS BCUR_UOM,
NULL AS QTY_ORD,
NULL AS UNIT_MEASURE,
NULL AS JOB_STATUS,
NULL AS ORDERED_COST,
NULL AS COST_CTR,
NULL AS REASON_CODE,
NULL AS DATE_ORDERD,
NULL AS INVOICED_COST,
NULL AS VENDOR_STATUS,
NULL AS PO_PRINT_DATE,
NULL AS UOM,
NULL AS SHIP_TO,
NULL AS QTY_RECEIVED,
NULL AS VNDRET_LOT,
NULL AS _FIVETRAN_DELETED,
NULL AS _FIVETRAN_SYNCED,
NULL AS _FIVETRAN_ID,
NULL AS PSA_RECORD_SOURCE,
'1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS,
'N' AS PSA_DELETE_IND,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
''::BINARY AS HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

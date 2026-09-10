---- SRC LAYER ----
WITH
SRC_psr            as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_recv_ln_ship') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_psh            as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_recv_hdr') }} as SRC 
                        qualify 1= row_number()over(partition by receiver_id order by _fivetran_synced desc, psa_load_dts desc) )

/*
SRC_psr            as ( SELECT * FROM lrsn_psft_sysadm.ps_recv_ln_ship )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_psh            as ( SELECT * FROM lrsn_psft_sysadm.ps_recv_hdr )
*/
---- LOGIC LAYER ----

, LOGIC_psr as (
    SELECT
        CONCAT_WS('||', BUSINESS_UNIT,PO_ID)                         as                                       PO_HEADER_BK
      , CONCAT_WS('||', BUSINESS_UNIT,PO_ID,LINE_NBR)                as                                         PO_ITEM_BK
      , INV_ITEM_ID                                                  as                                            ITEM_BK
      , BUSINESS_UNIT_IN                                             as                                           PLANT_BK
      , BUSINESS_UNIT                                                as                                    LEGAL_ENTITY_BK
      , RECEIVER_ID
      , RECV_LN_NBR
      , BUSINESS_UNIT
      , INV_ITEM_ID
      , PO_ID
      , LINE_NBR
      , _FIVETRAN_ID
      , RECV_SHIP_SEQ_NBR
      , AMT_ONLY_FLG
      , ASN_SEQ_NBR
      , BILL_OF_LADING
      , BUSINESS_UNIT_IN
      , BUSINESS_UNIT_PO
      , BUSINESS_UNIT_FROM
      , BILL_OF_ENTRY
      , BOE_LINE_NBR
      , BOE_TYPE
      , CATEGORY_ID
      , CLOSE_SHORT_FLG
      , CONFIG_CODE
      , CONVERSION_RATE
      , CONVERT_TO_STK
      , CONVERT_TO_PO
      , CONVERT_STK_TO_STD
      , COUNTRY_IST_ORIGIN
      , CURRENCY_CD
      , CURRENCY_CD_BASE
      , DESCR254_MIXED
      , DEVICE_TRACKING
      , DISTRIB_MTHD_FLG
      , DUE_DT
      , DUE_TIME
      , EIP_CTL_ID
      , ERS_INV_SEQ
      , ERS_STATUS
      , INSPECT_CD
      , INSPECT_DTTM
      , INSPECT_STATUS
      , INVOICE_ID
      , IST_DISTRIB_STATUS
      , ITM_ID_VNDR
      , ITM_SETID
      , LOT_CONTROL
      , LOT_STATUS
      , MATCH_LINE_FLG
      , MATCH_STATUS_LC
      , MERCH_AMT_BSE
      , MERCH_AMT_PO_BSE
      , MERCHANDISE_AMT
      , MERCHANDISE_AMT_PO
      , MFG_ID
      , MFG_ITM_ID
      , MOVE_STAT_AM
      , MOVE_STAT_INV
      , MOVE_STAT_MFG
      , OP_SEQUENCE
      , OPRID
      , PACKSLIP_NO
      , PO_TYPE
      , PRICE_PO
      , PRICE_PO_BSE
      , PRICE_RECV
      , PROCESS_COMPLETE
      , PROCESS_INSTANCE
      , PRODUCTION_ID
      , QTY_LN_ASSET_SUOM
      , QTY_LN_INV_SUOM
      , QTY_SH_ACCPT
      , QTY_SH_ACCPT_SUOM
      , QTY_SH_ACCPT_VUOM
      , QTY_SH_INSPD
      , QTY_SH_INSPD_SUOM
      , QTY_SH_INSPD_VUOM
      , QTY_SH_NETRCV_VUOM
      , QTY_SH_RECVD
      , QTY_SH_RECVD_SUOM
      , QTY_SH_RECVD_VUOM
      , QTY_SH_REJCT
      , QTY_SH_REJCT_SUOM
      , QTY_SH_REJCT_VUOM
      , QTY_SH_RTN
      , QTY_SH_RTN_SUOM
      , QTY_SH_RTN_VUOM
      , REJECT_ACTION
      , REJECT_REASON
      , REVISION
      , RMA_ID
      , RMA_LINE_NBR
      , RECEIPT_ALLOC_TYPE
      , RECEIPT_DTTM
      , RECEIPT_UM
      , RECEIVE_UOM
      , RECV_LN_MATCH_OPT
      , RECV_SHIP_STATUS
      , RECV_STOCK_UOM
      , REPLACEMENT_FLG
      , SCHED_NBR
      , SERIAL_CONTROL
      , SERIAL_STATUS
      , SHIP_DATE_STATUS
      , SHIP_QTY_STATUS
      , SHIPTO_ID
      , UNIT_MEASURE_STD
      , ORIG_INV_ITEM_ID
      , DESCR254_MIXED2
      , PO_GROUP_ID
      , PRIMARY_UNIT
      , UNIT_ALLOC_QTY
      , UNIT_ALLOC_AMT
      , USER_LINE_CHAR1
      , CUSTOM_C100_B1
      , CUSTOM_C100_B2
      , CUSTOM_C100_B3
      , CUSTOM_C100_B4
      , CUSTOM_DATE_B
      , CUSTOM_C1_B
      , USER_SCHED_CHAR1
      , CUSTOM_C100_C1
      , CUSTOM_C100_C2
      , CUSTOM_C100_C3
      , CUSTOM_DATE_C1
      , CUSTOM_DATE_C2
      , CUSTOM_C1_C
      , UPN_TYPE_CD
      , UPN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_RECORD_SOURCE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_psr
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)

, LOGIC_psh as (
    SELECT
        VENDOR_ID                                                    as                                        SUPPLIER_BK
      , VENDOR_ID                                                    as                                     DERV_VENDOR_ID
      , RECEIVER_ID                                                  as                                    HDR_RECEIVER_ID
    FROM SRC_psh
)
---- RENAME LAYER ----

, RENAME_psr as (
    SELECT
        PO_HEADER_BK
      , PO_ITEM_BK
      , ITEM_BK
      , PLANT_BK
      , LEGAL_ENTITY_BK
      , RECEIVER_ID
      , RECV_LN_NBR
      , BUSINESS_UNIT
      , INV_ITEM_ID
      , PO_ID
      , LINE_NBR
      , _FIVETRAN_ID
      , RECV_SHIP_SEQ_NBR
      , AMT_ONLY_FLG
      , ASN_SEQ_NBR
      , BILL_OF_LADING
      , BUSINESS_UNIT_IN
      , BUSINESS_UNIT_PO
      , BUSINESS_UNIT_FROM
      , BILL_OF_ENTRY
      , BOE_LINE_NBR
      , BOE_TYPE
      , CATEGORY_ID
      , CLOSE_SHORT_FLG
      , CONFIG_CODE
      , CONVERSION_RATE
      , CONVERT_TO_STK
      , CONVERT_TO_PO
      , CONVERT_STK_TO_STD
      , COUNTRY_IST_ORIGIN
      , CURRENCY_CD
      , CURRENCY_CD_BASE
      , DESCR254_MIXED
      , DEVICE_TRACKING
      , DISTRIB_MTHD_FLG
      , DUE_DT
      , DUE_TIME
      , EIP_CTL_ID
      , ERS_INV_SEQ
      , ERS_STATUS
      , INSPECT_CD
      , INSPECT_DTTM
      , INSPECT_STATUS
      , INVOICE_ID
      , IST_DISTRIB_STATUS
      , ITM_ID_VNDR
      , ITM_SETID
      , LOT_CONTROL
      , LOT_STATUS
      , MATCH_LINE_FLG
      , MATCH_STATUS_LC
      , MERCH_AMT_BSE
      , MERCH_AMT_PO_BSE
      , MERCHANDISE_AMT
      , MERCHANDISE_AMT_PO
      , MFG_ID
      , MFG_ITM_ID
      , MOVE_STAT_AM
      , MOVE_STAT_INV
      , MOVE_STAT_MFG
      , OP_SEQUENCE
      , OPRID
      , PACKSLIP_NO
      , PO_TYPE
      , PRICE_PO
      , PRICE_PO_BSE
      , PRICE_RECV
      , PROCESS_COMPLETE
      , PROCESS_INSTANCE
      , PRODUCTION_ID
      , QTY_LN_ASSET_SUOM
      , QTY_LN_INV_SUOM
      , QTY_SH_ACCPT
      , QTY_SH_ACCPT_SUOM
      , QTY_SH_ACCPT_VUOM
      , QTY_SH_INSPD
      , QTY_SH_INSPD_SUOM
      , QTY_SH_INSPD_VUOM
      , QTY_SH_NETRCV_VUOM
      , QTY_SH_RECVD
      , QTY_SH_RECVD_SUOM
      , QTY_SH_RECVD_VUOM
      , QTY_SH_REJCT
      , QTY_SH_REJCT_SUOM
      , QTY_SH_REJCT_VUOM
      , QTY_SH_RTN
      , QTY_SH_RTN_SUOM
      , QTY_SH_RTN_VUOM
      , REJECT_ACTION
      , REJECT_REASON
      , REVISION
      , RMA_ID
      , RMA_LINE_NBR
      , RECEIPT_ALLOC_TYPE
      , RECEIPT_DTTM
      , RECEIPT_UM
      , RECEIVE_UOM
      , RECV_LN_MATCH_OPT
      , RECV_SHIP_STATUS
      , RECV_STOCK_UOM
      , REPLACEMENT_FLG
      , SCHED_NBR
      , SERIAL_CONTROL
      , SERIAL_STATUS
      , SHIP_DATE_STATUS
      , SHIP_QTY_STATUS
      , SHIPTO_ID
      , UNIT_MEASURE_STD
      , ORIG_INV_ITEM_ID
      , DESCR254_MIXED2
      , PO_GROUP_ID
      , PRIMARY_UNIT
      , UNIT_ALLOC_QTY
      , UNIT_ALLOC_AMT
      , USER_LINE_CHAR1
      , CUSTOM_C100_B1
      , CUSTOM_C100_B2
      , CUSTOM_C100_B3
      , CUSTOM_C100_B4
      , CUSTOM_DATE_B
      , CUSTOM_C1_B
      , USER_SCHED_CHAR1
      , CUSTOM_C100_C1
      , CUSTOM_C100_C2
      , CUSTOM_C100_C3
      , CUSTOM_DATE_C1
      , CUSTOM_DATE_C2
      , CUSTOM_C1_C
      , UPN_TYPE_CD
      , UPN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_RECORD_SOURCE
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_psr
)

, RENAME_psh as (
    SELECT
        SUPPLIER_BK
      , DERV_VENDOR_ID
      , HDR_RECEIVER_ID
    FROM LOGIC_psh
)

, RENAME_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_psr as (
    SELECT *
    FROM RENAME_psr
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_RECV_LN_SHIP'
)

, FILTER_psh as (
    SELECT *
    FROM RENAME_psh
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_psr
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_psh
        ON FILTER_psr.receiver_id = FILTER_psh.hdr_receiver_id
)

---- FINAL LAYER ----
SELECT
          CONCAT_WS('||'          
          , COALESCE(RECEIVER_ID,'')
          , COALESCE(RECV_LN_NBR::TEXT,'')) as PO_ITEM_RECEIPT_BK
        , PO_HEADER_BK
        , PO_ITEM_BK
        , SUPPLIER_BK
        , ITEM_BK
        , PLANT_BK
        , LEGAL_ENTITY_BK
        , RECEIVER_ID
        , RECV_LN_NBR
        , BUSINESS_UNIT
        , INV_ITEM_ID
        , PO_ID
        , LINE_NBR
        , _FIVETRAN_ID
        , RECV_SHIP_SEQ_NBR
        , AMT_ONLY_FLG
        , ASN_SEQ_NBR
        , BILL_OF_LADING
        , BUSINESS_UNIT_IN
        , BUSINESS_UNIT_PO
        , BUSINESS_UNIT_FROM
        , BILL_OF_ENTRY
        , BOE_LINE_NBR
        , BOE_TYPE
        , CATEGORY_ID
        , CLOSE_SHORT_FLG
        , CONFIG_CODE
        , CONVERSION_RATE
        , CONVERT_TO_STK
        , CONVERT_TO_PO
        , CONVERT_STK_TO_STD
        , COUNTRY_IST_ORIGIN
        , CURRENCY_CD
        , CURRENCY_CD_BASE
        , DESCR254_MIXED
        , DEVICE_TRACKING
        , DISTRIB_MTHD_FLG
        , DUE_DT
        , DUE_TIME
        , EIP_CTL_ID
        , ERS_INV_SEQ
        , ERS_STATUS
        , INSPECT_CD
        , INSPECT_DTTM
        , INSPECT_STATUS
        , INVOICE_ID
        , IST_DISTRIB_STATUS
        , ITM_ID_VNDR
        , ITM_SETID
        , LOT_CONTROL
        , LOT_STATUS
        , MATCH_LINE_FLG
        , MATCH_STATUS_LC
        , MERCH_AMT_BSE
        , MERCH_AMT_PO_BSE
        , MERCHANDISE_AMT
        , MERCHANDISE_AMT_PO
        , MFG_ID
        , MFG_ITM_ID
        , MOVE_STAT_AM
        , MOVE_STAT_INV
        , MOVE_STAT_MFG
        , OP_SEQUENCE
        , OPRID
        , PACKSLIP_NO
        , PO_TYPE
        , PRICE_PO
        , PRICE_PO_BSE
        , PRICE_RECV
        , PROCESS_COMPLETE
        , PROCESS_INSTANCE
        , PRODUCTION_ID
        , QTY_LN_ASSET_SUOM
        , QTY_LN_INV_SUOM
        , QTY_SH_ACCPT
        , QTY_SH_ACCPT_SUOM
        , QTY_SH_ACCPT_VUOM
        , QTY_SH_INSPD
        , QTY_SH_INSPD_SUOM
        , QTY_SH_INSPD_VUOM
        , QTY_SH_NETRCV_VUOM
        , QTY_SH_RECVD
        , QTY_SH_RECVD_SUOM
        , QTY_SH_RECVD_VUOM
        , QTY_SH_REJCT
        , QTY_SH_REJCT_SUOM
        , QTY_SH_REJCT_VUOM
        , QTY_SH_RTN
        , QTY_SH_RTN_SUOM
        , QTY_SH_RTN_VUOM
        , REJECT_ACTION
        , REJECT_REASON
        , REVISION
        , RMA_ID
        , RMA_LINE_NBR
        , RECEIPT_ALLOC_TYPE
        , RECEIPT_DTTM
        , RECEIPT_UM
        , RECEIVE_UOM
        , RECV_LN_MATCH_OPT
        , RECV_SHIP_STATUS
        , RECV_STOCK_UOM
        , REPLACEMENT_FLG
        , SCHED_NBR
        , SERIAL_CONTROL
        , SERIAL_STATUS
        , SHIP_DATE_STATUS
        , SHIP_QTY_STATUS
        , SHIPTO_ID
        , UNIT_MEASURE_STD
        , ORIG_INV_ITEM_ID
        , DESCR254_MIXED2
        , PO_GROUP_ID
        , PRIMARY_UNIT
        , UNIT_ALLOC_QTY
        , UNIT_ALLOC_AMT
        , USER_LINE_CHAR1
        , CUSTOM_C100_B1
        , CUSTOM_C100_B2
        , CUSTOM_C100_B3
        , CUSTOM_C100_B4
        , CUSTOM_DATE_B
        , CUSTOM_C1_B
        , USER_SCHED_CHAR1
        , CUSTOM_C100_C1
        , CUSTOM_C100_C2
        , CUSTOM_C100_C3
        , CUSTOM_DATE_C1
        , CUSTOM_DATE_C2
        , CUSTOM_C1_C
        , UPN_TYPE_CD
        , UPN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_RECORD_SOURCE
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , /*To handle the optional null default for the Hash key generation and to match with the Ghost Key Hash value */
IFF(TRIM(RECEIVER_ID)= '', '-2', CONCAT_WS('||',RECEIVER_ID, RECV_LN_NBR,BKCC)) as DRVD_PO_ITEM_RECEIPT_BKCC
        , /*To handle the optional null default for the Hash key generation and to match with the Ghost Key Hash value */
IFF(TRIM(DERV_VENDOR_ID)= '', '-2', CONCAT_WS('||', DERV_VENDOR_ID, BKCC)) as DRVD_SUPPLIER_BKCC
        , /*To handle the optional null default for the Hash key generation and to match with the Ghost Key Hash value */
IFF(INV_ITEM_ID= '', '-2', CONCAT_WS('||', INV_ITEM_ID, BKCC)) as DRVD_ITEM_BKCC
        , /*To handle the optional null default for the Hash key generation and to match with the Ghost Key Hash value */
IFF(BUSINESS_UNIT_IN= '', '-2', CONCAT_WS('||', BUSINESS_UNIT_IN, BKCC)) as DRVD_PLANT_BKCC
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RECEIVER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RECV_LN_NBR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BUSINESS_UNIT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PO_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LINE_NBR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DERV_VENDOR_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(INV_ITEM_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BUSINESS_UNIT_IN as VARCHAR)),''), '^^')
        ))) as LNK_PO_RECEIPT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_UNIT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PO_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_UNIT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PO_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LINE_NBR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_PO_ITEM_RECEIPT_BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_RECEIPT_DK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_SUPPLIER_BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_ITEM_BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_PLANT_BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BUSINESS_UNIT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(RECV_SHIP_SEQ_NBR::text), '^^') 
            , '||', IFNULL(TRIM(AMT_ONLY_FLG::text), '^^') 
            , '||', IFNULL(TRIM(ASN_SEQ_NBR::text), '^^') 
            , '||', IFNULL(TRIM(BILL_OF_LADING::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_IN::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_PO::text), '^^') 
            , '||', IFNULL(TRIM(BUSINESS_UNIT_FROM::text), '^^') 
            , '||', IFNULL(TRIM(BILL_OF_ENTRY::text), '^^') 
            , '||', IFNULL(TRIM(BOE_LINE_NBR::text), '^^') 
            , '||', IFNULL(TRIM(BOE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(CLOSE_SHORT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(CONFIG_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CONVERSION_RATE::text), '^^') 
            , '||', IFNULL(TRIM(CONVERT_TO_STK::text), '^^') 
            , '||', IFNULL(TRIM(CONVERT_TO_PO::text), '^^') 
            , '||', IFNULL(TRIM(CONVERT_STK_TO_STD::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_IST_ORIGIN::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CD::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CD_BASE::text), '^^') 
            , '||', IFNULL(TRIM(DESCR254_MIXED::text), '^^') 
            , '||', IFNULL(TRIM(DEVICE_TRACKING::text), '^^') 
            , '||', IFNULL(TRIM(DISTRIB_MTHD_FLG::text), '^^') 
            , '||', IFNULL(TRIM(DUE_DT::text), '^^') 
            , '||', IFNULL(TRIM(DUE_TIME::text), '^^') 
            , '||', IFNULL(TRIM(EIP_CTL_ID::text), '^^') 
            , '||', IFNULL(TRIM(ERS_INV_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(ERS_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(INSPECT_CD::text), '^^') 
            , '||', IFNULL(TRIM(INSPECT_DTTM::text), '^^') 
            , '||', IFNULL(TRIM(INSPECT_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_ID::text), '^^') 
            , '||', IFNULL(TRIM(IST_DISTRIB_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ITM_ID_VNDR::text), '^^') 
            , '||', IFNULL(TRIM(ITM_SETID::text), '^^') 
            , '||', IFNULL(TRIM(LOT_CONTROL::text), '^^') 
            , '||', IFNULL(TRIM(LOT_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_LINE_FLG::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_STATUS_LC::text), '^^') 
            , '||', IFNULL(TRIM(MERCH_AMT_BSE::text), '^^') 
            , '||', IFNULL(TRIM(MERCH_AMT_PO_BSE::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANDISE_AMT::text), '^^') 
            , '||', IFNULL(TRIM(MERCHANDISE_AMT_PO::text), '^^') 
            , '||', IFNULL(TRIM(MFG_ID::text), '^^') 
            , '||', IFNULL(TRIM(MFG_ITM_ID::text), '^^') 
            , '||', IFNULL(TRIM(MOVE_STAT_AM::text), '^^') 
            , '||', IFNULL(TRIM(MOVE_STAT_INV::text), '^^') 
            , '||', IFNULL(TRIM(MOVE_STAT_MFG::text), '^^') 
            , '||', IFNULL(TRIM(OP_SEQUENCE::text), '^^') 
            , '||', IFNULL(TRIM(OPRID::text), '^^') 
            , '||', IFNULL(TRIM(PACKSLIP_NO::text), '^^') 
            , '||', IFNULL(TRIM(PO_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_PO::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_PO_BSE::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_RECV::text), '^^') 
            , '||', IFNULL(TRIM(PROCESS_COMPLETE::text), '^^') 
            , '||', IFNULL(TRIM(PROCESS_INSTANCE::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(QTY_LN_ASSET_SUOM::text), '^^') 
            , '||', IFNULL(TRIM(QTY_LN_INV_SUOM::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_ACCPT::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_ACCPT_SUOM::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_ACCPT_VUOM::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_INSPD::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_INSPD_SUOM::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_INSPD_VUOM::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_NETRCV_VUOM::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_RECVD::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_RECVD_SUOM::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_RECVD_VUOM::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_REJCT::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_REJCT_SUOM::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_REJCT_VUOM::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_RTN::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_RTN_SUOM::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SH_RTN_VUOM::text), '^^') 
            , '||', IFNULL(TRIM(REJECT_ACTION::text), '^^') 
            , '||', IFNULL(TRIM(REJECT_REASON::text), '^^') 
            , '||', IFNULL(TRIM(REVISION::text), '^^') 
            , '||', IFNULL(TRIM(RMA_ID::text), '^^') 
            , '||', IFNULL(TRIM(RMA_LINE_NBR::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_ALLOC_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_DTTM::text), '^^') 
            , '||', IFNULL(TRIM(RECEIPT_UM::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVE_UOM::text), '^^') 
            , '||', IFNULL(TRIM(RECV_LN_MATCH_OPT::text), '^^') 
            , '||', IFNULL(TRIM(RECV_SHIP_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(RECV_STOCK_UOM::text), '^^') 
            , '||', IFNULL(TRIM(REPLACEMENT_FLG::text), '^^') 
            , '||', IFNULL(TRIM(SCHED_NBR::text), '^^') 
            , '||', IFNULL(TRIM(SERIAL_CONTROL::text), '^^') 
            , '||', IFNULL(TRIM(SERIAL_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_DATE_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_QTY_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(SHIPTO_ID::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_MEASURE_STD::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_INV_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(DESCR254_MIXED2::text), '^^') 
            , '||', IFNULL(TRIM(PO_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_UNIT::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_ALLOC_QTY::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_ALLOC_AMT::text), '^^') 
            , '||', IFNULL(TRIM(USER_LINE_CHAR1::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_B1::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_B2::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_B3::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_B4::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_DATE_B::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C1_B::text), '^^') 
            , '||', IFNULL(TRIM(USER_SCHED_CHAR1::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_C1::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_C2::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C100_C3::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_DATE_C1::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_DATE_C2::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_C1_C::text), '^^') 
            , '||', IFNULL(TRIM(UPN_TYPE_CD::text), '^^') 
            , '||', IFNULL(TRIM(UPN_ID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_RECORD_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

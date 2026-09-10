---- SRC LAYER ----
WITH
SRC_L              as ( SELECT ITEM_HK, LEGAL_ENTITY_HK, LNK_PO_RECEIPT_HK, PLANT_HK, PO_HEADER_HK, PO_ITEM_HK, PO_ITEM_RECEIPT_DK, REC_SRC, SUPPLIER_HK FROM {{ ref('lnk_po_receipt') }} as SRC 
                        /* This filter is necessary to ensure only one record is kept per PO ITEM RECEIPT level. However, the link's granularity is designed to track changes related to Legal Entity, Supplier etc.,*/
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY PO_ITEM_RECEIPT_DK ORDER BY LOAD_DTS DESC) ),
SRC_H_SUPP         as ( SELECT SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('hub_supplier_v2') }} as SRC  ),
SRC_H_PO           as ( SELECT BKCC, PO_HEADER_BK, PO_HEADER_HK FROM {{ ref('hub_po_header') }} as SRC  ),
SRC_SAT_ML         as ( SELECT BKCC, LNK_PO_RECEIPT_HK, ORGANIZATION_ID, TRANSACTION_COST, TRANSACTION_DATE, TRANSACTION_ID, TRANSACTION_QUANTITY, TRANSACTION_TYPE_ID, TRANSACTION_UOM, _FIVETRAN_DELETED FROM {{ ref('lsat_po_receipt__ml_ebs') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY LNK_PO_RECEIPT_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATSUP_ML      as ( SELECT SEGMENT1, SUPPLIER_HK FROM {{ ref('sat_supplier__ml_ebs') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATITMB_ML     as ( SELECT ITEM_HK, SEGMENT1 FROM {{ ref('sat_item_base__ml_ebs_v2') }} as SRC 
                        where organization_id = 1    
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATPOITM_ML    as ( SELECT LINE_NUM, ORG_ID, PO_HEADER_ID, PO_ITEM_HK FROM {{ ref('sat_po_item__ml_ebs') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_SAT_WINN       as ( SELECT  LNK_PO_RECEIPT_HK, BELNR, BEWTP, BKCC, BUDAT, BUZEI, BWART, DMBTR, EBELN, EBELP, HSWAE, LSMEH, MATNR, MENGE, PSA_DELETE_IND, SHKZG, WERKS, WRBTR FROM {{ ref('lsat_po_receipt__winn_sap') }} as SRC 
                        WHERE BEWTP = 'E' 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY  LNK_PO_RECEIPT_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATHDR_WINN    as ( SELECT BUKRS, LIFNR, PO_HEADER_HK FROM {{ ref('sat_po_header__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK  ORDER BY LOAD_DTS DESC) ),
SRC_SAT_LRSN       as ( SELECT BKCC, BUSINESS_UNIT, BUSINESS_UNIT_IN, CURRENCY_CD, CURRENCY_CD_BASE, INV_ITEM_ID, LINE_NBR, LNK_PO_RECEIPT_HK, MERCHANDISE_AMT, MERCH_AMT_BSE, PO_ID, PO_TYPE, PRICE_RECV, PSA_DELETE_IND, QTY_SH_RECVD, RECEIPT_DTTM, RECEIVER_ID, RECEIVE_UOM, RECV_LN_NBR, RECV_SHIP_STATUS, _FIVETRAN_DELETED FROM {{ ref('lsat_po_receipt__lrsn_psft') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY LNK_PO_RECEIPT_HK  ORDER BY LOAD_DTS DESC) ),
SRC_SAT_E21        as ( SELECT COST_CTR, DATE_RCV, INV_EXT_COST, ITEM_NO, LNK_PO_RECEIPT_HK, LOAD_DTS, PART_CODE, PO_NUMBER, QTY_RECVD, RCV_CONV, RCV_UOM, REL_NUMB, SO_NUMBER, UNIT_PRICE, VEND_CODE, _FIVETRAN_DELETED FROM {{ ref('lsat_po_receipt__tt_e21') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY LNK_PO_RECEIPT_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATHDR_E21     as ( SELECT BILLTO_CODE, PO_HEADER_HK  , REL_NUMB FROM {{ ref('msat_po_header__tt_e21') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) ),
SRC_SAT_GP         as ( SELECT DATERECD, ITEMNMBR, LNK_PO_RECEIPT_HK, LOAD_DTS, PCHRPTCT, POLNENUM, PONUMBER, POPRCTNM, POPTYPE, PSA_DELETE_IND, QTYSHPPD, RCPTLNNM, STATUS, TRXLOCTN, UMQTYINB, UOFM, VENDORID FROM {{ ref('lsat_po_receipt__tt_gp') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY LNK_PO_RECEIPT_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATHDR_GP      as ( SELECT CMPANYID, DOCDATE, PO_HEADER_HK   FROM {{ ref('sat_po_header__tt_gp') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATPOITEM_GP   as ( SELECT LINENUMBER, LOCNCODE, PO_ITEM_HK   FROM {{ ref('sat_po_item__tt_gp') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_SAT_EMTK       as ( SELECT LNK_PO_RECEIPT_HK, TRANSACTION_COST, TRANSACTION_DATE, TRANSACTION_ID, TRANSACTION_QUANTITY, TRANSACTION_TYPE_ID, TRANSACTION_UOM, _FIVETRAN_DELETED FROM {{ ref('lsat_po_receipt__emtk_ebs') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY LNK_PO_RECEIPT_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATPOITEM_EMTK as ( SELECT LINE_NUM, PO_HEADER_ID, PO_ITEM_HK FROM {{ ref('sat_po_item__emtk_ebs') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATITMB_EMTK   as ( SELECT ITEM_HK, ORGANIZATION_ID, SEGMENT1 FROM {{ ref('sat_item_base__emtk_ebs_v1') }} as SRC 
                        WHERE organization_id = 101 -- master organization                                                   
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATPL_EMTK     as ( SELECT ORGANIZATION_CODE, PLANT_HK FROM {{ ref('sat_plant__emtk_ebs') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PLANT_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATLGL_EMTK    as ( SELECT LEGAL_ENTITY_HK, NAME FROM {{ ref('sat_legal_entity__emtk_ebs') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS DESC) ),
SRC_SAT_FIB        as ( SELECT LNK_PO_RECEIPT_HK, TRANSACTION_DATE, TRANSACTION_ID, TRANSACTION_QUANTITY, TRANSACTION_TYPE_ID, TRANSACTION_UOM, _FIVETRAN_DELETED FROM {{ ref('lsat_po_receipt__fib_ocf') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY LNK_PO_RECEIPT_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATPOITEM_FIB  as ( SELECT LINE_NUM, PO_HEADER_ID, PO_ITEM_HK, UNIT_PRICE FROM {{ ref('sat_po_item__fib_ocf') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATITMB_FIB    as ( SELECT ITEM_HK, ITEM_NUMBER, ORGANIZATION_ID FROM {{ ref('sat_item_base__fib_ocf') }} as SRC 
                        WHERE organization_id = 300000034179011 -- master organization                                                   
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATPL_FIB      as ( SELECT ORGANIZATION_CODE, PLANT_HK FROM {{ ref('sat_plant__fib_ocf') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PLANT_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATLGL_FIB     as ( SELECT LEGAL_ENTITY_HK, LEGAL_ENTITY_IDENTIFIER FROM {{ ref('sat_legal_entity__fib_ocf') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATHDR_ML      as ( SELECT PO_HEADER_HK  , SEGMENT1 FROM {{ ref('sat_po_header__ml_ebs') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATHDR_EMTK    as ( SELECT PO_HEADER_HK  , SEGMENT1 FROM {{ ref('sat_po_header__emtk_ebs') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATHDR_FIB     as ( SELECT PO_HEADER_HK  , SEGMENT_1 FROM {{ ref('sat_po_header__fib_ocf') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) ),
SRC_E21_ITEM       as ( SELECT PO_ITEM_HK, DATE_PROMISED, ORIG_DATE_PROMISED FROM {{ ref('msat_po_item__tt_e21') }} as SRC 
                        /* Defensive: prefer the latest NON Fivetran-deleted record so a future soft-delete at the
                           newest LOAD_DTS cannot surface a stale promised date. Verified no-op today (0 latest-state
                           deletes of 5,146,443 keys, 2026-07-17); guarded by t_e21_po_item_latest_not_fivetran_deleted. */
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY IFF(_FIVETRAN_DELETED = TRUE, 1, 0) ASC, LOAD_DTS DESC) ),
SRC_SCHED          as ( SELECT PO_ITEM_HK
                             , MAX(SCHED_PROMISED_DATE) as PROMISED_DATE_LATEST
                             , MIN(SCHED_PROMISED_DATE) as PROMISED_DATE_EARLIEST
                             , MAX(SCHED_NEED_BY_DATE)  as NEED_BY_DATE_LATEST
                             , MIN(SCHED_NEED_BY_DATE)  as NEED_BY_DATE_EARLIEST
                        FROM (
                            SELECT PO_ITEM_HK, TO_DATE(PROMISED_DATE) as SCHED_PROMISED_DATE, TO_DATE(NEED_BY_DATE) as SCHED_NEED_BY_DATE
                                 , (COALESCE(_FIVETRAN_DELETED, FALSE) AND CREATION_DATE::TIMESTAMP_NTZ > _FIVETRAN_SYNCED::TIMESTAMP_NTZ - INTERVAL '500 days') as IS_TRUE_DELETE
                            FROM {{ ref('msat_po_item_schedule_lines__ml_ebs') }}
                            QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK, LINE_LOCATION_ID ORDER BY LOAD_DTS DESC)
                            UNION ALL
                            SELECT PO_ITEM_HK, TO_DATE(PROMISED_DATE), TO_DATE(NEED_BY_DATE)
                                 , (COALESCE(_FIVETRAN_DELETED, FALSE) AND CREATION_DATE::TIMESTAMP_NTZ > _FIVETRAN_SYNCED::TIMESTAMP_NTZ - INTERVAL '500 days')
                            FROM {{ ref('msat_po_item_schedule_lines__emtk_ebs') }}
                            QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK, LINE_LOCATION_ID ORDER BY LOAD_DTS DESC)
                            UNION ALL
                            SELECT PO_ITEM_HK, TO_DATE(PROMISED_DATE), TO_DATE(NEED_BY_DATE)
                                 , (COALESCE(_FIVETRAN_DELETED, FALSE) AND CREATION_DATE::TIMESTAMP_NTZ > _FIVETRAN_SYNCED::TIMESTAMP_NTZ - INTERVAL '500 days')
                            FROM {{ ref('msat_po_item_schedule_lines__fib_ocf') }}
                            QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK, LINE_LOCATION_ID ORDER BY LOAD_DTS DESC)
                        ) SCHED_UNION
                        /* Fivetran soft-delete handling: PSA_DELETE_IND is obsolete for Fivetran sources
                           (ML/EMTK EBS, FIB Fusion). Fivetran marks soft-deletes via _FIVETRAN_DELETED.
                           IS_TRUE_DELETE excludes TRUE deletes (Fivetran-deleted AND created within 500 days
                           of the sync that detected the delete); archived/aged-out deletes (older) and all
                           active records are KEPT so historical schedules are not dropped. COALESCE guards the
                           NULL case: a deleted row with NULL CREATION_DATE/_FIVETRAN_SYNCED has indeterminate
                           age, so IS_TRUE_DELETE is NULL -> treated as NOT a true delete -> KEPT. */
                        WHERE NOT COALESCE(IS_TRUE_DELETE, FALSE)
                        GROUP BY PO_ITEM_HK )

/*
SRC_L              as ( SELECT * FROM RAW_VAULT.LNK_PO_RECEIPT )
SRC_H_SUPP         as ( SELECT * FROM RAW_VAULT.HUB_SUPPLIER_V2 )
SRC_H_PO           as ( SELECT * FROM RAW_VAULT.HUB_PO_HEADER )
SRC_SAT_ML         as ( SELECT * FROM RAW_VAULT.LSAT_PO_RECEIPT__ML_EBS )
SRC_SATSUP_ML      as ( SELECT * FROM RAW_VAULT.SAT_SUPPLIER__ML_EBS )
SRC_SATITMB_ML     as ( SELECT * FROM RAW_VAULT.SAT_ITEM_BASE__ML_EBS_V2 )
SRC_SATPOITM_ML    as ( SELECT * FROM RAW_VAULT.SAT_PO_ITEM__ML_EBS )
SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.LSAT_PO_RECEIPT__WINN_SAP )
SRC_SATHDR_WINN    as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__WINN_SAP )
SRC_SAT_LRSN       as ( SELECT * FROM RAW_VAULT.LSAT_PO_RECEIPT__LRSN_PSFT )
SRC_SAT_E21        as ( SELECT * FROM RAW_VAULT.LSAT_PO_RECEIPT__TT_E21 )
SRC_SATHDR_E21     as ( SELECT * FROM RAW_VAULT.MSAT_PO_HEADER__TT_E21 )
SRC_SAT_GP         as ( SELECT * FROM RAW_VAULT.LSAT_PO_RECEIPT__TT_GP )
SRC_SATHDR_GP      as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__TT_GP )
SRC_SATPOITEM_GP   as ( SELECT * FROM RAW_VAULT.SAT_PO_ITEM__TT_GP )
SRC_SAT_EMTK       as ( SELECT * FROM RAW_VAULT.LSAT_PO_RECEIPT__EMTK_EBS )
SRC_SATPOITEM_EMTK as ( SELECT * FROM RAW_VAULT.SAT_PO_ITEM__EMTK_EBS )
SRC_SATITMB_EMTK   as ( SELECT * FROM RAW_VAULT.SAT_ITEM_BASE__EMTK_EBS )
SRC_SATPL_EMTK     as ( SELECT * FROM RAW_VAULT.SAT_PLANT__EMTK_EBS )
SRC_SATLGL_EMTK    as ( SELECT * FROM RAW_VAULT.SAT_LEGAL_ENTITY__EMTK_EBS )
SRC_SAT_FIB        as ( SELECT * FROM RAW_VAULT.LSAT_PO_RECEIPT__FIB_OCF )
SRC_SATPOITEM_FIB  as ( SELECT * FROM RAW_VAULT.SAT_PO_ITEM__FIB_OCF )
SRC_SATITMB_FIB    as ( SELECT * FROM RAW_VAULT.SAT_ITEM_BASE__FIB_OCF )
SRC_SATPL_FIB      as ( SELECT * FROM RAW_VAULT.SAT_PLANT__FIB_OCF )
SRC_SATLGL_FIB     as ( SELECT * FROM RAW_VAULT.SAT_LEGAL_ENTITY__FIB_OCF )
SRC_SATHDR_ML      as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__ML_EBS )
SRC_SATHDR_EMTK    as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__EMTK_EBS )
SRC_SATHDR_FIB     as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__FIB_OCF )
*/
---- LOGIC LAYER ----

, LOGIC_L as (
    SELECT
        'PIT_PO_RECEIPT'                                             as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , PO_HEADER_HK
      , PO_ITEM_RECEIPT_DK
      , LNK_PO_RECEIPT_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PO_ITEM_HK
      , REC_SRC
    FROM SRC_L
)

, LOGIC_H_SUPP as (
    SELECT
        SUPPLIER_BK
      , SUPPLIER_HK                                                  as                                    HUB_SUPPLIER_HK
    FROM SRC_H_SUPP
)

, LOGIC_H_PO as (
    SELECT
        BKCC
      , PO_HEADER_BK
      , PO_HEADER_HK                                                 as                                   HUB_PO_HEADER_HK
    FROM SRC_H_PO
)

, LOGIC_SAT_ML as (
    SELECT
        TRANSACTION_TYPE_ID
      , TRANSACTION_TYPE_ID::TEXT                                    as                         SAT_ML_TRANSACTION_TYPE_ID
      , TRANSACTION_DATE
      , TRANSACTION_DATE::DATE                                       as                            SAT_ML_TRANSACTION_DATE
      , TRANSACTION_QUANTITY
      , TRANSACTION_COST
      , ORGANIZATION_ID
      , ORGANIZATION_ID::TEXT                                        as                             SAT_ML_ORGANIZATION_ID
      , BKCC                                                         as                                        SAT_ML_BKCC
      , LNK_PO_RECEIPT_HK                                            as                           SAT_ML_LNK_PO_RECEIPT_HK
      , TRANSACTION_UOM
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                            SAT_ML_FIVETRAN_DELETED
      , TRANSACTION_ID                                               as                              SAT_ML_TRANSACTION_ID
    FROM SRC_SAT_ML
)

, LOGIC_SATSUP_ML as (
    SELECT
        SEGMENT1                                                     as                                       SUP_SEGMENT1
      , SUP_SEGMENT1::TEXT                                           as                           SAT_ML_SUPPLIER_SEGMENT1
      , SUPPLIER_HK                                                  as                              SATSUP_ML_SUPPLIER_HK
    FROM SRC_SATSUP_ML
)

, LOGIC_SATITMB_ML as (
    SELECT
        SEGMENT1                                                     as                                       ITM_SEGMENT1
      , ITM_SEGMENT1::TEXT                                           as                               SAT_ML_ITEM_SEGMENT1
      , ITEM_HK                                                      as                                 SATITMB_ML_ITEM_HK
    FROM SRC_SATITMB_ML
)

, LOGIC_SATPOITM_ML as (
    SELECT
        PO_HEADER_ID
      , LINE_NUM
      , ORG_ID
      , COALESCE(PO_HEADER_ID::TEXT, '')                             as                                SAT_ML_PO_HEADER_ID
      , LINE_NUM::TEXT                                               as                                    SAT_ML_LINE_NUM
      , ORG_ID::TEXT                                                 as                                      SAT_ML_ORG_ID
      , PO_ITEM_HK                                                   as                             SATPOITM_ML_PO_ITEM_HK
    FROM SRC_SATPOITM_ML
)

, LOGIC_SAT_WINN as (
    SELECT
        DMBTR                                                        as                             PO_RECEIPT_VALUE_LOCAL
      , BWART                                                        as                                      MOVEMENT_TYPE
      , SHKZG                                                        as                                   DEBIT_CREDIT_IND
      , HSWAE                                                        as                                     LOCAL_CURRENCY
      , BEWTP
      , BUDAT
      , TRY_TO_DATE(BUDAT, 'YYYYMMDD')                               as                                     SAT_WINN_BUDAT
      , MENGE
      , WRBTR
      , EBELN
      , EBELP
      , MATNR
      , WERKS
      , BELNR
      , BUZEI
      , BKCC                                                         as                                      SAT_WINN_BKCC
      , LNK_PO_RECEIPT_HK                                           as                         SAT_WINN_LNK_PO_RECEIPT_HK
      , LSMEH
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_SAT_WINN
)

, LOGIC_SATHDR_WINN as (
    SELECT
        LIFNR
      , BUKRS
      , PO_HEADER_HK                                                 as                           SATHDR_WINN_PO_HEADER_HK
    FROM SRC_SATHDR_WINN
)

, LOGIC_SAT_LRSN as (
    SELECT
        CURRENCY_CD
      , RECV_SHIP_STATUS
      , LNK_PO_RECEIPT_HK                                            as                         SAT_LRSN_LNK_PO_RECEIPT_HK
      , PO_ID                                                        as                                     SAT_LRSN_PO_ID
      , LINE_NBR
      , LINE_NBR::TEXT                                               as                                  SAT_LRSN_LINE_NBR
      , INV_ITEM_ID                                                  as                               SAT_LRSN_INV_ITEM_ID
      , BUSINESS_UNIT_IN                                             as                          SAT_LRSN_BUSINESS_UNIT_IN
      , BUSINESS_UNIT                                                as                             SAT_LRSN_BUSINESS_UNIT
      , PO_TYPE
      , RECEIPT_DTTM
      , RECEIPT_DTTM::DATE                                           as                              SAT_LRSN_RECEIPT_DTTM
      , QTY_SH_RECVD
      , RECEIVE_UOM
      , MERCHANDISE_AMT
      , PRICE_RECV
      , MERCH_AMT_BSE
      , RECEIVER_ID
      , RECV_LN_NBR
      , RECV_LN_NBR::TEXT                                            as                               SAT_LRSN_RECV_LN_NBR
      , CURRENCY_CD_BASE
      , PSA_DELETE_IND                                               as                            SAT_LRSN_PSA_DELETE_IND
      , BKCC                                                         as                                      SAT_LRSN_BKCC
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                          SAT_LRSN_FIVETRAN_DELETED
    FROM SRC_SAT_LRSN
)

, LOGIC_SAT_E21 as (
    SELECT
        LNK_PO_RECEIPT_HK                                            as                          SAT_E21_LNK_PO_RECEIPT_HK
      , PO_NUMBER
      , ITEM_NO
      , REL_NUMB                                                     as                                   SAT_E21_REL_NUMB
      , VEND_CODE
      , COALESCE(VEND_CODE, '-2')                                    as                                  SAT_E21_VEND_CODE
      , PART_CODE
      , COST_CTR
      , DATE_RCV
      , LOAD_DTS
      , TO_CHAR(LOAD_DTS::DATE, 'YYYYMMDD')::INTEGER                 as                                   SAT_E21_LOAD_DTS
      , RCV_CONV
      , QTY_RECVD
      , UNIT_PRICE                                                   as                                     E21_UNIT_PRICE
      , RCV_UOM
      , CASE WHEN RCV_CONV = 0 THEN QTY_RECVD
            ELSE QTY_RECVD/RCV_CONV
        END                                                          as                               E21_RECEIPT_QUANTITY
      , CASE WHEN RCV_CONV = 0 THEN
            E21_UNIT_PRICE
            ELSE
            E21_UNIT_PRICE*RCV_CONV
        END                                                          as                                      E21_NET_PRICE
      , CASE WHEN SO_NUMBER IS NOT NULL THEN INV_EXT_COST 
            ELSE QTY_RECVD*UNIT_PRICE
        END                                                          as                                      E21_NET_VALUE
      , SO_NUMBER
      , INV_EXT_COST
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                           SAT_E21_FIVETRAN_DELETED
    FROM SRC_SAT_E21
)

, LOGIC_SATHDR_E21 as (
    SELECT
        PO_HEADER_HK                                                 as                          SATHDR_E21_PO_HEADER_HK
      , REL_NUMB                                                     as                               SAT_HDR_E21_REL_NUMB
      , BILLTO_CODE
    FROM SRC_SATHDR_E21
)

, LOGIC_SAT_GP as (
    SELECT
        LNK_PO_RECEIPT_HK                                            as                           SAT_GP_LNK_PO_RECEIPT_HK
      , POPRCTNM
      , RCPTLNNM
      , PONUMBER
      , POLNENUM
      , TRXLOCTN
      , VENDORID
      , ITEMNMBR
      , POPTYPE
      , DATERECD
      , LOAD_DTS
      , TO_CHAR(LOAD_DTS::DATE, 'YYYYMMDD')::INTEGER                 as                                    SAT_GP_LOAD_DTS
      , QTYSHPPD
      , UMQTYINB
      , PCHRPTCT
      , UOFM
      , STATUS
      , UMQTYINB*PCHRPTCT                                            as                                       GP_NET_PRICE
      , qtyshppd*UMQTYINB*PCHRPTCT                                   as                                       GP_NET_VALUE
      , PSA_DELETE_IND                                               as                              SAT_GP_PSA_DELETE_IND
    FROM SRC_SAT_GP
)

, LOGIC_SATHDR_GP as (
    SELECT
        PO_HEADER_HK                                                 as                             SATHDR_GP_PO_HEADER_HK
      , CMPANYID
      , COALESCE(CMPANYID::TEXT, '')                                 as                                     TT_GP_CMPANYID
      , DOCDATE
      , TO_CHAR(DOCDATE, 'YYYYMMDD')::INTEGER                        as                                      TT_GP_DOCDATE
    FROM SRC_SATHDR_GP
)

, LOGIC_SATPOITEM_GP as (
    SELECT
        PO_ITEM_HK                                                   as                           SATPOITM_GP_PO_ITEM_HK
      , LINENUMBER
      , LOCNCODE
    FROM SRC_SATPOITEM_GP
)

, LOGIC_SAT_EMTK as (
    SELECT
        TRANSACTION_TYPE_ID
      , TRANSACTION_TYPE_ID::TEXT                                    as                       SAT_EMTK_TRANSACTION_TYPE_ID
      , TRANSACTION_DATE
      , TRANSACTION_DATE::DATE                                       as                          SAT_EMTK_TRANSACTION_DATE
      , TRANSACTION_QUANTITY                                         as                      SAT_EMTK_TRANSACTION_QUANTITY
      , TRANSACTION_COST                                             as                          SAT_EMTK_TRANSACTION_COST
      , LNK_PO_RECEIPT_HK                                            as                         SAT_EMTK_LNK_PO_RECEIPT_HK
      , TRANSACTION_UOM                                              as                           SAT_EMTK_TRANSACTION_UOM
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                          SAT_EMTK_FIVETRAN_DELETED
      , TRANSACTION_ID                                               as                            SAT_EMTK_TRANSACTION_ID
    FROM SRC_SAT_EMTK
)

, LOGIC_SATPOITEM_EMTK as (
    SELECT
        PO_ITEM_HK                                                   as                                SAT_EMTK_PO_ITEM_HK
      , PO_HEADER_ID
      , COALESCE(PO_HEADER_ID::TEXT, '')                             as                              SAT_EMTK_PO_HEADER_ID
      , LINE_NUM                                                     as                                  SAT_EMTK_LINE_NUM
    FROM SRC_SATPOITEM_EMTK
)

, LOGIC_SATITMB_EMTK as (
    SELECT
        ITEM_HK                                                      as                               SATITMB_EMTK_ITEM_HK
      , SEGMENT1                                                     as                              SATITMB_EMTK_SEGMENT1
      , ORGANIZATION_ID
    FROM SRC_SATITMB_EMTK
)

, LOGIC_SATPL_EMTK as (
    SELECT
        PLANT_HK                                                     as                                  SAT_EMTK_PLANT_HK
      , ORGANIZATION_CODE                                            as                       SATPL_EMTK_ORGANIZATION_CODE
    FROM SRC_SATPL_EMTK
)

, LOGIC_SATLGL_EMTK as (
    SELECT
        LEGAL_ENTITY_HK                                              as                       SATLGL_EMTK_LEGAL_ENTITY_HK
      , NAME                                                         as                                   SATLGL_EMTK_NAME
    FROM SRC_SATLGL_EMTK
)

, LOGIC_SAT_FIB as (
    SELECT
        TRANSACTION_TYPE_ID
      , TRANSACTION_TYPE_ID::TEXT                                    as                        SAT_FIB_TRANSACTION_TYPE_ID
      , TRANSACTION_DATE
      , TRANSACTION_DATE::DATE                                       as                           SAT_FIB_TRANSACTION_DATE
      , TRANSACTION_QUANTITY                                         as                       SAT_FIB_TRANSACTION_QUANTITY
      , LNK_PO_RECEIPT_HK                                            as                          SAT_FIB_LNK_PO_RECEIPT_HK
      , TRANSACTION_UOM                                              as                            SAT_FIB_TRANSACTION_UOM
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                           SAT_FIB_FIVETRAN_DELETED
      , TRANSACTION_ID                                               as                             SAT_FIB_TRANSACTION_ID
    FROM SRC_SAT_FIB
)

, LOGIC_SATPOITEM_FIB as (
    SELECT
        PO_ITEM_HK                                                   as                                 SAT_FIB_PO_ITEM_HK
      , PO_HEADER_ID
      , COALESCE(PO_HEADER_ID::TEXT, '')                             as                               SAT_FIB_PO_HEADER_ID
      , UNIT_PRICE                                                   as                           SAT_FIB_TRANSACTION_COST
      , LINE_NUM                                                     as                                   SAT_FIB_LINE_NUM
    FROM SRC_SATPOITEM_FIB
)

, LOGIC_SATITMB_FIB as (
    SELECT
        ITEM_HK                                                      as                                SATITMB_FIB_ITEM_HK
      , ITEM_NUMBER                                                  as                            SATITMB_FIB_ITEM_NUMBER
      , ORGANIZATION_ID
    FROM SRC_SATITMB_FIB
)

, LOGIC_SATPL_FIB as (
    SELECT
        PLANT_HK                                                     as                                   SAT_FIB_PLANT_HK
      , ORGANIZATION_CODE                                            as                        SATPL_FIB_ORGANIZATION_CODE
    FROM SRC_SATPL_FIB
)

, LOGIC_SATLGL_FIB as (
    SELECT
        LEGAL_ENTITY_HK                                              as                        SATLGL_FIB_LEGAL_ENTITY_HK
      , LEGAL_ENTITY_IDENTIFIER                                      as                 SATLGL_FIB_LEGAL_ENTITY_IDENTIFIER
    FROM SRC_SATLGL_FIB
)

, LOGIC_SATHDR_ML as (
    SELECT
        PO_HEADER_HK                                                 as                           SATHDR_ML_PO_HEADER_HK
      , SEGMENT1                                                     as                                 SATHDR_ML_SEGMENT1
    FROM SRC_SATHDR_ML
)

, LOGIC_SATHDR_EMTK as (
    SELECT
        PO_HEADER_HK                                                 as                         SATHDR_EMTK_PO_HEADER_HK
      , SEGMENT1                                                     as                               SATHDR_EMTK_SEGMENT1
    FROM SRC_SATHDR_EMTK
)

, LOGIC_SATHDR_FIB as (
    SELECT
        PO_HEADER_HK                                                 as                          SATHDR_FIB_PO_HEADER_HK
      , SEGMENT_1                                                    as                                SATHDR_FIB_SEGMENT1
    FROM SRC_SATHDR_FIB
)

, LOGIC_E21_ITEM as (
    SELECT
        PO_ITEM_HK                                                   as                              E21_ITEM_PO_ITEM_HK
      , TO_CHAR(DATE_PROMISED, 'YYYYMMDD')::INTEGER                  as                                  E21_PROMISED_DATE
      , TO_CHAR(ORIG_DATE_PROMISED, 'YYYYMMDD')::INTEGER            as                             E21_ORIG_PROMISED_DATE
    FROM SRC_E21_ITEM
)

, LOGIC_SCHED as (
    SELECT
        PO_ITEM_HK                                                   as                                   SCHED_PO_ITEM_HK
      , TO_CHAR(PROMISED_DATE_LATEST, 'YYYYMMDD')::INTEGER           as                               PROMISED_DATE_LATEST
      , TO_CHAR(PROMISED_DATE_EARLIEST, 'YYYYMMDD')::INTEGER         as                             PROMISED_DATE_EARLIEST
      , TO_CHAR(NEED_BY_DATE_LATEST, 'YYYYMMDD')::INTEGER            as                                NEED_BY_DATE_LATEST
      , TO_CHAR(NEED_BY_DATE_EARLIEST, 'YYYYMMDD')::INTEGER          as                              NEED_BY_DATE_EARLIEST
    FROM SRC_SCHED
)
---- RENAME LAYER ----

, RENAME_L as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , PO_HEADER_HK
      , PO_ITEM_RECEIPT_DK
      , LNK_PO_RECEIPT_HK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , PO_ITEM_HK
      , REC_SRC
    FROM LOGIC_L
)

, RENAME_SAT_WINN as (
    SELECT
        PO_RECEIPT_VALUE_LOCAL
      , MOVEMENT_TYPE
      , DEBIT_CREDIT_IND
      , LOCAL_CURRENCY
      , BEWTP
      , BUDAT
      , SAT_WINN_BUDAT
      , MENGE
      , WRBTR
      , EBELN
      , EBELP
      , MATNR
      , WERKS
      , BELNR
      , BUZEI
      , SAT_WINN_BKCC
      , SAT_WINN_LNK_PO_RECEIPT_HK
      , LSMEH
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_SAT_WINN
)

, RENAME_SAT_LRSN as (
    SELECT
        CURRENCY_CD
      , RECV_SHIP_STATUS
      , SAT_LRSN_LNK_PO_RECEIPT_HK
      , SAT_LRSN_PO_ID
      , LINE_NBR
      , SAT_LRSN_LINE_NBR
      , SAT_LRSN_INV_ITEM_ID
      , SAT_LRSN_BUSINESS_UNIT_IN
      , SAT_LRSN_BUSINESS_UNIT
      , PO_TYPE
      , RECEIPT_DTTM
      , SAT_LRSN_RECEIPT_DTTM
      , QTY_SH_RECVD
      , RECEIVE_UOM
      , MERCHANDISE_AMT
      , PRICE_RECV
      , MERCH_AMT_BSE
      , RECEIVER_ID
      , RECV_LN_NBR
      , SAT_LRSN_RECV_LN_NBR
      , CURRENCY_CD_BASE
      , SAT_LRSN_PSA_DELETE_IND
      , SAT_LRSN_BKCC
      , _FIVETRAN_DELETED
      , SAT_LRSN_FIVETRAN_DELETED
    FROM LOGIC_SAT_LRSN
)

, RENAME_H_PO as (
    SELECT
        BKCC
      , PO_HEADER_BK
      , HUB_PO_HEADER_HK
    FROM LOGIC_H_PO
)

, RENAME_SAT_ML as (
    SELECT
        TRANSACTION_TYPE_ID
      , SAT_ML_TRANSACTION_TYPE_ID
      , TRANSACTION_DATE
      , SAT_ML_TRANSACTION_DATE
      , TRANSACTION_QUANTITY
      , TRANSACTION_COST
      , ORGANIZATION_ID
      , SAT_ML_ORGANIZATION_ID
      , SAT_ML_BKCC
      , SAT_ML_LNK_PO_RECEIPT_HK
      , TRANSACTION_UOM
      , _FIVETRAN_DELETED
      , SAT_ML_FIVETRAN_DELETED
      , SAT_ML_TRANSACTION_ID
    FROM LOGIC_SAT_ML
)

, RENAME_SATHDR_WINN as (
    SELECT
        LIFNR
      , BUKRS
      , SATHDR_WINN_PO_HEADER_HK
    FROM LOGIC_SATHDR_WINN
)

, RENAME_SATPOITM_ML as (
    SELECT
        PO_HEADER_ID
      , LINE_NUM
      , ORG_ID
      , SAT_ML_PO_HEADER_ID
      , SAT_ML_LINE_NUM
      , SAT_ML_ORG_ID
      , SATPOITM_ML_PO_ITEM_HK
    FROM LOGIC_SATPOITM_ML
)

, RENAME_SATSUP_ML as (
    SELECT
        SUP_SEGMENT1
      , SAT_ML_SUPPLIER_SEGMENT1
      , SATSUP_ML_SUPPLIER_HK
    FROM LOGIC_SATSUP_ML
)

, RENAME_SATITMB_ML as (
    SELECT
        ITM_SEGMENT1
      , SAT_ML_ITEM_SEGMENT1
      , SATITMB_ML_ITEM_HK
    FROM LOGIC_SATITMB_ML
)

, RENAME_H_SUPP as (
    SELECT
        SUPPLIER_BK
      , HUB_SUPPLIER_HK
    FROM LOGIC_H_SUPP
)

, RENAME_SATHDR_E21 as (
    SELECT
        SATHDR_E21_PO_HEADER_HK  
      , SAT_HDR_E21_REL_NUMB
      , BILLTO_CODE
    FROM LOGIC_SATHDR_E21
)

, RENAME_SAT_E21 as (
    SELECT
        SAT_E21_LNK_PO_RECEIPT_HK
      , PO_NUMBER
      , ITEM_NO
      , SAT_E21_REL_NUMB
      , VEND_CODE
      , SAT_E21_VEND_CODE
      , PART_CODE
      , COST_CTR
      , DATE_RCV
      , LOAD_DTS
      , SAT_E21_LOAD_DTS
      , RCV_CONV
      , QTY_RECVD
      , E21_UNIT_PRICE
      , RCV_UOM
      , E21_RECEIPT_QUANTITY
      , E21_NET_PRICE
      , E21_NET_VALUE
      , SO_NUMBER
      , INV_EXT_COST
      , _FIVETRAN_DELETED
      , SAT_E21_FIVETRAN_DELETED
    FROM LOGIC_SAT_E21
)

, RENAME_SATHDR_GP as (
    SELECT
        SATHDR_GP_PO_HEADER_HK
      , CMPANYID
      , TT_GP_CMPANYID
      , DOCDATE
      , TT_GP_DOCDATE
    FROM LOGIC_SATHDR_GP
)

, RENAME_SATPOITEM_GP as (
    SELECT
        SATPOITM_GP_PO_ITEM_HK  
      , LINENUMBER
      , LOCNCODE
    FROM LOGIC_SATPOITEM_GP
)

, RENAME_SAT_GP as (
    SELECT
        SAT_GP_LNK_PO_RECEIPT_HK
      , POPRCTNM
      , RCPTLNNM
      , PONUMBER
      , POLNENUM
      , TRXLOCTN
      , VENDORID
      , ITEMNMBR
      , POPTYPE
      , DATERECD
      , LOAD_DTS
      , SAT_GP_LOAD_DTS
      , QTYSHPPD
      , UMQTYINB
      , PCHRPTCT
      , UOFM
      , STATUS
      , GP_NET_PRICE
      , GP_NET_VALUE
      , SAT_GP_PSA_DELETE_IND
    FROM LOGIC_SAT_GP
)

, RENAME_SAT_EMTK as (
    SELECT
        TRANSACTION_TYPE_ID
      , SAT_EMTK_TRANSACTION_TYPE_ID
      , TRANSACTION_DATE
      , SAT_EMTK_TRANSACTION_DATE
      , SAT_EMTK_TRANSACTION_QUANTITY
      , SAT_EMTK_TRANSACTION_COST
      , SAT_EMTK_LNK_PO_RECEIPT_HK
      , SAT_EMTK_TRANSACTION_UOM
      , _FIVETRAN_DELETED
      , SAT_EMTK_FIVETRAN_DELETED
      , SAT_EMTK_TRANSACTION_ID
    FROM LOGIC_SAT_EMTK
)

, RENAME_SATPOITEM_EMTK as (
    SELECT
        SAT_EMTK_PO_ITEM_HK
      , PO_HEADER_ID
      , SAT_EMTK_PO_HEADER_ID
      , SAT_EMTK_LINE_NUM
    FROM LOGIC_SATPOITEM_EMTK
)

, RENAME_SATITMB_EMTK as (
    SELECT
        SATITMB_EMTK_ITEM_HK
      , SATITMB_EMTK_SEGMENT1
      , ORGANIZATION_ID
    FROM LOGIC_SATITMB_EMTK
)

, RENAME_SATLGL_EMTK as (
    SELECT
        SATLGL_EMTK_LEGAL_ENTITY_HK 
      , SATLGL_EMTK_NAME
    FROM LOGIC_SATLGL_EMTK
)

, RENAME_SATPL_EMTK as (
    SELECT
        SAT_EMTK_PLANT_HK
      , SATPL_EMTK_ORGANIZATION_CODE
    FROM LOGIC_SATPL_EMTK
)

, RENAME_SAT_FIB as (
    SELECT
        TRANSACTION_TYPE_ID
      , SAT_FIB_TRANSACTION_TYPE_ID
      , TRANSACTION_DATE
      , SAT_FIB_TRANSACTION_DATE
      , SAT_FIB_TRANSACTION_QUANTITY
      , SAT_FIB_LNK_PO_RECEIPT_HK
      , SAT_FIB_TRANSACTION_UOM
      , _FIVETRAN_DELETED
      , SAT_FIB_FIVETRAN_DELETED
      , SAT_FIB_TRANSACTION_ID
    FROM LOGIC_SAT_FIB
)

, RENAME_SATPOITEM_FIB as (
    SELECT
        SAT_FIB_PO_ITEM_HK
      , PO_HEADER_ID
      , SAT_FIB_PO_HEADER_ID
      , SAT_FIB_TRANSACTION_COST
      , SAT_FIB_LINE_NUM
    FROM LOGIC_SATPOITEM_FIB
)

, RENAME_SATITMB_FIB as (
    SELECT
        SATITMB_FIB_ITEM_HK
      , SATITMB_FIB_ITEM_NUMBER
      , ORGANIZATION_ID
    FROM LOGIC_SATITMB_FIB
)

, RENAME_SATLGL_FIB as (
    SELECT
        SATLGL_FIB_LEGAL_ENTITY_HK 
      , SATLGL_FIB_LEGAL_ENTITY_IDENTIFIER
    FROM LOGIC_SATLGL_FIB
)

, RENAME_SATPL_FIB as (
    SELECT
        SAT_FIB_PLANT_HK
      , SATPL_FIB_ORGANIZATION_CODE
    FROM LOGIC_SATPL_FIB
)

, RENAME_SATHDR_ML as (
    SELECT
        SATHDR_ML_PO_HEADER_HK  
      , SATHDR_ML_SEGMENT1
    FROM LOGIC_SATHDR_ML
)

, RENAME_SATHDR_EMTK as (
    SELECT
        SATHDR_EMTK_PO_HEADER_HK  
      , SATHDR_EMTK_SEGMENT1
    FROM LOGIC_SATHDR_EMTK
)

, RENAME_SATHDR_FIB as (
    SELECT
        SATHDR_FIB_PO_HEADER_HK  
      , SATHDR_FIB_SEGMENT1
    FROM LOGIC_SATHDR_FIB
)

, RENAME_E21_ITEM as (
    SELECT
        E21_ITEM_PO_ITEM_HK
      , E21_PROMISED_DATE
      , E21_ORIG_PROMISED_DATE
    FROM LOGIC_E21_ITEM
)

, RENAME_SCHED as (
    SELECT
        SCHED_PO_ITEM_HK
      , PROMISED_DATE_LATEST
      , PROMISED_DATE_EARLIEST
      , NEED_BY_DATE_LATEST
      , NEED_BY_DATE_EARLIEST
    FROM LOGIC_SCHED
)
---- FILTER LAYER ----

, FILTER_L as (
    SELECT *
    FROM RENAME_L
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_H_SUPP as (
    SELECT *
    FROM RENAME_H_SUPP
)

, FILTER_H_PO as (
    SELECT *
    FROM RENAME_H_PO
)

, FILTER_SAT_ML as (
    SELECT *
    FROM RENAME_SAT_ML
)

, FILTER_SATSUP_ML as (
    SELECT *
    FROM RENAME_SATSUP_ML
)

, FILTER_SATITMB_ML as (
    SELECT *
    FROM RENAME_SATITMB_ML
)

, FILTER_SATPOITM_ML as (
    SELECT *
    FROM RENAME_SATPOITM_ML
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

, FILTER_SATHDR_WINN as (
    SELECT *
    FROM RENAME_SATHDR_WINN
)

, FILTER_SAT_LRSN as (
    SELECT *
    FROM RENAME_SAT_LRSN
)

, FILTER_SAT_E21 as (
    SELECT *
    FROM RENAME_SAT_E21
)

, FILTER_SATHDR_E21 as (
    SELECT *
    FROM RENAME_SATHDR_E21
)

, FILTER_SAT_GP as (
    SELECT *
    FROM RENAME_SAT_GP
)

, FILTER_SATHDR_GP as (
    SELECT *
    FROM RENAME_SATHDR_GP
)

, FILTER_SATPOITEM_GP as (
    SELECT *
    FROM RENAME_SATPOITEM_GP
)

, FILTER_SAT_EMTK as (
    SELECT *
    FROM RENAME_SAT_EMTK
)

, FILTER_SATPOITEM_EMTK as (
    SELECT *
    FROM RENAME_SATPOITEM_EMTK
)

, FILTER_SATITMB_EMTK as (
    SELECT *
    FROM RENAME_SATITMB_EMTK
)

, FILTER_SATPL_EMTK as (
    SELECT *
    FROM RENAME_SATPL_EMTK
)

, FILTER_SATLGL_EMTK as (
    SELECT *
    FROM RENAME_SATLGL_EMTK
)

, FILTER_SAT_FIB as (
    SELECT *
    FROM RENAME_SAT_FIB
)

, FILTER_SATPOITEM_FIB as (
    SELECT *
    FROM RENAME_SATPOITEM_FIB
)

, FILTER_SATITMB_FIB as (
    SELECT *
    FROM RENAME_SATITMB_FIB
)

, FILTER_SATPL_FIB as (
    SELECT *
    FROM RENAME_SATPL_FIB
)

, FILTER_SATLGL_FIB as (
    SELECT *
    FROM RENAME_SATLGL_FIB
)

, FILTER_SATHDR_ML as (
    SELECT *
    FROM RENAME_SATHDR_ML
)

, FILTER_SATHDR_EMTK as (
    SELECT *
    FROM RENAME_SATHDR_EMTK
)

, FILTER_SATHDR_FIB as (
    SELECT *
    FROM RENAME_SATHDR_FIB
)

, FILTER_E21_ITEM as (
    SELECT *
    FROM RENAME_E21_ITEM
)

, FILTER_SCHED as (
    SELECT *
    FROM RENAME_SCHED
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_L
    LEFT JOIN FILTER_H_SUPP
        ON FILTER_L.SUPPLIER_HK  = HUB_SUPPLIER_HK
    LEFT JOIN FILTER_H_PO
        ON FILTER_L.PO_HEADER_HK = HUB_PO_HEADER_HK
    LEFT JOIN FILTER_SAT_ML
        ON FILTER_L.LNK_PO_RECEIPT_HK = SAT_ML_LNK_PO_RECEIPT_HK
    LEFT JOIN FILTER_SATSUP_ML
        ON FILTER_L.SUPPLIER_HK  = SATSUP_ML_SUPPLIER_HK
    LEFT JOIN FILTER_SATITMB_ML
        ON FILTER_L.ITEM_HK = SATITMB_ML_ITEM_HK
    LEFT JOIN FILTER_SATPOITM_ML
        ON FILTER_L.PO_ITEM_HK = SATPOITM_ML_PO_ITEM_HK
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_L.LNK_PO_RECEIPT_HK = SAT_WINN_LNK_PO_RECEIPT_HK
    LEFT JOIN FILTER_SATHDR_WINN
        ON FILTER_L.PO_HEADER_HK  = SATHDR_WINN_PO_HEADER_HK
    LEFT JOIN FILTER_SAT_LRSN
        ON FILTER_L.LNK_PO_RECEIPT_HK  = SAT_LRSN_LNK_PO_RECEIPT_HK
    LEFT JOIN FILTER_SAT_E21
        ON FILTER_L.LNK_PO_RECEIPT_HK  = SAT_E21_LNK_PO_RECEIPT_HK
    LEFT JOIN FILTER_SATHDR_E21
        ON FILTER_L.PO_HEADER_HK = SATHDR_E21_PO_HEADER_HK  
AND SAT_E21_REL_NUMB = SAT_HDR_E21_REL_NUMB
    LEFT JOIN FILTER_SAT_GP
        ON FILTER_L.LNK_PO_RECEIPT_HK  = SAT_GP_LNK_PO_RECEIPT_HK
    LEFT JOIN FILTER_SATHDR_GP
        ON FILTER_L.PO_HEADER_HK = SATHDR_GP_PO_HEADER_HK  
    LEFT JOIN FILTER_SATPOITEM_GP
        ON FILTER_L.PO_ITEM_HK = SATPOITM_GP_PO_ITEM_HK  
    LEFT JOIN FILTER_SAT_EMTK
        ON FILTER_L.LNK_PO_RECEIPT_HK  = SAT_EMTK_LNK_PO_RECEIPT_HK
    LEFT JOIN FILTER_SATPOITEM_EMTK
        ON FILTER_L.PO_ITEM_HK = SAT_EMTK_PO_ITEM_HK
    LEFT JOIN FILTER_SATITMB_EMTK
        ON FILTER_L.ITEM_HK = SATITMB_EMTK_ITEM_HK
    LEFT JOIN FILTER_SATPL_EMTK
        ON FILTER_L.PLANT_HK = SAT_EMTK_PLANT_HK
    LEFT JOIN FILTER_SATLGL_EMTK
        ON FILTER_L.LEGAL_ENTITY_HK  = SATLGL_EMTK_LEGAL_ENTITY_HK 
    LEFT JOIN FILTER_SAT_FIB
        ON FILTER_L.LNK_PO_RECEIPT_HK  = SAT_FIB_LNK_PO_RECEIPT_HK
    LEFT JOIN FILTER_SATPOITEM_FIB
        ON FILTER_L.PO_ITEM_HK = SAT_FIB_PO_ITEM_HK
    LEFT JOIN FILTER_SATITMB_FIB
        ON FILTER_L.ITEM_HK = SATITMB_FIB_ITEM_HK
    LEFT JOIN FILTER_SATPL_FIB
        ON FILTER_L.PLANT_HK = SAT_FIB_PLANT_HK
    LEFT JOIN FILTER_SATLGL_FIB
        ON FILTER_L.LEGAL_ENTITY_HK  = SATLGL_FIB_LEGAL_ENTITY_HK 
    LEFT JOIN FILTER_SATHDR_ML
        ON FILTER_L.PO_HEADER_HK = SATHDR_ML_PO_HEADER_HK  
    LEFT JOIN FILTER_SATHDR_EMTK
        ON FILTER_L.PO_HEADER_HK = SATHDR_EMTK_PO_HEADER_HK  
    LEFT JOIN FILTER_SATHDR_FIB
        ON FILTER_L.PO_HEADER_HK = SATHDR_FIB_PO_HEADER_HK  
    LEFT JOIN FILTER_E21_ITEM
        ON FILTER_L.PO_ITEM_HK = E21_ITEM_PO_ITEM_HK
    LEFT JOIN FILTER_SCHED
        ON FILTER_L.PO_ITEM_HK = SCHED_PO_ITEM_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , COALESCE(BILLTO_CODE, '-2')                                  as SAT_E21_BILLTO_CODE
        , CASE BKCC 
        WHEN 'Crouching_Dragon' THEN SAT_ML_PO_HEADER_ID
        WHEN 'Hiding_Tiger' THEN EBELN
        WHEN 'Swimming_Ocean' THEN CONCAT_WS('||', SAT_LRSN_BUSINESS_UNIT,SAT_LRSN_PO_ID)
        WHEN 'Kicking_Panda' THEN COALESCE(PO_NUMBER, PONUMBER)
        WHEN 'Diving_Sea' THEN SAT_EMTK_PO_HEADER_ID
        WHEN 'Jumping_River' THEN SAT_FIB_PO_HEADER_ID
        END as PO_HEADER_BK
        , CASE BKCC 
        WHEN 'Crouching_Dragon' THEN SATHDR_ML_SEGMENT1
        WHEN 'Hiding_Tiger' THEN EBELN
        WHEN 'Swimming_Ocean' THEN SAT_LRSN_PO_ID
        WHEN 'Kicking_Panda' THEN COALESCE(PO_NUMBER, PONUMBER)
        WHEN 'Diving_Sea' THEN SATHDR_EMTK_SEGMENT1
        WHEN 'Jumping_River' THEN SATHDR_FIB_SEGMENT1
        END as PO_NUMBER
        , CASE BKCC 
        WHEN 'Crouching_Dragon' THEN SAT_ML_LINE_NUM
        WHEN 'Hiding_Tiger' THEN EBELP::TEXT
        WHEN 'Swimming_Ocean' THEN SAT_LRSN_LINE_NBR
        WHEN 'Kicking_Panda' THEN COALESCE(POLNENUM , ITEM_NO)::TEXT
        WHEN 'Diving_Sea' THEN SAT_EMTK_LINE_NUM::TEXT
        WHEN 'Jumping_River' THEN SAT_FIB_LINE_NUM::TEXT
        END as PO_LINE_NUMBER
        , CASE BKCC 
        WHEN 'Crouching_Dragon' THEN SAT_ML_SUPPLIER_SEGMENT1
        WHEN 'Hiding_Tiger' THEN LIFNR
        WHEN 'Swimming_Ocean' THEN SUPPLIER_BK
        WHEN 'Kicking_Panda' THEN COALESCE(SAT_E21_VEND_CODE, VENDORID)
        WHEN 'Diving_Sea' THEN  SUPPLIER_BK
        WHEN  'Jumping_River'  THEN SUPPLIER_BK
        END as SUPPLIER_BK
        , CASE BKCC 
        WHEN 'Crouching_Dragon' THEN SAT_ML_ITEM_SEGMENT1
        WHEN 'Hiding_Tiger' THEN MATNR
        WHEN 'Swimming_Ocean' THEN SAT_LRSN_INV_ITEM_ID
        WHEN 'Kicking_Panda' THEN COALESCE(PART_CODE, ITEMNMBR)
        WHEN 'Diving_Sea' THEN SATITMB_EMTK_SEGMENT1
        WHEN 'Jumping_River' THEN SATITMB_FIB_ITEM_NUMBER
        END as ITEM_BK
        , CASE BKCC 
        WHEN 'Crouching_Dragon' THEN SAT_ML_ORGANIZATION_ID
        WHEN 'Hiding_Tiger' THEN WERKS
        WHEN 'Swimming_Ocean' THEN SAT_LRSN_BUSINESS_UNIT_IN
        WHEN 'Kicking_Panda' THEN COALESCE(COST_CTR, TRXLOCTN)
        WHEN 'Diving_Sea' THEN SATPL_EMTK_ORGANIZATION_CODE
        WHEN 'Jumping_River' THEN SATPL_FIB_ORGANIZATION_CODE
        END as PLANT_BK
        , CASE BKCC 
        WHEN 'Crouching_Dragon' THEN SAT_ML_ORG_ID
        WHEN 'Hiding_Tiger' THEN BUKRS
        WHEN 'Swimming_Ocean' THEN SAT_LRSN_BUSINESS_UNIT
        WHEN 'Kicking_Panda' THEN COALESCE(TT_GP_CMPANYID, SAT_E21_BILLTO_CODE)
        WHEN 'Diving_Sea' THEN SATLGL_EMTK_NAME::TEXT
        WHEN 'Jumping_River' THEN SATLGL_FIB_LEGAL_ENTITY_IDENTIFIER
        END as LEGAL_ENTITY_BK
        , COALESCE(SAT_ML_TRANSACTION_ID, SAT_EMTK_TRANSACTION_ID,SAT_FIB_TRANSACTION_ID)::TEXT as TRANSACTION_ID
        , COALESCE(BELNR,RECEIVER_ID,POPRCTNM)                         as MATERIAL_DOCUMENT_NUMBER
        , ROUND(COALESCE(BUZEI,RECV_LN_NBR,RCPTLNNM), 0)::TEXT         as MATERIAL_DOCUMENT_ITEM
        , SAT_E21_REL_NUMB                                             as RELEASE_NUMBER
        , COALESCE(BEWTP, SAT_ML_TRANSACTION_TYPE_ID,PO_TYPE,POPTYPE::TEXT,SAT_EMTK_TRANSACTION_TYPE_ID::TEXT,SAT_FIB_TRANSACTION_TYPE_ID::TEXT) as PO_RECEIPT_TYPE
        , COALESCE(SAT_WINN_BUDAT,SAT_ML_TRANSACTION_DATE,RECEIPT_DTTM,DATE_RCV,DATERECD,SAT_EMTK_TRANSACTION_DATE,SAT_FIB_TRANSACTION_DATE ) as PO_RECEIPT_DATE
        , COALESCE(MENGE, TRANSACTION_QUANTITY,QTY_SH_RECVD, E21_RECEIPT_QUANTITY,QTYSHPPD,SAT_EMTK_TRANSACTION_QUANTITY, SAT_FIB_TRANSACTION_QUANTITY ,0) as PO_RECEIPT_QUANTITY
        , UPPER(TRIM(COALESCE(LSMEH, TRANSACTION_UOM,RECEIVE_UOM,RCV_UOM, UOFM,SAT_EMTK_TRANSACTION_UOM,SAT_FIB_TRANSACTION_UOM))) as PO_RECEIPT_UOM
        , COALESCE(IFF(MENGE=0, 0, (WRBTR/MENGE)), TRANSACTION_COST, PRICE_RECV, E21_NET_PRICE, GP_NET_PRICE, SAT_EMTK_TRANSACTION_COST, SAT_FIB_TRANSACTION_COST, 0) as PO_RECEIPT_PRICE
        , PO_RECEIPT_VALUE_LOCAL
        , COALESCE(WRBTR, (TRANSACTION_COST * TRANSACTION_QUANTITY), MERCHANDISE_AMT,  E21_NET_VALUE, GP_NET_VALUE, (SAT_EMTK_TRANSACTION_COST * SAT_EMTK_TRANSACTION_QUANTITY), (SAT_FIB_TRANSACTION_COST * SAT_FIB_TRANSACTION_QUANTITY), 0) as PO_RECEIPT_VALUE
        , MOVEMENT_TYPE
        , DEBIT_CREDIT_IND
        , LOCAL_CURRENCY
        , CURRENCY_CD
        , RECV_SHIP_STATUS
        , PO_HEADER_HK
        , PO_ITEM_RECEIPT_DK
        , LNK_PO_RECEIPT_HK
        , ITEM_HK
        , SUPPLIER_HK
        , PLANT_HK
        , LEGAL_ENTITY_HK
        , PO_ITEM_HK
        , BKCC
        , REC_SRC
        , SAT_LRSN_LNK_PO_RECEIPT_HK
        , QTY_RECVD
        , RCV_UOM
        , E21_NET_VALUE
        , SO_NUMBER
        , INV_EXT_COST
        , POPTYPE
        , UMQTYINB
        , PCHRPTCT
        , SAT_ML_TRANSACTION_ID
        , SAT_EMTK_TRANSACTION_ID
        , SAT_FIB_TRANSACTION_ID
        , COALESCE(PROMISED_DATE_LATEST, E21_PROMISED_DATE)            as PROMISED_DATE_LATEST__YYYYMMDD
        , COALESCE(PROMISED_DATE_EARLIEST, E21_PROMISED_DATE)          as PROMISED_DATE_EARLIEST__YYYYMMDD
        , NEED_BY_DATE_LATEST                                          as NEED_BY_DATE_LATEST__YYYYMMDD
        , NEED_BY_DATE_EARLIEST                                        as NEED_BY_DATE_EARLIEST__YYYYMMDD
        , E21_ORIG_PROMISED_DATE                                       as ORIGINAL_PROMISED_DATE__YYYYMMDD
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(NULL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(NULL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(NULL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(NULL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(NULL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(NULL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(NULL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(NULL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PO_RECEIPT_TYPE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PO_RECEIPT_UOM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MOVEMENT_TYPE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DEBIT_CREDIT_IND as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LOCAL_CURRENCY as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_LINE_RECEIPT_IND_HK
FROM JOIN_RESULT
WHERE (TO_CHAR(PO_RECEIPT_DATE, 'YYYYMMDD')::INTEGER >= 20150101) -- MAINTAINING 10 YEARS HISTORICAL DATA
  and 
  /* Although this filter already exists in the SRC CTE above, it needs to be repeated here since this Link table drives the relationship between the entities . Filter "Cancelled" Receipt status (Larson)*/
  (
    SAT_ML_TRANSACTION_TYPE_ID in ('18', '71')
    or (bewtp = 'E' and lifnr is not null)
    or (recv_ship_status <> 'X' and TRIM(receiver_id) <> '')
    or(date_rcv is not null and qty_recvd>0) -- TTE21 Keep only Receipts
    or(status = 1  and POPTYPE !=2 and nullif(trim(PONUMBER),'') is not null) -- TTGP Filter Invoice &  Null PONUMBER as they are tied to internal inventory transfers
    or   SAT_emtk_TRANSACTION_TYPE_ID in ('18', '71')
    or  SAT_FIB_TRANSACTION_TYPE_ID in (71,18,36)
)
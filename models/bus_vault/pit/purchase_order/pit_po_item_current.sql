---- SRC LAYER ----
WITH
SRC_L              as ( SELECT ITEM_HK, LEGAL_ENTITY_HK, PO_HEADER_HK, PO_ITEM_HK, PURCHASING_ORG_HK, PURCHASING_RECORD_HK, REC_SRC, SUPPLIER_HK FROM {{ ref('lnk_po_item') }} as SRC 
                        /* This filter is necessary to ensure only one record is kept per PO ITEM level. However, the link's granularity is designed to track changes related to Legal Entity, Supplier etc.,*/
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_H              as ( SELECT BKCC, PO_ITEM_HK FROM {{ ref('hub_po_item') }} as SRC  ),
SRC_HPORG          as ( SELECT PURCHASING_ORG_BK, PURCHASING_ORG_HK FROM {{ ref('hub_purchasing_org_v2') }} as SRC  ),
SRC_HPR            as ( SELECT PURCHASING_RECORD_BK, PURCHASING_RECORD_HK FROM {{ ref('hub_purchasing_record') }} as SRC  ),
SRC_SAT_ML         as ( SELECT CANCEL_FLAG, CLOSED_CODE, LAST_UPDATE_DATE, LINE_NUM, ORG_ID, PO_HEADER_ID, PO_ITEM_HK, QUANTITY, UNIT_MEAS_LOOKUP_CODE, UNIT_PRICE, _FIVETRAN_DELETED FROM {{ ref('sat_po_item__ml_ebs') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATSUP_ML      as ( SELECT SEGMENT1, SUPPLIER_HK FROM {{ ref('sat_supplier__ml_ebs') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATITMB_ML     as ( SELECT ITEM_HK, ORGANIZATION_ID, SEGMENT1 FROM {{ ref('sat_item_base__ml_ebs_v2') }} as SRC 
                        WHERE ORGANIZATION_ID = 1 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATHDR_ML      as ( SELECT CREATION_DATE, CURRENCY_CODE, PO_HEADER_HK, SEGMENT1 FROM {{ ref('sat_po_header__ml_ebs') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) ),
SRC_CURR_CONV_ML   as ( SELECT CONVERSION_RATE, CONVERSION_TYPE, TO_CURRENCY, conversion_date, from_currency FROM {{ ref('ref_sat_currency_rates__ml_ebs') }} as SRC 
                        where TO_CURRENCY = 'USD' and UPPER(CONVERSION_TYPE) = 'SPOT'
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY CURR_RATES_BK ORDER BY LOAD_DTS DESC) ),
SRC_SAT_WINN       as ( SELECT AEDAT, BPRME, BPUMN, BPUMZ, BRTWR, BUKRS, EBELN, EBELP, ELIKZ, KNTTP, LOEKZ, MATNR, MEINS, MENGE, NETPR, NETWR, PEINH, PLIFZ, PO_ITEM_HK, PSA_DELETE_IND, REPOS, WEBAZ, WEPOS, WERKS, ZZCAUSE, ZZFRTCD FROM {{ ref('sat_po_item__winn_sap') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATHDR_WINN    as ( SELECT BEDAT, LIFNR, PO_HEADER_HK, WAERS FROM {{ ref('sat_po_header__winn_sap') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) ),
SRC_CURR_CONV_WINN as ( SELECT FCURR, FISCAL_MONTH_AVG_UKURS, FP_DATE_DT, TCURR FROM {{ ref('ref_currency_conversion_fiscal_month_avg') }} as SRC  ),
SRC_STG_SCHD_WINN  as ( SELECT PO_ITEM_HK, REQUESTED_DELIVERY_DATE_EARLIEST, REQUESTED_DELIVERY_DATE_LATEST FROM {{ ref('stg_pb_po_item_schedule__winn_sap') }} as SRC  ),
SRC_STG_LRSN       as ( SELECT BUSINESS_UNIT, CANCEL_STATUS, CURRENCY_CD, DUE_DT_EARLIEST, DUE_DT_LATEST, SHIP_DATE_EARLIEST, SHIP_DATE_LATEST, INV_ITEM_ID, ITEM_HK, LINE_NBR, LOAD_DTS, PO_HEADER_BK, PO_DT, PO_ID, PO_ITEM_HK, PRICE_PO, PRICE_PO_USD, SUM_MERCHANDISE_AMT, SUM_QTY_PO, SUPPLIER_BK, UNIT_OF_MEASURE, _FIVETRAN_DELETED FROM {{ ref('stg_pb_po_item__lrst_psft') }} as SRC  ),
SRC_SAT_E21        as ( SELECT DATE_REQD, ORIG_DATE_PROMISED, INV_EXT_COST, ITEM_NO, ITEM_STATUS, LOAD_DTS, PART_CODE, PO_ITEM_HK, PO_NUMBER, QTY_ORD, REL_NUMB, SO_NUMBER, UNIT_PRICE, UOM, UOM_CONV, VEND_CODE, _FIVETRAN_DELETED FROM {{ ref('msat_po_item__tt_e21') }} as SRC 
                        /* Defensive: prefer the latest NON Fivetran-deleted record ahead of the status/release
                           tiebreakers, so a future soft-delete cannot surface a stale date. Only ever moves selection
                           from a deleted to a non-deleted row; guarded by t_e21_po_item_latest_not_fivetran_deleted. */
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY IFF(_FIVETRAN_DELETED = TRUE, 1, 0) ASC, DECODE (ITEM_STATUS, '20',2 ,1) ,REL_NUMB DESC, LOAD_DTS DESC) ),
SRC_SATHDR_E21     as ( SELECT BILLTO_CODE, DATE_ENTERED, PO_HEADER_HK  , PO_TYPE, REL_NUMB FROM {{ ref('msat_po_header__tt_e21') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK, REL_NUMB ORDER BY LOAD_DTS DESC) ),
SRC_SAT_GP         as ( SELECT ITEMNMBR, LINENUMBER, LOAD_DTS, PONUMBER, PO_ITEM_HK, PSA_DELETE_IND, QTYORDER, REQDATE, PRMSHPDTE, UNITCOST, UOFM, VENDORID FROM {{ ref('sat_po_item__tt_gp') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY  LOAD_DTS DESC) ),
SRC_SATHDR_GP      as ( SELECT CMPANYID, DOCDATE, PO_HEADER_HK   FROM {{ ref('sat_po_header__tt_gp') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) ),
SRC_SAT_EMTK       as ( SELECT CANCEL_FLAG, CLOSED_CODE, LAST_UPDATE_DATE, LINE_NUM, PO_HEADER_ID, PO_ITEM_HK, QUANTITY, UNIT_MEAS_LOOKUP_CODE, UNIT_PRICE, _FIVETRAN_DELETED FROM {{ ref('sat_po_item__emtk_ebs') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATSUP_EMTK    as ( SELECT SEGMENT1, SUPPLIER_HK FROM {{ ref('sat_supplier__emtk_ebs') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATITMB_EMTK   as ( SELECT ITEM_HK, ORGANIZATION_ID, SEGMENT1 FROM {{ ref('sat_item_base__emtk_ebs_v1') }} as SRC 
                        WHERE  organization_id = 101 -- master organization 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATHDR_EMTK    as ( SELECT CREATION_DATE, CURRENCY_CODE, PO_HEADER_HK, SEGMENT1 FROM {{ ref('sat_po_header__emtk_ebs') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATLGL_EMTK    as ( SELECT LEGAL_ENTITY_HK, NAME FROM {{ ref('sat_legal_entity__emtk_ebs') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS DESC) ),
SRC_SAT_FIB        as ( SELECT CANCEL_FLAG, LAST_UPDATE_DATE, LINE_NUM, PO_HEADER_ID, PO_ITEM_HK, QUANTITY, SHIPPING_UOM_CODE, UNIT_PRICE, UOM_CODE, _FIVETRAN_DELETED FROM {{ ref('sat_po_item__fib_ocf') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATSUP_FIB     as ( SELECT SEGMENT_1, SUPPLIER_HK FROM {{ ref('sat_supplier__fib_ocf') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATITMB_FIB    as ( SELECT ITEM_HK, ITEM_NUMBER, ORGANIZATION_ID FROM {{ ref('sat_item_base__fib_ocf') }} as SRC 
                        WHERE  organization_id = 300000034179011 -- master organization 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY ITEM_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATHDR_FIB     as ( SELECT CREATION_DATE, CURRENCY_CODE, PO_HEADER_HK, SEGMENT_1 FROM {{ ref('sat_po_header__fib_ocf') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATLGL_FIB     as ( SELECT LEGAL_ENTITY_HK, LEGAL_ENTITY_IDENTIFIER FROM {{ ref('sat_legal_entity__fib_ocf') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS DESC) ),
SRC_EINE           as ( SELECT LD.PURCHASING_RECORD_HK, LD.PURCHASING_ORG_HK, HP.PLANT_BK, D.APLFZ, D.PSA_DELETE_IND, D.LOEKZ
                        FROM {{ ref('lnk_purchasing_record_details') }} as LD
                        INNER JOIN {{ ref('lsat_purchasing_record_details__winn_sap') }} as D ON LD.PURCHASING_RECORD_DETAILS_HK = D.PURCHASING_RECORD_DETAILS_HK
                        INNER JOIN {{ ref('hub_plant_v1') }} as HP ON LD.PLANT_HK = HP.PLANT_HK
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY LD.PURCHASING_RECORD_HK, LD.PURCHASING_ORG_HK, HP.PLANT_BK ORDER BY D.LOAD_DTS DESC) )

/*
SRC_L              as ( SELECT * FROM RAW_VAULT.LNK_PO_ITEM )
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_PO_ITEM )
SRC_HPORG          as ( SELECT * FROM RAW_VAULT.HUB_PURCHASING_ORG )
SRC_HPR            as ( SELECT * FROM RAW_VAULT.HUB_PURCHASING_RECORD )
SRC_SAT_ML         as ( SELECT * FROM RAW_VAULT.SAT_PO_ITEM__ML_EBS )
SRC_SATSUP_ML      as ( SELECT * FROM RAW_VAULT.SAT_SUPPLIER__ML_EBS )
SRC_SATITMB_ML     as ( SELECT * FROM RAW_VAULT.SAT_ITEM_BASE__ML_EBS_V2 )
SRC_SATHDR_ML      as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__ML_EBS )
SRC_CURR_CONV_ML   as ( SELECT * FROM BUS_VAULT.ref_sat_currency_rates__ml_ebs )
SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_PO_ITEM__WINN_SAP )
SRC_SATHDR_WINN    as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__WINN_SAP )
SRC_CURR_CONV_WINN as ( SELECT * FROM BUS_VAULT.ref_currency_conversion_fiscal_month_avg )
SRC_STG_SCHD_WINN  as ( SELECT * FROM BUS_VAULT.stg_pb_po_item_schedule__winn_sap )
SRC_STG_LRSN       as ( SELECT * FROM BUS_VAULT.stg_pb_po_item__lrst_psft )
SRC_SAT_E21        as ( SELECT * FROM RAW_VAULT.MSAT_PO_ITEM__TT_E21 )
SRC_SATHDR_E21     as ( SELECT * FROM RAW_VAULT.MSAT_PO_HEADER__TT_E21 )
SRC_SAT_GP         as ( SELECT * FROM RAW_VAULT.SAT_PO_ITEM__TT_GP )
SRC_SATHDR_GP      as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__TT_GP )
SRC_SAT_EMTK       as ( SELECT * FROM RAW_VAULT.SAT_PO_ITEM__EMTK_EBS )
SRC_SATSUP_EMTK    as ( SELECT * FROM RAW_VAULT.SAT_SUPPLIER__EMTK_EBS )
SRC_SATITMB_EMTK   as ( SELECT * FROM RAW_VAULT.SAT_ITEM_BASE__EMTK_EBS_V1 )
SRC_SATHDR_EMTK    as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__EMTK_EBS )
SRC_SATLGL_EMTK    as ( SELECT * FROM RAW_VAULT.SAT_LEGAL_ENTITY__EMTK_EBS )
SRC_SAT_FIB        as ( SELECT * FROM RAW_VAULT.SAT_PO_ITEM__FIB_OCF )
SRC_SATSUP_FIB     as ( SELECT * FROM RAW_VAULT.SAT_SUPPLIER__FIB_OCF )
SRC_SATITMB_FIB    as ( SELECT * FROM RAW_VAULT.SAT_ITEM_BASE__FIB_OCF )
SRC_SATHDR_FIB     as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__FIB_OCF )
SRC_SATLGL_FIB     as ( SELECT * FROM RAW_VAULT.SAT_LEGAL_ENTITY__FIB_OCF )
*/
---- LOGIC LAYER ----

, LOGIC_L as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , REC_SRC
    FROM SRC_L
)

, LOGIC_H as (
    SELECT
        'PIT_PO_ITEM'                                                as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , BKCC
      , PO_ITEM_HK                                                   as                                     HUB_PO_ITEM_HK
    FROM SRC_H
)

, LOGIC_HPORG as (
    SELECT
        PURCHASING_ORG_BK
      , PURCHASING_ORG_HK                                            as                              HUB_PURCHASING_ORG_HK
    FROM SRC_HPORG
)

, LOGIC_HPR as (
    SELECT
        PURCHASING_RECORD_BK
      , PURCHASING_RECORD_HK                                         as                           HUB_PURCHASING_RECORD_HK
    FROM SRC_HPR
)

, LOGIC_SAT_ML as (
    SELECT
        LINE_NUM
      , CANCEL_FLAG
      , QUANTITY                                                     as                                    SAT_ML_QUANTITY
      , UNIT_MEAS_LOOKUP_CODE
      , UNIT_PRICE                                                   as                                  SAT_ML_UNIT_PRICE
      , PO_ITEM_HK                                                   as                                  SAT_ML_PO_ITEM_HK
      , (QUANTITY * SAT_ML_UNIT_PRICE)                               as                                       ML_NET_VALUE
      , PO_HEADER_ID
      , COALESCE(PO_HEADER_ID::TEXT, '')                             as                                SAT_ML_PO_HEADER_ID
      , ORG_ID
      , COALESCE(ORG_ID::TEXT, '')                                   as                                      SAT_ML_ORG_ID
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                            SAT_ML_FIVETRAN_DELETED
      , LAST_UPDATE_DATE
      , TO_CHAR(LAST_UPDATE_DATE::DATE, 'YYYYMMDD')::INTEGER         as                            SAT_ML_LAST_UPDATE_DATE
      , CLOSED_CODE
    FROM SRC_SAT_ML
)

, LOGIC_SATSUP_ML as (
    SELECT
        SEGMENT1                                                     as                                       SUP_SEGMENT1
      , COALESCE(SUP_SEGMENT1::TEXT, '')                             as                             SATSUP_ML_SUP_SEGMENT1
      , SUPPLIER_HK                                                  as                              SATSUP_ML_SUPPLIER_HK
    FROM SRC_SATSUP_ML
)

, LOGIC_SATITMB_ML as (
    SELECT
        SEGMENT1                                                     as                                       ITM_SEGMENT1
      , ORGANIZATION_ID
      , ITEM_HK                                                      as                                 SATITMB_ML_ITEM_HK
    FROM SRC_SATITMB_ML
)

, LOGIC_SATHDR_ML as (
    SELECT
        CREATION_DATE                                                as                               PO_HDR_CREATION_DATE
      , TO_CHAR(PO_HDR_CREATION_DATE, 'YYYYMMDD')::INTEGER           as                     SATHDR_ML_PO_HDR_CREATION_DATE
      , TO_dATE(TO_CHAR(PO_HDR_CREATION_DATE, 'YYYYMMDD'),'YYYYMMDD') as                                  SATHDR_ML_PO_DATE
      , SEGMENT1                                                     as                                   SAT_ML_PO_NUMBER
      , CURRENCY_CODE                                                as                               SAT_ML_CURRENCY_CODE
      , PO_HEADER_HK                                                 as                             SATHDR_ML_PO_HEADER_HK
    FROM SRC_SATHDR_ML
)

, LOGIC_CURR_CONV_ML as (
    SELECT
        conversion_date
      , from_currency
      , TO_CURRENCY
      , CONVERSION_TYPE
      , CONVERSION_RATE
      , CONVERSION_RATE::NUMBER(38,4)                                     as                             SAT_ML_CONVERSION_RATE
    FROM SRC_CURR_CONV_ML
)

, LOGIC_SAT_WINN as (
    SELECT
        BRTWR                                                        as                                        GROSS_VALUE
      , CASE WHEN WEPOS = 'X' THEN 'Y'
            WHEN WEPOS IS NULL THEN 'N'
        WHEN WEPOS = '' THEN 'N' END                                 as                                  GOODS_RECEIPT_IND
      , CASE WHEN ELIKZ = 'X' THEN 'Y'
            WHEN ELIKZ IS NULL THEN 'N'
        WHEN ELIKZ = '' THEN 'N' END                                 as                         GOODS_RECEIPT_COMPLETE_IND
      , CASE WHEN REPOS = 'X' THEN 'Y'
            WHEN REPOS IS NULL THEN 'N'
        WHEN REPOS = '' THEN 'N' END                                 as                                INVOICE_RECEIPT_IND
      , KNTTP                                                        as                                 ACCOUNT_ASSIGNMENT
      , PLIFZ                                                        as                            TOTAL_PLANNED_LEAD_DAYS
      , WEBAZ                                                        as                      GOODS_RECEIPT_PROCESSING_DAYS
      , BPUMZ                                                        as                CONVERSION_PRICE_UOM_TO_ORDER_UOM_N
      , BPUMN                                                        as                CONVERSION_PRICE_UOM_TO_ORDER_UOM_D
      , EBELP
      , LOEKZ
      , MENGE
      , MEINS
      , NETPR
      , PEINH
      , BPRME
      , WEPOS
      , ELIKZ
      , REPOS
      , CASE WHEN MENGE = 0 THEN 0 ELSE NETWR / MENGE END            as                          SAT_WINN_ORDER_UNIT_PRICE
      , PO_ITEM_HK                                                   as                                SAT_WINN_PO_ITEM_HK
      , NETWR
      , EBELN
      , COALESCE(EBELN, '')                                          as                                     SAT_WINN_EBELN
      , MATNR
      , COALESCE(MATNR, '')                                          as                                     SAT_WINN_MATNR
      , BUKRS
      , COALESCE(BUKRS, '')                                          as                                     SAT_WINN_BUKRS
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
      , AEDAT
      , TO_CHAR(try_to_date(AEDAT, 'YYYYMMDD'), 'YYYYMMDD')::INTEGER as                          SAT_WINN_LAST_UPDATE_DATE
      , ZZCAUSE                                                      as                              PO_DATE_CHANGE_REASON
      , ZZFRTCD                                                      as                          FREIGHT_DELAY_REASON_CODE
      , WERKS                                                        as                                     SAT_WINN_WERKS
    FROM SRC_SAT_WINN
)

, LOGIC_SATHDR_WINN as (
    SELECT
        LIFNR
      , COALESCE(LIFNR, '')                                          as                                  SATHDR_WINN_LIFNR
      , BEDAT
      , TO_CHAR(try_to_date(BEDAT, 'YYYYMMDD'), 'YYYYMMDD')::INTEGER as                      SAT_WINN_PO_HDR_CREATION_DATE
      , WAERS
      , PO_HEADER_HK                                                 as                           SATHDR_WINN_PO_HEADER_HK
    FROM SRC_SATHDR_WINN
)

, LOGIC_CURR_CONV_WINN as (
    SELECT
        FP_DATE_DT
      , FCURR
      , TCURR
      , FISCAL_MONTH_AVG_UKURS
    FROM SRC_CURR_CONV_WINN
)

, LOGIC_STG_SCHD_WINN as (
    SELECT
        PO_ITEM_HK                                                   as                                STG_WINN_PO_ITEM_HK
      , REQUESTED_DELIVERY_DATE_LATEST                               as                WINN_REQUESTED_DELIVERY_DATE_LATEST
      , REQUESTED_DELIVERY_DATE_EARLIEST                             as              WINN_REQUESTED_DELIVERY_DATE_EARLIEST
    FROM SRC_STG_SCHD_WINN
)

, LOGIC_STG_LRSN as (
    SELECT
        CURRENCY_CD
      , PO_ITEM_HK                                                   as                                STG_LRSN_PO_ITEM_HK
      , ITEM_HK                                                      as                                   STG_LRSN_ITEM_HK
      , PO_HEADER_BK                                                 as                                  LRSN_PO_HEADER_BK
      , PO_ID
      , COALESCE(PO_ID::TEXT, '')                                    as                                     STG_LRSN_PO_ID
      , LINE_NBR
      , SUPPLIER_BK                                                  as                                   SUPPLIER_BK_LRSN
      , INV_ITEM_ID
      , BUSINESS_UNIT
      , PO_DT
      , TO_CHAR(PO_DT, 'YYYYMMDD')::INTEGER                          as                                     STG_LRSN_PO_DT
      , LOAD_DTS
      , TO_CHAR(LOAD_DTS::DATE, 'YYYYMMDD')::INTEGER                 as                                  STG_LRSN_LOAD_DTS
      , SUM_QTY_PO                                                   as                                         QTY_PO_SUM
      , UNIT_OF_MEASURE
      , SUM_MERCHANDISE_AMT                                          as                                MERCHANDISE_AMT_SUM
      , PRICE_PO_USD
      , PRICE_PO
      , CANCEL_STATUS
      , _FIVETRAN_DELETED                                            as                         STG_LRSN__FIVETRAN_DELETED
      , DUE_DT_LATEST
      , DUE_DT_EARLIEST
      , SHIP_DATE_LATEST
      , SHIP_DATE_EARLIEST
    FROM SRC_STG_LRSN
)

, LOGIC_SAT_E21 as (
    SELECT
        PO_ITEM_HK                                                   as                                 SAT_E21_PO_ITEM_HK
      , PO_NUMBER
      , REL_NUMB                                                     as                                  SAT_E21_REL_NUMB
      , ITEM_NO
      , VEND_CODE
      , PART_CODE
      , LOAD_DTS
      , TO_CHAR(LOAD_DTS::DATE, 'YYYYMMDD')::INTEGER                 as                                   SAT_E21_LOAD_DTS
      , UOM_CONV
      , QTY_ORD
      , UNIT_PRICE
      , COALESCE(UNIT_PRICE, 0)                                      as                                     E21_UNIT_PRICE
      , UOM
      , CASE WHEN UOM_CONV = 0 THEN QTY_ORD ELSE QTY_ORD/UOM_CONV END as                                 E21_ORDER_QUANTITY
      , CASE WHEN UOM_CONV = 0 THEN E21_UNIT_PRICE ELSE E21_UNIT_PRICE*UOM_CONV END as                                      E21_NET_PRICE
      , CASE WHEN SO_NUMBER IS NOT NULL THEN INV_EXT_COST 
            ELSE QTY_ORD*E21_UNIT_PRICE
        END                                                          as                                      E21_NET_VALUE
      , ITEM_STATUS
      , SO_NUMBER
      , INV_EXT_COST
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                           SAT_E21_FIVETRAN_DELETED
      , DATE_REQD
      , TO_CHAR(DATE_REQD, 'YYYYMMDD')::INTEGER                      as                                   TT_E21_DATE_REQD
      , TO_CHAR(ORIG_DATE_PROMISED, 'YYYYMMDD')::INTEGER             as                          TT_E21_ORIG_DATE_PROMISED
    FROM SRC_SAT_E21
)

, LOGIC_SATHDR_E21 as (
    SELECT
        PO_HEADER_HK                                                 as                          SATHDR_E21_PO_HEADER_HK
      , REL_NUMB                                                     as                               SAT_HDR_E21_REL_NUMB
      , BILLTO_CODE
      , PO_TYPE
      , DATE_ENTERED
      , TO_CHAR(DATE_ENTERED, 'YYYYMMDD')::INTEGER                   as                                TT_E21_DATE_ENTERED
      , 'USD'                                                        as                                         TT_E21_USD
    FROM SRC_SATHDR_E21
)

, LOGIC_SAT_GP as (
    SELECT
        PO_ITEM_HK                                                   as                                  SAT_GP_PO_ITEM_HK
      , PONUMBER
      , LINENUMBER
      , VENDORID
      , ITEMNMBR
      , LOAD_DTS
      , TO_CHAR(LOAD_DTS::DATE, 'YYYYMMDD')::INTEGER                 as                                    SAT_GP_LOAD_DTS
      , QTYORDER
      , UNITCOST
      , UOFM
      , QTYORDER*UNITCOST                                            as                                       GP_NET_VALUE
      , PSA_DELETE_IND                                               as                          SAT_E21__FIVETRAN_DELETED
      , REQDATE
      , TO_CHAR(REQDATE, 'YYYYMMDD')::INTEGER                        as                                      TT_GP_REQDATE
      , TO_CHAR(PRMSHPDTE, 'YYYYMMDD')::INTEGER                      as                                    TT_GP_PRMSHPDTE
    FROM SRC_SAT_GP
)

, LOGIC_SATHDR_GP as (
    SELECT
        PO_HEADER_HK                                                 as                             SATHDR_GP_PO_HEADER_HK
      , CMPANYID
      , COALESCE(CMPANYID::TEXT, '')                                 as                                     TT_GP_CMPANYID
      , DOCDATE
      , TO_CHAR(DOCDATE, 'YYYYMMDD')::INTEGER                        as                                      TT_GP_DOCDATE
      , 'USD'                                                        as                                          TT_GP_USD
    FROM SRC_SATHDR_GP
)

, LOGIC_SAT_EMTK as (
    SELECT
        PO_ITEM_HK                                                   as                                SAT_EMTK_PO_ITEM_HK
      , PO_HEADER_ID
      , COALESCE(PO_HEADER_ID::TEXT, '')                             as                              SAT_EMTK_PO_HEADER_ID
      , LINE_NUM                                                     as                                  SAT_EMTK_LINE_NUM
      , CANCEL_FLAG                                                  as                               SAT_EMTK_CANCEL_FLAG
      , QUANTITY                                                     as                                  SAT_EMTK_QUANTITY
      , UNIT_MEAS_LOOKUP_CODE                                        as                     SAT_EMTK_UNIT_MEAS_LOOKUP_CODE
      , UNIT_PRICE                                                   as                                SAT_EMTK_UNIT_PRICE
      , CLOSED_CODE                                                  as                               SAT_EMTK_CLOSED_CODE
      , LAST_UPDATE_DATE
      , TO_CHAR(LAST_UPDATE_DATE::DATE, 'YYYYMMDD')::INTEGER         as                          SAT_EMTK_LAST_UPDATE_DATE
      , (SAT_EMTK_QUANTITY * SAT_EMTK_UNIT_PRICE)                    as                                     EMTK_NET_VALUE
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                          SAT_EMTK_FIVETRAN_DELETED
    FROM SRC_SAT_EMTK
)

, LOGIC_SATSUP_EMTK as (
    SELECT
        SUPPLIER_HK                                                  as                            SATSUP_EMTK_SUPPLIER_HK
      , SEGMENT1
      , COALESCE(SEGMENT1::TEXT, '')                                 as                               SATSUP_EMTK_SEGMENT1
    FROM SRC_SATSUP_EMTK
)

, LOGIC_SATITMB_EMTK as (
    SELECT
        ITEM_HK                                                      as                               SATITMB_EMTK_ITEM_HK
      , SEGMENT1
      , COALESCE(SEGMENT1::TEXT, '')                                 as                              SATITMB_EMTK_SEGMENT1
      , ORGANIZATION_ID
    FROM SRC_SATITMB_EMTK
)

, LOGIC_SATHDR_EMTK as (
    SELECT
        PO_HEADER_HK                                                 as                           SATHDR_EMTK_PO_HEADER_HK
      , CREATION_DATE
      , TO_CHAR(CREATION_DATE, 'YYYYMMDD')::INTEGER                  as                          SATHDR_EMTK_CREATION_DATE
      , SEGMENT1                                                     as                                 SAT_EMTK_PO_NUMBER
      , CURRENCY_CODE                                                as                             SAT_EMTK_CURRENCY_CODE
    FROM SRC_SATHDR_EMTK
)

, LOGIC_SATLGL_EMTK as (
    SELECT
        LEGAL_ENTITY_HK                                              as                       SATLGL_EMTK_LEGAL_ENTITY_HK
      , NAME                                                         as                                   SATLGL_EMTK_NAME
    FROM SRC_SATLGL_EMTK
)

, LOGIC_SAT_FIB as (
    SELECT
        PO_ITEM_HK                                                   as                                 SAT_FIB_PO_ITEM_HK
      , PO_HEADER_ID
      , COALESCE(PO_HEADER_ID::TEXT, '')                             as                               SAT_FIB_PO_HEADER_ID
      , LINE_NUM                                                     as                                   SAT_FIB_LINE_NUM
      , CANCEL_FLAG                                                  as                                SAT_FIB_CANCEL_FLAG
      , QUANTITY
      , COALESCE(QUANTITY, 0)                                        as                                   SAT_FIB_QUANTITY
      , UOM_CODE                                                     as                                   SAT_FIB_UOM_CODE
      , SHIPPING_UOM_CODE                                            as                          SAT_FIB_SHIPPING_UOM_CODE
      , UNIT_PRICE
      , COALESCE(UNIT_PRICE, 0)                                      as                                 SAT_FIB_UNIT_PRICE
      , LAST_UPDATE_DATE
      , TO_CHAR(LAST_UPDATE_DATE::DATE, 'YYYYMMDD')::INTEGER         as                           SAT_FIB_LAST_UPDATE_DATE
      , COALESCE((SAT_FIB_QUANTITY * SAT_FIB_UNIT_PRICE), 0)         as                                      FIB_NET_VALUE
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                           SAT_FIB_FIVETRAN_DELETED
    FROM SRC_SAT_FIB
)

, LOGIC_SATSUP_FIB as (
    SELECT
        SUPPLIER_HK                                                  as                             SATSUP_FIB_SUPPLIER_HK
      , SEGMENT_1
      , COALESCE(SEGMENT_1::TEXT, '')                                as                                SATSUP_FIB_SEGMENT1
    FROM SRC_SATSUP_FIB
)

, LOGIC_SATITMB_FIB as (
    SELECT
        ITEM_HK                                                      as                                SATITMB_FIB_ITEM_HK
      , ITEM_NUMBER
      , ITEM_NUMBER::TEXT                                            as                            SATITMB_FIB_ITEM_NUMBER
      , ORGANIZATION_ID
    FROM SRC_SATITMB_FIB
)

, LOGIC_SATHDR_FIB as (
    SELECT
        PO_HEADER_HK                                                 as                            SATHDR_FIB_PO_HEADER_HK
      , CREATION_DATE
      , TO_CHAR(CREATION_DATE, 'YYYYMMDD')::INTEGER                  as                           SATHDR_FIB_CREATION_DATE
      , SEGMENT_1                                                    as                                  SAT_FIB_PO_NUMBER
      , CURRENCY_CODE                                                as                              SAT_FIB_CURRENCY_CODE
    FROM SRC_SATHDR_FIB
)

, LOGIC_SATLGL_FIB as (
    SELECT
        LEGAL_ENTITY_HK                                              as                        SATLGL_FIB_LEGAL_ENTITY_HK
      , LEGAL_ENTITY_IDENTIFIER                                      as                        LEGAL_ENTITY_IDENTIFIER_FIB
    FROM SRC_SATLGL_FIB
)

, LOGIC_EINE as (
    SELECT
        PURCHASING_RECORD_HK                                        as                          EINE_PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK                                           as                             EINE_PURCHASING_ORG_HK
      , PLANT_BK                                                    as                                      EINE_PLANT_BK
      , APLFZ                                                       as                           TRANSPORTATION_LEAD_DAYS
    FROM SRC_EINE
    WHERE (PSA_DELETE_IND IS NULL OR PSA_DELETE_IND <> 'Y')
      AND (LOEKZ IS NULL OR LOEKZ <> 'X')
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , BKCC
      , HUB_PO_ITEM_HK
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        GROSS_VALUE
      , GOODS_RECEIPT_IND
      , GOODS_RECEIPT_COMPLETE_IND
      , INVOICE_RECEIPT_IND
      , ACCOUNT_ASSIGNMENT
      , TOTAL_PLANNED_LEAD_DAYS
      , GOODS_RECEIPT_PROCESSING_DAYS
      , CONVERSION_PRICE_UOM_TO_ORDER_UOM_N
      , CONVERSION_PRICE_UOM_TO_ORDER_UOM_D
      , EBELP
      , LOEKZ
      , MENGE
      , MEINS
      , NETPR
      , PEINH
      , BPRME
      , WEPOS
      , ELIKZ
      , REPOS
      ,  SAT_WINN_ORDER_UNIT_PRICE
      , SAT_WINN_PO_ITEM_HK
      , NETWR
      , EBELN
      , SAT_WINN_EBELN
      , MATNR
      , SAT_WINN_MATNR
      , BUKRS
      , SAT_WINN_BUKRS
      , SAT_WINN_PSA_DELETE_IND
      , AEDAT
      , SAT_WINN_LAST_UPDATE_DATE
      , PO_DATE_CHANGE_REASON
      , FREIGHT_DELAY_REASON_CODE
      , SAT_WINN_WERKS
    FROM LOGIC_SAT_WINN
)

, RENAME_STG_LRSN as (
    SELECT
        CURRENCY_CD
      , STG_LRSN_PO_ITEM_HK
      , STG_LRSN_ITEM_HK
      , LRSN_PO_HEADER_BK
      , PO_ID
      , STG_LRSN_PO_ID
      , LINE_NBR
      , SUPPLIER_BK_LRSN
      , INV_ITEM_ID
      , BUSINESS_UNIT
      , PO_DT
      , STG_LRSN_PO_DT
      , LOAD_DTS
      , STG_LRSN_LOAD_DTS
      , QTY_PO_SUM
      , UNIT_OF_MEASURE
      , MERCHANDISE_AMT_SUM
      , PRICE_PO_USD
      , PRICE_PO
      , CANCEL_STATUS
      , STG_LRSN__FIVETRAN_DELETED
      , DUE_DT_LATEST
      , DUE_DT_EARLIEST
      , SHIP_DATE_LATEST
      , SHIP_DATE_EARLIEST
    FROM LOGIC_STG_LRSN
)

, RENAME_L as (
    SELECT
        PO_ITEM_HK
      , PO_HEADER_HK
      , ITEM_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK
      , PURCHASING_RECORD_HK
      , PURCHASING_ORG_HK
      , REC_SRC
    FROM LOGIC_L
)

, RENAME_HPORG as (
    SELECT
        PURCHASING_ORG_BK
      , HUB_PURCHASING_ORG_HK
    FROM LOGIC_HPORG
)

, RENAME_HPR as (
    SELECT
        PURCHASING_RECORD_BK
      , HUB_PURCHASING_RECORD_HK
    FROM LOGIC_HPR
)

, RENAME_SAT_ML as (
    SELECT
        LINE_NUM
      , CANCEL_FLAG
      , SAT_ML_QUANTITY
      , UNIT_MEAS_LOOKUP_CODE
      , SAT_ML_UNIT_PRICE
      , SAT_ML_PO_ITEM_HK
      , ML_NET_VALUE
      , PO_HEADER_ID
      , SAT_ML_PO_HEADER_ID
      , ORG_ID
      , SAT_ML_ORG_ID
      , _FIVETRAN_DELETED
      , SAT_ML_FIVETRAN_DELETED
      , LAST_UPDATE_DATE
      , SAT_ML_LAST_UPDATE_DATE
      , CLOSED_CODE
    FROM LOGIC_SAT_ML
)

, RENAME_SATHDR_WINN as (
    SELECT
        LIFNR
      , SATHDR_WINN_LIFNR
      , BEDAT
      , SAT_WINN_PO_HDR_CREATION_DATE
      , WAERS
      , SATHDR_WINN_PO_HEADER_HK
    FROM LOGIC_SATHDR_WINN
)

, RENAME_SATSUP_ML as (
    SELECT
        SUP_SEGMENT1
      , SATSUP_ML_SUP_SEGMENT1
      , SATSUP_ML_SUPPLIER_HK
    FROM LOGIC_SATSUP_ML
)

, RENAME_SATITMB_ML as (
    SELECT
        ITM_SEGMENT1
      , ORGANIZATION_ID
      , SATITMB_ML_ITEM_HK
    FROM LOGIC_SATITMB_ML
)

, RENAME_SATHDR_ML as (
    SELECT
        PO_HDR_CREATION_DATE
      , SATHDR_ML_PO_HDR_CREATION_DATE
      , SATHDR_ML_PO_DATE
      , SAT_ML_PO_NUMBER
      , SAT_ML_CURRENCY_CODE
      , SATHDR_ML_PO_HEADER_HK
    FROM LOGIC_SATHDR_ML
)

, RENAME_STG_SCHD_WINN as (
    SELECT
        STG_WINN_PO_ITEM_HK
      , WINN_REQUESTED_DELIVERY_DATE_LATEST
      , WINN_REQUESTED_DELIVERY_DATE_EARLIEST
    FROM LOGIC_STG_SCHD_WINN
)

, RENAME_CURR_CONV_WINN as (
    SELECT
        FP_DATE_DT
      , FCURR
      , TCURR
      , FISCAL_MONTH_AVG_UKURS
    FROM LOGIC_CURR_CONV_WINN
)

, RENAME_CURR_CONV_ML as (
    SELECT
        conversion_date
      , from_currency
      , TO_CURRENCY
      , CONVERSION_TYPE
      , CONVERSION_RATE
      , SAT_ML_CONVERSION_RATE
    FROM LOGIC_CURR_CONV_ML
)

, RENAME_SAT_E21 as (
    SELECT
        SAT_E21_PO_ITEM_HK
      , PO_NUMBER
      , SAT_E21_REL_NUMB 
      , ITEM_NO
      , VEND_CODE
      , PART_CODE
      , LOAD_DTS
      , SAT_E21_LOAD_DTS
      , UOM_CONV
      , QTY_ORD
      , UNIT_PRICE
      , E21_UNIT_PRICE
      , UOM
      , E21_ORDER_QUANTITY
      , E21_NET_PRICE
      , E21_NET_VALUE
      , ITEM_STATUS
      , SO_NUMBER
      , INV_EXT_COST
      , _FIVETRAN_DELETED
      , SAT_E21_FIVETRAN_DELETED
      , DATE_REQD
      , TT_E21_DATE_REQD
      , TT_E21_ORIG_DATE_PROMISED
    FROM LOGIC_SAT_E21
)

, RENAME_SATHDR_E21 as (
    SELECT
        SATHDR_E21_PO_HEADER_HK  
      , SAT_HDR_E21_REL_NUMB
      , BILLTO_CODE
      , PO_TYPE
      , DATE_ENTERED
      , TT_E21_DATE_ENTERED
      , TT_E21_USD
    FROM LOGIC_SATHDR_E21
)

, RENAME_SAT_GP as (
    SELECT
        SAT_GP_PO_ITEM_HK
      , PONUMBER
      , LINENUMBER
      , VENDORID
      , ITEMNMBR
      , LOAD_DTS
      , SAT_GP_LOAD_DTS
      , QTYORDER
      , UNITCOST
      , UOFM
      , GP_NET_VALUE
      , SAT_E21__FIVETRAN_DELETED
      , REQDATE
      , TT_GP_REQDATE
      , TT_GP_PRMSHPDTE
    FROM LOGIC_SAT_GP
)

, RENAME_SATHDR_GP as (
    SELECT
        SATHDR_GP_PO_HEADER_HK
      , CMPANYID
      , TT_GP_CMPANYID
      , DOCDATE
      , TT_GP_DOCDATE
      , TT_GP_USD
    FROM LOGIC_SATHDR_GP
)

, RENAME_SAT_EMTK as (
    SELECT
        SAT_EMTK_PO_ITEM_HK
      , PO_HEADER_ID
      , SAT_EMTK_PO_HEADER_ID
      , SAT_EMTK_LINE_NUM
      , SAT_EMTK_CANCEL_FLAG
      , SAT_EMTK_QUANTITY
      , SAT_EMTK_UNIT_MEAS_LOOKUP_CODE
      , SAT_EMTK_UNIT_PRICE
      , SAT_EMTK_CLOSED_CODE
      , LAST_UPDATE_DATE
      , SAT_EMTK_LAST_UPDATE_DATE
      , EMTK_NET_VALUE
      , _FIVETRAN_DELETED
      , SAT_EMTK_FIVETRAN_DELETED
    FROM LOGIC_SAT_EMTK
)

, RENAME_SATHDR_EMTK as (
    SELECT
        SATHDR_EMTK_PO_HEADER_HK
      , CREATION_DATE
      , SATHDR_EMTK_CREATION_DATE
      , SAT_EMTK_PO_NUMBER
      , SAT_EMTK_CURRENCY_CODE
    FROM LOGIC_SATHDR_EMTK
)

, RENAME_SATSUP_EMTK as (
    SELECT
        SATSUP_EMTK_SUPPLIER_HK
      , SEGMENT1
      , SATSUP_EMTK_SEGMENT1
    FROM LOGIC_SATSUP_EMTK
)

, RENAME_SATITMB_EMTK as (
    SELECT
        SATITMB_EMTK_ITEM_HK
      , SEGMENT1
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

, RENAME_SAT_FIB as (
    SELECT
        SAT_FIB_PO_ITEM_HK
      , PO_HEADER_ID
      , SAT_FIB_PO_HEADER_ID
      , SAT_FIB_LINE_NUM
      , SAT_FIB_CANCEL_FLAG
      , QUANTITY
      , SAT_FIB_QUANTITY
      , SAT_FIB_UOM_CODE
      , SAT_FIB_SHIPPING_UOM_CODE
      , UNIT_PRICE
      , SAT_FIB_UNIT_PRICE
      , LAST_UPDATE_DATE
      , SAT_FIB_LAST_UPDATE_DATE
      , FIB_NET_VALUE
      , _FIVETRAN_DELETED
      , SAT_FIB_FIVETRAN_DELETED
    FROM LOGIC_SAT_FIB
)

, RENAME_SATHDR_FIB as (
    SELECT
        SATHDR_FIB_PO_HEADER_HK
      , CREATION_DATE
      , SATHDR_FIB_CREATION_DATE
      , SAT_FIB_PO_NUMBER
      , SAT_FIB_CURRENCY_CODE
    FROM LOGIC_SATHDR_FIB
)

, RENAME_SATSUP_FIB as (
    SELECT
        SATSUP_FIB_SUPPLIER_HK
      , SEGMENT_1
      , SATSUP_FIB_SEGMENT1
    FROM LOGIC_SATSUP_FIB
)

, RENAME_SATITMB_FIB as (
    SELECT
        SATITMB_FIB_ITEM_HK
      , ITEM_NUMBER
      , SATITMB_FIB_ITEM_NUMBER
      , ORGANIZATION_ID
    FROM LOGIC_SATITMB_FIB
)

, RENAME_SATLGL_FIB as (
    SELECT
        SATLGL_FIB_LEGAL_ENTITY_HK 
      , LEGAL_ENTITY_IDENTIFIER_FIB
    FROM LOGIC_SATLGL_FIB
)

, RENAME_EINE as (
    SELECT
        EINE_PURCHASING_RECORD_HK
      , EINE_PURCHASING_ORG_HK
      , EINE_PLANT_BK
      , TRANSPORTATION_LEAD_DAYS
    FROM LOGIC_EINE
)
---- FILTER LAYER ----

, FILTER_L as (
    SELECT *
    FROM RENAME_L
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_H as (
    SELECT *
    FROM RENAME_H
)

, FILTER_HPORG as (
    SELECT *
    FROM RENAME_HPORG
)

, FILTER_HPR as (
    SELECT *
    FROM RENAME_HPR
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

, FILTER_SATHDR_ML as (
    SELECT *
    FROM RENAME_SATHDR_ML
)

, FILTER_CURR_CONV_ML as (
    SELECT *
    FROM RENAME_CURR_CONV_ML
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

, FILTER_SATHDR_WINN as (
    SELECT *
    FROM RENAME_SATHDR_WINN
)

, FILTER_CURR_CONV_WINN as (
    SELECT *
    FROM RENAME_CURR_CONV_WINN
)

, FILTER_STG_SCHD_WINN as (
    SELECT *
    FROM RENAME_STG_SCHD_WINN
)

, FILTER_STG_LRSN as (
    SELECT *
    FROM RENAME_STG_LRSN
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

, FILTER_SAT_EMTK as (
    SELECT *
    FROM RENAME_SAT_EMTK
)

, FILTER_SATSUP_EMTK as (
    SELECT *
    FROM RENAME_SATSUP_EMTK
)

, FILTER_SATITMB_EMTK as (
    SELECT *
    FROM RENAME_SATITMB_EMTK
)

, FILTER_SATHDR_EMTK as (
    SELECT *
    FROM RENAME_SATHDR_EMTK
)

, FILTER_SATLGL_EMTK as (
    SELECT *
    FROM RENAME_SATLGL_EMTK
)

, FILTER_SAT_FIB as (
    SELECT *
    FROM RENAME_SAT_FIB
)

, FILTER_SATSUP_FIB as (
    SELECT *
    FROM RENAME_SATSUP_FIB
)

, FILTER_SATITMB_FIB as (
    SELECT *
    FROM RENAME_SATITMB_FIB
)

, FILTER_SATHDR_FIB as (
    SELECT *
    FROM RENAME_SATHDR_FIB
)

, FILTER_SATLGL_FIB as (
    SELECT *
    FROM RENAME_SATLGL_FIB
)

, FILTER_EINE as (
    SELECT *
    FROM RENAME_EINE
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_L
    LEFT JOIN FILTER_H
        ON FILTER_L.PO_ITEM_HK = HUB_PO_ITEM_HK
    LEFT JOIN FILTER_HPORG
        ON FILTER_L.PURCHASING_ORG_HK = HUB_PURCHASING_ORG_HK
    LEFT JOIN FILTER_HPR
        ON FILTER_L.PURCHASING_RECORD_HK = HUB_PURCHASING_RECORD_HK
    LEFT JOIN FILTER_SAT_ML
        ON FILTER_L.PO_ITEM_HK = SAT_ML_PO_ITEM_HK
    LEFT JOIN FILTER_SATSUP_ML
        ON FILTER_L.SUPPLIER_HK = SATSUP_ML_SUPPLIER_HK
    LEFT JOIN FILTER_SATITMB_ML
        ON FILTER_L.ITEM_HK = SATITMB_ML_ITEM_HK
    LEFT JOIN FILTER_SATHDR_ML
        ON FILTER_L.PO_HEADER_HK = SATHDR_ML_PO_HEADER_HK
    LEFT JOIN FILTER_CURR_CONV_ML
        ON FILTER_CURR_CONV_ML.conversion_date  = SATHDR_ML_PO_DATE 
        AND FROM_CURRENCY = SAT_ML_CURRENCY_CODE        
        -- AND TO_CURRENCY = 'USD'
        -- AND    CONVERSION_TYPE = 'Spot'
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_L.PO_ITEM_HK = SAT_WINN_PO_ITEM_HK
    LEFT JOIN FILTER_EINE
        ON FILTER_L.PURCHASING_RECORD_HK = EINE_PURCHASING_RECORD_HK
        AND FILTER_L.PURCHASING_ORG_HK = EINE_PURCHASING_ORG_HK
        AND SAT_WINN_WERKS = EINE_PLANT_BK
    LEFT JOIN FILTER_SATHDR_WINN
        ON FILTER_L.PO_HEADER_HK = SATHDR_WINN_PO_HEADER_HK
    LEFT JOIN FILTER_CURR_CONV_WINN
        ON FILTER_CURR_CONV_WINN.fp_date_dt  = TRY_TO_DATE(bedat, 'YYYYMMDD')
        AND fcurr = WAERS
        AND TCURR = 'USD'
    LEFT JOIN FILTER_STG_SCHD_WINN
        ON FILTER_L.PO_ITEM_HK = STG_WINN_PO_ITEM_HK
    LEFT JOIN FILTER_STG_LRSN
        ON FILTER_L.PO_ITEM_HK = STG_LRSN_PO_ITEM_HK
    LEFT JOIN FILTER_SAT_E21
        ON FILTER_L.PO_ITEM_HK = SAT_E21_PO_ITEM_HK
    LEFT JOIN FILTER_SATHDR_E21
        ON FILTER_L.PO_HEADER_HK = SATHDR_E21_PO_HEADER_HK  
        AND SAT_E21_REL_NUMB = SAT_HDR_E21_REL_NUMB
    LEFT JOIN FILTER_SAT_GP
        ON FILTER_L.PO_ITEM_HK = SAT_GP_PO_ITEM_HK
    LEFT JOIN FILTER_SATHDR_GP
        ON FILTER_L.PO_HEADER_HK = SATHDR_GP_PO_HEADER_HK  
    LEFT JOIN FILTER_SAT_EMTK
        ON FILTER_L.PO_ITEM_HK = SAT_EMTK_PO_ITEM_HK
    LEFT JOIN FILTER_SATSUP_EMTK
        ON FILTER_L.SUPPLIER_HK = SATSUP_EMTK_SUPPLIER_HK
    LEFT JOIN FILTER_SATITMB_EMTK
        ON FILTER_L.ITEM_HK = SATITMB_EMTK_ITEM_HK
    LEFT JOIN FILTER_SATHDR_EMTK
        ON FILTER_L.PO_HEADER_HK = SATHDR_EMTK_PO_HEADER_HK
    LEFT JOIN FILTER_SATLGL_EMTK
        ON FILTER_L.LEGAL_ENTITY_HK  = SATLGL_EMTK_LEGAL_ENTITY_HK 
    LEFT JOIN FILTER_SAT_FIB
        ON FILTER_L.PO_ITEM_HK = SAT_FIB_PO_ITEM_HK
    LEFT JOIN FILTER_SATSUP_FIB
        ON FILTER_L.SUPPLIER_HK = SATSUP_FIB_SUPPLIER_HK
    LEFT JOIN FILTER_SATITMB_FIB
        ON FILTER_L.ITEM_HK = SATITMB_FIB_ITEM_HK
    LEFT JOIN FILTER_SATHDR_FIB
        ON FILTER_L.PO_HEADER_HK = SATHDR_FIB_PO_HEADER_HK
    LEFT JOIN FILTER_SATLGL_FIB
        ON FILTER_L.LEGAL_ENTITY_HK  = SATLGL_FIB_LEGAL_ENTITY_HK 
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , COALESCE(SAT_ML_PO_HEADER_ID, SAT_WINN_EBELN, LRSN_PO_HEADER_BK, PO_NUMBER, PONUMBER,SAT_EMTK_PO_HEADER_ID,SAT_FIB_PO_HEADER_ID) as PO_HEADER_BK
        , COALESCE(SAT_ML_PO_NUMBER, SAT_WINN_EBELN, STG_LRSN_PO_ID, PO_NUMBER, PONUMBER,SAT_EMTK_PO_NUMBER,SAT_FIB_PO_NUMBER) as PO_NUMBER
        , COALESCE(LINE_NUM,  EBELP, LINE_NBR, ITEM_NO, LINENUMBER,SAT_EMTK_LINE_NUM,SAT_FIB_LINE_NUM)::TEXT as PO_LINE_NUMBER
        , COALESCE(SATSUP_ML_SUP_SEGMENT1, SATHDR_WINN_LIFNR, SUPPLIER_BK_LRSN, VEND_CODE, VENDORID,SATSUP_EMTK_SEGMENT1,SATSUP_FIB_SEGMENT1) as SUPPLIER_BK
        , CASE  WHEN BKCC = 'Crouching_Dragon' THEN COALESCE(ITM_SEGMENT1::TEXT, '')
                WHEN BKCC = 'Hiding_Tiger' THEN SAT_WINN_MATNR
                WHEN BKCC = 'Swimming_Ocean' THEN INV_ITEM_ID
                WHEN BKCC = 'Diving_Sea' THEN COALESCE(SATITMB_EMTK_SEGMENT1, '-2')
                WHEN BKCC = 'Kicking_Panda' THEN COALESCE(PART_CODE,ITEMNMBR, '-2')
                WHEN BKCC = 'Jumping_River' THEN COALESCE(SATITMB_FIB_ITEM_NUMBER, '-2')
                ELSE '-2'
        END as ITEM_BK
        , COALESCE(SAT_ML_ORG_ID , SAT_WINN_BUKRS, BUSINESS_UNIT, BILLTO_CODE, TT_GP_CMPANYID,SATLGL_EMTK_NAME,LEGAL_ENTITY_IDENTIFIER_FIB) as LEGAL_ENTITY_BK
        , COALESCE(SATHDR_ML_PO_HDR_CREATION_DATE, SAT_WINN_PO_HDR_CREATION_DATE, STG_LRSN_PO_DT, TT_E21_DATE_ENTERED, TT_GP_DOCDATE,SATHDR_EMTK_CREATION_DATE,SATHDR_FIB_CREATION_DATE) as PO_CREATION_DATE
        , COALESCE(SAT_ML_LAST_UPDATE_DATE, SAT_WINN_LAST_UPDATE_DATE, STG_LRSN_LOAD_DTS, SAT_E21_LOAD_DTS, SAT_GP_LOAD_DTS,SAT_EMTK_LAST_UPDATE_DATE,SAT_FIB_LAST_UPDATE_DATE) as PO_ITEM_LAST_UPDATE_DATE
        , CASE WHEN CANCEL_FLAG = 'N' THEN 'N'
               WHEN BKCC = 'Crouching_Dragon' AND CANCEL_FLAG IS NULL THEN 'N'
               WHEN CANCEL_FLAG = 'Y' THEN 'Y' 
               WHEN LOEKZ IN ('L', 'X', 'S') THEN 'Y'
               WHEN LOEKZ ='' THEN 'N' 
               WHEN CANCEL_STATUS IN ('X','D') THEN 'Y'
               WHEN SAT_EMTK_CANCEL_FLAG = 'N' THEN 'N'
               WHEN BKCC = 'Diving_Sea' AND  SAT_EMTK_CANCEL_FLAG IS NULL THEN 'N'
               WHEN SAT_EMTK_CANCEL_FLAG = 'Y' THEN 'Y' 
               WHEN BKCC = 'Jumping_River' AND  SAT_FIB_CANCEL_FLAG IS NULL THEN 'N'
               WHEN SAT_FIB_CANCEL_FLAG = 'Y' THEN 'Y' 
            ELSE 'N'
        END as PO_LINE_DEL_IND
        , COALESCE(SAT_ML_QUANTITY,  MENGE, QTY_PO_SUM, E21_ORDER_QUANTITY, QTYORDER,SAT_EMTK_QUANTITY,SAT_FIB_QUANTITY) as ORDER_QUANTITY
        , UPPER(TRIM(COALESCE(UNIT_MEAS_LOOKUP_CODE, MEINS, UNIT_OF_MEASURE, UOM, UOFM,SAT_EMTK_UNIT_MEAS_LOOKUP_CODE,SAT_FIB_SHIPPING_UOM_CODE))) as ORDER_UOM
        , COALESCE( SAT_WINN_ORDER_UNIT_PRICE, SAT_ML_UNIT_PRICE, SAT_EMTK_UNIT_PRICE, SAT_FIB_UNIT_PRICE, UNITCOST, E21_UNIT_PRICE, PRICE_PO) as ORDER_UNIT_PRICE
        , COALESCE(WAERS,SAT_ML_CURRENCY_CODE,CURRENCY_CD,SAT_EMTK_CURRENCY_CODE,SAT_FIB_CURRENCY_CODE,TT_GP_USD,TT_E21_USD) as PO_CURRENCY_CODE
        , CAST( IFF( WAERS = 'USD', SAT_WINN_ORDER_UNIT_PRICE,FISCAL_MONTH_AVG_UKURS *  SAT_WINN_ORDER_UNIT_PRICE)AS NUMBER(32,4)) as  SAT_WINN_ORDER_UNIT_PRICE_USD
        , CAST(IFF( SAT_ML_CURRENCY_CODE = 'USD', SAT_ML_UNIT_PRICE,SAT_ML_CONVERSION_RATE*  SAT_ML_UNIT_PRICE)  AS NUMBER(32,4)) as  SAT_ML_ORDER_UNIT_PRICE_USD
        , CASE  WHEN BKCC = 'Crouching_Dragon' THEN CAST(IFF( SAT_ML_CURRENCY_CODE = 'USD', SAT_ML_UNIT_PRICE,SAT_ML_CONVERSION_RATE*  SAT_ML_UNIT_PRICE)  AS NUMBER(32,4))
                WHEN BKCC = 'Hiding_Tiger' THEN CAST( IFF( WAERS = 'USD', SAT_WINN_ORDER_UNIT_PRICE,FISCAL_MONTH_AVG_UKURS *  SAT_WINN_ORDER_UNIT_PRICE)AS NUMBER(32,4))
                WHEN BKCC = 'Swimming_Ocean' THEN PRICE_PO_USD
                WHEN BKCC = 'Diving_Sea' THEN SAT_EMTK_UNIT_PRICE
                WHEN BKCC = 'Kicking_Panda' THEN COALESCE(UNITCOST, E21_UNIT_PRICE)
                WHEN BKCC = 'Jumping_River' THEN SAT_FIB_UNIT_PRICE
        END as ORDER_UNIT_PRICE_USD
        , COALESCE(SAT_ML_UNIT_PRICE, NETPR, PRICE_PO, E21_NET_PRICE, UNITCOST,SAT_EMTK_UNIT_PRICE,SAT_FIB_UNIT_PRICE) as NET_PRICE
        , COALESCE(IFF(BKCC in ('Crouching_Dragon' , 'Swimming_Ocean','Kicking_Panda','Diving_Sea','Jumping_River'), 1, NULL), PEINH) as PRICE_UNIT
        , UPPER(TRIM(COALESCE(UNIT_MEAS_LOOKUP_CODE, BPRME, UNIT_OF_MEASURE, UOM, UOFM,SAT_EMTK_UNIT_MEAS_LOOKUP_CODE,SAT_FIB_SHIPPING_UOM_CODE))) as PURCHASE_ORDER_PRICE_UOM
        , COALESCE(ML_NET_VALUE, NETWR, MERCHANDISE_AMT_SUM, E21_NET_VALUE, GP_NET_VALUE,EMTK_NET_VALUE,FIB_NET_VALUE, 0) as NET_VALUE
        , GROSS_VALUE
        , GOODS_RECEIPT_IND
        , GOODS_RECEIPT_COMPLETE_IND
        , COALESCE(CLOSED_CODE,CANCEL_STATUS,SAT_EMTK_CLOSED_CODE)     as CLOSED_STATUS
        , INVOICE_RECEIPT_IND
        , ACCOUNT_ASSIGNMENT
        , TOTAL_PLANNED_LEAD_DAYS
        , COALESCE(WINN_REQUESTED_DELIVERY_DATE_LATEST,TT_GP_REQDATE,TT_E21_DATE_REQD,DUE_DT_LATEST) as REQUESTED_DELIVERY_DATE_LATEST__YYYYMMDD
        , COALESCE(WINN_REQUESTED_DELIVERY_DATE_EARLIEST,TT_GP_REQDATE,TT_E21_DATE_REQD,DUE_DT_EARLIEST) as REQUESTED_DELIVERY_DATE_EARLIEST__YYYYMMDD
        , GOODS_RECEIPT_PROCESSING_DAYS
        , CONVERSION_PRICE_UOM_TO_ORDER_UOM_N
        , CONVERSION_PRICE_UOM_TO_ORDER_UOM_D
        , CURRENCY_CD
        , PO_ITEM_HK
        , PO_HEADER_HK
        , ITEM_HK
        , LEGAL_ENTITY_HK
        , SUPPLIER_HK
        , PURCHASING_RECORD_HK
        , PURCHASING_ORG_HK
        , REC_SRC
        , BKCC
        , PURCHASING_ORG_BK
        , PURCHASING_RECORD_BK
        ,  SAT_WINN_ORDER_UNIT_PRICE
        , STG_WINN_PO_ITEM_HK
        , WINN_REQUESTED_DELIVERY_DATE_LATEST
        , WINN_REQUESTED_DELIVERY_DATE_EARLIEST
        , FP_DATE_DT
        , FCURR
        , TCURR
        , FISCAL_MONTH_AVG_UKURS
        , CONVERSION_DATE
        , FROM_CURRENCY
        , TO_CURRENCY
        , CONVERSION_TYPE
        , SAT_ML_CONVERSION_RATE
        , SO_NUMBER
        , INV_EXT_COST
        , DATE_REQD
        , TT_E21_DATE_REQD
        , TT_GP_REQDATE
        , PO_DATE_CHANGE_REASON
        , FREIGHT_DELAY_REASON_CODE
        , TT_E21_ORIG_DATE_PROMISED                                    as                    ORIGINAL_PROMISED_DATE__YYYYMMDD
        , TT_GP_PRMSHPDTE                                              as                         PROMISE_SHIP_DATE__YYYYMMDD
        , SHIP_DATE_LATEST                                             as              SUPPLIER_SHIP_DATE_LATEST__YYYYMMDD
        , SHIP_DATE_EARLIEST                                           as            SUPPLIER_SHIP_DATE_EARLIEST__YYYYMMDD
        , TRANSPORTATION_LEAD_DAYS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_LINE_DEL_IND as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(GOODS_RECEIPT_IND as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(GOODS_RECEIPT_COMPLETE_IND as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CLOSED_STATUS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(INVOICE_RECEIPT_IND as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ACCOUNT_ASSIGNMENT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORDER_UOM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PURCHASE_ORDER_PRICE_UOM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(NULL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(NULL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(NULL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(NULL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(NULL as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_LINE_RECEIPT_IND_HK
FROM JOIN_RESULT
WHERE (PO_CREATION_DATE >= 20150101) 
-- Exclude suppliers with NULL or empty values to ensure only valid values are included in the PIT table.
AND (NULLIF(SUPPLIER_BK,'') IS NOT NULL)

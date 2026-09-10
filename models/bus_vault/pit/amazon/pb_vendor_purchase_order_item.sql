
---- SRC LAYER ----
WITH
SRC_h_item         as ( SELECT BKCC, REC_SRC, VENDOR_ORDER_ITEM_HK, VENDOR_ORDER_LINE_BK FROM {{ ref('hub_vendor_order_item') }} as SRC  ),
SRC_s_item         as ( SELECT AMOUNT, ITEM_SEQUENCE_NUMBER, LIST_PRICE_AMOUNT, NET_COST_AMOUNT, PSA_DELETE_IND , PURCHASE_ORDER_NUMBER, VENDOR_ORDER_ITEM_HK FROM {{ ref('sat_vendor_order_item__amazon') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER (PARTITION BY VENDOR_ORDER_ITEM_HK ORDER BY LOAD_DTS DESC) = 1 ),
SRC_s_stat         as ( SELECT NET_COST_AMOUNT,LIST_PRICE_AMOUNT,ACCEPTED_QUANTITY_AMOUNT, CONFIRMATION_STATUS, ORDERED_QUANTITY_AMOUNT, RECEIVED_QUANTITY_AMOUNT, RECEIVE_STATUS, REJECTED_QUANTITY_AMOUNT, VENDOR_ORDER_ITEM_HK FROM {{ ref('sat_vendor_order_item_status__amazon') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER (PARTITION BY VENDOR_ORDER_ITEM_HK ORDER BY LOAD_DTS DESC) = 1 ),
SRC_r_stat         as ( SELECT ACCEPTED_QUANTITY_AMOUNT, ACKNOWLEDGEMENT_DATE, REJECTED_QUANTITY_AMOUNT, VENDOR_ORDER_ITEM_HK FROM {{ ref('msat_vendor_order_item_receipt__amazon') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER (PARTITION BY VENDOR_ORDER_ITEM_HK ORDER BY LOAD_DTS DESC) = 1 ),
SRC_lnk            as ( SELECT ITEM_HK, ORDER_LINE_HK, VENDOR_ORDER_ITEM_HK, VENDOR_ORDER_HK FROM {{ ref('lnk_sales_order_vendor_details') }} as SRC  ),
SRC_h_mara         as ( SELECT ITEM_BK, ITEM_HK FROM {{ ref('hub_item_v1') }} as SRC  ),
SRC_h_vbap         as ( SELECT ORDER_LINE_BK, ORDER_LINE_HK FROM {{ ref('hub_order_line') }} as SRC  ),
SRC_h_vendor_order as ( SELECT VENDOR_ORDER_BK, VENDOR_ORDER_HK FROM {{ ref('hub_vendor_order') }} as SRC  )

/*
SRC_h_item         as ( SELECT * FROM RAW_VAULT.HUB_VENDOR_ORDER_ITEM )
SRC_s_item         as ( SELECT * FROM RAW_VAULT.SAT_VENDOR_ORDER_ITEM__AMAZON )
SRC_s_stat         as ( SELECT * FROM RAW_VAULT.SAT_VENDOR_ORDER_ITEM_STATUS__AMAZON )
SRC_r_stat         as ( SELECT * FROM RAW_VAULT.MSAT_VENDOR_ORDER_ITEM_RECEIPT__AMAZON )
SRC_lnk            as ( SELECT * FROM RAW_VAULT.LNK_SALES_ORDER_VENDOR_DETAILS )
SRC_h_mara         as ( SELECT * FROM RAW_VAULT.HUB_ITEM_V1 )
SRC_h_vbap         as ( SELECT * FROM RAW_VAULT.hub_order_line )
SRC_h_vendor_order as ( SELECT * FROM RAW_VAULT.HUB_VENDOR_ORDER )
*/
---- LOGIC LAYER ----

, LOGIC_h_item as (
    SELECT
        VENDOR_ORDER_ITEM_HK
      , VENDOR_ORDER_LINE_BK
      , REC_SRC
      , BKCC
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP ) as PIT_LOAD_DTS
    FROM SRC_h_item
)

, LOGIC_s_item as (
    SELECT
        VENDOR_ORDER_ITEM_HK                                         as                             VENDOR_ORDER_ITEM_HK_S
      , ITEM_SEQUENCE_NUMBER                                         as                          VENDOR_PO_SEQUENCE_NUMBER
      , NET_COST_AMOUNT
      , AMOUNT
      , LIST_PRICE_AMOUNT
      , PSA_DELETE_IND
      , PURCHASE_ORDER_NUMBER                                        as                                   VENDOR_PO_NUMBER
    FROM SRC_s_item
)

, LOGIC_s_stat as (
    SELECT
        VENDOR_ORDER_ITEM_HK                                         as                          VENDOR_ORDER_ITEM_HK_STAT
      , ORDERED_QUANTITY_AMOUNT
      , REJECTED_QUANTITY_AMOUNT
      , RECEIVED_QUANTITY_AMOUNT
      , ACCEPTED_QUANTITY_AMOUNT
      , CONFIRMATION_STATUS                             
      , RECEIVE_STATUS
      , NET_COST_AMOUNT AS STATUS_NET_COST_AMOUNT
      , LIST_PRICE_AMOUNT AS STATUS_LIST_PRICE_AMOUNT
    FROM SRC_s_stat
)

, LOGIC_r_stat as (
    SELECT
        VENDOR_ORDER_ITEM_HK                                         as                         VENDOR_ORDER_ITEM_HK_RSTAT
      , ACKNOWLEDGEMENT_DATE
      , ACCEPTED_QUANTITY_AMOUNT                                     as                   RECEIPT_ACCEPTED_QUANTITY_AMOUNT
      , REJECTED_QUANTITY_AMOUNT                                     as                   RECEIPT_REJECTED_QUANTITY_AMOUNT
    FROM SRC_r_stat
)

, LOGIC_lnk as (
    SELECT
        VENDOR_ORDER_ITEM_HK                                         as                           VENDOR_ORDER_ITEM_HK_LNK
      , ITEM_HK                                                      as                                        ITEM_HK_lnk
      , ORDER_LINE_HK                                                as                                  ORDER_LINE_HK_LNK
      , VENDOR_ORDER_HK                                              as                                  VENDOR_ORDER_HK_LNK
    FROM SRC_lnk
)

, LOGIC_h_mara as (
    SELECT
        ITEM_HK
      , ITEM_BK
    FROM SRC_h_mara
)

, LOGIC_h_vbap as (
    SELECT
        ORDER_LINE_HK
      , ORDER_LINE_BK
    FROM SRC_h_vbap
)

, LOGIC_h_vendor_order as (
    SELECT
        VENDOR_ORDER_BK
      , VENDOR_ORDER_HK
    FROM SRC_h_vendor_order
)
---- RENAME LAYER ----

, RENAME_h_item as (
    SELECT
        VENDOR_ORDER_ITEM_HK
      , VENDOR_ORDER_LINE_BK
      , REC_SRC
      , BKCC
      , PIT_LOAD_DTS
    FROM LOGIC_h_item
)

, RENAME_s_item as (
    SELECT
        VENDOR_ORDER_ITEM_HK_S
      , VENDOR_PO_SEQUENCE_NUMBER
      , NET_COST_AMOUNT
      , AMOUNT
      , LIST_PRICE_AMOUNT
      , PSA_DELETE_IND 
      , VENDOR_PO_NUMBER
    FROM LOGIC_s_item
)

, RENAME_s_stat as (
    SELECT
        VENDOR_ORDER_ITEM_HK_STAT
      , ORDERED_QUANTITY_AMOUNT
      , REJECTED_QUANTITY_AMOUNT
      , RECEIVED_QUANTITY_AMOUNT
      , ACCEPTED_QUANTITY_AMOUNT
      , CONFIRMATION_STATUS
      , RECEIVE_STATUS
      , STATUS_NET_COST_AMOUNT
      , STATUS_LIST_PRICE_AMOUNT
    FROM LOGIC_s_stat
)

, RENAME_r_stat as (
    SELECT
        VENDOR_ORDER_ITEM_HK_RSTAT
      , ACKNOWLEDGEMENT_DATE
      , RECEIPT_ACCEPTED_QUANTITY_AMOUNT
      , RECEIPT_REJECTED_QUANTITY_AMOUNT
    FROM LOGIC_r_stat
)

, RENAME_lnk as (
    SELECT
        VENDOR_ORDER_ITEM_HK_LNK
      , ITEM_HK_lnk
      , ORDER_LINE_HK_LNK
      , VENDOR_ORDER_HK_LNK
    FROM LOGIC_lnk
)

, RENAME_h_mara as (
    SELECT
        ITEM_HK
      , ITEM_BK
    FROM LOGIC_h_mara
)

, RENAME_h_vbap as (
    SELECT
        ORDER_LINE_HK
      , ORDER_LINE_BK
    FROM LOGIC_h_vbap
)

, RENAME_h_vendor_order as (
    SELECT
        VENDOR_ORDER_BK
      , VENDOR_ORDER_HK
    FROM LOGIC_h_vendor_order
)
---- FILTER LAYER ----

, FILTER_h_item as (
    SELECT *
    FROM RENAME_h_item
)

, FILTER_s_item as (
    SELECT *
    FROM RENAME_s_item
)

, FILTER_s_stat as (
    SELECT *
    FROM RENAME_s_stat
)

, FILTER_r_stat as (
    SELECT *
    FROM RENAME_r_stat
)

, FILTER_lnk as (
    SELECT *
    FROM RENAME_lnk
)

, FILTER_h_mara as (
    SELECT *
    FROM RENAME_h_mara
)

, FILTER_h_vbap as (
    SELECT *
    FROM RENAME_h_vbap
)

, FILTER_h_vendor_order as (
    SELECT *
    FROM RENAME_h_vendor_order
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_lnk
    INNER JOIN FILTER_h_item
        ON FILTER_lnk.VENDOR_ORDER_ITEM_HK_LNK = FILTER_h_item.VENDOR_ORDER_ITEM_HK
    INNER JOIN FILTER_h_mara
        ON FILTER_lnk.ITEM_HK_LNK = FILTER_h_mara.ITEM_HK
    INNER JOIN FILTER_h_vbap
        ON FILTER_lnk.ORDER_LINE_HK_LNK = FILTER_h_vbap.ORDER_LINE_HK
    INNER JOIN FILTER_h_vendor_order
        ON FILTER_lnk.VENDOR_ORDER_HK_LNK = FILTER_h_vendor_order.VENDOR_ORDER_HK
    INNER JOIN FILTER_s_item
        ON FILTER_h_item.VENDOR_ORDER_ITEM_HK = FILTER_s_item.VENDOR_ORDER_ITEM_HK_S
    INNER JOIN FILTER_s_stat
        ON FILTER_h_item.VENDOR_ORDER_ITEM_HK = FILTER_s_stat.VENDOR_ORDER_ITEM_HK_STAT
    INNER JOIN FILTER_r_stat
        ON FILTER_h_item.VENDOR_ORDER_ITEM_HK = FILTER_r_stat.VENDOR_ORDER_ITEM_HK_RSTAT
)

---- FINAL LAYER ----
SELECT
          VENDOR_ORDER_ITEM_HK
        , VENDOR_ORDER_BK
        , VENDOR_ORDER_LINE_BK
        , REC_SRC
        , BKCC
        , PIT_LOAD_DTS
        , VENDOR_PO_SEQUENCE_NUMBER
        , NET_COST_AMOUNT
        , AMOUNT
        , LIST_PRICE_AMOUNT 
        , ORDERED_QUANTITY_AMOUNT
        , REJECTED_QUANTITY_AMOUNT
        , RECEIVED_QUANTITY_AMOUNT
        , ACCEPTED_QUANTITY_AMOUNT
        , STATUS_NET_COST_AMOUNT
        , STATUS_LIST_PRICE_AMOUNT
        , CONFIRMATION_STATUS
        , RECEIPT_REJECTED_QUANTITY_AMOUNT
        , RECEIPT_ACCEPTED_QUANTITY_AMOUNT
        , RECEIVE_STATUS
        , VENDOR_PO_NUMBER
        , CAST(TO_CHAR(acknowledgement_date, 'YYYYMMDD') AS INTEGER) as ACKNOWLEDGEMENT_DATE__YYYYMMDD
        , ITEM_HK
        , ITEM_BK
        , ORDER_LINE_HK
        , ORDER_LINE_BK
        , VENDOR_ORDER_HK
        , CURRENT_TIMESTAMP()                                          as SNAPSHOT_DTS
        , 'PIT_VENDOR_PURCHASE_ORDER' as PIT_REC_SRC        
        , CASE BKCC WHEN 'Running_Horse' THEN PSA_DELETE_IND END        as PSA_DELETE_IND
        , row_number() over(order by 1)                                as SEQ_ID
FROM JOIN_RESULT
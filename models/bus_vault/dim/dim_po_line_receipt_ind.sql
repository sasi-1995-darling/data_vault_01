---- SRC LAYER ----
WITH
SRC_P_PO_ITM       as ( SELECT * FROM {{ ref('pit_po_item_current') }} as SRC  ),
SRC_P_PO_RCPT      as ( SELECT * FROM {{ ref('pit_po_receipt_current') }} as SRC  ),
SRC_P_PO_INVC      as ( SELECT * FROM {{ ref('pit_po_invoice_current') }} as SRC  )

/*
SRC_P_PO_ITM       as ( SELECT * FROM BUS_VAULT.PIT_PO_ITEM_CURRENT )
, SRC_P_PO_RCPT      as ( SELECT * FROM BUS_VAULT.PIT_PO_RECEIPT_CURRENT )
, SRC_P_PO_INVC      as ( SELECT * FROM BUS_VAULT.PIT_PO_INVOICE_CURRENT )
*/
---- LOGIC LAYER ----

, LOGIC_P_PO_ITM as (
    SELECT
        PO_LINE_DEL_IND
      , GOODS_RECEIPT_IND
      , GOODS_RECEIPT_COMPLETE_IND
      , CLOSED_STATUS
      , INVOICE_RECEIPT_IND
      , ACCOUNT_ASSIGNMENT
      , ORDER_UOM
      , PURCHASE_ORDER_PRICE_UOM
      , NULL                                                         as                                    PO_RECEIPT_TYPE
      , NULL                                                         as                                     PO_RECEIPT_UOM
      , NULL                                                         as                                      MOVEMENT_TYPE
      , NULL                                                         as                                   DEBIT_CREDIT_IND
      , NULL                                                         as                                     LOCAL_CURRENCY
      , BKCC
      , REC_SRC
    FROM SRC_P_PO_ITM
)

, LOGIC_P_PO_RCPT as (
    SELECT
        NULL                                                         as                                    PO_LINE_DEL_IND
      , NULL                                                         as                                  GOODS_RECEIPT_IND
      , NULL                                                         as                         GOODS_RECEIPT_COMPLETE_IND
      , NULL                                                         as                                      CLOSED_STATUS
      , NULL                                                         as                                INVOICE_RECEIPT_IND
      , NULL                                                         as                                 ACCOUNT_ASSIGNMENT
      , NULL                                                         as                                          ORDER_UOM
      , NULL                                                         as                           PURCHASE_ORDER_PRICE_UOM
      , PO_RECEIPT_TYPE
      , PO_RECEIPT_UOM
      , MOVEMENT_TYPE
      , DEBIT_CREDIT_IND
      , LOCAL_CURRENCY
      , BKCC
      , REC_SRC
    FROM SRC_P_PO_RCPT
)

, LOGIC_P_PO_INVC as (
    SELECT
        NULL                                                         as                                    PO_LINE_DEL_IND
      , NULL                                                         as                                  GOODS_RECEIPT_IND
      , NULL                                                         as                         GOODS_RECEIPT_COMPLETE_IND
      , NULL                                                         as                                      CLOSED_STATUS
      , NULL                                                         as                                INVOICE_RECEIPT_IND
      , NULL                                                         as                                 ACCOUNT_ASSIGNMENT
      , NULL                                                         as                                          ORDER_UOM
      , NULL                                                         as                           PURCHASE_ORDER_PRICE_UOM
      , PO_RECEIPT_TYPE
      , PO_RECEIPT_UOM
      , MOVEMENT_TYPE
      , DEBIT_CREDIT_IND
      , LOCAL_CURRENCY
      , BKCC
      , REC_SRC
    FROM SRC_P_PO_INVC
)
---- RENAME LAYER ----

, RENAME_P_PO_ITM as (
    SELECT
        PO_LINE_DEL_IND
      , GOODS_RECEIPT_IND
      , GOODS_RECEIPT_COMPLETE_IND
      , CLOSED_STATUS
      , INVOICE_RECEIPT_IND
      , ACCOUNT_ASSIGNMENT
      , ORDER_UOM
      , PURCHASE_ORDER_PRICE_UOM
      , PO_RECEIPT_TYPE
      , PO_RECEIPT_UOM
      , MOVEMENT_TYPE
      , DEBIT_CREDIT_IND
      , LOCAL_CURRENCY
      , BKCC
      , REC_SRC
    FROM LOGIC_P_PO_ITM
)

, RENAME_P_PO_RCPT as (
    SELECT
        PO_LINE_DEL_IND
      , GOODS_RECEIPT_IND
      , GOODS_RECEIPT_COMPLETE_IND
      , CLOSED_STATUS
      , INVOICE_RECEIPT_IND
      , ACCOUNT_ASSIGNMENT
      , ORDER_UOM
      , PURCHASE_ORDER_PRICE_UOM
      , PO_RECEIPT_TYPE
      , PO_RECEIPT_UOM
      , MOVEMENT_TYPE
      , DEBIT_CREDIT_IND
      , LOCAL_CURRENCY
      , BKCC
      , REC_SRC
    FROM LOGIC_P_PO_RCPT
)

, RENAME_P_PO_INVC as (
    SELECT
        PO_LINE_DEL_IND
      , GOODS_RECEIPT_IND
      , GOODS_RECEIPT_COMPLETE_IND
      , CLOSED_STATUS
      , INVOICE_RECEIPT_IND
      , ACCOUNT_ASSIGNMENT
      , ORDER_UOM
      , PURCHASE_ORDER_PRICE_UOM
      , PO_RECEIPT_TYPE
      , PO_RECEIPT_UOM
      , MOVEMENT_TYPE
      , DEBIT_CREDIT_IND
      , LOCAL_CURRENCY
      , BKCC
      , REC_SRC
    FROM LOGIC_P_PO_INVC
)
---- FILTER LAYER ----

, FILTER_P_PO_ITM as (
    SELECT *
    FROM RENAME_P_PO_ITM
)

, FILTER_P_PO_RCPT as (
    SELECT *
    FROM RENAME_P_PO_RCPT
)

, FILTER_P_PO_INVC as (
    SELECT *
    FROM RENAME_P_PO_INVC
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_P_PO_ITM
    UNION ALL
    SELECT * FROM FILTER_P_PO_RCPT
    UNION
    SELECT * FROM FILTER_P_PO_INVC
)

---- FINAL LAYER ----
SELECT
        MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_LINE_DEL_IND as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(GOODS_RECEIPT_IND as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(GOODS_RECEIPT_COMPLETE_IND as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(CLOSED_STATUS as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(INVOICE_RECEIPT_IND as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ACCOUNT_ASSIGNMENT as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORDER_UOM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PURCHASE_ORDER_PRICE_UOM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PO_RECEIPT_TYPE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PO_RECEIPT_UOM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MOVEMENT_TYPE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DEBIT_CREDIT_IND as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LOCAL_CURRENCY as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_LINE_RECEIPT_IND_HK
        ,  PO_LINE_DEL_IND
        , GOODS_RECEIPT_IND
        , GOODS_RECEIPT_COMPLETE_IND
        , CLOSED_STATUS
        , INVOICE_RECEIPT_IND
        , ACCOUNT_ASSIGNMENT
        , ORDER_UOM
        , PURCHASE_ORDER_PRICE_UOM
        , PO_RECEIPT_TYPE
        , PO_RECEIPT_UOM
        , MOVEMENT_TYPE
        , DEBIT_CREDIT_IND
        , LOCAL_CURRENCY
        , BKCC
        , REC_SRC
FROM JOIN_RESULT

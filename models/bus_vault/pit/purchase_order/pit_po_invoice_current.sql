---- SRC LAYER ----
WITH
SRC_L              as ( SELECT ITEM_HK, LEGAL_ENTITY_HK, LNK_PO_RECEIPT_HK, PLANT_HK, PO_HEADER_HK, PO_ITEM_RECEIPT_DK, REC_SRC, SUPPLIER_HK FROM {{ ref('lnk_po_receipt') }} as SRC 
                        /* This filter is necessary to ensure only one record is kept per PO ITEM RECEIPT level. However, the link's granularity is designed to track changes related to Legal Entity, Supplier etc.,*/
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY PO_ITEM_RECEIPT_DK ORDER BY LOAD_DTS DESC) ),
SRC_SAT_WINN       as ( SELECT BELNR, BEWTP, BKCC, BUDAT, BUZEI, BWART, DMBTR, EBELN, EBELP, HSWAE, LNK_PO_RECEIPT_HK, LSMEH, MATNR, MENGE, PSA_DELETE_IND, SHKZG, WERKS, WRBTR FROM {{ ref('lsat_po_receipt__winn_sap') }} as SRC 
                        WHERE BEWTP = 'Q'
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY LNK_PO_RECEIPT_HK ORDER BY LOAD_DTS DESC) ),
SRC_SATHDR_WINN    as ( SELECT BUKRS, LIFNR, PO_HEADER_HK FROM {{ ref('sat_po_header__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK  ORDER BY LOAD_DTS DESC) )

/*
SRC_L              as ( SELECT * FROM RAW_VAULT.LNK_PO_RECEIPT )
SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.LSAT_PO_RECEIPT__WINN_SAP )
SRC_SATHDR_WINN    as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_L as (
    SELECT
        'PIT_PO_RECEIPT'                                             as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , PO_HEADER_HK
      , LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , REC_SRC
    FROM SRC_L
)

, LOGIC_SAT_WINN as (
    SELECT
        EBELN                                                        as                                       PO_HEADER_BK
      , EBELP                                                        as                                     PO_LINE_NUMBER
      , MATNR                                                        as                                            ITEM_BK
      , WERKS                                                        as                                           PLANT_BK
      , BELNR                                                        as                           MATERIAL_DOCUMENT_NUMBER
      , BUZEI                                                        as                             MATERIAL_DOCUMENT_ITEM
      , BEWTP                                                        as                                    PO_RECEIPT_TYPE
      , BUDAT
      , TRY_TO_DATE(BUDAT, 'YYYYMMDD')                               as                                    PO_RECEIPT_DATE
      , MENGE                                                        as                                PO_RECEIPT_QUANTITY
      , LSMEH                                                        as                                     PO_RECEIPT_UOM
      , IFF(MENGE=0, 0, (WRBTR /MENGE))                              as                                   PO_RECEIPT_PRICE
      , DMBTR                                                        as                             PO_RECEIPT_VALUE_LOCAL
      , WRBTR                                                        as                                   PO_RECEIPT_VALUE
      , BWART                                                        as                                      MOVEMENT_TYPE
      , SHKZG                                                        as                                   DEBIT_CREDIT_IND
      , HSWAE                                                        as                                     LOCAL_CURRENCY
      , PSA_DELETE_IND                                               as                                         IS_DELETED
      , BKCC
      , LNK_PO_RECEIPT_HK                                            as                         SAT_WINN_LNK_PO_RECEIPT_HK
    FROM SRC_SAT_WINN
)

, LOGIC_SATHDR_WINN as (
    SELECT
        LIFNR                                                        as                                        SUPPLIER_BK
      , BUKRS                                                        as                                    LEGAL_ENTITY_BK
      , PO_HEADER_HK                                                 as                           SATHDR_WINN_PO_HEADER_HK
    FROM SRC_SATHDR_WINN
)
---- RENAME LAYER ----

, RENAME_L as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , PO_HEADER_HK
      , LNK_PO_RECEIPT_HK
      , PO_ITEM_RECEIPT_DK
      , ITEM_HK
      , SUPPLIER_HK
      , PLANT_HK
      , LEGAL_ENTITY_HK
      , REC_SRC
    FROM LOGIC_L
)

, RENAME_SAT_WINN as (
    SELECT
        PO_HEADER_BK
      , PO_LINE_NUMBER
      , ITEM_BK
      , PLANT_BK
      , MATERIAL_DOCUMENT_NUMBER
      , MATERIAL_DOCUMENT_ITEM
      , PO_RECEIPT_TYPE
      , BUDAT
      , PO_RECEIPT_DATE
      , PO_RECEIPT_QUANTITY
      , PO_RECEIPT_UOM
      , PO_RECEIPT_PRICE
      , PO_RECEIPT_VALUE_LOCAL
      , PO_RECEIPT_VALUE
      , MOVEMENT_TYPE
      , DEBIT_CREDIT_IND
      , LOCAL_CURRENCY
      , IS_DELETED
      , BKCC
      , SAT_WINN_LNK_PO_RECEIPT_HK
    FROM LOGIC_SAT_WINN
)

, RENAME_SATHDR_WINN as (
    SELECT
        SUPPLIER_BK
      , LEGAL_ENTITY_BK
      , SATHDR_WINN_PO_HEADER_HK
    FROM LOGIC_SATHDR_WINN
)
---- FILTER LAYER ----

, FILTER_L as (
    SELECT *
    FROM RENAME_L
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

, FILTER_SATHDR_WINN as (
    SELECT *
    FROM RENAME_SATHDR_WINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_L
    INNER JOIN FILTER_SAT_WINN
        ON FILTER_L.LNK_PO_RECEIPT_HK = SAT_WINN_LNK_PO_RECEIPT_HK
    LEFT JOIN FILTER_SATHDR_WINN
        ON FILTER_L.PO_HEADER_HK = SATHDR_WINN_PO_HEADER_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , PO_HEADER_BK
        , PO_LINE_NUMBER
        , SUPPLIER_BK
        , ITEM_BK
        , PLANT_BK
        , LEGAL_ENTITY_BK
        , MATERIAL_DOCUMENT_NUMBER
        , MATERIAL_DOCUMENT_ITEM
        , PO_RECEIPT_TYPE
        , PO_RECEIPT_DATE
        , PO_RECEIPT_QUANTITY
        , PO_RECEIPT_UOM
        , PO_RECEIPT_PRICE
        , PO_RECEIPT_VALUE_LOCAL
        , PO_RECEIPT_VALUE
        , MOVEMENT_TYPE
        , DEBIT_CREDIT_IND
        , LOCAL_CURRENCY
        , PO_HEADER_HK
        , LNK_PO_RECEIPT_HK
        , PO_ITEM_RECEIPT_DK
        , ITEM_HK
        , SUPPLIER_HK
        , PLANT_HK
        , LEGAL_ENTITY_HK
        , BKCC
        , REC_SRC
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

{{
  config(
    materialized = 'incremental',
    unique_key='CONTROLLING_LEDGER_ENTRY_HK',
    incremental_strategy= 'merge'
  )
}}
---- SRC LAYER ----
WITH
SRC_LCLE           as ( SELECT CONTROLLING_LEDGER_ENTRY_HK, COST_OBJECT_LINE_ITEMS_HK, CONTROLLING_AREA_HK, CONTROLLING_LEDGER_HEADER_HK, POSTING_ROW_HK, COST_ELEMENT_HK, LEDGER_HK, LOAD_DTS, REC_SRC FROM {{ ref('lnk_controlling_ledger_entry') }} as SRC  ),
SRC_HCLH           as ( SELECT CONTROLLING_LEDGER_HEADER_HK, REC_SRC FROM {{ ref('hub_controlling_ledger_header') }} as SRC  ),
SRC_HL             as ( SELECT LEDGER_HK, REC_SRC FROM {{ ref('hub_ledger') }} as SRC  ),
SRC_HC             as ( SELECT CONTROLLING_AREA_HK, REC_SRC FROM {{ ref('hub_controlling_area') }} as SRC  ),
SRC_HCE            as ( SELECT COST_ELEMENT_HK, REC_SRC FROM {{ ref('hub_cost_element') }} as SRC  ),
SRC_SCLE           as ( SELECT CONTROLLING_LEDGER_ENTRY_HK, MANDT, KOKRS, BELNR, BUZEI, PERIO, WTGBTR, WOGBTR, WKGBTR, WKFBTR, PAGBTR, PAFBTR, MEGBTR, MEFBTR, MBGBTR, MBFBTR, LEDNR, OBJNR, GJAHR, WRTTP, VERSN, KSTAR, HRKFT, VRGNG, PAROB, PAROB1, USPOB, VBUND, PARGB, BEKNZ, TWAER, OWAER, MEINH, MEINB, MVFLG, SGTXT, REFBZ, ZLENR, BW_REFBZ, GKONT, GKOAR, WERKS, MATNR, RBEST, EBELN, EBELP, ZEKKN, PERNR, BTRKL, OBJNR_N1, OBJNR_N2, PAOBJNR, BELTP, BUKRS, GSBER, FKBER, SCOPE, PBUKRS, PFKBER, PSCOPE, DABRZ, BWSTRAT, TIMESTMP, REFBZ_FI, PRODPER, PSA_DELETE_IND, BKCC, REC_SRC FROM {{ ref('lsat_controlling_ledger_entry__winn_sap') }} as SRC 
                        qualify 1= row_number() over (partition by CONTROLLING_LEDGER_ENTRY_HK order by LOAD_DTS DESC))


/*
SRC_LCLE           as ( SELECT * FROM RAW_VAULT.lnk_controlling_ledger_entry )
SRC_HCLH           as ( SELECT * FROM RAW_VAULT.hub_controlling_ledger_header )
SRC_HL             as ( SELECT * FROM RAW_VAULT.hub_ledger )
SRC_HCE            as ( SELECT * FROM RAW_VAULT.hub_cost_element )
SRC_HCA            as ( SELECT * FROM RAW_VAULT.hub_controlling_area )
SRC_SCLE           as ( SELECT * FROM RAW_VAULT.sat_controlling_ledger_entry__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_LCLE as (
    SELECT
        CONTROLLING_LEDGER_ENTRY_HK
      , COST_OBJECT_LINE_ITEMS_HK
      , CONTROLLING_AREA_HK
      , CONTROLLING_LEDGER_HEADER_HK
      , POSTING_ROW_HK
      , COST_ELEMENT_HK
      , LEDGER_HK
      , LOAD_DTS
      , REC_SRC                      
    FROM SRC_LCLE
)

, LOGIC_HCLH as (
    SELECT
        CONTROLLING_LEDGER_HEADER_HK
      , REC_SRC
    FROM SRC_HCLH
)

, LOGIC_HL as (
    SELECT
        LEDGER_HK
      , REC_SRC
    FROM SRC_HL
)

, LOGIC_HC as (
    SELECT
        CONTROLLING_AREA_HK
      , REC_SRC                                                      
    FROM SRC_HC
)

, LOGIC_HCE as (
    SELECT
        COST_ELEMENT_HK
      , REC_SRC
    FROM SRC_HCE
)
, LOGIC_SCLE as (
    SELECT
        CONTROLLING_LEDGER_ENTRY_HK
      , MANDT
      , KOKRS
      , BELNR
      , BUZEI
      , PERIO
      , WTGBTR
      , WOGBTR
      , WKGBTR
      , WKFBTR
      , PAGBTR
      , PAFBTR
      , MEGBTR
      , MEFBTR
      , MBGBTR
      , MBFBTR
      , LEDNR
      , OBJNR
      , CAST(GJAHR AS INTEGER)                                       as                                              GJAHR
      , WRTTP
      , VERSN
      , KSTAR
      , HRKFT
      , VRGNG
      , PAROB
      , PAROB1
      , USPOB
      , VBUND
      , PARGB
      , BEKNZ
      , TWAER
      , OWAER
      , MEINH
      , MEINB
      , MVFLG
      , SGTXT
      , REFBZ
      , ZLENR
      , BW_REFBZ
      , GKONT
      , GKOAR
      , WERKS
      , MATNR
      , RBEST
      , EBELN
      , EBELP
      , ZEKKN
      , PERNR
      , BTRKL
      , OBJNR_N1
      , OBJNR_N2
      , PAOBJNR
      , BELTP
      , BUKRS
      , GSBER
      , FKBER
      , SCOPE
      , PBUKRS
      , PFKBER
      , PSCOPE
      , TRY_CAST(DABRZ AS INTEGER)                                   as                                              DABRZ
      , BWSTRAT
      , TIMESTMP
      , REFBZ_FI
      , PRODPER
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC
    FROM SRC_SCLE
)
---- RENAME LAYER ----
, RENAME_LCLE as (
    SELECT
        CONTROLLING_LEDGER_ENTRY_HK
      , COST_OBJECT_LINE_ITEMS_HK
      , CONTROLLING_AREA_HK
      , CONTROLLING_LEDGER_HEADER_HK
      , POSTING_ROW_HK
      , COST_ELEMENT_HK
      , LEDGER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_LCLE
)

, RENAME_HCLH as (
    SELECT
       CONTROLLING_LEDGER_HEADER_HK                   as        HUB_CONTROLLING_LEDGER_HEADER_HK
    , REC_SRC                                      as        HCLH_REC_SRC
    FROM LOGIC_HCLH
)

, RENAME_HL as (
    SELECT
        LEDGER_HK                                     as  HUB_LEDGER_HK
      , REC_SRC                                       as  HL_REC_SRC
    FROM LOGIC_HL
)

, RENAME_HC as (
    SELECT
        CONTROLLING_AREA_HK                             as HUB_CONTROLLING_AREA_HK
      , REC_SRC                                         as HC_REC_SRC
    FROM LOGIC_HC
)

, RENAME_HCE as (
    SELECT
       COST_ELEMENT_HK                                  as  HUB_COST_ELEMENT_HK
      , REC_SRC                                         as  HCE_REC_SRC
    FROM LOGIC_HCE
)
, RENAME_SCLE as (
    SELECT
        CONTROLLING_LEDGER_ENTRY_HK                                    AS          SAT_CONTROLLING_LEDGER_ENTRY_HK
      , MANDT                                                          AS          CLIENT
      , KOKRS                                                          AS          CONTROLLING_AREA
      , BELNR                                                          AS          DOCUMENT_NUMBER
      , BUZEI                                                          AS          POSTING_ROW
      , PERIO                                                          AS          PERIOD
      , WTGBTR                                                         AS          TOTAL_VALUE_TRANSACTION_CURRENCY
      , WOGBTR                                                         AS          TOTAL_VALUE_OBJECT_CURRENCY
      , WKGBTR                                                         AS          TOTAL_VALUE_CO_AREA_CURRENCY
      , WKFBTR                                                         AS          FIXED_VALUE_CO_AREA_CURRENCY
      , PAGBTR                                                         AS          TOTAL_PRICE_VARIANCE_CO_AREA_CURRENCY
      , PAFBTR                                                         AS          FIXED_PRICE_VARIANCE_CO_AREA_CURRENCY
      , MEGBTR                                                         AS          TOTAL_QUANTITY
      , MEFBTR                                                         AS          FIXED_QUANTITY
      , MBGBTR                                                         AS          TOTAL_QUANTITY_ENTERED
      , MBFBTR                                                         AS          FIXED_QUANTITY_ENTERED
      , LEDNR                                                          AS          LEDGER
      , OBJNR                                                          AS          OBJECT_NUMBER
      , CAST(GJAHR AS INTEGER)                                         AS          FISCAL_YEAR__YYYY
      , WRTTP                                                          AS          VALUE_TYPE
      , VERSN                                                          AS          VERSION
      , KSTAR                                                          AS          COST_ELEMENT
      , HRKFT                                                          AS          ORIGIN
      , VRGNG                                                          AS          TRANSACTION
      , PAROB                                                          AS          PARTNER_OBJECT
      , PAROB1                                                         AS          PARTNER_OBJECT_ALWAYS_FILLED
      , USPOB                                                          AS          SOURCE_OBJECT_COST_CENTER_ACTIVITY_TYPE
      , VBUND                                                          AS          TRADING_PARTNER_COMPANY_ID
      , PARGB                                                          AS          TRADING_PARTNER_BUSINESS_AREA
      , BEKNZ                                                          AS          DEBIT_CREDIT_INDICATOR
      , TWAER                                                          AS          TRANSACTION_CURRENCY
      , OWAER                                                          AS          OBJECT_CURRENCY
      , MEINH                                                          AS          BASE_UNIT_OF_MEASURE
      , MEINB                                                          AS          UNIT_OF_MEASURE
      , MVFLG                                                          AS          SETTLEMENT_RULE_INDICATOR
      , SGTXT                                                          AS          ITEM_TEXT
      , REFBZ                                                          AS          REFERENCE_DOCUMENT_POSTING_ROW
      , ZLENR                                                          AS          DOCUMENT_ITEM_NUMBER
      , BW_REFBZ                                                       AS          OPERATIVE_VERSION_POSTING_ROW
      , GKONT                                                          AS          OFFSETTING_ACCOUNT_NUMBER
      , GKOAR                                                          AS          OFFSETTING_ACCOUNT_TYPE
      , WERKS                                                          AS          PLANT
      , MATNR                                                          AS          MATERIAL_NUMBER
      , RBEST                                                          AS          REFERENCE_PURCHASE_ORDER_CATEGORY
      , EBELN                                                          AS          PURCHASING_DOCUMENT_NUMBER
      , EBELP                                                          AS          PURCHASING_DOCUMENT_ITEM_NUMBER
      , ZEKKN                                                          AS          ACCOUNT_ASSIGNMENT_SEQUENTIAL_NUMBER
      , PERNR                                                          AS          PERSONNEL_NUMBER
      , BTRKL                                                          AS          CO_AREA_CURRENCY_AMOUNT_CLASS
      , OBJNR_N1                                                       AS          AUXILIARY_ACCOUNT_ASSIGNMENT_1
      , OBJNR_N2                                                       AS          AUXILIARY_ACCOUNT_ASSIGNMENT_2
      , PAOBJNR                                                        AS          PROFITABILITY_SEGMENT_NUMBER
      , BELTP                                                          AS          DEBIT_TYPE
      , BUKRS                                                          AS          COMPANY_CODE
      , GSBER                                                          AS          BUSINESS_AREA
      , FKBER                                                          AS          FUNCTIONAL_AREA
      , SCOPE                                                          AS          SEGMENT
      , PBUKRS                                                         AS          PARTNER_COMPANY_CODE
      , PFKBER                                                         AS          PARTNER_FUNCTIONAL_AREA
      , PSCOPE                                                         AS          PARTNER_SEGMENT
      , TRY_CAST(DABRZ AS INTEGER)                                     AS          SETTLEMENT_DATE__YYYYMMDD
      , BWSTRAT                                                        AS          ALLOCATION_PRICE_STRATEGY
      , TIMESTMP                                                       AS          TIME_CREATED_GMT
      , REFBZ_FI                                                       AS          FI_REFERENCE_DOCUMENT_POSTING_ITEM
      , PRODPER                                                        AS          JVA_PRODUCTION_MONTH
      , PSA_DELETE_IND
      , BKCC
      , REC_SRC                                                        AS         SAT_REC_SRC
    FROM LOGIC_SCLE
)
---- FILTER LAYER ----

, FILTER_LCLE as 
(
    SELECT *
    FROM RENAME_LCLE
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'        /* This filter is to exclude the ghost records */
)

, FILTER_HCLH as 
(
    SELECT *
    FROM RENAME_HCLH
    WHERE HCLH_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_HL as 
(
    SELECT *
    FROM RENAME_HL
    WHERE HL_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_HC as 
(
    SELECT *
    FROM RENAME_HC
    WHERE HC_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_HCE as 
(
    SELECT *
    FROM RENAME_HCE
    WHERE HCE_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_SCLE as 
(
    SELECT *
    FROM RENAME_SCLE
    WHERE SAT_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LCLE
    LEFT JOIN FILTER_HCLH
        ON FILTER_LCLE.CONTROLLING_LEDGER_HEADER_HK = FILTER_HCLH.HUB_CONTROLLING_LEDGER_HEADER_HK
    LEFT JOIN FILTER_HL
        ON FILTER_LCLE.LEDGER_HK = FILTER_HL.HUB_LEDGER_HK
    LEFT JOIN FILTER_HC
        ON FILTER_LCLE.CONTROLLING_AREA_HK = FILTER_HC.HUB_CONTROLLING_AREA_HK
    LEFT JOIN FILTER_HCE
        ON FILTER_LCLE.COST_ELEMENT_HK = FILTER_HCE.HUB_COST_ELEMENT_HK
    LEFT JOIN FILTER_SCLE
        ON FILTER_LCLE.CONTROLLING_LEDGER_ENTRY_HK = FILTER_SCLE.SAT_CONTROLLING_LEDGER_ENTRY_HK
)

---- FINAL LAYER ----
SELECT
          'PB_CONTROLLING_LEDGER_ENTRY'                                as PB_REC_SRC
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , CONTROLLING_LEDGER_ENTRY_HK
        , COST_OBJECT_LINE_ITEMS_HK
        , CONTROLLING_AREA_HK
        , CONTROLLING_LEDGER_HEADER_HK
        , POSTING_ROW_HK
        , COST_ELEMENT_HK
        , LEDGER_HK
        , LOAD_DTS
        , REC_SRC
        , CLIENT
        , CONTROLLING_AREA
        , DOCUMENT_NUMBER
        , POSTING_ROW
        , PERIOD
        , TOTAL_VALUE_TRANSACTION_CURRENCY
        , TOTAL_VALUE_OBJECT_CURRENCY
        , TOTAL_VALUE_CO_AREA_CURRENCY
        , FIXED_VALUE_CO_AREA_CURRENCY
        , TOTAL_PRICE_VARIANCE_CO_AREA_CURRENCY
        , FIXED_PRICE_VARIANCE_CO_AREA_CURRENCY
        , TOTAL_QUANTITY
        , FIXED_QUANTITY
        , TOTAL_QUANTITY_ENTERED
        , FIXED_QUANTITY_ENTERED
        , LEDGER
        , OBJECT_NUMBER
        , FISCAL_YEAR__YYYY
        , VALUE_TYPE
        , VERSION
        , COST_ELEMENT
        , ORIGIN
        , TRANSACTION
        , PARTNER_OBJECT
        , PARTNER_OBJECT_ALWAYS_FILLED
        , SOURCE_OBJECT_COST_CENTER_ACTIVITY_TYPE
        , TRADING_PARTNER_COMPANY_ID
        , TRADING_PARTNER_BUSINESS_AREA
        , DEBIT_CREDIT_INDICATOR
        , TRANSACTION_CURRENCY
        , OBJECT_CURRENCY
        , BASE_UNIT_OF_MEASURE
        , UNIT_OF_MEASURE
        , SETTLEMENT_RULE_INDICATOR
        , ITEM_TEXT
        , REFERENCE_DOCUMENT_POSTING_ROW
        , DOCUMENT_ITEM_NUMBER
        , OPERATIVE_VERSION_POSTING_ROW
        , OFFSETTING_ACCOUNT_NUMBER
        , OFFSETTING_ACCOUNT_TYPE
        , PLANT
        , MATERIAL_NUMBER
        , REFERENCE_PURCHASE_ORDER_CATEGORY
        , PURCHASING_DOCUMENT_NUMBER
        , PURCHASING_DOCUMENT_ITEM_NUMBER
        , ACCOUNT_ASSIGNMENT_SEQUENTIAL_NUMBER
        , PERSONNEL_NUMBER
        , CO_AREA_CURRENCY_AMOUNT_CLASS
        , AUXILIARY_ACCOUNT_ASSIGNMENT_1
        , AUXILIARY_ACCOUNT_ASSIGNMENT_2
        , PROFITABILITY_SEGMENT_NUMBER
        , DEBIT_TYPE
        , COMPANY_CODE
        , BUSINESS_AREA
        , FUNCTIONAL_AREA
        , SEGMENT
        , PARTNER_COMPANY_CODE
        , PARTNER_FUNCTIONAL_AREA
        , PARTNER_SEGMENT
        , SETTLEMENT_DATE__YYYYMMDD
        , ALLOCATION_PRICE_STRATEGY
        , TIME_CREATED_GMT
        , FI_REFERENCE_DOCUMENT_POSTING_ITEM
        , JVA_PRODUCTION_MONTH
        , BKCC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND
          END as IS_DELETED
FROM JOIN_RESULT

{% if is_incremental() %}
    WHERE CONTROLLING_LEDGER_ENTRY_HK NOT IN (
        SELECT CONTROLLING_LEDGER_ENTRY_HK 
        FROM {{ this }}
    )
    AND TO_DATE(FISCAL_YEAR__YYYY || LPAD(PERIOD::INTEGER, 2, '0') || '01', 'YYYYMMDD') 
        >= DATE_TRUNC('day', CURRENT_DATE() - 60)
{% endif %}
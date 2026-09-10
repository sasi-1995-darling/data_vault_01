---- SRC LAYER ----
WITH
SRC_FGSS           as ( SELECT BKCC, BUSINESS_UNIT, CAL_MONTH, CAL_YEAR, CATEGORY_CD, CATEGORY_DESC, CATEGORY_LEADER_NAME, COUNTRY_OF_ORIGIN, DIRECTOR_NAME, DOCUMENT_TYPE, FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III, ITEM_BK, ITEM_HK, OPCO, OPCO_ITEM, PAYMENT_TERMS, PLANT_BK, PLANT_HK, POSTING_DATE_KEY, RECEIPT_QTY, RECEIPT_SPEND, REC_SRC, SPEND_USD, SUPPLIER_NAME_CHILD, SUPPLIER_NAME_PARENT, SUPPLIER_NUMBER_CHILD, SUPPLIER_NUMBER_PARENT, UOM FROM {{ ref('fact_global_direct_spend_daily_summary') }} as SRC  ),
SRC_DITM           as ( SELECT ITEM_ID, ITEM_TITLE FROM {{ ref('dim_item_fbin') }} as SRC 
                        qualify ROW_NUMBER() over ( partition by ITEM_ID order by ITEM_TITLE desc ) = 1 ),
SRC_DFY            as ( SELECT DATE_BK, FISCAL_445_CAL_MONTH, FISCAL_445_CAL_YEAR FROM {{ ref('dim_date_fiscal_445') }} as SRC  )

/*
SRC_FGSS           as ( SELECT * FROM BUS_VAULT.FACT_GLOBAL_DIRECT_SPEND_DAILY_SUMMARY )
SRC_DITM           as ( SELECT * FROM BUS_VAULT.DIM_ITEM_FBIN )
SRC_DFY            as ( SELECT * FROM BUS_VAULT.DIM_DATE_FISCAL_445 )
*/
---- LOGIC LAYER ----

, LOGIC_FGSS as (
    SELECT
        SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , ITEM_BK                                                      as                                               ITEM
      , COUNTRY_OF_ORIGIN
      , CAL_YEAR
      , CAL_MONTH
      , BUSINESS_UNIT
      , OPCO
      , PLANT_BK                                                     as                                              PLANT
      , OPCO_ITEM
      , POSTING_DATE_KEY
      , RECEIPT_SPEND
      , SPEND_USD
      , RECEIPT_QTY                                                  as                                             VOLUME
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , UOM
      , CATEGORY_CD
      , CATEGORY_DESC
      , ITEM_HK
      , PLANT_HK
      , BKCC
      , REC_SRC
    FROM SRC_FGSS
)

, LOGIC_DITM as (
    SELECT
        ITEM_TITLE                                                   as                                   ITEM_DESCRIPTION
      , ITEM_ID
    FROM SRC_DITM
)

, LOGIC_DFY as (
    SELECT
        DATE_BK
      , FISCAL_445_CAL_YEAR
      , FISCAL_445_CAL_MONTH
    FROM SRC_DFY
)
---- RENAME LAYER ----

, RENAME_FGSS as (
    SELECT
        SUPPLIER_NUMBER_PARENT
      , SUPPLIER_NAME_PARENT
      , SUPPLIER_NUMBER_CHILD
      , SUPPLIER_NAME_CHILD
      , PAYMENT_TERMS
      , DOCUMENT_TYPE
      , ITEM
      , COUNTRY_OF_ORIGIN
      , CAL_YEAR
      , CAL_MONTH
      , BUSINESS_UNIT
      , OPCO
      , PLANT
      , OPCO_ITEM
      , POSTING_DATE_KEY
      , RECEIPT_SPEND
      , SPEND_USD
      , VOLUME
      , DIRECTOR_NAME
      , CATEGORY_LEADER_NAME
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , UOM
      , CATEGORY_CD
      , CATEGORY_DESC
      , ITEM_HK
      , PLANT_HK
      , BKCC
      , REC_SRC
    FROM LOGIC_FGSS
)

, RENAME_DITM as (
    SELECT
        ITEM_DESCRIPTION
      , ITEM_ID
    FROM LOGIC_DITM
)

, RENAME_DFY as (
    SELECT
        DATE_BK
      , FISCAL_445_CAL_YEAR
      , FISCAL_445_CAL_MONTH
    FROM LOGIC_DFY
)
---- FILTER LAYER ----

, FILTER_FGSS as (
    SELECT *
    FROM RENAME_FGSS
)

, FILTER_DITM as (
    SELECT *
    FROM RENAME_DITM
)

, FILTER_DFY as (
    SELECT *
    FROM RENAME_DFY
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_FGSS
    LEFT JOIN FILTER_DITM
        ON FILTER_FGSS.ITEM_HK = FILTER_DITM.ITEM_ID
    LEFT JOIN FILTER_DFY
        ON FILTER_FGSS.POSTING_DATE_KEY = FILTER_DFY.DATE_BK
)

---- FINAL LAYER ----
SELECT
          SUPPLIER_NUMBER_PARENT
        , SUPPLIER_NAME_PARENT
        , SUPPLIER_NUMBER_CHILD
        , SUPPLIER_NAME_CHILD
        , PAYMENT_TERMS
        , DOCUMENT_TYPE
        , ITEM
        , ITEM_DESCRIPTION
        , COUNTRY_OF_ORIGIN
        , CAL_YEAR
        , CAL_MONTH
        , BUSINESS_UNIT
        , OPCO
        , PLANT
        , OPCO_ITEM
        , POSTING_DATE_KEY
        , CONCAT(CAL_YEAR, '|', CAL_MONTH )                            as YEAR_MONTH
        , RECEIPT_SPEND
        , SPEND_USD
        , VOLUME
        , DIRECTOR_NAME
        , CATEGORY_LEADER_NAME
        , FBIN_CATEGORY_I
        , FBIN_CATEGORY_II
        , FBIN_CATEGORY_III
        , UOM
        , CATEGORY_CD
        , CATEGORY_DESC
        , ITEM_HK
        , PLANT_HK
        , FISCAL_445_CAL_YEAR
        , FISCAL_445_CAL_MONTH
        , CONCAT(FISCAL_445_CAL_YEAR, '|', FISCAL_445_CAL_MONTH)       as FISCAL_445_YEAR_MONTH
        , BKCC
        , REC_SRC
FROM JOIN_RESULT

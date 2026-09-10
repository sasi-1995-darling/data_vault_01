---- SRC LAYER ----
WITH
SRC_P              as ( SELECT * FROM {{ ref('pb_cost_activity_type_total_current') }} as SRC  )

/*
SRC_P              as ( SELECT * FROM RAW_VAULT.PIT_COST_ACTIVITY_TYPE_TOTAL_CURRENT )
*/
---- LOGIC LAYER ----

, LOGIC_P as (
    SELECT
        COST_ACTIVITY_TYPE_TOTALS_HK                               
      , LEDGER_FOR_CONTROLLING_OBJECTS
      , OBJECT_NUM
      , FISCAL_YEAR__YYYY
      , VALUE_TYPE
      , VERSION
      , CO_BUSINESS_TRANSACTION
      , PERIOD_BLOCK
      , ACTIVITY_QTY_1
      , ACTIVITY_QTY_2
      , CAPACITY_1
      , CAPACITY_2
      , OUTPUT_1
      , OUTPUT_2
      , SCHEDULED_ACTIVITY_1
      , SCHEDULED_ACTIVITY_2
      , EQUIVALENCE_NUM_1
      , EQUIVALENCE_NUM_2
      , IS_DELETED
      , REC_SRC
      , BKCC
    FROM SRC_P
)
---- RENAME LAYER ----

, RENAME_P as (
    SELECT
        COST_ACTIVITY_TYPE_TOTALS_HK
      , LEDGER_FOR_CONTROLLING_OBJECTS
      , OBJECT_NUM
      , FISCAL_YEAR__YYYY
      , VALUE_TYPE
      , VERSION
      , CO_BUSINESS_TRANSACTION
      , PERIOD_BLOCK
      , ACTIVITY_QTY_1
      , ACTIVITY_QTY_2
      , CAPACITY_1
      , CAPACITY_2
      , OUTPUT_1
      , OUTPUT_2
      , SCHEDULED_ACTIVITY_1
      , SCHEDULED_ACTIVITY_2
      , EQUIVALENCE_NUM_1
      , EQUIVALENCE_NUM_2
      , IS_DELETED
      , REC_SRC
      , BKCC
    FROM LOGIC_P
)
---- FILTER LAYER ----

, FILTER_P as (
    SELECT *
    FROM RENAME_P
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_P
)

---- FINAL LAYER ----
SELECT
          COST_ACTIVITY_TYPE_TOTALS_HK
        , LEDGER_FOR_CONTROLLING_OBJECTS
        , OBJECT_NUM
        , FISCAL_YEAR__YYYY
        , VALUE_TYPE
        , VERSION
        , CO_BUSINESS_TRANSACTION
        , PERIOD_BLOCK
        , ACTIVITY_QTY_1
        , ACTIVITY_QTY_2
        , CAPACITY_1
        , CAPACITY_2
        , OUTPUT_1
        , OUTPUT_2
        , SCHEDULED_ACTIVITY_1
        , SCHEDULED_ACTIVITY_2
        , EQUIVALENCE_NUM_1
        , EQUIVALENCE_NUM_2
        , IS_DELETED
        , REC_SRC
        , BKCC
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_LCAT           as ( SELECT * FROM {{ ref('lnk_cost_activity_type_total') }} as SRC  ),
SRC_HCO            as ( SELECT * FROM {{ ref('hub_cost_object') }} as SRC  ),
SRC_HAFP           as ( SELECT * FROM {{ ref('hub_fiscal_period') }} as SRC  ),
SRC_HCVT           as ( SELECT * FROM {{ ref('hub_cost_value_type') }} as SRC  ),
SRC_HCV            as ( SELECT * FROM {{ ref('hub_cost_version') }} as SRC  ),
SRC_HL             as ( SELECT * FROM {{ ref('hub_ledger') }} as SRC  ),
SRC_HCBTT          as ( SELECT * FROM {{ ref('hub_cost_transaction_type') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_cost_activity_type_total__winn_sap') }} as SRC  
    qualify 1= row_number() over (partition by COST_ACTIVITY_TYPE_TOTALS_HK order by LOAD_DTS DESC))

/*
SRC_LCAT           as ( SELECT * FROM RAW_VAULT.lnk_cost_activity_totals )
, SRC_HCO            as ( SELECT * FROM RAW_VAULT.hub_cost_object )
, SRC_HAFP           as ( SELECT * FROM RAW_VAULT.hub_accounting_fiscal_period )
, SRC_HCVT           as ( SELECT * FROM RAW_VAULT.hub_cost_value_type )
, SRC_HCV            as ( SELECT * FROM RAW_VAULT.hub_cost_version )
, SRC_HL             as ( SELECT * FROM RAW_VAULT.hub_ledger )
, SRC_HCBTT          as ( SELECT * FROM RAW_VAULT.hub_cost_business_transaction_type )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.sat_cost_activity_totals__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_LCAT as (
    SELECT
        COST_ACTIVITY_TYPE_TOTALS_HK
      , OBJECT_NUMBER_HK
      , FISCAL_PERIOD_HK
      , COST_VALUE_TYPE_HK
      , COST_VERSION_HK
      , LEDGER_HK
      , COST_TRANSACTION_TYPE_HK
      , PERIOD_BLOCK_HK
      , REC_SRC
      , BKCC
    FROM SRC_LCAT
)

, LOGIC_HCO as (
    SELECT
        OBJECT_NUMBER_HK                                               as                                 HUB_OBJECT_NUMBER_HK
      , OBJECT_NUMBER_BK
    FROM SRC_HCO
)

, LOGIC_HAFP as (
    SELECT
        FISCAL_PERIOD_HK                                  as                    HUB_FISCAL_PERIOD_HK
      , FISCAL_YEAR_BK
      , PERIOD_BLOCK_BK
    FROM SRC_HAFP
)

, LOGIC_HCVT as (
    SELECT
        COST_VALUE_TYPE_HK                                           as                             HUB_COST_VALUE_TYPE_HK
      , COST_VALUE_TYPE_BK
    FROM SRC_HCVT
)

, LOGIC_HCV as (
    SELECT
        COST_VERSION_HK                                              as                                HUB_COST_VERSION_HK
      , COST_VERSION_BK
    FROM SRC_HCV
)

, LOGIC_HL as (
    SELECT
        LEDGER_HK                                                    as                                      HUB_LEDGER_HK
      , LEDGER_BK
    FROM SRC_HL
)

, LOGIC_HCBTT as (
    SELECT
        COST_TRANSACTION_TYPE_HK                                     as                       HUB_COST_TRANSACTION_TYPE_HK
      , COST_TRANSACTION_TYPE_BK
    FROM SRC_HCBTT
)

, LOGIC_SAT_WINN as (
    SELECT
        COST_ACTIVITY_TYPE_TOTALS_HK                                 as              SAT_WINN_COST_ACTIVITY_TYPE_TOTALS_HK
      , LEDNR                                                        as                     LEDGER_FOR_CONTROLLING_OBJECTS
      , OBJNR                                                        as                                         OBJECT_NUM
      , CAST(GJAHR AS NUMBER)                                        as                                  FISCAL_YEAR__YYYY
      , WRTTP                                                        as                                         VALUE_TYPE
      , VERSN                                                        as                                            VERSION
      , VRGNG                                                        as                            CO_BUSINESS_TRANSACTION
      , PERBL                                                        as                                       PERIOD_BLOCK
      , LST001                                                       as                                     ACTIVITY_QTY_1
      , LST002                                                       as                                     ACTIVITY_QTY_2
      , KAP001                                                       as                                         CAPACITY_1
      , KAP002                                                       as                                         CAPACITY_2
      , AUS001                                                       as                                           OUTPUT_1
      , AUS002                                                       as                                           OUTPUT_2
      , DIS001                                                       as                               SCHEDULED_ACTIVITY_1
      , DIS002                                                       as                               SCHEDULED_ACTIVITY_2
      , AEQ001                                                       as                                  EQUIVALENCE_NUM_1
      , AEQ002                                                       as                                  EQUIVALENCE_NUM_2
      , PSA_DELETE_IND
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_LCAT as (
    SELECT
        COST_ACTIVITY_TYPE_TOTALS_HK
      , OBJECT_NUMBER_HK
      , FISCAL_PERIOD_HK
      , COST_VALUE_TYPE_HK
      , COST_VERSION_HK
      , LEDGER_HK
      , COST_TRANSACTION_TYPE_HK
      , PERIOD_BLOCK_HK
      , BKCC
      , REC_SRC
    FROM LOGIC_LCAT
)

, RENAME_HCO as (
    SELECT
        HUB_OBJECT_NUMBER_HK
      , OBJECT_NUMBER_BK
    FROM LOGIC_HCO
)

, RENAME_HAFP as (
    SELECT
        HUB_FISCAL_PERIOD_HK
       , FISCAL_YEAR_BK
      , PERIOD_BLOCK_BK
    FROM LOGIC_HAFP
)

, RENAME_HCVT as (
    SELECT
        HUB_COST_VALUE_TYPE_HK
      , COST_VALUE_TYPE_BK
    FROM LOGIC_HCVT
)

, RENAME_HCV as (
    SELECT
        HUB_COST_VERSION_HK
      , COST_VERSION_BK
    FROM LOGIC_HCV
)

, RENAME_HL as (
    SELECT
        HUB_LEDGER_HK
      , LEDGER_BK
    FROM LOGIC_HL
)

, RENAME_HCBTT as (
    SELECT
        HUB_COST_TRANSACTION_TYPE_HK
      , COST_TRANSACTION_TYPE_BK
    FROM LOGIC_HCBTT
)

, RENAME_SAT_WINN as (
    SELECT
        SAT_WINN_COST_ACTIVITY_TYPE_TOTALS_HK
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
      , PSA_DELETE_IND
    FROM LOGIC_SAT_WINN
)
---- FILTER LAYER ----

, FILTER_LCAT as (
    SELECT *
    FROM RENAME_LCAT
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_HCO as (
    SELECT *
    FROM RENAME_HCO
)

, FILTER_HAFP as (
    SELECT *
    FROM RENAME_HAFP
)

, FILTER_HCVT as (
    SELECT *
    FROM RENAME_HCVT
)

, FILTER_HCV as (
    SELECT *
    FROM RENAME_HCV
)

, FILTER_HL as (
    SELECT *
    FROM RENAME_HL
)

, FILTER_HCBTT as (
    SELECT *
    FROM RENAME_HCBTT
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LCAT
    LEFT JOIN FILTER_HCO
        ON FILTER_LCAT.OBJECT_NUMBER_HK = FILTER_HCO.HUB_OBJECT_NUMBER_HK
    LEFT JOIN FILTER_HAFP
        ON FILTER_LCAT.FISCAL_PERIOD_HK = FILTER_HAFP.HUB_FISCAL_PERIOD_HK
    LEFT JOIN FILTER_HCVT
        ON FILTER_LCAT.COST_VALUE_TYPE_HK = FILTER_HCVT.HUB_COST_VALUE_TYPE_HK
    LEFT JOIN FILTER_HCV
        ON FILTER_LCAT.COST_VERSION_HK = FILTER_HCV.HUB_COST_VERSION_HK
    LEFT JOIN FILTER_HL
        ON FILTER_LCAT.LEDGER_HK = FILTER_HL.HUB_LEDGER_HK
    LEFT JOIN FILTER_HCBTT
        ON FILTER_LCAT.COST_TRANSACTION_TYPE_HK = FILTER_HCBTT.HUB_COST_TRANSACTION_TYPE_HK
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_LCAT.COST_ACTIVITY_TYPE_TOTALS_HK = SAT_WINN_COST_ACTIVITY_TYPE_TOTALS_HK
)

---- FINAL LAYER ----
SELECT
          'PIT_COST_ACTIVITY_TYPE_TOTAL_TABLES'                        as PIT_REC_SRC
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PIT_LOAD_DTS
        , COST_ACTIVITY_TYPE_TOTALS_HK
        , OBJECT_NUMBER_HK
        , FISCAL_PERIOD_HK
        , COST_VALUE_TYPE_HK
        , COST_VERSION_HK
        , LEDGER_HK
        , COST_TRANSACTION_TYPE_HK
        , PERIOD_BLOCK_HK
        , REC_SRC
        , BKCC
        , HUB_OBJECT_NUMBER_HK
        , OBJECT_NUMBER_BK
        , HUB_FISCAL_PERIOD_HK
        , FISCAL_YEAR_BK
        , PERIOD_BLOCK_BK
        , HUB_COST_VALUE_TYPE_HK
        , COST_VALUE_TYPE_BK
        , HUB_COST_VERSION_HK
        , COST_VERSION_BK
        , HUB_LEDGER_HK
        , LEDGER_BK
        , HUB_COST_TRANSACTION_TYPE_HK
        , COST_TRANSACTION_TYPE_BK
        , SAT_WINN_COST_ACTIVITY_TYPE_TOTALS_HK
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
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED
FROM JOIN_RESULT

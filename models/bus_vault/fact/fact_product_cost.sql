---- SRC LAYER ----
WITH
SRC_COPA               as ( SELECT LNK_COPA_SALES_HK, REC_SRC, BKCC, POSTING_DATE__YYYYMMDD, VVQTY, VVCST, VVMKV, VVFRC, VVGRS, VVLTS, VVVPO, VVMKF, VVSEF, VVAFC, VVPRV, VVPRD, VVPRT, VVPRO, VVPRP 
                            FROM {{ ref('pb_copa') }} as SRC 
                            WHERE PALEDGER = '01' AND RECORD_TYPE IN ('F', 'C') )

/*
SRC_COPA            as ( SELECT * FROM RAW_VAULT.LSAT_COPA_SALES__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_COPA as (
    SELECT
        LNK_COPA_SALES_HK
      , REC_SRC
      , BKCC
      , POSTING_DATE__YYYYMMDD
        -- Actuals Quantities
      , SUM(VVQTY)                                                            as                                       ACTUAL_QUANTITY
      , SUM(VVQTY)                                                            as                                        SALES_QUANTITY

        -- Standard Cost
      , SUM(VVCST)                                                            as                                         STANDARD_COST
      , SUM(VVCST)                                                            as                                          CURRENT_COST
      , SUM(VVFRC)                                                            as                                          FREIGHT_COST

        -- Cost Component
      , SUM(VVGRS)                                                            as                                         MATERIAL_COST
      , SUM(VVLTS)                                                            as                                            LABOR_COST
      , SUM(VVVPO)                                                            as                          VARIABLE_PRODUCTION_OVERHEAD
      , SUM(VVMKF)                                                            as                          FIXED_MANUFACTURING_OVERHEAD

        -- Cost Amount
      , SUM(VVMKV)                                                            as                                  VARIABLE_COST_AMOUNT
      , SUM(COALESCE(VVMKF, 0) + COALESCE(VVSEF, 0) + COALESCE(VVAFC, 0))     as                                     FIXED_COST_AMOUNT
      , SUM(COALESCE(VVMKV, 0) + COALESCE(VVMKF, 0) + COALESCE(VVSEF, 0) + COALESCE(VVAFC, 0)) as                    TOTAL_COST_AMOUNT

        -- Per Unit Calculations
      , ROUND(SUM(VVCST) / NULLIF(SUM(VVQTY), 0), 4)                          as                                STANDARD_COST_PER_UNIT
      , ROUND(SUM(VVMKV) / NULLIF(SUM(VVQTY), 0), 4)                          as                                VARIABLE_COST_PER_UNIT
      , ROUND(SUM(VVCST) / NULLIF(SUM(VVQTY), 0), 4)                          as                                  PER_UNIT_FROZEN_COST
      , ROUND(SUM(VVCST) / NULLIF(SUM(VVQTY), 0), 4)                          as                                 PER_UNIT_CURRENT_COST

        -- Allocated Fixed Cost Per Unit
      , ROUND(SUM(COALESCE(VVMKF, 0) + COALESCE(VVSEF, 0) + COALESCE(VVAFC, 0)) 
            / NULLIF(SUM(VVQTY), 0), 4)                                       as                         ALLOCATED_FIXED_COST_PER_UNIT

        -- Per Unit Component Breakdowns
      , ROUND(SUM(VVGRS) / NULLIF(SUM(VVQTY), 0), 4)                          as                                PER_UNIT_MATERIAL_COST
      , ROUND(SUM(VVLTS) / NULLIF(SUM(VVQTY), 0), 4)                          as                                   PER_UNIT_LABOR_COST
      , ROUND(SUM(VVVPO) / NULLIF(SUM(VVQTY), 0), 4)                          as                            PER_UNIT_VARIABLE_OVERHEAD
      , ROUND(SUM(VVMKF) / NULLIF(SUM(VVQTY), 0), 4)                          as                               PER_UNIT_FIXED_OVERHEAD

        -- Variances
      , SUM(VVPRV)                                                            as                               MATERIAL_PRICE_VARIANCE
      , SUM(VVPRD)                                                            as                               MATERIAL_USAGE_VARIANCE
      , SUM(VVPRT)                                                            as                               MATERIAL_LABOR_VARIANCE
      , SUM(VVPRD)                                                            as                             LABOR_EFFICIENCY_VARIANCE
      , SUM(VVPRV + VVPRO)                                                    as                            OVERHEAD_SPENDING_VARIANCE
      , SUM(VVPRP)                                                            as                              OVERHEAD_VOLUME_VARIANCE

        -- Total Variance Per Unit
      , ROUND(SUM(COALESCE(VVPRV, 0) + COALESCE(VVPRD, 0) + COALESCE(VVPRT, 0) + COALESCE(VVPRO, 0) + COALESCE(VVPRP, 0)) 
            / NULLIF(SUM(VVQTY), 0), 4)                                       as                                COST_VARIANCE_PER_UNIT
    FROM SRC_COPA
    GROUP BY ALL
)

---- RENAME LAYER ----

, RENAME_COPA as (
    SELECT
        LNK_COPA_SALES_HK
      , REC_SRC
      , BKCC
      , POSTING_DATE__YYYYMMDD
      , ACTUAL_QUANTITY
      , SALES_QUANTITY
      , STANDARD_COST
      , CURRENT_COST
      , FREIGHT_COST
      , MATERIAL_COST
      , LABOR_COST
      , VARIABLE_PRODUCTION_OVERHEAD
      , FIXED_MANUFACTURING_OVERHEAD
      , VARIABLE_COST_AMOUNT
      , FIXED_COST_AMOUNT
      , TOTAL_COST_AMOUNT
      , STANDARD_COST_PER_UNIT
      , VARIABLE_COST_PER_UNIT
      , PER_UNIT_FROZEN_COST
      , PER_UNIT_CURRENT_COST
      , ALLOCATED_FIXED_COST_PER_UNIT
      , PER_UNIT_MATERIAL_COST
      , PER_UNIT_LABOR_COST
      , PER_UNIT_VARIABLE_OVERHEAD
      , PER_UNIT_FIXED_OVERHEAD
      , MATERIAL_PRICE_VARIANCE
      , MATERIAL_USAGE_VARIANCE
      , MATERIAL_LABOR_VARIANCE
      , LABOR_EFFICIENCY_VARIANCE
      , OVERHEAD_SPENDING_VARIANCE
      , OVERHEAD_VOLUME_VARIANCE
      , COST_VARIANCE_PER_UNIT
    FROM LOGIC_COPA
)

---- FILTER LAYER ----

, FILTER_COPA as (
    SELECT *
    FROM RENAME_COPA
)

---- JOIN LAYER ----

, JOIN_RESULT as (
    SELECT *
    FROM FILTER_COPA
)

---- FINAL LAYER ----
SELECT
          LNK_COPA_SALES_HK
        , REC_SRC
        , BKCC
        , POSTING_DATE__YYYYMMDD
        , ACTUAL_QUANTITY
        , SALES_QUANTITY
        , STANDARD_COST
        , CURRENT_COST
        , FREIGHT_COST
        , MATERIAL_COST
        , LABOR_COST
        , VARIABLE_PRODUCTION_OVERHEAD
        , FIXED_MANUFACTURING_OVERHEAD
        , VARIABLE_COST_AMOUNT
        , FIXED_COST_AMOUNT
        , TOTAL_COST_AMOUNT
        , STANDARD_COST_PER_UNIT
        , VARIABLE_COST_PER_UNIT
        , PER_UNIT_FROZEN_COST
        , PER_UNIT_CURRENT_COST
        , ALLOCATED_FIXED_COST_PER_UNIT
        , PER_UNIT_MATERIAL_COST
        , PER_UNIT_LABOR_COST
        , PER_UNIT_VARIABLE_OVERHEAD
        , PER_UNIT_FIXED_OVERHEAD
        , MATERIAL_PRICE_VARIANCE
        , MATERIAL_USAGE_VARIANCE
        , MATERIAL_LABOR_VARIANCE
        , LABOR_EFFICIENCY_VARIANCE
        , OVERHEAD_SPENDING_VARIANCE
        , OVERHEAD_VOLUME_VARIANCE
        , COST_VARIANCE_PER_UNIT
FROM JOIN_RESULT

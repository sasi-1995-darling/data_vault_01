---- SRC LAYER ----
WITH
SRC_L              as ( SELECT LNK_MATERIAL_VALUATION_HK, PLANT_HK, ITEM_HK, BWTAR_DC, LOAD_DTS, REC_SRC FROM {{ ref('lnk_material_valuation') }} as SRC  ),
SRC_HIV1           as ( SELECT ITEM_HK, ITEM_BK, REC_SRC FROM {{ ref('hub_item_v1') }} as SRC  ),
SRC_HPV1           as ( SELECT PLANT_HK, PLANT_BK, REC_SRC FROM {{ ref('hub_plant_v1') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT LNK_MATERIAL_VALUATION_HK, MATNR, BWKEY, BWTAR, LBKUM, SALK3, VPRSV, VERPR, STPRS, PEINH, BKLAS, LFGJA, LFMON, PSTAT, LAEPR, MLAST, MLMAA, VMKUM, VMSAL, VJKUM, VJSAL, BKCC, PSA_DELETE_IND FROM {{ ref('lsat_material_valuation__winn_sap') }} as SRC  
    qualify 1= row_number() over (partition by LNK_MATERIAL_VALUATION_HK order by LOAD_DTS DESC))

---- LOGIC LAYER ----

, LOGIC_L as (
    SELECT
        'PIT_MATERIAL_VALUATION'                                     as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , LNK_MATERIAL_VALUATION_HK                                      
      , PLANT_HK                                                     as                                       LNK_PLANT_HK                                
      , ITEM_HK                                                     as                                         LNK_ITEM_HK
      , BWTAR_DC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_L
)

, LOGIC_HIV1 as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , REC_SRC       as       HIV1_REC_SRC
    FROM SRC_HIV1
)

, LOGIC_HPV1 as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , REC_SRC       as       HPV1_REC_SRC
    FROM SRC_HPV1
)

, LOGIC_SAT_WINN as (
    SELECT
        MATNR                                           as                      ITEM_NUMBER    
      , BWKEY                                           as                      VALUATION_AREA    
      , BWTAR                                           as                      VALUATION_TYPE    
      , LBKUM                                           as                      TOTAL_VALUATED_STOCK    
      , SALK3                                           as                      VALUE_OF_TOTAL_VALUATED_STOCK    
      , VPRSV                                           as                      PRICE_CONTROL_IND    
      , VERPR                                           as                      AVG_PERIODIC_UNIT_PRICE    
      , STPRS                                           as                      STD_PRICE    
      , PEINH                                           as                      PRICE_UNIT    
      , BKLAS                                           as                      VALUATION_CLASS    
      , CAST(LFGJA AS INTEGER)                                           as                      CURR_PERIOD_FISCAL_YEAR__YYYYMMDD    
      , LFMON                                           as                      CURR_POSTING_PERIOD   
      , PSTAT                                           as                      MAINTENANCE_STATUS    
      , CAST(LAEPR AS INTEGER)                                           as                      LAST_PRICE_CHANGE_DATE__YYYYMMDD    
      , MLAST                                           as                      MAT_PRICE_DETERMINATION_CONTROL    
      , MLMAA                                           as                      MAT_LEDGER_ACTIVATED_MAT_LEVEL    
      , VMKUM                                           as                      PREV_TOTAL_VALUATED_STOCK    
      , VMSAL                                           as                      VAL_PREV_TOTAL_VALUATED_STOCK    
      , VJKUM                                           as                      PREV_YEAR_TOTAL_VALUATED_STOCK    
      , VJSAL                                           as                      VAL_PREV_YEAR_TOTAL_VALUATED_STOCK    
      , BKCC
      , LNK_MATERIAL_VALUATION_HK                                           as                       SAT_WINN_LNK_MATERIAL_VALUATION_HK
      , PSA_DELETE_IND
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_L as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , LNK_MATERIAL_VALUATION_HK                                      
      , LNK_PLANT_HK                                
      , LNK_ITEM_HK
      , BWTAR_DC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_L
)

, RENAME_HIV1 as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , HIV1_REC_SRC
    FROM LOGIC_HIV1
)

, RENAME_HPV1 as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , HPV1_REC_SRC
    FROM LOGIC_HPV1
)

, RENAME_SAT_WINN as (
    SELECT
        ITEM_NUMBER
      , VALUATION_AREA
      , VALUATION_TYPE
      , TOTAL_VALUATED_STOCK
      , VALUE_OF_TOTAL_VALUATED_STOCK
      , PRICE_CONTROL_IND
      , AVG_PERIODIC_UNIT_PRICE
      , STD_PRICE
      , PRICE_UNIT
      , VALUATION_CLASS
      , CURR_PERIOD_FISCAL_YEAR__YYYYMMDD
      , CURR_POSTING_PERIOD
      , MAINTENANCE_STATUS
      , LAST_PRICE_CHANGE_DATE__YYYYMMDD
      , MAT_PRICE_DETERMINATION_CONTROL
      , MAT_LEDGER_ACTIVATED_MAT_LEVEL
      , PREV_TOTAL_VALUATED_STOCK
      , VAL_PREV_TOTAL_VALUATED_STOCK
      , PREV_YEAR_TOTAL_VALUATED_STOCK
      , VAL_PREV_YEAR_TOTAL_VALUATED_STOCK
      , BKCC
      , SAT_WINN_LNK_MATERIAL_VALUATION_HK
      , PSA_DELETE_IND
    FROM LOGIC_SAT_WINN
)
---- FILTER LAYER ----

, FILTER_L as (
    SELECT *
    FROM RENAME_L
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_HIV1 as (
    SELECT *
    FROM RENAME_HIV1
    WHERE HIV1_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'
)

, FILTER_HPV1 as (
    SELECT *
    FROM RENAME_HPV1
    WHERE HPV1_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_L
    LEFT JOIN FILTER_HIV1
        ON FILTER_L.LNK_ITEM_HK = FILTER_HIV1.ITEM_HK
    LEFT JOIN FILTER_HPV1
        ON FILTER_L.LNK_PLANT_HK = FILTER_HPV1.PLANT_HK
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_L.LNK_MATERIAL_VALUATION_HK = FILTER_SAT_WINN.SAT_WINN_LNK_MATERIAL_VALUATION_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , LNK_MATERIAL_VALUATION_HK                                      
        , PLANT_HK                                
        , ITEM_HK
        , BWTAR_DC
        , ITEM_NUMBER
        , VALUATION_AREA
        , VALUATION_TYPE
        , TOTAL_VALUATED_STOCK
        , VALUE_OF_TOTAL_VALUATED_STOCK
        , PRICE_CONTROL_IND
        , AVG_PERIODIC_UNIT_PRICE
        , STD_PRICE
        , PRICE_UNIT
        , VALUATION_CLASS
        , CURR_PERIOD_FISCAL_YEAR__YYYYMMDD
        , CURR_POSTING_PERIOD
        , MAINTENANCE_STATUS
        , LAST_PRICE_CHANGE_DATE__YYYYMMDD
        , MAT_PRICE_DETERMINATION_CONTROL
        , MAT_LEDGER_ACTIVATED_MAT_LEVEL
        , PREV_TOTAL_VALUATED_STOCK
        , VAL_PREV_TOTAL_VALUATED_STOCK
        , PREV_YEAR_TOTAL_VALUATED_STOCK
        , VAL_PREV_YEAR_TOTAL_VALUATED_STOCK
        , BKCC
        , LOAD_DTS
        , REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED
FROM JOIN_RESULT

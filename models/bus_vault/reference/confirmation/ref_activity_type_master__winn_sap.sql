---- SRC LAYER ----
WITH
SRC_b              as ( SELECT AUSEH, AUSFK, DATAB, DATBI, ERSDA, FIXVO, HRKFT, KOKRS, KSTTY, LARK1, LARK2, LATYP, LATYPI, LEINH, LOAD_DTS, LSTAR, MANDT, MANIST, MANPLAN, SPRKZ, TARKZ, TARKZ_I, USNAM, VKSTA, YRATE FROM {{ ref('v_psa_stg_co_activity_type__winn_sap') }} as SRC  )

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_CO_ACTIVITY_TYPE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        LSTAR                                                        as                                      ACTIVITY_TYPE
      , DATBI                                                        as                                      VALID_TO_DATE
      , KOKRS                                                        as                                   CONTROLLING_AREA
      , MANDT                                                        as                                             CLIENT
      , DATAB                                                        as                                    VALID_FROM_DATE
      , LEINH                                                        as                                      ACTIVITY_UNIT
      , LATYP                                                        as                             ACTIVITY_TYPE_CATEGORY
      , LATYPI                                                       as         ACTIVITY_TYPE_CATEGORY_FOR_ACTUAL_POSTINGS
      , ERSDA                                                        as                                         CREATED_ON
      , USNAM                                                        as                                         ENTERED_BY
      , KSTTY                                                        as                       VALID_COST_CENTER_CATEGORIES
      , AUSEH                                                        as                                        OUTPUT_UNIT
      , AUSFK                                                        as                                      OUTPUT_FACTOR
      , VKSTA                                                        as                            ALLOCATION_COST_ELEMENT
      , LARK1                                                        as                             COMPONENT_RELEVANCY_CO
      , LARK2                                                        as                             COMPONENT_RELEVANCE_HR
      , SPRKZ                                                        as                                     LOCK_INDICATOR
      , HRKFT                                                        as                           COST_ELEMENT_SUBDIVISION
      , FIXVO                                                        as                     PREDISTRIBUTION_OF_FIXED_COSTS
      , TARKZ                                                        as                                   ALLOCATION_PRICE
      , YRATE                                                        as                         PERIOD_BASED_AVERAGE_PRICE
      , TARKZ_I                                                      as                            ACTUAL_ALLOCATION_PRICE
      , MANIST                                                       as                            CONFIRM_QUANTITY_ACTUAL
      , MANPLAN                                                      as                                      PLAN_QUANTITY
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        ACTIVITY_TYPE
      , VALID_TO_DATE
      , CONTROLLING_AREA
      , CLIENT
      , VALID_FROM_DATE
      , ACTIVITY_UNIT
      , ACTIVITY_TYPE_CATEGORY
      , ACTIVITY_TYPE_CATEGORY_FOR_ACTUAL_POSTINGS
      , CREATED_ON
      , ENTERED_BY
      , VALID_COST_CENTER_CATEGORIES
      , OUTPUT_UNIT
      , OUTPUT_FACTOR
      , ALLOCATION_COST_ELEMENT
      , COMPONENT_RELEVANCY_CO
      , COMPONENT_RELEVANCE_HR
      , LOCK_INDICATOR
      , COST_ELEMENT_SUBDIVISION
      , PREDISTRIBUTION_OF_FIXED_COSTS
      , ALLOCATION_PRICE
      , PERIOD_BASED_AVERAGE_PRICE
      , ACTUAL_ALLOCATION_PRICE
      , CONFIRM_QUANTITY_ACTUAL
      , PLAN_QUANTITY
      , LOAD_DTS
    FROM LOGIC_b
)
---- FILTER LAYER ----

, FILTER_b as (
    SELECT *
    FROM RENAME_b
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_b
)

---- FINAL LAYER ----
SELECT
          ACTIVITY_TYPE
        , VALID_TO_DATE
        , CONTROLLING_AREA
        , CLIENT
        , VALID_FROM_DATE
        , ACTIVITY_UNIT
        , ACTIVITY_TYPE_CATEGORY
        , ACTIVITY_TYPE_CATEGORY_FOR_ACTUAL_POSTINGS
        , CREATED_ON
        , ENTERED_BY
        , VALID_COST_CENTER_CATEGORIES
        , OUTPUT_UNIT
        , OUTPUT_FACTOR
        , ALLOCATION_COST_ELEMENT
        , COMPONENT_RELEVANCY_CO
        , COMPONENT_RELEVANCE_HR
        , LOCK_INDICATOR
        , COST_ELEMENT_SUBDIVISION
        , PREDISTRIBUTION_OF_FIXED_COSTS
        , ALLOCATION_PRICE
        , PERIOD_BASED_AVERAGE_PRICE
        , ACTUAL_ALLOCATION_PRICE
        , CONFIRM_QUANTITY_ACTUAL
        , PLAN_QUANTITY
        , LOAD_DTS
FROM JOIN_RESULT

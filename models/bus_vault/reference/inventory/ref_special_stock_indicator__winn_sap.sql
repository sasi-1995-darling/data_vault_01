---- SRC LAYER ----
WITH
SRC_gp             as ( SELECT LOAD_DTS, SOBFI, SOBKZ, SOBLO, SOBVO, SOTXT, SPRAS FROM {{ ref('v_psa_stg_special_stock_indicator__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by SOBKZ, SPRAS order by LOAD_DTS desc) )

/*
SRC_gp             as ( SELECT * FROM staging.v_psa_stg_special_stock_indicator__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_gp as (
    SELECT
        SPRAS                                                        as                                       LANGUAGE_KEY
      , SOBKZ                                                        as                       SPECIAL_STOCK_INDICATOR_CODE
      , SOTXT                                                        as                       SPECIAL_STCOK_INDICATOR_TEXT
      , LOAD_DTS
      , SOBFI                                                        as SPECIAL_STOCK_INDICATOR_ACCOUNTING_ASSIGNMENT_INDICATOR
      , SOBLO                                                        as SPECIAL_STOCK_INDICATOR_LOGISTICS_ASSIGNMENT_INDICATOR
      , SOBVO                                                        as SPECIAL_STOCK_INDICATOR_TRANSACTION_ASSIGNMENT_INDICATOR
    FROM SRC_gp
)
---- RENAME LAYER ----

, RENAME_gp as (
    SELECT
        LANGUAGE_KEY
      , SPECIAL_STOCK_INDICATOR_CODE
      , SPECIAL_STCOK_INDICATOR_TEXT
      , LOAD_DTS
      , SPECIAL_STOCK_INDICATOR_ACCOUNTING_ASSIGNMENT_INDICATOR
      , SPECIAL_STOCK_INDICATOR_LOGISTICS_ASSIGNMENT_INDICATOR
      , SPECIAL_STOCK_INDICATOR_TRANSACTION_ASSIGNMENT_INDICATOR
    FROM LOGIC_gp
)
---- FILTER LAYER ----

, FILTER_gp as (
    SELECT *
    FROM RENAME_gp
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_gp
)

---- FINAL LAYER ----
SELECT
          LANGUAGE_KEY
        , SPECIAL_STOCK_INDICATOR_CODE
        , SPECIAL_STCOK_INDICATOR_TEXT
        , LOAD_DTS
        , SPECIAL_STOCK_INDICATOR_ACCOUNTING_ASSIGNMENT_INDICATOR
        , SPECIAL_STOCK_INDICATOR_LOGISTICS_ASSIGNMENT_INDICATOR
        , SPECIAL_STOCK_INDICATOR_TRANSACTION_ASSIGNMENT_INDICATOR
FROM JOIN_RESULT

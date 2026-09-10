---- SRC LAYER ----
WITH
SRC_crncy          as ( SELECT * FROM {{ ref('v_psa_stg_ref_currency_conversion_fiscal_month_avg') }} as SRC  )

/*
SRC_crncy          as ( SELECT * FROM staging.v_psa_stg_ref_currency_conversion_fiscal_month_avg )
*/
---- LOGIC LAYER ----

, LOGIC_crncy as (
    SELECT
        FP_FISCAL_MONTH
      , FP_DATE_DT
      , KURST
      , FCURR
      , TCURR
      , FISCAL_MONTH_AVG_UKURS
      , FFACT
      , TFACT
      , MANDT
      , LOAD_DTS
    FROM SRC_crncy
)
---- RENAME LAYER ----

, RENAME_crncy as (
    SELECT
        FP_FISCAL_MONTH
      , FP_DATE_DT
      , KURST
      , FCURR
      , TCURR
      , FISCAL_MONTH_AVG_UKURS
      , FFACT
      , TFACT
      , MANDT
      , LOAD_DTS
    FROM LOGIC_crncy
)
---- FILTER LAYER ----

, FILTER_crncy as (
    SELECT *
    FROM RENAME_crncy
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_crncy
)

---- FINAL LAYER ----
SELECT
          FP_FISCAL_MONTH
        , FP_DATE_DT
        , KURST
        , FCURR
        , TCURR
        , FISCAL_MONTH_AVG_UKURS
        , FFACT
        , TFACT
        , MANDT
        , LOAD_DTS
FROM JOIN_RESULT

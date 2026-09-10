---- SRC LAYER ----
WITH
SRC_LT         as ( SELECT MANDT, LANGU, RLDNR, GLREQUEST, NAME, GLDELFLAG, GLCHANGETIME, GLSOURCESYSTEM FROM {{ ref('v_psa_stg_ledger_text__winn_sap') }} as SRC
                    qualify 1= row_number() over(partition by LANGU, RLDNR order by LOAD_DTS desc))
/*
SRC_LT         as ( SELECT * FROM STAGING.v_psa_stg_ledger_text__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_LT as (
    SELECT
        MANDT                                                        as                                             CLIENT
      , LANGU                                                        as                                       LANGUAGE_KEY
      , RLDNR                                                        as                                             LEDGER
      , GLREQUEST
      , NAME                                                         as                                        LEDGER_NAME
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
    FROM SRC_LT
)
---- RENAME LAYER ----

, RENAME_LT as (
    SELECT
        CLIENT
      , LANGUAGE_KEY
      , LEDGER
      , GLREQUEST
      , LEDGER_NAME
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
    FROM LOGIC_LT
)
---- FILTER LAYER ----

, FILTER_LT as (
    SELECT *
    FROM RENAME_LT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LT
)

---- FINAL LAYER ----
SELECT
          CLIENT
        , LANGUAGE_KEY
        , LEDGER
        , GLREQUEST
        , LEDGER_NAME
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_b              as ( SELECT IDENT, LOAD_DTS, LTEXT, SPRAS FROM {{ ref('v_psa_stg_factory_calendar__winn_sap') }} as SRC 
                               qualify 1= row_number()over(partition by IDENT, SPRAS order by LOAD_DTS desc)  )

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_FACTORY_CALENDAR__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        IDENT                                                        as                              FACTORY_CALENDAR_CODE
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , LTEXT                                                        as                              FACTORY_CALENDAR_TEXT
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        FACTORY_CALENDAR_CODE
      , LANGUAGE_KEY
      , FACTORY_CALENDAR_TEXT
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
          FACTORY_CALENDAR_CODE
        , LANGUAGE_KEY
        , FACTORY_CALENDAR_TEXT
        , LOAD_DTS
FROM JOIN_RESULT

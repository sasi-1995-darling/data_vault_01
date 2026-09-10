---- SRC LAYER ----
WITH
SRC_b              as ( SELECT LOAD_DTS, MANDT, MATYP, MATYT, SPRAS FROM {{ ref('v_psa_stg_machine_type__winn_sap') }} as SRC  )

/*
SRC_b              as ( SELECT * FROM staging.V_PSA_STG_MACHINE_TYPE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        MATYP                                                        as                                       MACHINE_TYPE
      , MANDT                                                        as                                             CLIENT
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , MATYT                                                        as                                  MACHINE_TYPE_TEXT
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        MACHINE_TYPE
      , CLIENT
      , LANGUAGE_KEY
      , MACHINE_TYPE_TEXT
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
          MACHINE_TYPE
        , CLIENT
        , LANGUAGE_KEY
        , MACHINE_TYPE_TEXT
        , LOAD_DTS
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_b              as ( SELECT WERKS, LOAD_DTS, SPRAS, RWPRO, TEXT40 FROM {{ ref('v_psa_stg_coverage_profile_description__winn_sap') }} as SRC 
                        WHERE SPRAS = 'E'
                        qualify 1= row_number()over(partition by WERKS, SPRAS, RWPRO order by LOAD_DTS desc) )

/*
SRC_b              as ( SELECT * FROM staging.v_psa_stg_coverage_profile_description__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_b as (
    SELECT
        SPRAS                                                        as                                       LANGUAGE_KEY
      , WERKS                                                        as                                       PLANT
      , RWPRO                                                        as                                       COVERAGE_PROFILE_CODE
      , TEXT40                                                       as                                       COVERAGE_PROFILE_TEXT
      , LOAD_DTS
    FROM SRC_b
)
---- RENAME LAYER ----

, RENAME_b as (
    SELECT
        LANGUAGE_KEY
      , PLANT
      , COVERAGE_PROFILE_CODE
      , COVERAGE_PROFILE_TEXT
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
        LANGUAGE_KEY
      , PLANT
      , COVERAGE_PROFILE_CODE
      , COVERAGE_PROFILE_TEXT
      , LOAD_DTS
FROM JOIN_RESULT
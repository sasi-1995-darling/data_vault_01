---- SRC LAYER ----
WITH
SRC_fcpc           as ( SELECT PATTERN, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE FROM {{ ref('v_psa_stg_test_email_patterns_for_flo_dynamo') }} as SRC 
                        qualify 1= row_number() over(partition by PATTERN order by PSA_LOAD_DTS DESC)  )

/*
SRC_fcpc           as ( SELECT * FROM staging.v_psa_stg_test_email_patterns_for_flo_dynamo )
*/
---- LOGIC LAYER ----

, LOGIC_fcpc as (
    SELECT
        PATTERN
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_fcpc
)
---- RENAME LAYER ----

, RENAME_fcpc as (
    SELECT
        PATTERN
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_fcpc
)
---- FILTER LAYER ----

, FILTER_fcpc as (
    SELECT *
    FROM RENAME_fcpc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_fcpc
)

---- FINAL LAYER ----
SELECT
          PATTERN
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
FROM JOIN_RESULT

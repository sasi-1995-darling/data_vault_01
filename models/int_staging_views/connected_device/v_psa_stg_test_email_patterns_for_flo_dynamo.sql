---- SRC LAYER ----
WITH
SRC_src            as ( SELECT PATTERN, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE FROM {{ source('reference', 'ref_test_email_pattern') }} as SRC 
                        WHERE PSA_DELETE_IND='N' )

/*
SRC_src            as ( SELECT * FROM reference.ref_test_email_pattern )
*/
---- LOGIC LAYER ----

, LOGIC_src as (
    SELECT
        PATTERN
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_src
)
---- RENAME LAYER ----

, RENAME_src as (
    SELECT
        PATTERN
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_src
)
---- FILTER LAYER ----

, FILTER_src as (
    SELECT *
    FROM RENAME_src
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_src
)

---- FINAL LAYER ----
SELECT
          PATTERN
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
FROM JOIN_RESULT

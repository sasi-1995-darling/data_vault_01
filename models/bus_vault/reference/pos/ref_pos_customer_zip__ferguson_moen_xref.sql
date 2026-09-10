---- SRC LAYER ----
WITH
SRC_mnzpfei        as ( SELECT ZIP_CODE, CUSTOMER_BK, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_pos_zip_cross_ref__moen_ferguson_new') }} as SRC  )

/*
SRC_mnzpfei        as ( SELECT * FROM staging.v_psa_stg_pos_zip_cross_ref__moen_ferguson_new )
*/
---- LOGIC LAYER ----

, LOGIC_mnzpfei as (
    SELECT
        ZIP_CODE
      , CUSTOMER_BK                                                  as                                   MOEN_CUSTOMER_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM SRC_mnzpfei
)
---- RENAME LAYER ----

, RENAME_mnzpfei as (
    SELECT
        ZIP_CODE
      , MOEN_CUSTOMER_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_mnzpfei
)
---- FILTER LAYER ----

, FILTER_mnzpfei as (
    SELECT *
    FROM RENAME_mnzpfei
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_mnzpfei
)

---- FINAL LAYER ----
SELECT
          ZIP_CODE
        , MOEN_CUSTOMER_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT

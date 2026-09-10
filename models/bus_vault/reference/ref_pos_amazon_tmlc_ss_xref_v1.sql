---- SRC LAYER ----
WITH
SRC_LTT            as ( SELECT * FROM {{ ref('v_psa_stg_pos_cross_ref__amazon_tmlc_ss_latest') }} as SRC  )

/*
SRC_LTT            as ( SELECT * FROM staging.v_psa_stg_pos_cross_ref__amazon_tmlc_ss_latest )
*/
---- LOGIC LAYER ----

, LOGIC_LTT as (
    SELECT
        CUSTOMER_SKU_HK
      , BASE_MATERIAL_HK
      , ASIN
      , MODEL_NUMBER
      , LOAD_DTS
      , _FILE
      , _LINE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_LTT
)
---- RENAME LAYER ----

, RENAME_LTT as (
    SELECT
        CUSTOMER_SKU_HK
      , BASE_MATERIAL_HK
      , ASIN
      , MODEL_NUMBER
      , LOAD_DTS
      , _FILE
      , _LINE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_LTT
)
---- FILTER LAYER ----

, FILTER_LTT as (
    SELECT *
    FROM RENAME_LTT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LTT
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_SKU_HK
        , BASE_MATERIAL_HK
        , ASIN
        , MODEL_NUMBER
        , LOAD_DTS
        , _FILE
        , _LINE
        , _MODIFIED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT

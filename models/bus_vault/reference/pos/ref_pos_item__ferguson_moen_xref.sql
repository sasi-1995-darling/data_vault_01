---- SRC LAYER ----
WITH
SRC_mnitfei        as ( SELECT FEI_PRODUCT_CODE, SAP_MATERIAL_NUMBER, SAP_ACCOUNT_NUMBER, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_pos_item_cross_ref__moen_ferguson_new') }} as SRC  )

/*
SRC_mnitfei        as ( SELECT * FROM staging.v_psa_stg_pos_item_cross_ref__moen_ferguson_new )
*/
---- LOGIC LAYER ----

, LOGIC_mnitfei as (
    SELECT
        FEI_PRODUCT_CODE                                             as                                 FEI_PRODUCT_NUMBER
      , SAP_MATERIAL_NUMBER                                          as                                   MOEN_ITEM_NUMBER
      , SAP_ACCOUNT_NUMBER                                           as                            MOEN_KEY_ACCOUNT_NUMBER
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM SRC_mnitfei
)
---- RENAME LAYER ----

, RENAME_mnitfei as (
    SELECT
        FEI_PRODUCT_NUMBER
      , MOEN_ITEM_NUMBER
      , MOEN_KEY_ACCOUNT_NUMBER
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_mnitfei
)
---- FILTER LAYER ----

, FILTER_mnitfei as (
    SELECT *
    FROM RENAME_mnitfei
    WHERE TRUE 
/* The following qualify clause is required to pull the latest set of unique values into Ref Table */
qualify 1 = row_number() over (partition by FEI_PRODUCT_NUMBER, MOEN_ITEM_NUMBER, MOEN_KEY_ACCOUNT_NUMBER order by LOAD_DTS desc)
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_mnitfei
)

---- FINAL LAYER ----
SELECT
          FEI_PRODUCT_NUMBER
        , MOEN_ITEM_NUMBER
        , MOEN_KEY_ACCOUNT_NUMBER
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT

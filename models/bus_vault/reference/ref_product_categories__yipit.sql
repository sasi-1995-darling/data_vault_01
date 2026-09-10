---- SRC LAYER ----
WITH
SRC_ypm            as ( SELECT * FROM {{ ref('v_psa_stg_granular_products_monthly__yipit') }} as SRC 
                        where nullif(trim(sku),'') is not null qualify row_number() over(partition by retailer, segment, category,sub_category, class, sub_class, brand, sku, model_num order by load_dts desc)=1 )

/*
SRC_ypm            as ( SELECT * FROM staging.v_psa_stg_granular_products_monthly__yipit )
*/
---- LOGIC LAYER ----

, LOGIC_ypm as (
    SELECT
        COALESCE(RETAILER,'N/A')                                     as                                           RETAILER
      , COALESCE(SEGMENT,'N/A')                                      as                                            SEGMENT
      , COALESCE(CATEGORY,'N/A')                                     as                                           CATEGORY
      , COALESCE(SUB_CATEGORY,'N/A')                                 as                                       SUB_CATEGORY
      , COALESCE(CLASS,'N/A')                                        as                                              CLASS
      , COALESCE(SUB_CLASS,'N/A')                                    as                                          SUB_CLASS
      , COALESCE(BRAND,'N/A')                                        as                                              BRAND
      , COALESCE(SKU,'N/A')                                          as                                                SKU
      , COALESCE(MODEL_NUM,'N/A')                                    as                                          MODEL_NUM
      , LOAD_DTS
      , SKU_HK
      , MODEL_NUM_HK
      , REC_SRC
    FROM SRC_ypm
)
---- RENAME LAYER ----

, RENAME_ypm as (
    SELECT
        RETAILER
      , SEGMENT
      , CATEGORY
      , SUB_CATEGORY
      , CLASS
      , SUB_CLASS
      , BRAND
      , SKU
      , MODEL_NUM
      , LOAD_DTS
      , SKU_HK
      , MODEL_NUM_HK
      , REC_SRC
    FROM LOGIC_ypm
)
---- FILTER LAYER ----

, FILTER_ypm as (
    SELECT *
    FROM RENAME_ypm
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_ypm
)

---- FINAL LAYER ----
SELECT
          RETAILER
        , SEGMENT
        , CATEGORY
        , SUB_CATEGORY
        , CLASS
        , SUB_CLASS
        , BRAND
        , SKU
        , MODEL_NUM
        , LOAD_DTS
        , SKU_HK
        , MODEL_NUM_HK
        , REC_SRC
FROM JOIN_RESULT
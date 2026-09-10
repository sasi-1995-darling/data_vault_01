{{ config(alias='dim_brand' + ('_service_level' if target.name not in ['dev', 'qa', 'prod'] else '')) }}
---- SRC LAYER ----
WITH
SRC_dim_brand      as ( SELECT BRAND, BUSINESS_UNIT, COMPETITOR_IND, SUB_BRAND_CODE, SUB_BRAND_NAME FROM {{ ref('dim_brand') }} as SRC  )

/*
SRC_dim_brand      as ( SELECT * FROM bus_vault.dim_brand )
*/
---- LOGIC LAYER ----

, LOGIC_dim_brand as (
    SELECT
        COMPETITOR_IND
      , SUB_BRAND_CODE                                               as                           DIM_BRAND_SUB_BRAND_CODE
      , SUB_BRAND_NAME                                               as                           DIM_BRAND_SUB_BRAND_NAME
      , BRAND                                                        as                                    DIM_BRAND_BRAND
      , BUSINESS_UNIT                                                as                            DIM_BRAND_BUSINESS_UNIT
    FROM SRC_dim_brand
)
---- RENAME LAYER ----

, RENAME_dim_brand as (
    SELECT
        COMPETITOR_IND
      , DIM_BRAND_SUB_BRAND_CODE
      , DIM_BRAND_SUB_BRAND_NAME
      , DIM_BRAND_BRAND
      , DIM_BRAND_BUSINESS_UNIT
    FROM LOGIC_dim_brand
)
---- FILTER LAYER ----

, FILTER_dim_brand as (
    SELECT *
    FROM RENAME_dim_brand
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_dim_brand
)

---- FINAL LAYER ----
SELECT
          UPPER(DIM_BRAND_SUB_BRAND_CODE)                              as SUB_BRAND_CODE
        , UPPER(DIM_BRAND_SUB_BRAND_NAME)                              as SUB_BRAND_NAME
        , UPPER(DIM_BRAND_BRAND)                                       as BRAND
        , UPPER(DIM_BRAND_BUSINESS_UNIT)                               as BUSINESS_UNIT
        , COMPETITOR_IND
FROM JOIN_RESULT

{{ config(alias='rep_daily_cumulative_product_rating_v2') }}
---- SRC LAYER ----
WITH
SRC_FPR            as ( SELECT * FROM {{ ref('im_fact_daily_cumulative_product_rating_v2') }} as SRC  ),
SRC_DP             as ( SELECT * FROM {{ ref('im_dim_product_v2') }} as SRC  ),
SRC_DB             as ( SELECT * FROM {{ ref('im_dim_brand_v2') }} as SRC  ),
SRC_DD             as ( SELECT * FROM {{ ref('im_dim_date_gregorian') }} as SRC  )

/*
SRC_FPR            as ( SELECT * FROM consumer_feedback.IM_FACT_DAILY_CUMULATIVE_PRODUCT_RATING_V2 )
, SRC_DP             as ( SELECT * FROM consumer_feedback.IM_DIM_PRODUCT_V2 )
, SRC_DB             as ( SELECT * FROM consumer_feedback.IM_DIM_BRAND_V2 )
, SRC_DD             as ( SELECT * FROM consumer_feedback.IM_DIM_DATE_GREGORIAN )
*/
---- LOGIC LAYER ----

, LOGIC_FPR as (
    SELECT
        RETAILER_BK
      , COUNTRY
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , INCRE_1_STAR                                                 as                                   CORRECTED_1_STAR
      , INCRE_2_STAR                                                 as                                   CORRECTED_2_STAR
      , INCRE_3_STAR                                                 as                                   CORRECTED_3_STAR
      , INCRE_4_STAR                                                 as                                   CORRECTED_4_STAR
      , INCRE_5_STAR                                                 as                                   CORRECTED_5_STAR
      , INCRE_1_STAR
      , INCRE_2_STAR
      , INCRE_3_STAR
      , INCRE_4_STAR
      , INCRE_5_STAR
      , CUMULATIVE_REVIEWS                                           as                       CORRECTED_CUMULATIVE_REVIEWS
      , SOURCE
      , PRODUCT_BK                                                   as                                     FPR_PRODUCT_BK
      , BRAND_BK                                                     as                                       FPR_BRAND_BK
      , DATE_KEY                                                     as                                       FPR_DATE_KEY
    FROM SRC_FPR
)

, LOGIC_DP as (
    SELECT
        CUSTOMER_PRODUCT_ID
      , PRODUCT_NAME
      , MODEL
      , LEVEL_1
      , LEVEL_2
      , SMART_ATTR
      , FIRE_RESISTANT_ATTR
      , CONNECTED_FLAG
      , PRODUCT_BK                                                   as                                      DP_PRODUCT_BK
      , PRODUCT_FAMILY
    FROM SRC_DP
)

, LOGIC_DB as (
    SELECT
        SYSTEM_BRAND                                                 as                                         BRAND_NAME
      , SUBBRAND
      , BUSINESS_UNIT
      , BRAND_BK                                                     as                                        DB_BRAND_BK
    FROM SRC_DB
)

, LOGIC_DD as (
    SELECT
        DATE_ACTUAL                                                  as                                           DATE_KEY
      , DATE_BK                                                      as                                         DD_DATE_BK
    FROM SRC_DD
)
---- RENAME LAYER ----

, RENAME_DP as (
    SELECT
        CUSTOMER_PRODUCT_ID
      , PRODUCT_NAME
      , MODEL
      , LEVEL_1
      , LEVEL_2
      , SMART_ATTR
      , FIRE_RESISTANT_ATTR
      , CONNECTED_FLAG
      , DP_PRODUCT_BK
      , PRODUCT_FAMILY
    FROM LOGIC_DP
)

, RENAME_FPR as (
    SELECT
        RETAILER_BK
      , COUNTRY
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , CORRECTED_1_STAR
      , CORRECTED_2_STAR
      , CORRECTED_3_STAR
      , CORRECTED_4_STAR
      , CORRECTED_5_STAR
      , INCRE_1_STAR
      , INCRE_2_STAR
      , INCRE_3_STAR
      , INCRE_4_STAR
      , INCRE_5_STAR
      , CORRECTED_CUMULATIVE_REVIEWS
      , SOURCE
      , FPR_PRODUCT_BK
      , FPR_BRAND_BK
      , FPR_DATE_KEY
    FROM LOGIC_FPR
)

, RENAME_DD as (
    SELECT
        DATE_KEY
      , DD_DATE_BK
    FROM LOGIC_DD
)

, RENAME_DB as (
    SELECT
        BRAND_NAME
      , SUBBRAND
      , BUSINESS_UNIT
      , DB_BRAND_BK
    FROM LOGIC_DB
)
---- FILTER LAYER ----

, FILTER_FPR as (
    SELECT *
    FROM RENAME_FPR
)

, FILTER_DP as (
    SELECT *
    FROM RENAME_DP
)

, FILTER_DB as (
    SELECT *
    FROM RENAME_DB
)

, FILTER_DD as (
    SELECT *
    FROM RENAME_DD
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_FPR
    INNER JOIN FILTER_DP
        ON FPR_PRODUCT_BK = DP_PRODUCT_BK
    INNER JOIN FILTER_DB
        ON FPR_BRAND_BK = DB_BRAND_BK
    INNER JOIN FILTER_DD
        ON FPR_DATE_KEY = DD_DATE_BK
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_PRODUCT_ID
        , RETAILER_BK
        , DATE_KEY
        , COUNTRY
        , CUMULATIVE_STAR_RATING
        , CUMULATIVE_REVIEWS
        , CUMULATIVE_5_STAR_REVIEWS
        , CUMULATIVE_4_STAR_REVIEWS
        , CUMULATIVE_3_STAR_REVIEWS
        , CUMULATIVE_2_STAR_REVIEWS
        , CUMULATIVE_1_STAR_REVIEWS
        , CORRECTED_1_STAR
        , CORRECTED_2_STAR
        , CORRECTED_3_STAR
        , CORRECTED_4_STAR
        , CORRECTED_5_STAR
        , INCRE_1_STAR
        , INCRE_2_STAR
        , INCRE_3_STAR
        , INCRE_4_STAR
        , INCRE_5_STAR
        , CORRECTED_CUMULATIVE_REVIEWS
        , BRAND_NAME
        , SUBBRAND
        , PRODUCT_NAME
        , MODEL
        , LEVEL_1
        , LEVEL_2
        , SMART_ATTR
        , FIRE_RESISTANT_ATTR
        , SOURCE
        , CONNECTED_FLAG
        , BUSINESS_UNIT
        , PRODUCT_FAMILY
FROM JOIN_RESULT

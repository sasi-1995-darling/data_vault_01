{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT * FROM {{ ref('pb_stg_daily_cumulative_product_rating_v2__delighted_pa') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.PB_STG_DAILY_CUMULATIVE_PRODUCT_RATING_V2__DELIGHTED_PA )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , PRODUCT_BK
      , RETAILER_BK
      , BKCC
      , REC_SRC
      , REVIEW_DATE_KEY                                              as                                           DATE_KEY
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , STAR_1                                                       as                                       INCRE_1_STAR
      , STAR_2                                                       as                                       INCRE_2_STAR
      , STAR_3                                                       as                                       INCRE_3_STAR
      , STAR_4                                                       as                                       INCRE_4_STAR
      , STAR_5                                                       as                                       INCRE_5_STAR
      , UPDATED_AT
      , BRAND_BK
      , SOURCE
      , COUNTRY
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , PRODUCT_BK
      , RETAILER_BK
      , BKCC
      , REC_SRC
      , DATE_KEY
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , INCRE_1_STAR
      , INCRE_2_STAR
      , INCRE_3_STAR
      , INCRE_4_STAR
      , INCRE_5_STAR
      , UPDATED_AT
      , BRAND_BK
      , SOURCE
      , COUNTRY
    FROM LOGIC_PB
)
---- FILTER LAYER ----

, FILTER_PB as (
    SELECT *
    FROM RENAME_PB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PB
)

---- FINAL LAYER ----
SELECT
          PRODUCT_RETAILER_HK
        , PRODUCT_HK
        , RETAILER_HK
        , PRODUCT_BK
        , RETAILER_BK
        , BKCC
        , REC_SRC
        , DATE_KEY
        , CUMULATIVE_STAR_RATING
        , CUMULATIVE_REVIEWS
        , sum(INCRE_5_STAR) over (partition BY PRODUCT_BK, SOURCE order by DATE_KEY asc rows between unbounded preceding and current row) as CUMULATIVE_5_STAR_REVIEWS
        , sum(INCRE_4_STAR) over (partition BY PRODUCT_BK, SOURCE order by DATE_KEY asc rows between unbounded preceding and current row) as CUMULATIVE_4_STAR_REVIEWS
        , sum(INCRE_3_STAR) over (partition BY PRODUCT_BK, SOURCE order by DATE_KEY asc rows between unbounded preceding and current row) as CUMULATIVE_3_STAR_REVIEWS
        , sum(INCRE_2_STAR) over (partition BY PRODUCT_BK, SOURCE order by DATE_KEY asc rows between unbounded preceding and current row) as CUMULATIVE_2_STAR_REVIEWS
        , sum(INCRE_1_STAR) over (partition BY PRODUCT_BK, SOURCE order by DATE_KEY asc rows between unbounded preceding and current row) as CUMULATIVE_1_STAR_REVIEWS
        , INCRE_1_STAR
        , INCRE_2_STAR
        , INCRE_3_STAR
        , INCRE_4_STAR
        , INCRE_5_STAR
        , UPDATED_AT
        , BRAND_BK
        , SOURCE
        , COUNTRY
FROM JOIN_RESULT

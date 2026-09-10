{{ config(alias='rep_product_review_v2') }}
---- SRC LAYER ----
WITH
SRC_FPR            as ( SELECT BRAND_BK, MANUFACTURER_COMMENT_TEXT, PRODUCT_BK, PURCHASE_SOURCE, PURCHASE_SOURCE_EXTRA_TEXT, RETAILER_BK, REVIEW_DATE_KEY, REVIEW_TEXT, REVIEW_TITLE, REVIEW_URL, SOURCE, STAR_RATING, SURVEY_TYPE, UKEY, PURCHASE_CHANNEL FROM {{ ref('im_fact_product_review_v2') }} as SRC  ),
SRC_DP             as ( SELECT CONNECTED_FLAG, CUSTOMER_PRODUCT_ID, FIRE_RESISTANT_ATTR, LEVEL_1, LEVEL_2, MODEL, PRODUCT_BK, PRODUCT_FAMILY, PRODUCT_NAME , SMART_ATTR FROM {{ ref('im_dim_product_v2') }} as SRC  ),
SRC_DB             as ( SELECT BRAND_BK, BUSINESS_UNIT, SUBBRAND, SYSTEM_BRAND FROM {{ ref('im_dim_brand_v2') }} as SRC  ),
SRC_DD             as ( SELECT DATE_ACTUAL, DATE_BK FROM {{ ref('im_dim_date_gregorian') }} as SRC  )

/*
SRC_FPR            as ( SELECT * FROM consumer_feedback.IM_FACT_PRODUCT_REVIEW_V2 )
SRC_DP             as ( SELECT * FROM consumer_feedback.IM_DIM_PRODUCT_V2 )
SRC_DB             as ( SELECT * FROM consumer_feedback.IM_DIM_BRAND_V2 )
SRC_DD             as ( SELECT * FROM consumer_feedback.IM_DIM_DATE_GREGORIAN )
*/
---- LOGIC LAYER ----

, LOGIC_FPR as (
    SELECT
        RETAILER_BK
      , REVIEW_TITLE                                                 as                                            SUMMARY
      , REVIEW_TEXT                                                  as                                          TEXT_BODY
      , STAR_RATING
      , REVIEW_URL
      , MANUFACTURER_COMMENT_TEXT
      , UKEY
      , SOURCE
      , PRODUCT_BK                                                   as                                     FPR_PRODUCT_BK
      , BRAND_BK                                                     as                                       FPR_BRAND_BK
      , REVIEW_DATE_KEY                                              as                                FPR_REVIEW_DATE_KEY
      , PURCHASE_SOURCE
      , PURCHASE_SOURCE_EXTRA_TEXT
      , SURVEY_TYPE
      , PURCHASE_CHANNEL
    FROM SRC_FPR
)

, LOGIC_DP as (
    SELECT
        CUSTOMER_PRODUCT_ID
      , PRODUCT_NAME                                                 as                                      PRODUCT_TITLE
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
      , SUBBRAND                                                     as                                          SUB_BRAND
      , BUSINESS_UNIT
      , BRAND_BK                                                     as                                        DB_BRAND_BK
    FROM SRC_DB
)

, LOGIC_DD as (
    SELECT
        DATE_ACTUAL                                                  as                                    REVIEW_DATE_KEY
      , DATE_BK                                                      as                                         DD_DATE_BK
    FROM SRC_DD
)
---- RENAME LAYER ----

, RENAME_DP as (
    SELECT
        CUSTOMER_PRODUCT_ID
      , PRODUCT_TITLE
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
      , SUMMARY
      , TEXT_BODY
      , STAR_RATING
      , REVIEW_URL
      , MANUFACTURER_COMMENT_TEXT
      , UKEY
      , SOURCE
      , FPR_PRODUCT_BK
      , FPR_BRAND_BK
      , FPR_REVIEW_DATE_KEY
      , PURCHASE_SOURCE
      , PURCHASE_SOURCE_EXTRA_TEXT
      , SURVEY_TYPE
      , PURCHASE_CHANNEL
    FROM LOGIC_FPR
)

, RENAME_DD as (
    SELECT
        REVIEW_DATE_KEY
      , DD_DATE_BK
    FROM LOGIC_DD
)

, RENAME_DB as (
    SELECT
        BRAND_NAME
      , SUB_BRAND
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
        ON FPR_REVIEW_DATE_KEY = DD_DATE_BK
)

---- FINAL LAYER ----
SELECT
          CUSTOMER_PRODUCT_ID
        , RETAILER_BK
        , REVIEW_DATE_KEY
        , SUMMARY
        , TEXT_BODY
        , STAR_RATING
        , REVIEW_URL
        , MANUFACTURER_COMMENT_TEXT
        , UKEY
        , BRAND_NAME
        , SUB_BRAND
        , PRODUCT_TITLE
        , MODEL
        , LEVEL_1
        , LEVEL_2
        , SMART_ATTR
        , FIRE_RESISTANT_ATTR
        , SOURCE
        , CONNECTED_FLAG
        , BUSINESS_UNIT
        , PRODUCT_FAMILY
        , PURCHASE_SOURCE
        , PURCHASE_SOURCE_EXTRA_TEXT
        , SURVEY_TYPE
        , PURCHASE_CHANNEL
FROM JOIN_RESULT
GROUP BY ALL
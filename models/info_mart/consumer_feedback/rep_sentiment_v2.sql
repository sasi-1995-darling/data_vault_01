{{ config(alias='rep_sentiment_v2') }}
---- SRC LAYER ----
WITH
SRC_FPR            as ( SELECT UKEY, RETAILER_BK, STAR_RATING, REVIEW_TEXT, SOURCE, PRODUCT_BK, BRAND_BK, REVIEW_DATE_KEY FROM {{ ref('im_fact_product_review_v2') }} as SRC  ),
SRC_DP             as ( SELECT PRODUCT_NAME , MODEL, SMART_ATTR, FIRE_RESISTANT_ATTR, CUSTOMER_PRODUCT_ID, CONNECTED_FLAG, LEVEL_1, LEVEL_2, PRODUCT_BK, PRODUCT_FAMILY FROM {{ ref('im_dim_product_v2') }} as SRC  ),
SRC_DB             as ( SELECT SYSTEM_BRAND, SUBBRAND, BRAND_BK, COMPETITOR_IND, BUSINESS_UNIT FROM {{ ref('im_dim_brand_v2') }} as SRC  ),
SRC_DD             as ( SELECT DATE_ACTUAL, DATE_BK FROM {{ ref('im_dim_date_gregorian') }} as SRC  ),
SRC_SO             as ( SELECT UNIQUE_ID, SENTIMENT, SUBCATEGORY_LABEL, SUBCATEGORY_SENTENCE, CATEGORY_LABEL, TAG, CREATED_AT, REVIEW_SOURCE_ID, HS_FLAG, REVIEW_ID FROM {{ ref('dim_sentiment_output') }} as SRC  )

/*
SRC_FPR            as ( SELECT * FROM consumer_feedback.IM_FACT_PRODUCT_REVIEW_V2 )
SRC_DP             as ( SELECT * FROM consumer_feedback.IM_DIM_PRODUCT_V2 )
SRC_DB             as ( SELECT * FROM consumer_feedback.IM_DIM_BRAND_V2 )
SRC_DD             as ( SELECT * FROM consumer_feedback.IM_DIM_DATE_GREGORIAN )
SRC_SO             as ( SELECT * FROM consumer_feedback.DIM_SENTIMENT_OUTPUT )
*/
---- LOGIC LAYER ----

, LOGIC_FPR as (
    SELECT
        UKEY
      , 'NULL'                                                       as                                        RETAILER_ID
      , RETAILER_BK                                                  as                                      RETAILER_NAME
      , STAR_RATING
      , REVIEW_TEXT
      , STAR_RATING                                                  as                                      ACTUAL_RATING
      , SOURCE                                                       as                                         FPR_SOURCE
      , UKEY                                                         as                                           FPR_UKEY
      , PRODUCT_BK                                                   as                                     FPR_PRODUCT_BK
      , BRAND_BK                                                     as                                       FPR_BRAND_BK
      , REVIEW_DATE_KEY                                              as                                FPR_REVIEW_DATE_KEY
    FROM SRC_FPR
)

, LOGIC_DP as (
    SELECT
        PRODUCT_NAME                                                 as                                      PRODUCT_TITLE
      , MODEL
      , SMART_ATTR
      , FIRE_RESISTANT_ATTR
      , CUSTOMER_PRODUCT_ID                                          as                                         PRODUCT_ID
      , CUSTOMER_PRODUCT_ID
      , CONNECTED_FLAG
      , LEVEL_1
      , LEVEL_2
      , PRODUCT_BK                                                   as                                      DP_PRODUCT_BK
      , PRODUCT_FAMILY
    FROM SRC_DP
)

, LOGIC_DB as (
    SELECT
        SYSTEM_BRAND                                                 as                                         BRAND_NAME
      , SUBBRAND                                                     as                                          SUB_BRAND
      , BRAND_BK                                                     as                                        DB_BRAND_BK
      , COMPETITOR_IND
      , BUSINESS_UNIT
    FROM SRC_DB
)

, LOGIC_DD as (
    SELECT
        DATE_ACTUAL
      , DATE_BK                                                      as                                         DD_DATE_BK
    FROM SRC_DD
)

, LOGIC_SO as (
    SELECT
        UNIQUE_ID                                                    as                                                 ID
      , SENTIMENT
      , SUBCATEGORY_LABEL
      , SUBCATEGORY_SENTENCE
      , CATEGORY_LABEL
      , TAG
      , CREATED_AT
      , REVIEW_SOURCE_ID
      , HS_FLAG
      , REVIEW_ID                                                    as                                       SO_REVIEW_ID
      , REVIEW_SOURCE_ID                                             as                                SO_REVIEW_SOURCE_ID
    FROM SRC_SO
)
---- RENAME LAYER ----

, RENAME_DB as (
    SELECT
        BRAND_NAME
      , SUB_BRAND
      , DB_BRAND_BK
      , COMPETITOR_IND
      , BUSINESS_UNIT
    FROM LOGIC_DB
)

, RENAME_DP as (
    SELECT
        PRODUCT_TITLE
      , MODEL
      , SMART_ATTR
      , FIRE_RESISTANT_ATTR
      , PRODUCT_ID
      , CUSTOMER_PRODUCT_ID
      , CONNECTED_FLAG
      , LEVEL_1
      , LEVEL_2
      , DP_PRODUCT_BK
      , PRODUCT_FAMILY
    FROM LOGIC_DP
)

, RENAME_SO as (
    SELECT
        ID
      , SENTIMENT
      , SUBCATEGORY_LABEL
      , SUBCATEGORY_SENTENCE
      , CATEGORY_LABEL
      , TAG
      , CREATED_AT
      , REVIEW_SOURCE_ID
      , HS_FLAG
      , SO_REVIEW_ID
      , SO_REVIEW_SOURCE_ID
    FROM LOGIC_SO
)

, RENAME_FPR as (
    SELECT
        UKEY
      , RETAILER_ID
      , RETAILER_NAME
      , STAR_RATING
      , REVIEW_TEXT
      , ACTUAL_RATING
      , FPR_SOURCE
      , FPR_UKEY
      , FPR_PRODUCT_BK
      , FPR_BRAND_BK
      , FPR_REVIEW_DATE_KEY
    FROM LOGIC_FPR
)

, RENAME_DD as (
    SELECT
        DATE_ACTUAL
      , DD_DATE_BK
    FROM LOGIC_DD
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

, FILTER_SO as (
    SELECT *
    FROM RENAME_SO
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
    INNER JOIN FILTER_SO
        ON FPR_UKEY = SO_review_id and UPPER(FPR_source) = UPPER(SO_review_source_id)
)

---- FINAL LAYER ----
SELECT
          BRAND_NAME
        , SUB_BRAND
        , PRODUCT_TITLE
        , MODEL
        , SMART_ATTR
        , FIRE_RESISTANT_ATTR
        , ID
        , UKEY
        , RETAILER_ID
        , RETAILER_NAME
        , STAR_RATING
        , PRODUCT_ID
        , CUSTOMER_PRODUCT_ID
        , DATE_ACTUAL
        , SENTIMENT
        , REVIEW_TEXT
        , SUBCATEGORY_LABEL
        , SUBCATEGORY_SENTENCE
        , CATEGORY_LABEL
        , TAG
        , CREATED_AT
        , ACTUAL_RATING
        , REVIEW_SOURCE_ID
        , CONNECTED_FLAG
        , LEVEL_1
        , LEVEL_2
        , HS_FLAG
        , BUSINESS_UNIT
        , PRODUCT_FAMILY
FROM JOIN_RESULT
WHERE
    COMPETITOR_IND = 'N'
    AND CONNECTED_FLAG = 'Y'
GROUP BY ALL
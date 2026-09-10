{{ config(alias='rep_sentiment_input_v2') }}
---- SRC LAYER ----
WITH
SRC_FPR            as ( SELECT * FROM {{ ref('im_fact_product_review_v2') }} as SRC  ),
SRC_DP             as ( SELECT * FROM {{ ref('im_dim_product_v2') }} as SRC  ),
SRC_DB             as ( SELECT * FROM {{ ref('im_dim_brand_v2') }} as SRC  ),
SRC_DD             as ( SELECT * FROM {{ ref('im_dim_date_gregorian') }} as SRC  )

/*
SRC_FPR            as ( SELECT * FROM consumer_feedback.IM_FACT_PRODUCT_REVIEW_V2 )
, SRC_DP             as ( SELECT * FROM consumer_feedback.IM_DIM_PRODUCT_V2 )
, SRC_DB             as ( SELECT * FROM consumer_feedback.IM_DIM_BRAND_V2 )
, SRC_DD             as ( SELECT * FROM consumer_feedback.IM_DIM_DATE_GREGORIAN )
*/
---- LOGIC LAYER ----

, LOGIC_FPR as (
    SELECT
        UKEY                                                         as                                          Unique_ID
      , SOURCE                                                       as                                   Review_Source_ID
      , UKEY                                                         as                                          Review_ID
      , REVIEW_TITLE                                                 as                                       Review_Title
      , REVIEW_TEXT                                                  as                                        Review_Text
      , REVIEW_DATE_KEY                                              as                                         Created_At
      , REVIEW_DATE_KEY                                              as                                         Updated_At
      , PRODUCT_BK                                                   as                                     FPR_PRODUCT_BK
      , BRAND_BK                                                     as                                       FPR_BRAND_BK
      , REVIEW_DATE_KEY                                              as                                FPR_REVIEW_DATE_KEY
      , SENTIMENT_PROCESSED                                          as                             UP_SENTIMENT_PROCESSED
    FROM SRC_FPR
)

, LOGIC_DP as (
    SELECT
        LEVEL_2                                                      as                                         PRODUCT_ID
      , PRODUCT_NAME                                                 as                                      PRODUCT_TITLE
      , CONNECTED_FLAG
      , PRODUCT_BK                                                   as                                      DP_PRODUCT_BK
    FROM SRC_DP
)

, LOGIC_DB as (
    SELECT
        SYSTEM_BRAND                                                 as                                           Brand_ID
      , COMPETITOR_IND
      , BRAND_BK                                                     as                                        DB_BRAND_BK
    FROM SRC_DB
)

, LOGIC_DD as (
    SELECT
        DATE_ACTUAL                                                  as                                               Date
      , DATE_BK                                                      as                                         DD_DATE_BK
    FROM SRC_DD
)
---- RENAME LAYER ----

, RENAME_FPR as (
    SELECT
        Unique_ID
      , Review_Source_ID
      , Review_ID
      , Review_Title
      , Review_Text
      ,  Created_At
      , Updated_At
      , FPR_PRODUCT_BK
      , FPR_BRAND_BK
      , FPR_REVIEW_DATE_KEY
      , UP_SENTIMENT_PROCESSED
    FROM LOGIC_FPR
)

, RENAME_DB as (
    SELECT
        Brand_ID
      , COMPETITOR_IND
      , DB_BRAND_BK
    FROM LOGIC_DB
)

, RENAME_DP as (
    SELECT
        PRODUCT_ID
      , PRODUCT_TITLE
      , CONNECTED_FLAG
      , DP_PRODUCT_BK
    FROM LOGIC_DP
)

, RENAME_DD as (
    SELECT
        Date
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
          UNIQUE_ID
        , BRAND_ID
        , PRODUCT_ID
        , REVIEW_SOURCE_ID
        , REVIEW_ID
        , REVIEW_TITLE
        , REVIEW_TEXT
        , DATE
        , PRODUCT_TITLE
        ,  CREATED_AT
        , UPDATED_AT
FROM JOIN_RESULT
WHERE
    COMPETITOR_IND = 'N'
    AND CONNECTED_FLAG = 'Y'
    AND UP_SENTIMENT_PROCESSED = 'N'
    AND REVIEW_TEXT IS NOT NULL
GROUP BY ALL
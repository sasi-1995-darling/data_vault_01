{{ config(alias='dim_sentiment_output') }}
---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT UNIQUE_ID, BRAND_ID, PRODUCT_ID, REVIEW_SOURCE_ID, REVIEW_ID, REVIEW_TITLE, REVIEW_TEXT, DATE, PRODUCT_TITLE, CATEGORY_LABEL, SUBCATEGORY_LABEL, SUBCATEGORY_SENTENCE, SENTIMENT, TAG, CREATED_AT, HS_FLAG FROM {{ ref('dim_sentiment_output') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM bus_vault.dim_sentiment_output )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
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
      , CATEGORY_LABEL
      , SUBCATEGORY_LABEL
      , SUBCATEGORY_SENTENCE
      , SENTIMENT
      , TAG
      , CREATED_AT
      , HS_FLAG
    FROM SRC_S1
)
---- RENAME LAYER ----

, RENAME_S1 as (
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
      , CATEGORY_LABEL
      , SUBCATEGORY_LABEL
      , SUBCATEGORY_SENTENCE
      , SENTIMENT
      , TAG
      , CREATED_AT
      , HS_FLAG
    FROM LOGIC_S1
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
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
        , CATEGORY_LABEL
        , SUBCATEGORY_LABEL
        , SUBCATEGORY_SENTENCE
        , SENTIMENT
        , TAG
        , CREATED_AT
        , HS_FLAG
FROM JOIN_RESULT

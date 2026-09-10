---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT UNIQUE_ID, BRAND_ID, PRODUCT_ID, REVIEW_SOURCE_ID, REVIEW_ID, REVIEW_TITLE, REVIEW_TEXT, DATE, PRODUCT_TITLE, CATEGORY_LABEL, SUBCATEGORY_LABEL, SUBCATEGORY_SENTENCE, SENTIMENT, TAG, CREATED_AT, HS_FLAG, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND, REC_SRC, BKCC FROM {{ ref('ref_sentiment_output') }} as SRC 
                        qualify 1= row_number() over(partition by Unique_ID order by PSA_LOAD_DTS DESC) )
 
/*
SRC_S1             as ( SELECT * FROM bus_vault.ref_sentiment_output )
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
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
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
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
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
          row_number() over(order by 1)                                as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PIT_LOAD_DTS
        , UNIQUE_ID
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
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
WHERE PSA_DELETE_IND = 'N'
---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT UNIQUE_ID, BRAND_ID, PRODUCT_ID, REVIEW_SOURCE_ID, REVIEW_ID, REVIEW_TITLE, REVIEW_TEXT, DATE, PRODUCT_TITLE, CATEGORY_LABEL, SUBCATEGORY_LABEL, SUBCATEGORY_SENTENCE, SENTIMENT, TAG, CREATED_AT, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND, HS_FLAG FROM {{ source('sentiment_psa', 'sentiment_output') }} as SRC  ),
SRC_A1             as ( SELECT REC_SRC, BKCC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM sentiment_psa.sentiment_output )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
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
      , CASE
            WHEN HS_FLAG = 'software' THEN 'Software'
            WHEN HS_FLAG = 'hardware' THEN 'Hardware'
            WHEN HS_FLAG = 'other' THEN 'Other'
            WHEN HS_FLAG IS NULL THEN ''
        END                                                          as                                            HS_FLAG
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , HS_FLAG                                                      as                                        RAW_HS_FLAG
    FROM SRC_S1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
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
      , RAW_HS_FLAG
    FROM LOGIC_S1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'FBIN.DATASCIENCE.SENTIMENT.SENTIMENT_OUTPUT'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S1
    INNER JOIN FILTER_A1
        ON '1' = '1'
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
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(UNIQUE_ID::text), '^^') 
            , '||', IFNULL(TRIM(BRAND_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_ID::text), '^^') 
            , '||', IFNULL(TRIM(REVIEW_SOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(REVIEW_ID::text), '^^') 
            , '||', IFNULL(TRIM(REVIEW_TITLE::text), '^^') 
            , '||', IFNULL(TRIM(REVIEW_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(DATE::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_TITLE::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY_LABEL::text), '^^') 
            , '||', IFNULL(TRIM(SUBCATEGORY_LABEL::text), '^^') 
            , '||', IFNULL(TRIM(SUBCATEGORY_SENTENCE::text), '^^') 
            , '||', IFNULL(TRIM(SENTIMENT::text), '^^') 
            , '||', IFNULL(TRIM(TAG::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(HS_FLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

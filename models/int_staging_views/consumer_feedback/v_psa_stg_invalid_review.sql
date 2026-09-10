---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT PRODUCT_ID, BRAND_ID, REVIEW_SOURCE_ID, REVIEW_ID, REVIEW_TITLE, REVIEW_TEXT, DATE, PRODUCT_TITLE, SUBCATEGORY_LABEL, SUBCATEGORY_SENTENCE, SENTIMENT, CREATED_AT, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND, HS_FLAG FROM {{ source('sentiment_psa', 'invalid_reviews') }} as SRC  ),
SRC_A1             as ( SELECT REC_SRC, BKCC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM sentiment_psa.invalid_reviews )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        PRODUCT_ID
      , BRAND_ID
      , REVIEW_SOURCE_ID
      , REVIEW_ID
      , REVIEW_TITLE
      , REVIEW_TEXT
      , DATE
      , PRODUCT_TITLE
      , SUBCATEGORY_LABEL
      , SUBCATEGORY_SENTENCE
      , SENTIMENT
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
        PRODUCT_ID
      , BRAND_ID
      , REVIEW_SOURCE_ID
      , REVIEW_ID
      , REVIEW_TITLE
      , REVIEW_TEXT
      , DATE
      , PRODUCT_TITLE
      , SUBCATEGORY_LABEL
      , SUBCATEGORY_SENTENCE
      , SENTIMENT
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
    WHERE rec_src = 'FBIN.DATASCIENCE.SENTIMENT.INVALID_REVIEWS'
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
          PRODUCT_ID
        , BRAND_ID
        , REVIEW_SOURCE_ID
        , REVIEW_ID
        , REVIEW_TITLE
        , REVIEW_TEXT
        , DATE
        , PRODUCT_TITLE
        , SUBCATEGORY_LABEL
        , SUBCATEGORY_SENTENCE
        , SENTIMENT
        , CREATED_AT
        , HS_FLAG
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PRODUCT_ID::text), '^^') 
            , '||', IFNULL(TRIM(BRAND_ID::text), '^^') 
            , '||', IFNULL(TRIM(REVIEW_SOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(REVIEW_ID::text), '^^') 
            , '||', IFNULL(TRIM(REVIEW_TITLE::text), '^^') 
            , '||', IFNULL(TRIM(REVIEW_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(DATE::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_TITLE::text), '^^') 
            , '||', IFNULL(TRIM(SUBCATEGORY_LABEL::text), '^^') 
            , '||', IFNULL(TRIM(SUBCATEGORY_SENTENCE::text), '^^') 
            , '||', IFNULL(TRIM(SENTIMENT::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(HS_FLAG::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

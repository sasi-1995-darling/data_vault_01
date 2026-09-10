{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HP             as ( SELECT * FROM {{ ref('hub_product_v2') }} as SRC  ),
SRC_SRB            as ( SELECT * FROM {{ ref('sat_review__bazaarvoice') }} as SRC 
                        qualify 1= row_number() over(partition by ID order by PSA_LOAD_DTS DESC) ),
SRC_SP             as ( SELECT * FROM {{ ref('ref_sentiment_processed') }} as SRC 
                        WHERE UPPER(REVIEW_SOURCE_ID) = 'BAZAARVOICE' )

/*
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PRODUCT_V2 )
SRC_SRB            as ( SELECT * FROM raw_vault.SAT_REVIEW__BAZAARVOICE )
SRC_SP             as ( SELECT * FROM bus_vault.REF_SENTIMENT_PROCESSED )
*/
---- LOGIC LAYER ----

, LOGIC_HP as (
    SELECT
        PRODUCT_HK                                                   as                                      HP_PRODUCT_HK
      , PRODUCT_BK
      , '0'                                                          as                                        RETAILER_BK
      , PRODUCT_BK                                                   as                                CUSTOMER_PRODUCT_ID
      , BKCC
      , 'Moen'                                                       as                                           BRAND_BK
      , PRODUCT_BK                                                   as                                         PRODUCT_ID
    FROM SRC_HP
)

, LOGIC_SRB as (
    SELECT
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(0 as VARCHAR)),''), '^^')
        )))                                                          as                                PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(0 as VARCHAR)),''), '^^')
        )))                                                          as                                        RETAILER_HK
      , REC_SRC
      , (COALESCE(TO_CHAR(TO_TIMESTAMP(SUBMISSION_TIME),'YYYYMMDD'), '19000101'))::INTEGER as                                    REVIEW_DATE_KEY
      , TITLE                                                        as                                       REVIEW_TITLE
      , REVIEW_TEXT
      , RATING                                                       as                                        STAR_RATING
      , ''                                                           as                                         REVIEW_URL
      , CONCAT('MOEN-',TO_VARCHAR(ID))                               as                                               UKEY
      , TO_VARCHAR(CID)                                              as                                             AUTHOR
      , (TO_CHAR(TO_TIMESTAMP(SUBMISSION_TIME),'YYYYMMDD'))::INTEGER as                                  DB_CREATED_AT_KEY
      , (TO_CHAR(TO_TIMESTAMP(LAST_MODIFICATION_TIME),'YYYYMMDD'))::INTEGER as                                UPDATED_AT_DATE_KEY
      , ''                                                           as                                            COUNTRY
      , ''                                                           as                          MANUFACTURER_COMMENT_TEXT
      , ('0')::INTEGER                                               as                      MANUFACTURER_COMMENT_DATE_KEY
      , 'FALSE'                                                      as                                         IS_DELETED
      , CONCAT('MOEN-',TO_VARCHAR(ID))                               as                                             SRB_ID
    FROM SRC_SRB
)

, LOGIC_SP as (
    SELECT
        REVIEW_ID
    FROM SRC_SP
)
---- RENAME LAYER ----

, RENAME_SRB as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , REC_SRC
      , REVIEW_DATE_KEY
      , REVIEW_TITLE
      , REVIEW_TEXT
      , STAR_RATING
      , REVIEW_URL
      , UKEY
      , AUTHOR
      , DB_CREATED_AT_KEY
      , UPDATED_AT_DATE_KEY
      , COUNTRY
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE_KEY
      , IS_DELETED
      , SRB_ID
    FROM LOGIC_SRB
)

, RENAME_HP as (
    SELECT
        HP_PRODUCT_HK
      , PRODUCT_BK
      , RETAILER_BK
      , CUSTOMER_PRODUCT_ID
      , BKCC
      , BRAND_BK
      , PRODUCT_ID
    FROM LOGIC_HP
)

, RENAME_SP as (
    SELECT
        REVIEW_ID
    FROM LOGIC_SP
)
---- FILTER LAYER ----

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_SRB as (
    SELECT *
    FROM RENAME_SRB
)

, FILTER_SP as (
    SELECT *
    FROM RENAME_SP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HP
    INNER JOIN FILTER_SRB
        ON HP_PRODUCT_HK = PRODUCT_HK
    LEFT JOIN FILTER_SP
        ON SRB_ID = REVIEW_ID
)

---- FINAL LAYER ----
SELECT
          PRODUCT_RETAILER_HK
        , PRODUCT_HK
        , RETAILER_HK
        , PRODUCT_BK
        , RETAILER_BK
        , CUSTOMER_PRODUCT_ID
        , BKCC
        , REC_SRC
        , REVIEW_DATE_KEY
        , REVIEW_TITLE
        , REVIEW_TEXT
        , STAR_RATING
        , REVIEW_URL
        , UKEY
        , AUTHOR
        , DB_CREATED_AT_KEY
        , UPDATED_AT_DATE_KEY
        , COUNTRY
        , BRAND_BK
        , MANUFACTURER_COMMENT_TEXT
        , MANUFACTURER_COMMENT_DATE_KEY
        , 'BAZAARVOICE'                                                as SOURCE
        , PRODUCT_ID
        , IS_DELETED
        , CASE WHEN REVIEW_ID IS NULL THEN 'N' ELSE 'Y' END            as SENTIMENT_PROCESSED
        , 'NOT APPLICABLE'                                             as PURCHASE_SOURCE
        , 'NOT APPLICABLE'                                             as PURCHASE_SOURCE_EXTRA_TEXT
        , CAST('Not Applicable' AS TEXT)                               as SURVEY_TYPE
FROM JOIN_RESULT
WHERE PRODUCT_BK <> '0'
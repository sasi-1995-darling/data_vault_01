{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LPR            as ( SELECT * FROM {{ ref('lnk_product_retailer') }} as SRC  ),
SRC_HP             as ( SELECT * FROM {{ ref('hub_product_v2') }} as SRC  ),
SRC_SA             as ( SELECT * FROM {{ ref('sat_applist__appbot') }} as SRC 
                        qualify 1= row_number() over(partition by PRODUCT_HK order by psa_load_dts DESC) ),
SRC_HR             as ( SELECT * FROM {{ ref('hub_retailer') }} as SRC  ),
SRC_LPRP           as ( SELECT * FROM {{ ref('lsat_product_review__appbot') }} as SRC 
                        qualify 1= row_number() over(partition by ID order by PSA_LOAD_DTS DESC) ),
SRC_SP             as ( SELECT * FROM {{ ref('ref_sentiment_processed') }} as SRC 
                        WHERE UPPER(REVIEW_SOURCE_ID) = 'APPBOT' )

/*
SRC_LPR            as ( SELECT * FROM raw_vault.LNK_PRODUCT_RETAILER )
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PRODUCT_V2 )
SRC_SA             as ( SELECT * FROM raw_vault.SAT_APPLIST__APPBOT )
SRC_HR             as ( SELECT * FROM raw_vault.HUB_RETAILER )
SRC_LPRP           as ( SELECT * FROM raw_vault.LSAT_PRODUCT_REVIEW__APPBOT )
SRC_SP             as ( SELECT * FROM bus_vault.REF_SENTIMENT_PROCESSED )
*/
---- LOGIC LAYER ----

, LOGIC_LPR as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , REC_SRC
    FROM SRC_LPR
)

, LOGIC_HP as (
    SELECT
        PRODUCT_HK                                                   as                                      HP_PRODUCT_HK
      , PRODUCT_BK
      , BKCC
    FROM SRC_HP
)

, LOGIC_SA as (
    SELECT
        PRODUCT_HK                                                   as                                      SA_PRODUCT_HK
      , ID                                                           as                             SA_CUSTOMER_PRODUCT_ID
      , CASE 
            WHEN CONTAINS(NAME, 'Moen') THEN 'Moen'
            WHEN CONTAINS(NAME, 'MOEN') THEN 'Moen'
            WHEN CONTAINS(NAME, 'Master Lock') THEN 'Master Lock'
            WHEN CONTAINS(NAME, 'Yale') THEN 'Yale'
            WHEN CONTAINS(NAME, 'Phyn') THEN 'Phyn'
            WHEN CONTAINS(NAME, 'KOHLER') THEN 'Kohler'
            WHEN CONTAINS(NAME, 'Kohler') THEN 'Kohler'
            WHEN CONTAINS(NAME, 'ShowerMe') THEN 'ShowerMe'
            WHEN CONTAINS(NAME, 'SentrySafe') THEN 'SentrySafe'
            WHEN CONTAINS(NAME, 'August') THEN 'August'
            WHEN CONTAINS(NAME, 'Therma-Tru Benchmark Doors') THEN 'Therma-Tru'
            WHEN CONTAINS(NAME, 'Fypon') THEN 'Fypon'
            WHEN CONTAINS(NAME, 'Larson') THEN 'Larson'
            WHEN CONTAINS(NAME, 'Fiberon') THEN 'Fiberon'
            ELSE
            NAME
        END                                                          as                                           BRAND_BK
    FROM SRC_SA
)

, LOGIC_HR as (
    SELECT
        RETAILER_HK                                                  as                                     HR_RETAILER_HK
      , RETAILER_BK
    FROM SRC_HR
)

, LOGIC_LPRP as (
    SELECT
        PRODUCT_RETAILER_HK                                          as                           LPRP_PRODUCT_RETAILER_HK
      , (TO_CHAR(PUBLISHED_AT,'YYYYMMDD'))::INTEGER                  as                                    REVIEW_DATE_KEY
      , SUBJECT                                                      as                                       REVIEW_TITLE
      , BODY                                                         as                                        REVIEW_TEXT
      , RATING                                                       as                                        STAR_RATING
      , PERMALINK_URL                                                as                                         REVIEW_URL
      , ID                                                           as                                               UKEY
      , AUTHOR
      , (TO_CHAR(PUBLISHED_AT,'YYYYMMDD'))::INTEGER                  as                                  DB_CREATED_AT_KEY
      , (TO_CHAR(PUBLISHED_AT,'YYYYMMDD'))::INTEGER                  as                                UPDATED_AT_DATE_KEY
      , COUNTRY
      , COALESCE(REPLY_TEXT,'')                                      as                          MANUFACTURER_COMMENT_TEXT
      , (TO_CHAR(TO_DATE(REPLY_DATE), 'YYYYMMDD'))::INTEGER          as                      MANUFACTURER_COMMENT_DATE_KEY
      , TO_CHAR(ID)                                                  as                                         PRODUCT_ID
      , 'FALSE'                                                      as                                         IS_DELETED
    FROM SRC_LPRP
)

, LOGIC_SP as (
    SELECT
        REVIEW_ID
    FROM SRC_SP
)
---- RENAME LAYER ----

, RENAME_LPR as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , REC_SRC
    FROM LOGIC_LPR
)

, RENAME_HP as (
    SELECT
        HP_PRODUCT_HK
      , PRODUCT_BK
      , BKCC
    FROM LOGIC_HP
)

, RENAME_HR as (
    SELECT
        HR_RETAILER_HK
      , RETAILER_BK
    FROM LOGIC_HR
)

, RENAME_SA as (
    SELECT
        SA_PRODUCT_HK
      , SA_CUSTOMER_PRODUCT_ID
      , BRAND_BK
    FROM LOGIC_SA
)

, RENAME_LPRP as (
    SELECT
        LPRP_PRODUCT_RETAILER_HK
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
      , PRODUCT_ID
      , IS_DELETED
    FROM LOGIC_LPRP
)

, RENAME_SP as (
    SELECT
        REVIEW_ID
    FROM LOGIC_SP
)
---- FILTER LAYER ----

, FILTER_LPR as (
    SELECT *
    FROM RENAME_LPR
)

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_SA as (
    SELECT *
    FROM RENAME_SA
)

, FILTER_HR as (
    SELECT *
    FROM RENAME_HR
)

, FILTER_LPRP as (
    SELECT *
    FROM RENAME_LPRP
)

, FILTER_SP as (
    SELECT *
    FROM RENAME_SP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LPR
    INNER JOIN FILTER_HP
        ON FILTER_LPR.PRODUCT_HK = HP_PRODUCT_HK
    INNER JOIN FILTER_SA
        ON FILTER_LPR.PRODUCT_HK = SA_PRODUCT_HK
    INNER JOIN FILTER_HR
        ON FILTER_LPR.RETAILER_HK = HR_RETAILER_HK
    INNER JOIN FILTER_LPRP
        ON FILTER_LPR.PRODUCT_RETAILER_HK = LPRP_PRODUCT_RETAILER_HK
    LEFT JOIN FILTER_SP
        ON UKEY = REVIEW_ID
)

---- FINAL LAYER ----
SELECT
          PRODUCT_RETAILER_HK
        , PRODUCT_HK
        , RETAILER_HK
        , PRODUCT_BK
        , RETAILER_BK
        , SA_CUSTOMER_PRODUCT_ID
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
        , 'APPBOT'                                                     as SOURCE
        , PRODUCT_ID
        , IS_DELETED
        , CASE WHEN REVIEW_ID IS NULL THEN 'N' ELSE 'Y' END            as SENTIMENT_PROCESSED
        , 'NOT APPLICABLE'                                             as PURCHASE_SOURCE
        , 'NOT APPLICABLE'                                             as PURCHASE_SOURCE_EXTRA_TEXT
        , CAST('Not Applicable' AS TEXT)                               as SURVEY_TYPE
FROM JOIN_RESULT
WHERE RETAILER_BK IN ('iOS','Google Play')
{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LPR            as ( SELECT * FROM {{ ref('lnk_product_retailer') }} as SRC  ),
SRC_HP             as ( SELECT * FROM {{ ref('hub_product_v2') }} as SRC  ),
SRC_HR             as ( SELECT * FROM {{ ref('hub_retailer') }} as SRC  ),
SRC_LPRP           as ( SELECT * FROM {{ ref('lsat_product_review__profitero') }} as SRC 
                        WHERE IS_DELETED = FALSE
                        qualify 1= row_number() over(partition by CUSTOMER_PRODUCT_ID, RETAILER_Id, product_id, UKEY, IS_DELETED order by UPDATED_AT DESC) ),
SRC_LPB            as ( SELECT * FROM {{ ref('lnk_product_brand') }} as SRC  ),
SRC_HB             as ( SELECT * FROM {{ ref('hub_brand_v2') }} as SRC  ),
SRC_SP             as ( SELECT * FROM {{ ref('ref_sentiment_processed') }} as SRC 
                        WHERE UPPER(REVIEW_SOURCE_ID) = 'PROFITERO' )

/*
SRC_LPR            as ( SELECT * FROM raw_vault.LNK_PRODUCT_RETAILER )
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PRODUCT_V2 )
SRC_HR             as ( SELECT * FROM raw_vault.HUB_RETAILER )
SRC_LPRP           as ( SELECT * FROM raw_vault.LSAT_PRODUCT_REVIEW__PROFITERO )
SRC_LPB            as ( SELECT * FROM raw_vault.LNK_PRODUCT_BRAND )
SRC_HB             as ( SELECT * FROM raw_vault.HUB_BRAND_V2 )
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

, LOGIC_HR as (
    SELECT
        RETAILER_HK                                                  as                                     HR_RETAILER_HK
      , RETAILER_BK
    FROM SRC_HR
)

, LOGIC_LPRP as (
    SELECT
        PRODUCT_RETAILER_HK                                          as                           LPRP_PRODUCT_RETAILER_HK
      , (to_varchar(to_date(DATE), 'YYYYMMDD'))::INTEGER             as                                    REVIEW_DATE_KEY
      , COALESCE(SUMMARY, '')                                        as                                       REVIEW_TITLE
      , COALESCE(TEXT, '')                                           as                                        REVIEW_TEXT
      , STAR_RATING
      , COALESCE(REVIEW_URL, '')                                     as                                         REVIEW_URL
      , UKEY
      , COALESCE(AUTHOR, '')                                         as                                             AUTHOR
      , (TO_CHAR(TO_DATE(TO_CHAR(DB_CREATED_AT)),'YYYYMMDD'))::INTEGER as                                  DB_CREATED_AT_KEY
      , (TO_CHAR(TO_DATE(TO_CHAR(UPDATED_AT)),'YYYYMMDD'))::INTEGER  as                                UPDATED_AT_DATE_KEY
      , COALESCE(MANUFACTURER_COMMENT_TEXT, '')                      as                          MANUFACTURER_COMMENT_TEXT
      , (to_varchar(MANUFACTURER_COMMENT_DATE, 'YYYYMMDD'))::INTEGER as                      MANUFACTURER_COMMENT_DATE_KEY
      , TO_CHAR(PRODUCT_ID)                                          as                                         PRODUCT_ID
      , IS_DELETED
    FROM SRC_LPRP
)

, LOGIC_LPB as (
    SELECT
        PRODUCT_HK                                                   as                                     LPB_PRODUCT_HK
      , BRAND_HK                                                     as                                       LPB_BRAND_HK
      , LOAD_DTS
    FROM SRC_LPB
)

, LOGIC_HB as (
    SELECT
        BRAND_HK                                                     as                                        HB_BRAND_HK
      , BRAND_BK
    FROM SRC_HB
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
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE_KEY
      , PRODUCT_ID
      , IS_DELETED
    FROM LOGIC_LPRP
)

, RENAME_LPB as (
    SELECT
        LPB_PRODUCT_HK
      , LPB_BRAND_HK
      , LOAD_DTS
    FROM LOGIC_LPB
)

, RENAME_HB as (
    SELECT
        HB_BRAND_HK
      , BRAND_BK
    FROM LOGIC_HB
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

, FILTER_HR as (
    SELECT *
    FROM RENAME_HR
)

, FILTER_LPRP as (
    SELECT *
    FROM RENAME_LPRP
)

, FILTER_LPB as (
    SELECT *
    FROM RENAME_LPB
)

, FILTER_HB as (
    SELECT *
    FROM RENAME_HB
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
    INNER JOIN FILTER_HR
        ON FILTER_LPR.RETAILER_HK = HR_RETAILER_HK
    INNER JOIN FILTER_LPRP
        ON FILTER_LPR.PRODUCT_RETAILER_HK = LPRP_PRODUCT_RETAILER_HK
    INNER JOIN FILTER_LPB
        ON HP_PRODUCT_HK = LPB_PRODUCT_HK
    INNER JOIN FILTER_HB
        ON LPB_BRAND_HK = HB_BRAND_HK
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
        , BRAND_BK
        , MANUFACTURER_COMMENT_TEXT
        , MANUFACTURER_COMMENT_DATE_KEY
        , 'US'                                                         as COUNTRY
        , 'PROFITERO'                                                  as SOURCE
        , PRODUCT_ID
        , IS_DELETED
        , CASE WHEN REVIEW_ID IS NULL THEN 'N' ELSE 'Y' END            as SENTIMENT_PROCESSED
        , 'NOT APPLICABLE'                                             as PURCHASE_SOURCE
        , 'NOT APPLICABLE'                                             as PURCHASE_SOURCE_EXTRA_TEXT
        , LOAD_DTS
        , CAST('Not Applicable' AS TEXT)                               as SURVEY_TYPE
FROM JOIN_RESULT

{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HP             as ( SELECT * FROM {{ ref('hub_product_v2') }} as SRC  ),
SRC_SPD            as ( SELECT * FROM {{ ref('sat_product__delighted') }} as SRC 
                        qualify 1= row_number() over(partition by PRODUCT_HK order by psa_load_dts DESC) ),
SRC_SRH            as ( SELECT * FROM {{ ref('sat_response__hyd_delighted') }} as SRC 
                        qualify 1= row_number() over(partition by ID order by PSA_LOAD_DTS DESC) ),
SRC_SP             as ( SELECT * FROM {{ ref('ref_sentiment_processed') }} as SRC 
                        WHERE UPPER(REVIEW_SOURCE_ID) = 'DELIGHTED' )

/*
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PRODUCT_V2 )
SRC_SPD            as ( SELECT * FROM raw_vault.SAT_PRODUCT__DELIGHTED )
SRC_SRH            as ( SELECT * FROM raw_vault.SAT_RESPONSE__HYD_DELIGHTED )
SRC_SP             as ( SELECT * FROM bus_vault.REF_SENTIMENT_PROCESSED )
*/
---- LOGIC LAYER ----

, LOGIC_HP as (
    SELECT
        PRODUCT_HK                                                   as                                      HP_PRODUCT_HK
      , PRODUCT_BK
      , '0'                                                          as                                        RETAILER_BK
      , BKCC
      , 'Moen'                                                       as                                           BRAND_BK
    FROM SRC_HP
)

, LOGIC_SPD as (
    SELECT
        PRODUCT_HK                                                   as                                     SPD_PRODUCT_HK
      , TO_CHAR(ID)                                                  as                                CUSTOMER_PRODUCT_ID
      , TO_CHAR(ID)                                                  as                                         PRODUCT_ID
    FROM SRC_SPD
)

, LOGIC_SRH as (
    SELECT
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(0 as VARCHAR)),''), '^^')
        )))                                                          as                                PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(0 as VARCHAR)),''), '^^')
        )))                                                          as                                        RETAILER_HK
      , REC_SRC
      , (COALESCE(TO_CHAR(TO_TIMESTAMP(CREATED_AT),'YYYYMMDD'), '19000101'))::INTEGER as                                    REVIEW_DATE_KEY
      , ''                                                           as                                       REVIEW_TITLE
      , COMMENT                                                      as                                        REVIEW_TEXT
      , SCORE                                                        as                                        STAR_RATING
      , PERMALINK                                                    as                                         REVIEW_URL
      , TO_VARCHAR(ID)                                               as                                               UKEY
      , TO_VARCHAR(PERSON_ID)                                        as                                             AUTHOR
      , (TO_CHAR(TO_TIMESTAMP(CREATED_AT),'YYYYMMDD'))::INTEGER      as                                  DB_CREATED_AT_KEY
      , (TO_CHAR(TO_TIMESTAMP(UPDATED_AT),'YYYYMMDD'))::INTEGER      as                                UPDATED_AT_DATE_KEY
      , ''                                                           as                                            COUNTRY
      , ''                                                           as                          MANUFACTURER_COMMENT_TEXT
      , ('0')::INTEGER                                               as                      MANUFACTURER_COMMENT_DATE_KEY
      , 'FALSE'                                                      as                                         IS_DELETED
      , PROPERTIES_CONTEXT_TRAITS_EMAIL
    FROM SRC_SRH
)

, LOGIC_SP as (
    SELECT
        REVIEW_ID
    FROM SRC_SP
)
---- RENAME LAYER ----

, RENAME_SRH as (
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
      , PROPERTIES_CONTEXT_TRAITS_EMAIL
    FROM LOGIC_SRH
)

, RENAME_HP as (
    SELECT
        HP_PRODUCT_HK
      , PRODUCT_BK
      , RETAILER_BK
      , BKCC
      , BRAND_BK
    FROM LOGIC_HP
)

, RENAME_SPD as (
    SELECT
        SPD_PRODUCT_HK
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
    FROM LOGIC_SPD
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

, FILTER_SPD as (
    SELECT *
    FROM RENAME_SPD
)

, FILTER_SRH as (
    SELECT *
    FROM RENAME_SRH
)

, FILTER_SP as (
    SELECT *
    FROM RENAME_SP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HP
    INNER JOIN FILTER_SPD
        ON HP_PRODUCT_HK = SPD_PRODUCT_HK
    INNER JOIN FILTER_SRH
        ON HP_PRODUCT_HK = PRODUCT_HK
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
        , 'DELIGHTED'                                                  as SOURCE
        , PRODUCT_ID
        , IS_DELETED
        , CASE WHEN REVIEW_ID IS NULL THEN 'N' ELSE 'Y' END            as SENTIMENT_PROCESSED
        , 'NOT APPLICABLE'                                             as PURCHASE_SOURCE
        , 'NOT APPLICABLE'                                             as PURCHASE_SOURCE_EXTRA_TEXT
        , CAST('Not Applicable' AS TEXT)                                           as SURVEY_TYPE
        , UPPER(PROPERTIES_CONTEXT_TRAITS_EMAIL)                       as RESPONDENT_EMAIL
FROM JOIN_RESULT

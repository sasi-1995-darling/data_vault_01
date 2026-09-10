{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HP             as ( SELECT * FROM {{ ref('hub_product_v2') }} as SRC  ),
SRC_SPD            as ( SELECT * FROM {{ ref('sat_product__delighted') }} as SRC 
                        qualify 1= row_number() over(partition by PRODUCT_HK order by psa_load_dts DESC) ),
SRC_SRS            as ( SELECT * FROM {{ ref('sat_response__sws_delighted') }} as SRC 
                        qualify 1= row_number() over(partition by ID order by PSA_LOAD_DTS DESC) ),
SRC_SP             as ( SELECT * FROM {{ ref('ref_sentiment_processed') }} as SRC 
                        WHERE UPPER(REVIEW_SOURCE_ID) = 'DELIGHTED' ),
SRC_SRA            as ( SELECT * FROM {{ ref('sat_response_answer__sws_delighted') }} as SRC 
                        WHERE FIVETRAN_DELETED = 'FALSE'
                        qualify 1= row_number() over(partition by RESPONSE_ID order by PSA_LOAD_DTS DESC) ),
SRC_SRAS           as ( SELECT * FROM {{ ref('sat_response_answer_selection__sws_delighted') }} as SRC 
                        WHERE FIVETRAN_DELETED = 'FALSE'
                        qualify 1= row_number() over(partition by RESPONSE_ANSWER_ID order by PSA_LOAD_DTS DESC) )

/*
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PRODUCT_V2 )
SRC_SPD            as ( SELECT * FROM raw_vault.SAT_PRODUCT__DELIGHTED )
SRC_SRS            as ( SELECT * FROM raw_vault.SAT_RESPONSE__SWS_DELIGHTED )
SRC_SP             as ( SELECT * FROM bus_vault.REF_SENTIMENT_PROCESSED )
SRC_SRA            as ( SELECT * FROM raw_vault.SAT_RESPONSE_ANSWER__SWS_DELIGHTED )
SRC_SRAS           as ( SELECT * FROM raw_vault.SAT_RESPONSE_ANSWER_SELECTION__SWS_DELIGHTED )
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

, LOGIC_SRS as (
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
    FROM SRC_SRS
)

, LOGIC_SP as (
    SELECT
        REVIEW_ID
    FROM SRC_SP
)

, LOGIC_SRA as (
    SELECT
        PRODUCT_HK                                                   as                                     SRA_PRODUCT_HK
      , ID                                                           as                                             SRA_ID
      , RESPONSE_ID
      , EMAIL
    FROM SRC_SRA
)

, LOGIC_SRAS as (
    SELECT
        PRODUCT_HK                                                   as                                    SRAS_PRODUCT_HK
      , TEXT                                                         as                                    PURCHASE_SOURCE
      , RESPONSE_ANSWER_ID
      , EXTRA_TEXT                                                   as                         PURCHASE_SOURCE_EXTRA_TEXT
    FROM SRC_SRAS
)
---- RENAME LAYER ----

, RENAME_SRS as (
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
    FROM LOGIC_SRS
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

, RENAME_SRA as (
    SELECT
        SRA_PRODUCT_HK
      , SRA_ID
      , RESPONSE_ID
      , EMAIL
    FROM LOGIC_SRA
)

, RENAME_SRAS as (
    SELECT
        SRAS_PRODUCT_HK
      , PURCHASE_SOURCE
      , RESPONSE_ANSWER_ID
      , PURCHASE_SOURCE_EXTRA_TEXT
    FROM LOGIC_SRAS
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

, FILTER_SRS as (
    SELECT *
    FROM RENAME_SRS
)

, FILTER_SP as (
    SELECT *
    FROM RENAME_SP
)

, FILTER_SRA as (
    SELECT *
    FROM RENAME_SRA
)

, FILTER_SRAS as (
    SELECT *
    FROM RENAME_SRAS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HP
    INNER JOIN FILTER_SPD
        ON HP_PRODUCT_HK = SPD_PRODUCT_HK
    INNER JOIN FILTER_SRS
        ON HP_PRODUCT_HK = PRODUCT_HK
    LEFT JOIN FILTER_SP
        ON UKEY = REVIEW_ID
    LEFT JOIN FILTER_SRA
        ON UKEY = RESPONSE_ID
    LEFT JOIN FILTER_SRAS
        ON SRA_ID = RESPONSE_ANSWER_ID
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
        , PURCHASE_SOURCE
        , PURCHASE_SOURCE_EXTRA_TEXT
        , CAST('Shutoff (30-day)' AS TEXT)                             as SURVEY_TYPE
        , UPPER(EMAIL)                                                 as RESPONDENT_EMAIL
FROM JOIN_RESULT

{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LNK            as ( SELECT QUESTION_HK, RESPONSE_HK, SURVEY_HK, SURVEY_QUESTION_RESPONSE_ANSWER_HK FROM {{ ref('lnk_survey_question_response_answer') }} as SRC  ),
SRC_SSD            as ( SELECT BKCC, BRAND_NAME, NAME, REC_SRC, SURVEY_HK FROM {{ ref('msat_survey_details__simplesat_yale') }} as SRC 
                           WHERE UPPER(NAME) NOT LIKE '%TEST%'
                        qualify 1= row_number() over(partition by SURVEY_HK order by psa_load_dts DESC) ),
SRC_SRD            as ( SELECT CREATED, CUSTOMER_NAME, MODIFIED, PRODUCT_BK, PRODUCT_HK, RESPONSE_HK FROM {{ ref('msat_response_details__simplesat_yale') }} as SRC 
                        qualify 1= row_number() over(partition by RESPONSE_HK order by psa_load_dts DESC) ),
SRC_LSAT           as ( SELECT CHOICE_LABEL, CHOICE, FOLLOW_UP_ANSWER, RESPONSE_ID, SURVEY_QUESTION_RESPONSE_ANSWER_HK FROM {{ ref('lmsat_survey_question_response_answer__simplesat_yale') }} as SRC
                        where CHOICE_LABEL IN ('Detractor', 'Promoter','Passive')
                        qualify 1= row_number() over(partition by SURVEY_QUESTION_RESPONSE_ANSWER_HK order by psa_load_dts DESC) ),
SRC_SQD            as ( SELECT QUESTION_HK FROM {{ ref('msat_question_details__simplesat_yale') }} as SRC
                        qualify 1= row_number() over(partition by QUESTION_HK order by psa_load_dts DESC) ),
SRC_SP             as ( SELECT REVIEW_ID FROM {{ ref('ref_sentiment_processed') }} as SRC 
                        WHERE UPPER(REVIEW_SOURCE_ID) = 'SIMPLESAT' )

/*
SRC_LNK            as ( SELECT * FROM raw_vault.LNK_SURVEY_QUESTION_RESPONSE_ANSWER )
SRC_SSD            as ( SELECT * FROM raw_vault.SAT_SURVEY_DETAILS__SIMPLESAT_YALE )
SRC_SRD            as ( SELECT * FROM raw_vault.SAT_RESPONSE_DETAILS__SIMPLESAT_YALE )
SRC_LSAT           as ( SELECT * FROM raw_vault.LSAT_SURVEY_QUESTION_RESPONSE_ANSWER__SIMPLESAT_YALE )
SRC_SQD            as ( SELECT * FROM raw_vault.SAT_QUESTION_DETAILS__SIMPLESAT_YALE )
SRC_SP             as ( SELECT * FROM bus_vault.REF_SENTIMENT_PROCESSED )
*/
---- LOGIC LAYER ----

, LOGIC_LNK as (
    SELECT
        QUESTION_HK                                                  as                                  LNK_QUESTION_HK
      , SURVEY_HK                                                    as                                      LNK_SURVEY_HK
      , RESPONSE_HK                                                  as                                    LNK_RESPONSE_HK
      , SURVEY_QUESTION_RESPONSE_ANSWER_HK                           as             LNK_SURVEY_QUESTION_RESPONSE_ANSWER_HK
    FROM SRC_LNK
)

, LOGIC_SSD as (
    SELECT
        BKCC
      , REC_SRC
      , BRAND_NAME                                                   as                                           BRAND_BK
      , CASE
            WHEN UPPER(TRIM(NAME)) LIKE '%10%DAY%'  THEN 'NPS (10-day)'
            WHEN UPPER(TRIM(NAME)) LIKE '%180%DAY%' THEN 'NPS (180-day)'
        ELSE NULL END                                                  as                                        SURVEY_TYPE
      , SURVEY_HK                                                    as                                      SSD_SURVEY_HK
      , NAME
    FROM SRC_SSD
)

, LOGIC_SRD as (
    SELECT
        (COALESCE(TO_CHAR(TO_TIMESTAMP(CREATED),'YYYYMMDD'), '19000101'))::INTEGER as                                    REVIEW_DATE_KEY
      , CUSTOMER_NAME                                                as                                             AUTHOR
      , (TO_CHAR(TO_TIMESTAMP(CREATED),'YYYYMMDD'))::INTEGER         as                                  DB_CREATED_AT_KEY
      , (TO_CHAR(TO_TIMESTAMP(MODIFIED),'YYYYMMDD'))::INTEGER        as                                UPDATED_AT_DATE_KEY
      , ''                                                           as                                            COUNTRY
      , CREATED
      , MODIFIED
      , RESPONSE_HK                                                  as                                    SRD_RESPONSE_HK
      , PRODUCT_BK                                                   as                                         PRODUCT_BK
      , PRODUCT_HK                                                   as                                         PRODUCT_HK
    FROM SRC_SRD
)

, LOGIC_LSAT as (
    SELECT
        FOLLOW_UP_ANSWER                                             as                                        REVIEW_TEXT
      , CHOICE                                                       as                                        STAR_RATING
      , TO_VARCHAR(RESPONSE_ID)                                      as                                               UKEY
      , RESPONSE_ID
      , SURVEY_QUESTION_RESPONSE_ANSWER_HK                           as            LSAT_SURVEY_QUESTION_RESPONSE_ANSWER_HK
    FROM SRC_LSAT
)

, LOGIC_SQD as (
    SELECT
        QUESTION_HK                                                  as                                  SQD_QUESTION_HK
    FROM SRC_SQD
)

, LOGIC_SP as (
    SELECT
        REVIEW_ID
    FROM SRC_SP
)
---- RENAME LAYER ----

, RENAME_SSD as (
    SELECT
        BKCC
      , REC_SRC
      , BRAND_BK
      , SURVEY_TYPE
      , SSD_SURVEY_HK
      , NAME
    FROM LOGIC_SSD
)

, RENAME_SRD as (
    SELECT
        REVIEW_DATE_KEY
      , AUTHOR
      , DB_CREATED_AT_KEY
      , UPDATED_AT_DATE_KEY
      , COUNTRY
      , CREATED
      , MODIFIED
      , SRD_RESPONSE_HK
      , PRODUCT_BK
      , PRODUCT_HK
    FROM LOGIC_SRD
)

, RENAME_LSAT as (
    SELECT
        REVIEW_TEXT
      , STAR_RATING
      , UKEY
      , RESPONSE_ID
      , LSAT_SURVEY_QUESTION_RESPONSE_ANSWER_HK
    FROM LOGIC_LSAT
)

, RENAME_SQD as (
    SELECT
        SQD_QUESTION_HK
    FROM LOGIC_SQD
)

, RENAME_SP as (
    SELECT
        REVIEW_ID
    FROM LOGIC_SP
)

, RENAME_LNK as (
    SELECT
        LNK_QUESTION_HK
      , LNK_SURVEY_HK
      , LNK_RESPONSE_HK
      , LNK_SURVEY_QUESTION_RESPONSE_ANSWER_HK
    FROM LOGIC_LNK
)
---- FILTER LAYER ----

, FILTER_LNK as (
    SELECT *
    FROM RENAME_LNK
)

, FILTER_SSD as (
    SELECT *
    FROM RENAME_SSD
)

, FILTER_SRD as (
    SELECT *
    FROM RENAME_SRD
)

, FILTER_LSAT as (
    SELECT *
    FROM RENAME_LSAT
)

, FILTER_SQD as (
    SELECT *
    FROM RENAME_SQD
)

, FILTER_SP as (
    SELECT *
    FROM RENAME_SP
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LNK
    INNER JOIN FILTER_SSD
        ON LNK_SURVEY_HK = SSD_SURVEY_HK
    INNER JOIN FILTER_SRD
        ON LNK_RESPONSE_HK = SRD_RESPONSE_HK
    INNER JOIN FILTER_LSAT
        ON LNK_SURVEY_QUESTION_RESPONSE_ANSWER_HK = LSAT_SURVEY_QUESTION_RESPONSE_ANSWER_HK
    INNER JOIN FILTER_SQD
        ON LNK_QUESTION_HK = SQD_QUESTION_HK
    LEFT JOIN FILTER_SP
        ON UKEY = REVIEW_ID
)

---- FINAL LAYER ----
SELECT
          PRODUCT_BK
        , '0'                                                          as RETAILER_BK
        , PRODUCT_BK                                                   as CUSTOMER_PRODUCT_ID
        , BKCC
        , REC_SRC
        , REVIEW_DATE_KEY
        , ''                                                           as REVIEW_TITLE
        , REVIEW_TEXT
        , STAR_RATING
        , ''                                                           as REVIEW_URL
        , UKEY
        , AUTHOR
        , DB_CREATED_AT_KEY
        , UPDATED_AT_DATE_KEY
        , COUNTRY
        , BRAND_BK
        , ''                                                           as MANUFACTURER_COMMENT_TEXT
        , ('0')::INTEGER                                               as MANUFACTURER_COMMENT_DATE_KEY
        , 'SIMPLESAT'                                                  as SOURCE
        , PRODUCT_BK                                                   as PRODUCT_ID
        , 'FALSE'                                                      as IS_DELETED
        , CASE WHEN REVIEW_ID IS NULL THEN 'N' ELSE 'Y' END            as SENTIMENT_PROCESSED
        , 'NOT APPLICABLE'                                             as PURCHASE_SOURCE
        , 'NOT APPLICABLE'                                             as PURCHASE_SOURCE_EXTRA_TEXT
        , SURVEY_TYPE
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(0 as VARCHAR)),''), '^^')
        ))) as PRODUCT_RETAILER_HK
        , PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(0 as VARCHAR)),''), '^^')
        ))) as RETAILER_HK
FROM JOIN_RESULT
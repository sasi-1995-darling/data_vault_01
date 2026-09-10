---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT * FROM {{ source('ft_bazaarvoice_yale', 'review') }} as SRC  ),
SRC_A1             as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM ft_bazaarvoice_yale.review )
, SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        PRODUCT_ID                                                   as                                         PRODUCT_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , ID
      , CONTEXT_DATA_VALUES
      , TAG_DIMENSIONS
      , COMMENT_IDS
      , SECONDARY_RATINGS_ORDER
      , CONTEXT_DATA_VALUES_ORDER
      , BADGES_ORDER
      , ADDITIONAL_FIELDS_ORDER
      , INAPPROPRIATE_FEEDBACK_LIST
      , LAST_MODIFICATION_TIME
      , BADGES
      , PHOTOS
      , VIDEOS
      , ADDITIONAL_FIELDS
      , TAG_DIMENSIONS_ORDER
      , SECONDARY_RATINGS
      , _FIVETRAN_DELETED
      , PRODUCT_ID
      , _FIVETRAN_SYNCED
      , IS_SYNDICATED
      , SOURCE_CLIENT
      , RATING
      , TITLE
      , TOTAL_FEEDBACK_COUNT
      , PRODUCT_RECOMMENDATION_IDS
      , TOTAL_INAPPROPRIATE_FEEDBACK_COUNT
      , SUBMISSION_ID
      , ORIGINAL_PRODUCT_NAME
      , TOTAL_NEGATIVE_FEEDBACK_COUNT
      , RATING_RANGE
      , USER_NICKNAME
      , CONTENT_LOCALE
      , CAMPAIGN_ID
      , IS_RATINGS_ONLY
      , TOTAL_CLIENT_RESPONSE_COUNT
      , TOTAL_POSITIVE_FEEDBACK_COUNT
      , IS_RECOMMENDED
      , TOTAL_COMMENT_COUNT
      , SUBMISSION_TIME
      , MODERATION_STATUS
      , REVIEW_TEXT
      , USER_LOCATION
      , LAST_MODERATED_TIME
      , AUTHOR_ID
      , IS_FEATURED
      , CID
      , HELPFULNESS
      , CUSTOM_SYNDICATION_SOURCE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
        PRODUCT_BK
      , LOAD_DTS
      , ID
      , CONTEXT_DATA_VALUES
      , TAG_DIMENSIONS
      , COMMENT_IDS
      , SECONDARY_RATINGS_ORDER
      , CONTEXT_DATA_VALUES_ORDER
      , BADGES_ORDER
      , ADDITIONAL_FIELDS_ORDER
      , INAPPROPRIATE_FEEDBACK_LIST
      , LAST_MODIFICATION_TIME
      , BADGES
      , PHOTOS
      , VIDEOS
      , ADDITIONAL_FIELDS
      , TAG_DIMENSIONS_ORDER
      , SECONDARY_RATINGS
      , _FIVETRAN_DELETED
      , PRODUCT_ID
      , _FIVETRAN_SYNCED
      , IS_SYNDICATED
      , SOURCE_CLIENT
      , RATING
      , TITLE
      , TOTAL_FEEDBACK_COUNT
      , PRODUCT_RECOMMENDATION_IDS
      , TOTAL_INAPPROPRIATE_FEEDBACK_COUNT
      , SUBMISSION_ID
      , ORIGINAL_PRODUCT_NAME
      , TOTAL_NEGATIVE_FEEDBACK_COUNT
      , RATING_RANGE
      , USER_NICKNAME
      , CONTENT_LOCALE
      , CAMPAIGN_ID
      , IS_RATINGS_ONLY
      , TOTAL_CLIENT_RESPONSE_COUNT
      , TOTAL_POSITIVE_FEEDBACK_COUNT
      , IS_RECOMMENDED
      , TOTAL_COMMENT_COUNT
      , SUBMISSION_TIME
      , MODERATION_STATUS
      , REVIEW_TEXT
      , USER_LOCATION
      , LAST_MODERATED_TIME
      , AUTHOR_ID
      , IS_FEATURED
      , CID
      , HELPFULNESS
      , CUSTOM_SYNDICATION_SOURCE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
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
    WHERE rec_src = 'US.BAZAARVOICE_YALE.REVIEW'
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
          PRODUCT_BK
        , LOAD_DTS
        , ID
        , CONTEXT_DATA_VALUES
        , TAG_DIMENSIONS
        , COMMENT_IDS
        , SECONDARY_RATINGS_ORDER
        , CONTEXT_DATA_VALUES_ORDER
        , BADGES_ORDER
        , ADDITIONAL_FIELDS_ORDER
        , INAPPROPRIATE_FEEDBACK_LIST
        , LAST_MODIFICATION_TIME
        , BADGES
        , PHOTOS
        , VIDEOS
        , ADDITIONAL_FIELDS
        , TAG_DIMENSIONS_ORDER
        , SECONDARY_RATINGS
        , _FIVETRAN_DELETED
        , PRODUCT_ID
        , _FIVETRAN_SYNCED
        , IS_SYNDICATED
        , SOURCE_CLIENT
        , RATING
        , TITLE
        , TOTAL_FEEDBACK_COUNT
        , PRODUCT_RECOMMENDATION_IDS
        , TOTAL_INAPPROPRIATE_FEEDBACK_COUNT
        , SUBMISSION_ID
        , ORIGINAL_PRODUCT_NAME
        , TOTAL_NEGATIVE_FEEDBACK_COUNT
        , RATING_RANGE
        , USER_NICKNAME
        , CONTENT_LOCALE
        , CAMPAIGN_ID
        , IS_RATINGS_ONLY
        , TOTAL_CLIENT_RESPONSE_COUNT
        , TOTAL_POSITIVE_FEEDBACK_COUNT
        , IS_RECOMMENDED
        , TOTAL_COMMENT_COUNT
        , SUBMISSION_TIME
        , MODERATION_STATUS
        , REVIEW_TEXT
        , USER_LOCATION
        , LAST_MODERATED_TIME
        , AUTHOR_ID
        , IS_FEATURED
        , CID
        , HELPFULNESS
        , CUSTOM_SYNDICATION_SOURCE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ID::text), '^^') 
            , '||', IFNULL(TRIM(CONTEXT_DATA_VALUES::text), '^^') 
            , '||', IFNULL(TRIM(TAG_DIMENSIONS::text), '^^') 
            , '||', IFNULL(TRIM(COMMENT_IDS::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_RATINGS_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(CONTEXT_DATA_VALUES_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(BADGES_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(ADDITIONAL_FIELDS_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(INAPPROPRIATE_FEEDBACK_LIST::text), '^^') 
            , '||', IFNULL(TRIM(LAST_MODIFICATION_TIME::text), '^^') 
            , '||', IFNULL(TRIM(BADGES::text), '^^') 
            , '||', IFNULL(TRIM(PHOTOS::text), '^^') 
            , '||', IFNULL(TRIM(VIDEOS::text), '^^') 
            , '||', IFNULL(TRIM(ADDITIONAL_FIELDS::text), '^^') 
            , '||', IFNULL(TRIM(TAG_DIMENSIONS_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_RATINGS::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_ID::text), '^^') 
            , '||', IFNULL(TRIM(IS_SYNDICATED::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_CLIENT::text), '^^') 
            , '||', IFNULL(TRIM(RATING::text), '^^') 
            , '||', IFNULL(TRIM(TITLE::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_FEEDBACK_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_RECOMMENDATION_IDS::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_INAPPROPRIATE_FEEDBACK_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(SUBMISSION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_PRODUCT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_NEGATIVE_FEEDBACK_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(RATING_RANGE::text), '^^') 
            , '||', IFNULL(TRIM(USER_NICKNAME::text), '^^') 
            , '||', IFNULL(TRIM(CONTENT_LOCALE::text), '^^') 
            , '||', IFNULL(TRIM(CAMPAIGN_ID::text), '^^') 
            , '||', IFNULL(TRIM(IS_RATINGS_ONLY::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_CLIENT_RESPONSE_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_POSITIVE_FEEDBACK_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(IS_RECOMMENDED::text), '^^') 
            , '||', IFNULL(TRIM(TOTAL_COMMENT_COUNT::text), '^^') 
            , '||', IFNULL(TRIM(SUBMISSION_TIME::text), '^^') 
            , '||', IFNULL(TRIM(MODERATION_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(REVIEW_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(USER_LOCATION::text), '^^') 
            , '||', IFNULL(TRIM(LAST_MODERATED_TIME::text), '^^') 
            , '||', IFNULL(TRIM(AUTHOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(IS_FEATURED::text), '^^') 
            , '||', IFNULL(TRIM(CID::text), '^^') 
            , '||', IFNULL(TRIM(HELPFULNESS::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOM_SYNDICATION_SOURCE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_BK,ID ORDER BY LOAD_DTS desc, psa_load_dts desc ))=1
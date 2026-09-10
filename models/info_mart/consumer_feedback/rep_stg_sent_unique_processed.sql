{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_SSM            as ( SELECT * FROM {{ ref('v_psa_stg_sentiment_subcategory_mapping') }} as SRC  ),
SRC_IR             as ( SELECT * FROM {{ ref('v_psa_stg_invalid_review') }} as SRC  )

/*
SRC_SSM            as ( SELECT * FROM sentiment_psa.v_psa_stg_sentiment_subcategory_mapping )
, SRC_IR             as ( SELECT * FROM consumer_feedback.v_psa_stg_invalid_review )
*/
---- LOGIC LAYER ----

, LOGIC_SSM as (
    SELECT
        REVIEW_ID
      , REVIEW_SOURCE_ID
    FROM SRC_SSM
)

, LOGIC_IR as (
    SELECT
        REVIEW_ID
      , REVIEW_SOURCE_ID
    FROM SRC_IR
)
---- RENAME LAYER ----

, RENAME_SSM as (
    SELECT
        REVIEW_ID
      , REVIEW_SOURCE_ID
    FROM LOGIC_SSM
)

, RENAME_IR as (
    SELECT
        REVIEW_ID
      , REVIEW_SOURCE_ID
    FROM LOGIC_IR
)
---- FILTER LAYER ----

, FILTER_SSM as (
    SELECT *
    FROM RENAME_SSM
)

, FILTER_IR as (
    SELECT *
    FROM RENAME_IR
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SSM
    UNION ALL
    SELECT * FROM FILTER_IR
)

---- FINAL LAYER ----
SELECT
          REVIEW_ID
        , REVIEW_SOURCE_ID
FROM JOIN_RESULT
GROUP BY REVIEW_ID, REVIEW_SOURCE_ID
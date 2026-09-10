---- SRC LAYER ----
WITH
SRC_ReWin as (
    select *
    from {{ ref('v_psa_stg_prod_retailer_review__winn_profitero') }} as src
    {% if is_incremental() %}
      where src.load_dts >= (
        select dateadd(
          'hour',
          -1,
          max(load_dts)
        )
        from {{ this }}
        where rec_src = 'US.PROFITERO_WINN.REVIEWS'
      )
    {% endif %}
),

SRC_ReSec as (
    select *
    from {{ ref('v_psa_stg_prod_retailer_review__security_profitero') }} as src
    {% if is_incremental() %}
      where src.load_dts >= (
        select dateadd(
          'hour',
          -1,
          max(load_dts)
        )
        from {{ this }}
        where rec_src = 'US.PROFITERO_SECURITY.REVIEWS'
      )
    {% endif %}
),

SRC_ReFy as (
    select *
    from {{ ref('v_psa_stg_prod_retailer_review__fypon_profitero') }} as src
    {% if is_incremental() %}
      where src.load_dts >= (
        select dateadd(
          'hour',
          -1,
          max(load_dts)
        )
        from {{ this }}
        where rec_src = 'US.PROFITERO_FYPON.REVIEWS'
      )
    {% endif %}
),

SRC_ReFib as (
    select *
    from {{ ref('v_psa_stg_prod_retailer_review__fiberon_profitero') }} as src
    {% if is_incremental() %}
      where src.load_dts >= (
        select dateadd(
          'hour',
          -1,
          max(load_dts)
        )
        from {{ this }}
        where rec_src = 'US.PROFITERO_FIBERON.REVIEWS'
      )
    {% endif %}
),

SRC_ReTT as (
    select *
    from {{ ref('v_psa_stg_prod_retailer_review__thermatru_profitero') }} as src
    {% if is_incremental() %}
      where src.load_dts >= (
        select dateadd(
          'hour',
          -1,
          max(load_dts)
        )
        from {{ this }}
        where rec_src = 'US.PROFITERO_THERMATRU.REVIEWS'
      )
    {% endif %}
),

SRC_ReLar as (
    select *
    from {{ ref('v_psa_stg_prod_retailer_review__larson_profitero') }} as src
    {% if is_incremental() %}
      where src.load_dts >= (
        select dateadd(
          'hour',
          -1,
          max(load_dts)
        )
        from {{ this }}
        where rec_src = 'US.PROFITERO_LARSON.REVIEWS'
      )
    {% endif %}
)

/*
SRC_ReWin          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__winn_profitero )
SRC_ReSec          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__security_profitero )
SRC_ReFy           as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__fypon_profitero )
SRC_ReFib          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__fiberon_profitero )
SRC_ReTT           as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__thermatru_profitero )
SRC_ReLar          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__larson_profitero )
*/
---- LOGIC LAYER ----

, LOGIC_ReWin as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , SUMMARY
      , TEXT
      , STAR_RATING
      , "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_ReWin
)

, LOGIC_ReSec as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , SUMMARY
      , TEXT
      , STAR_RATING
      , "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_ReSec
)

, LOGIC_ReFy as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , SUMMARY
      , TEXT
      , STAR_RATING
      , "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_ReFy
)

, LOGIC_ReFib as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , SUMMARY
      , TEXT
      , STAR_RATING
      , "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_ReFib
)

, LOGIC_ReTT as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , SUMMARY
      , TEXT
      , STAR_RATING
      , "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_ReTT
)

, LOGIC_ReLar as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , SUMMARY
      , TEXT
      , STAR_RATING
      , "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM SRC_ReLar
)
---- RENAME LAYER ----

, RENAME_ReWin as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , SUMMARY
      , TEXT
      , STAR_RATING
      , "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_ReWin
)

, RENAME_ReSec as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , SUMMARY
      , TEXT
      , STAR_RATING
      , "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_ReSec
)

, RENAME_ReFy as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , SUMMARY
      , TEXT
      , STAR_RATING
      , "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_ReFy
)

, RENAME_ReFib as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , SUMMARY
      , TEXT
      , STAR_RATING
      , "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_ReFib
)

, RENAME_ReTT as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , SUMMARY
      , TEXT
      , STAR_RATING
      , "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_ReTT
)

, RENAME_ReLar as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , SUMMARY
      , TEXT
      , STAR_RATING
      , "UNIQUE"
      , DUPLICATE_GROUP
      , REVIEW_URL
      , MANUFACTURER_COMMENT
      , MANUFACTURER_COMMENT_TEXT
      , MANUFACTURER_COMMENT_DATE
      , HAS_IMAGE
      , RETAILER_ID
      , UKEY
      , AUTHOR
      , DB_CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , BKCC
      , REC_SRC
      , HASHDIFF
    FROM LOGIC_ReLar
)
---- FILTER LAYER ----

, FILTER_ReWin as (
    SELECT *
    FROM RENAME_ReWin
)

, FILTER_ReSec as (
    SELECT *
    FROM RENAME_ReSec
)

, FILTER_ReFy as (
    SELECT *
    FROM RENAME_ReFy
)

, FILTER_ReFib as (
    SELECT *
    FROM RENAME_ReFib
)

, FILTER_ReTT as (
    SELECT *
    FROM RENAME_ReTT
)

, FILTER_ReLar as (
    SELECT *
    FROM RENAME_ReLar
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_ReWin
    UNION ALL
    SELECT * FROM FILTER_ReSec
    UNION ALL
    SELECT * FROM FILTER_ReFy
    UNION ALL
    SELECT * FROM FILTER_ReFib
    UNION ALL
    SELECT * FROM FILTER_ReTT
    UNION ALL
    SELECT * FROM FILTER_ReLar
)

---- FINAL LAYER ----
SELECT
          PRODUCT_RETAILER_HK
        , LOAD_DTS
        , DATE
        , CUSTOMER_PRODUCT_ID
        , PRODUCT_ID
        , SUMMARY
        , TEXT
        , STAR_RATING
        , "UNIQUE"
        , DUPLICATE_GROUP
        , REVIEW_URL
        , MANUFACTURER_COMMENT
        , MANUFACTURER_COMMENT_TEXT
        , MANUFACTURER_COMMENT_DATE
        , HAS_IMAGE
        , RETAILER_ID
        , UKEY
        , AUTHOR
        , DB_CREATED_AT
        , UPDATED_AT
        , IS_DELETED
        , BKCC
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCT_RETAILER_HK = JOIN_RESULT.PRODUCT_RETAILER_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by PRODUCT_RETAILER_HK, HASHDIFF order by LOAD_DTS)
{% if not is_incremental() %} 
union all
SELECT
MD5_BINARY(GR.VALUE) AS PRODUCT_RETAILER_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, null as DATE
, null as CUSTOMER_PRODUCT_ID
, GR.VALUE  as PRODUCT_ID
, null as SUMMARY
, null as TEXT
, null as STAR_RATING
, null as "UNIQUE"
, GR.VALUE as DUPLICATE_GROUP
, null as REVIEW_URL
, null as MANUFACTURER_COMMENT
, null as MANUFACTURER_COMMENT_TEXT
, null as MANUFACTURER_COMMENT_DATE
, null as HAS_IMAGE
, null as RETAILER_ID
, GR.VALUE  as UKEY
, null as AUTHOR
, null as DB_CREATED_AT
, null as UPDATED_AT
, null as IS_DELETED
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}
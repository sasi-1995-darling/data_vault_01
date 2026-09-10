---- SRC LAYER ----
WITH
SRC_ReApp          as   ( {% if not is_incremental() %}
                            SELECT * FROM {{ ref('v_psa_stg_prod_retailer_review__appbot') }} as SRC 
                        {% else %}
                            SELECT * FROM {{ this }} where false
                        {% endif %}                           
                        ),
SRC_ReAppFT        as ( SELECT * FROM {{ ref('v_psa_stg_prod_retailer_review__appbot_fivetran') }} as SRC 
                           {% if is_incremental() %}
                                where
                                    src.load_dts >= (
                                        select
                                            coalesce(
                                                dateadd('hour', -1, max(load_dts)), '1900-01-01'::timestamp
                                            )
                                        from {{ this }}
                                        where rec_src = 'US.APPBOT_FT.REVIEWS'
                                    )
                            {% endif %}   )

/*
SRC_ReApp          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__appbot )
SRC_ReAppFT        as ( SELECT * FROM staging.v_psa_stg_prod_retailer_review__appbot_fivetran )
*/
---- LOGIC LAYER ----

, LOGIC_ReApp as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , APP_ID
      , APP_STORE_ID
      , ID
      , AUTHOR
      , RATING
      , BODY
      , SUBJECT
      , PUBLISHED_AT
      , PUBLISHED_AT_DATETIME
      , VERSION
      , COUNTRY
      , COUNTRY_ID
      , COUNTRY_CODE
      , TRANSLATED_SUBJECT
      , TRANSLATED_BODY
      , REPLY_TEXT
      , REPLY_DATE
      , TOPICS
      , TOPIC_IDS
      , STORE_ID
      , DEVICE
      , DEVICE_FRIENDLY_NAME
      , OS_VERSION
      , OS_VERSION_FRIENDLY_NAME
      , SENTIMENT
      , DETECTED_LANGUAGE
      , DETECTED_LANGUAGE_ID
      , PERMALINK_URL
      , REPLY_URL
      , INTERNAL_URL
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_ReApp
)

, LOGIC_ReAppFT as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , APP_ID
      , APP_STORE_ID
      , ID
      , AUTHOR
      , RATING
      , BODY
      , SUBJECT
      , PUBLISHED_AT
      , PUBLISHED_AT_DATETIME
      , VERSION
      , COUNTRY
      , COUNTRY_ID
      , COUNTRY_CODE
      , TRANSLATED_SUBJECT
      , TRANSLATED_BODY
      , REPLY_TEXT
      , REPLY_DATE
      , TOPICS
      , TOPIC_IDS
      , STORE_ID
      , DEVICE
      , DEVICE_FRIENDLY_NAME
      , OS_VERSION
      , OS_VERSION_FRIENDLY_NAME
      , SENTIMENT
      , DETECTED_LANGUAGE
      , DETECTED_LANGUAGE_ID
      , PERMALINK_URL
      , REPLY_URL
      , INTERNAL_URL
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_ReAppFT
)
---- RENAME LAYER ----

, RENAME_ReApp as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , APP_ID
      , APP_STORE_ID
      , ID
      , AUTHOR
      , RATING
      , BODY
      , SUBJECT
      , PUBLISHED_AT
      , PUBLISHED_AT_DATETIME
      , VERSION
      , COUNTRY
      , COUNTRY_ID
      , COUNTRY_CODE
      , TRANSLATED_SUBJECT
      , TRANSLATED_BODY
      , REPLY_TEXT
      , REPLY_DATE
      , TOPICS
      , TOPIC_IDS
      , STORE_ID
      , DEVICE
      , DEVICE_FRIENDLY_NAME
      , OS_VERSION
      , OS_VERSION_FRIENDLY_NAME
      , SENTIMENT
      , DETECTED_LANGUAGE
      , DETECTED_LANGUAGE_ID
      , PERMALINK_URL
      , REPLY_URL
      , INTERNAL_URL
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_ReApp
)

, RENAME_ReAppFT as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , APP_ID
      , APP_STORE_ID
      , ID
      , AUTHOR
      , RATING
      , BODY
      , SUBJECT
      , PUBLISHED_AT
      , PUBLISHED_AT_DATETIME
      , VERSION
      , COUNTRY
      , COUNTRY_ID
      , COUNTRY_CODE
      , TRANSLATED_SUBJECT
      , TRANSLATED_BODY
      , REPLY_TEXT
      , REPLY_DATE
      , TOPICS
      , TOPIC_IDS
      , STORE_ID
      , DEVICE
      , DEVICE_FRIENDLY_NAME
      , OS_VERSION
      , OS_VERSION_FRIENDLY_NAME
      , SENTIMENT
      , DETECTED_LANGUAGE
      , DETECTED_LANGUAGE_ID
      , PERMALINK_URL
      , REPLY_URL
      , INTERNAL_URL
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_ReAppFT
)
---- FILTER LAYER ----

, FILTER_ReApp as (
    SELECT *
    FROM RENAME_ReApp
)

, FILTER_ReAppFT as (
    SELECT *
    FROM RENAME_ReAppFT
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_ReApp
    UNION ALL
    SELECT * FROM FILTER_ReAppFT
)

---- FINAL LAYER ----
SELECT
          PRODUCT_RETAILER_HK
        , LOAD_DTS
        , APP_ID
        , APP_STORE_ID
        , ID
        , AUTHOR
        , RATING
        , BODY
        , SUBJECT
        , PUBLISHED_AT
        , PUBLISHED_AT_DATETIME
        , VERSION
        , COUNTRY
        , COUNTRY_ID
        , COUNTRY_CODE
        , TRANSLATED_SUBJECT
        , TRANSLATED_BODY
        , REPLY_TEXT
        , REPLY_DATE
        , TOPICS
        , TOPIC_IDS
        , STORE_ID
        , DEVICE
        , DEVICE_FRIENDLY_NAME
        , OS_VERSION
        , OS_VERSION_FRIENDLY_NAME
        , SENTIMENT
        , DETECTED_LANGUAGE
        , DETECTED_LANGUAGE_ID
        , PERMALINK_URL
        , REPLY_URL
        , INTERNAL_URL
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
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
qualify 1= row_number()over(partition by PRODUCT_RETAILER_HK, HASHDIFF order by PUBLISHED_AT, LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS PRODUCT_RETAILER_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, null as APP_ID
, null as APP_STORE_ID
, GR.VALUE as ID
, null as AUTHOR
, null as RATING
, null as BODY
, null as SUBJECT
, null as PUBLISHED_AT
, null as PUBLISHED_AT_DATETIME
, null as VERSION
, GR.VALUE as COUNTRY
, null as COUNTRY_ID
, null as COUNTRY_CODE
, null as TRANSLATED_SUBJECT
, null as TRANSLATED_BODY
, null as REPLY_TEXT
, null as REPLY_DATE
, null as TOPICS
, null as TOPIC_IDS
, null as STORE_ID
, null as DEVICE
, null as DEVICE_FRIENDLY_NAME
, null as OS_VERSION
, null as OS_VERSION_FRIENDLY_NAME
, null as SENTIMENT
, null as DETECTED_LANGUAGE
, null as DETECTED_LANGUAGE_ID
, null as PERMALINK_URL
, null as REPLY_URL
, null as INTERNAL_URL
,'1900-01-01'::TIMESTAMP_LTZ as PSA_LOAD_DTS
, null as PSA_RECORD_SOURCE
, null as PSA_DELETE_IND

, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}
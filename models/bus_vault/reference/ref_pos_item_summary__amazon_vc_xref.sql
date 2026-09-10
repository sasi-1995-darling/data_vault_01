---- SRC LAYER ----
WITH
SRC_ISA            as ( SELECT * FROM {{ ref('v_psa_stg_item_summary__amazon_vc') }} as SRC 
                        qualify row_number() over(partition by asin, marketplace_id order by load_dts desc)=1 )

/*
SRC_ISA            as ( SELECT * FROM staging.v_psa_stg_item_summary__amazon_vc )
*/
---- LOGIC LAYER ----

, LOGIC_ISA as (
    SELECT
        AMAZON_ASIN_HK
      , AMAZON_MODEL_NUM_HK
      , ASIN
      , MODEL_NUMBER
      , LOAD_DTS
      , MARKETPLACE_ID
      , ADULT_PRODUCT
      , AUTOGRAPHED
      , BRAND
      , DISPLAY_NAME
      , CLASSIFICATION_ID
      , COLOR
      , CONTRIBUTORS
      , ITEM_CLASSIFICATION
      , ITEM_NAME
      , MANUFACTURER
      , MEMORABILIA
      , PACKAGE_QUANTITY
      , PART_NUMBER
      , RELEASE_DATE
      , SIZE
      , STYLE
      , TRADE_IN_ELIGIBLE
      , WEBSITE_DISPLAY_GROUP
      , WEBSITE_DISPLAY_GROUP_NAME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_ISA
)
---- RENAME LAYER ----

, RENAME_ISA as (
    SELECT
        AMAZON_ASIN_HK
      , AMAZON_MODEL_NUM_HK
      , ASIN
      , MODEL_NUMBER
      , LOAD_DTS
      , MARKETPLACE_ID
      , ADULT_PRODUCT
      , AUTOGRAPHED
      , BRAND
      , DISPLAY_NAME
      , CLASSIFICATION_ID
      , COLOR
      , CONTRIBUTORS
      , ITEM_CLASSIFICATION
      , ITEM_NAME
      , MANUFACTURER
      , MEMORABILIA
      , PACKAGE_QUANTITY
      , PART_NUMBER
      , RELEASE_DATE
      , SIZE
      , STYLE
      , TRADE_IN_ELIGIBLE
      , WEBSITE_DISPLAY_GROUP
      , WEBSITE_DISPLAY_GROUP_NAME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_ISA
)
---- FILTER LAYER ----

, FILTER_ISA as (
    SELECT *
    FROM RENAME_ISA
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_ISA
)

---- FINAL LAYER ----
SELECT
          AMAZON_ASIN_HK
        , AMAZON_MODEL_NUM_HK
        , ASIN
        , MODEL_NUMBER
        , LOAD_DTS
        , MARKETPLACE_ID
        , ADULT_PRODUCT
        , AUTOGRAPHED
        , BRAND
        , DISPLAY_NAME
        , CLASSIFICATION_ID
        , COLOR
        , CONTRIBUTORS
        , ITEM_CLASSIFICATION
        , ITEM_NAME
        , MANUFACTURER
        , MEMORABILIA
        , PACKAGE_QUANTITY
        , PART_NUMBER
        , RELEASE_DATE
        , SIZE
        , STYLE
        , TRADE_IN_ELIGIBLE
        , WEBSITE_DISPLAY_GROUP
        , WEBSITE_DISPLAY_GROUP_NAME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT

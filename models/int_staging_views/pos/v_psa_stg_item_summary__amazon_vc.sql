---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('amazon_sp_ft_psa', 'item_summary') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM amazon_sp_ft_psa.item_summary )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        ASIN
      , MODEL_NUMBER
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
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
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        ASIN
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
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'US.API.AMAZON_VC.ITEM_SUMMARY'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ASIN
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
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ASIN as VARCHAR)),''), '^^')
        ))) as AMAZON_ASIN_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(MODEL_NUMBER as VARCHAR)),''), '^^')
        ))) as AMAZON_MODEL_NUM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(MARKETPLACE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ADULT_PRODUCT::text), '^^') 
            , '||', IFNULL(TRIM(AUTOGRAPHED::text), '^^') 
            , '||', IFNULL(TRIM(BRAND::text), '^^') 
            , '||', IFNULL(TRIM(DISPLAY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CLASSIFICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(COLOR::text), '^^') 
            , '||', IFNULL(TRIM(CONTRIBUTORS::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CLASSIFICATION::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_NAME::text), '^^') 
            , '||', IFNULL(TRIM(MANUFACTURER::text), '^^') 
            , '||', IFNULL(TRIM(MEMORABILIA::text), '^^') 
            , '||', IFNULL(TRIM(PACKAGE_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(PART_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(RELEASE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SIZE::text), '^^') 
            , '||', IFNULL(TRIM(STYLE::text), '^^') 
            , '||', IFNULL(TRIM(TRADE_IN_ELIGIBLE::text), '^^') 
            , '||', IFNULL(TRIM(WEBSITE_DISPLAY_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(WEBSITE_DISPLAY_GROUP_NAME::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

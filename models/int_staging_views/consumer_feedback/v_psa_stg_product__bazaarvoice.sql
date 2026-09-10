---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT * FROM {{ source('bazaarvoice_psa', 'product') }} as SRC  ),
SRC_A1             as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S1             as ( SELECT * FROM bazaarvoice_psa.product )
, SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        ID                                                           as                                         PRODUCT_BK
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , ID
      , BRAND
      , PRODUCT_PAGE_URL
      , MANUFACTURER_PART_NUMBERS
      , MODEL_NUMBERS
      , FAMILY_IDS
      , BRAND_EXTERNAL_ID
      , QUESTION_IDS
      , ATTRIBUTES
      , UPCS
      , ATTRIBUTES_ORDER
      , ISBNS
      , EANS
      , STORY_IDS
      , _FIVETRAN_DELETED
      , CATEGORY_ID
      , _FIVETRAN_SYNCED
      , IMAGE_URL
      , ACTIVE
      , DESCRIPTION
      , NAME
      , DISABLED
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
      , BRAND
      , PRODUCT_PAGE_URL
      , MANUFACTURER_PART_NUMBERS
      , MODEL_NUMBERS
      , FAMILY_IDS
      , BRAND_EXTERNAL_ID
      , QUESTION_IDS
      , ATTRIBUTES
      , UPCS
      , ATTRIBUTES_ORDER
      , ISBNS
      , EANS
      , STORY_IDS
      , _FIVETRAN_DELETED
      , CATEGORY_ID
      , _FIVETRAN_SYNCED
      , IMAGE_URL
      , ACTIVE
      , DESCRIPTION
      , NAME
      , DISABLED
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
    WHERE rec_src = 'US.BAZAARVOICE.PRODUCT'
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
        , BRAND
        , PRODUCT_PAGE_URL
        , MANUFACTURER_PART_NUMBERS
        , MODEL_NUMBERS
        , FAMILY_IDS
        , BRAND_EXTERNAL_ID
        , QUESTION_IDS
        , ATTRIBUTES
        , UPCS
        , ATTRIBUTES_ORDER
        , ISBNS
        , EANS
        , STORY_IDS
        , _FIVETRAN_DELETED
        , CATEGORY_ID
        , _FIVETRAN_SYNCED
        , IMAGE_URL
        , ACTIVE
        , DESCRIPTION
        , NAME
        , DISABLED
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
            , '||', IFNULL(TRIM(BRAND::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_PAGE_URL::text), '^^') 
            , '||', IFNULL(TRIM(MANUFACTURER_PART_NUMBERS::text), '^^') 
            , '||', IFNULL(TRIM(MODEL_NUMBERS::text), '^^') 
            , '||', IFNULL(TRIM(FAMILY_IDS::text), '^^') 
            , '||', IFNULL(TRIM(BRAND_EXTERNAL_ID::text), '^^') 
            , '||', IFNULL(TRIM(QUESTION_IDS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTES::text), '^^') 
            , '||', IFNULL(TRIM(UPCS::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTES_ORDER::text), '^^') 
            , '||', IFNULL(TRIM(ISBNS::text), '^^') 
            , '||', IFNULL(TRIM(EANS::text), '^^') 
            , '||', IFNULL(TRIM(STORY_IDS::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(IMAGE_URL::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVE::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(NAME::text), '^^') 
            , '||', IFNULL(TRIM(DISABLED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_s              as ( SELECT BRAND, BUSINESS_ID, CATEGORY, CLASS, CREATE_DATE, ITEM, ITEM_DESCRIPTION, ITEM_IDENTIFIER, LAST_RUN_DATE, LAST_UPDATE_DATE, MATERIAL_TYPE, 
                        MERGED_BUSINESS_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, SOURCE_CREATION_DATE, SOURCE_LAST_UPDATED_DATE, SOURCE_PKEY, SOURCE_SYSTEM, 
                        SUBCATEGORY, SUBCLASS FROM {{ source('mdm_product_category', 'outbound_item_product_category') }} as SRC
                        /*where multiple records exist pull the most recently updated at source*/
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY UPPER(TRIM(ITEM)), BRAND ORDER BY SOURCE_LAST_UPDATED_DATE desc)  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_s              as ( SELECT * FROM mdm_product_category.outbound_item_product_category )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        BUSINESS_ID
      , ITEM_IDENTIFIER
      , ITEM
      , CATEGORY                                                     as                                         S_CATEGORY
      , SUBCATEGORY                                                  as                                      S_SUBCATEGORY
      , CLASS                                                        as                                            S_CLASS
      , SUBCLASS                                                     as                                         S_SUBCLASS
      , CREATE_DATE
      , LAST_UPDATE_DATE
      , LAST_RUN_DATE
      , ITEM_DESCRIPTION                                             as                                 S_ITEM_DESCRIPTION
      , MATERIAL_TYPE                                                as                                    S_MATERIAL_TYPE
      , BRAND
      , SOURCE_SYSTEM
      , MERGED_BUSINESS_ID
      , SOURCE_PKEY
      , SOURCE_CREATION_DATE
      , SOURCE_LAST_UPDATED_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , TO_TIMESTAMP_TZ(SOURCE_LAST_UPDATED_DATE, 'MM/DD/YYYY HH24:MI:SS.FF') as                                 LOAD_DTS
    FROM SRC_s
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        BUSINESS_ID
      , ITEM_IDENTIFIER
      , ITEM
      , S_CATEGORY
      , S_SUBCATEGORY
      , S_CLASS
      , S_SUBCLASS
      , CREATE_DATE
      , LAST_UPDATE_DATE
      , LAST_RUN_DATE
      , S_ITEM_DESCRIPTION
      , S_MATERIAL_TYPE
      , BRAND
      , SOURCE_SYSTEM
      , MERGED_BUSINESS_ID
      , SOURCE_PKEY
      , SOURCE_CREATION_DATE
      , SOURCE_LAST_UPDATED_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_s
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USILCHI.INFORMATICA.MDM.OUTBOUND_ITEM_PRODUCT_CATEGORY'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          UPPER(TRIM(ITEM))                                            as ITEM_BK
        , BUSINESS_ID
        , ITEM_IDENTIFIER
        , ITEM
        , S_CATEGORY
        , UPPER(TRIM(S_CATEGORY))                                      as CATEGORY
        , S_SUBCATEGORY
        , UPPER(TRIM(S_SUBCATEGORY))                                   as SUBCATEGORY
        , S_CLASS
        , UPPER(TRIM(S_CLASS))                                         as CLASS
        , S_SUBCLASS
        , UPPER(TRIM(S_SUBCLASS))                                      as SUBCLASS
        , CREATE_DATE
        , LAST_UPDATE_DATE
        , LAST_RUN_DATE
        , S_ITEM_DESCRIPTION
        , UPPER(TRIM(S_ITEM_DESCRIPTION))                              as ITEM_DESCRIPTION
        , S_MATERIAL_TYPE
        , UPPER(TRIM(S_MATERIAL_TYPE))                                 as MATERIAL_TYPE
        , BRAND
        , SOURCE_SYSTEM
        , MERGED_BUSINESS_ID
        , SOURCE_PKEY
        , SOURCE_CREATION_DATE
        , SOURCE_LAST_UPDATED_DATE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(BUSINESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_IDENTIFIER::text), '^^') 
            , '||', IFNULL(TRIM(ITEM::text), '^^') 
            , '||', IFNULL(TRIM(S_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(S_SUBCATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(S_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(S_SUBCLASS::text), '^^') 
            , '||', IFNULL(TRIM(CREATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_RUN_DATE::text), '^^') 
            , '||', IFNULL(TRIM(S_ITEM_DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(S_MATERIAL_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(BRAND::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_SYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(MERGED_BUSINESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_PKEY::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_LAST_UPDATED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

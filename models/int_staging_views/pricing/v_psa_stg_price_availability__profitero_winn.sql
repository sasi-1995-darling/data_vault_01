---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('profitero', 'price_availability_history') }} as SRC  ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_R              as ( SELECT * FROM {{ source('profitero', 'retailers') }} as SRC 
                        where psa_delete_ind='N'
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY id ORDER BY PSA_LOAD_DTS DESC ))=1 )

/*
SRC_S              as ( SELECT * FROM profitero.price_availability_history )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_R              as ( SELECT * FROM profitero.retailers )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(CUSTOMER_PRODUCT_ID), ''), '-1')        as                                         PRODUCT_BK
      , CONVERT_TIMEZONE('UTC', IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, updated_at)) as                                           LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID::VARCHAR                                 as                                CUSTOMER_PRODUCT_ID
      , RETAILER_ID::VARCHAR                                         as                                        RETAILER_ID
      , PRODUCT_ID::VARCHAR                                          as                                         PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_S
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)

, LOGIC_R as (
    SELECT
        coalesce(nullif(trim(NAME), ''), '-1')                       as                                        RETAILER_BK
      , ID                                                           as                                      R_retailer_id
    FROM SRC_R
)
---- RENAME LAYER ----

, RENAME_R as (
    SELECT
        RETAILER_BK
      , R_retailer_id
    FROM LOGIC_R
)

, RENAME_S as (
    SELECT
        PRODUCT_BK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , RETAILER_ID
      , PRODUCT_ID
      , UPDATED_AT
      , AVAILABILITY
      , MATCH_TYPE
      , REGULAR_PRICE
      , PROMOTION_TEXT
      , PROMOTION_PRICE
      , FIRST_PARTY_WON_BUY_BOX
      , THIRD_PARTY_SELLER
      , ADD_ON_ITEM
      , PRIME_EXCLUSIVE
      , PROMO_TYPE
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_S
)

, RENAME_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
    WHERE psa_delete_ind='N'
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'US.PROFITERO_WINN.PRICING_AVAILABILITY_HISTORY'
)

, FILTER_R as (
    SELECT *
    FROM RENAME_R
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_a
        ON '1' = '1'
    INNER JOIN FILTER_R
        ON retailer_id = R_retailer_id
)

---- FINAL LAYER ----
SELECT
          RETAILER_BK
        , PRODUCT_BK
        , LOAD_DTS
        , DATE
        , CUSTOMER_PRODUCT_ID
        , RETAILER_ID
        , PRODUCT_ID
        , UPDATED_AT
        , AVAILABILITY
        , MATCH_TYPE
        , REGULAR_PRICE
        , PROMOTION_TEXT
        , PROMOTION_PRICE
        , FIRST_PARTY_WON_BUY_BOX
        , THIRD_PARTY_SELLER
        , ADD_ON_ITEM
        , PRIME_EXCLUSIVE
        , PROMO_TYPE
        , R_RETAILER_ID
        , IS_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_RETAILER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RETAILER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RETAILER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(UPDATED_AT::text), '^^') 
            , '||', IFNULL(TRIM(AVAILABILITY::text), '^^') 
            , '||', IFNULL(TRIM(MATCH_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(REGULAR_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(PROMOTION_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(PROMOTION_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(FIRST_PARTY_WON_BUY_BOX::text), '^^') 
            , '||', IFNULL(TRIM(THIRD_PARTY_SELLER::text), '^^') 
            , '||', IFNULL(TRIM(ADD_ON_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(PRIME_EXCLUSIVE::text), '^^') 
            , '||', IFNULL(TRIM(PROMO_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(IS_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

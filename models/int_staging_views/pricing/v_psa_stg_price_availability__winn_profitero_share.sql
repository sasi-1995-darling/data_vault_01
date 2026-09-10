---- SRC LAYER ----
WITH
SRC_S              as ( SELECT DIM_DATE_KEY, DIM_ACCOUNT_PRODUCT_KEY, DIM_RETAILER_KEY, DIM_RETAILER_LOCATION_KEY, AVAILABILITY, REGULAR_PRICE, PROMOTION_TEXT, PROMOTION_PRICE, FIRST_PARTY_WON_BUY_BOX, THIRD_PARTY_SELLER, PRIME_EXCLUSIVE, PROMO_TYPE, UPDATED_AT, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND FROM {{ source('profitero_share_moen', 'dim_product_history') }} as SRC  ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_DD             as ( SELECT DIM_DATE_KEY, DT_DATE FROM {{ source('profitero_share_moen', 'dim_date') }} as SRC  ),
SRC_AP             as ( SELECT DIM_ACCOUNT_PRODUCT_KEY, ACCOUNT_PRODUCT_ID, UPDATED_AT, PSA_LOAD_DTS, PSA_DELETE_IND
                FROM {{ source('profitero_share_moen', 'dim_account_product') }} as SRC
                QUALIFY NOT (PSA_DELETE_IND = 'Y'
                             AND MIN(PSA_DELETE_IND) OVER(PARTITION BY DIM_ACCOUNT_PRODUCT_KEY, PSA_LOAD_DTS) = 'N')
                   AND (ROW_NUMBER() OVER(PARTITION BY DIM_ACCOUNT_PRODUCT_KEY ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC ))=1 ),
SRC_R              as ( SELECT DIM_RETAILER_KEY, RETAILER_NAME, UPDATED_AT, PSA_LOAD_DTS, PSA_DELETE_IND
                FROM {{ source('profitero_share_moen', 'dim_retailer') }} as SRC
                QUALIFY NOT (PSA_DELETE_IND = 'Y'
                             AND MIN(PSA_DELETE_IND) OVER(PARTITION BY DIM_RETAILER_KEY, PSA_LOAD_DTS) = 'N')
                   AND (ROW_NUMBER() OVER(PARTITION BY DIM_RETAILER_KEY ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC ))=1 )
, SRC_RL             as ( SELECT DIM_RETAILER_LOCATION_KEY, RETAILER_LOCATION_NAME, UPDATED_AT, PSA_LOAD_DTS, PSA_DELETE_IND
                FROM {{ source('profitero_share_moen', 'dim_retailer_location') }} as SRC
                QUALIFY NOT (PSA_DELETE_IND = 'Y'
                             AND MIN(PSA_DELETE_IND) OVER(PARTITION BY DIM_RETAILER_LOCATION_KEY, PSA_LOAD_DTS) = 'N')
                   AND (ROW_NUMBER() OVER(PARTITION BY DIM_RETAILER_LOCATION_KEY ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC ))=1 )

/*
SRC_S              as ( SELECT * FROM profitero_share_moen.dim_product_history )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_DD             as ( SELECT * FROM profitero_share_moen.dim_date )
, SRC_AP             as ( SELECT * FROM profitero_share_moen.dim_account_product )
, SRC_R              as ( SELECT * FROM profitero_share_moen.dim_retailer )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        coalesce(nullif(trim(ap.ACCOUNT_PRODUCT_ID::VARCHAR), ''), '-1')  as                                         PRODUCT_BK
      , CONVERT_TIMEZONE('UTC', s.PSA_LOAD_DTS)                          as                                           LOAD_DTS
      , dd.DT_DATE                                                        as                                               DATE
      , ap.ACCOUNT_PRODUCT_ID::VARCHAR                                   as                                CUSTOMER_PRODUCT_ID
      , s.DIM_RETAILER_KEY::VARCHAR                                      as                                        RETAILER_ID
      , ap.ACCOUNT_PRODUCT_ID::VARCHAR                                   as                                         PRODUCT_ID
      , s.UPDATED_AT
      , s.AVAILABILITY
      , NULL::VARCHAR                                                     as                                         MATCH_TYPE
      , s.REGULAR_PRICE
      , s.PROMOTION_TEXT
      , s.PROMOTION_PRICE
      , s.FIRST_PARTY_WON_BUY_BOX
      , s.THIRD_PARTY_SELLER
      , NULL::BOOLEAN                                                     as                                        ADD_ON_ITEM
      , s.PRIME_EXCLUSIVE
      , s.PROMO_TYPE
      , FALSE                                                             as                                         IS_DELETED
      , s.PSA_LOAD_DTS
      , ap.PSA_LOAD_DTS                                                  as                                  AP_PSA_LOAD_DTS
      , s.PSA_RECORD_SOURCE
      , s.PSA_DELETE_IND
      , s.DIM_RETAILER_LOCATION_KEY
    FROM SRC_S s
    LEFT JOIN SRC_DD dd
        ON s.DIM_DATE_KEY = dd.DIM_DATE_KEY
    LEFT JOIN SRC_AP ap
        ON s.DIM_ACCOUNT_PRODUCT_KEY = ap.DIM_ACCOUNT_PRODUCT_KEY
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)

, LOGIC_R as (
    SELECT
        coalesce(nullif(trim(RETAILER_NAME), ''), '-1')                  as                                        RETAILER_BK
      , RETAILER_NAME
      , DIM_RETAILER_KEY::VARCHAR                                        as                                      R_retailer_id
      , PSA_LOAD_DTS                                                     as                                   R_PSA_LOAD_DTS
    FROM SRC_R
)

, LOGIC_RL as (
    SELECT
        coalesce(nullif(trim(RETAILER_LOCATION_NAME), ''), '-1')              as                              RETAILER_LOCATION_BK
      , RETAILER_LOCATION_NAME
      , DIM_RETAILER_LOCATION_KEY                                          as                           RL_retailer_location_id
      , PSA_LOAD_DTS                                                         as                                RL_PSA_LOAD_DTS
    FROM SRC_RL
)
---- RENAME LAYER ----

, RENAME_R as (
    SELECT
        RETAILER_BK
      , RETAILER_NAME
      , R_retailer_id
      , R_PSA_LOAD_DTS
    FROM LOGIC_R
)

, RENAME_RL as (
    SELECT
        RETAILER_LOCATION_BK
      , RETAILER_LOCATION_NAME
      , RL_retailer_location_id
      , RL_PSA_LOAD_DTS
    FROM LOGIC_RL
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
      , AP_PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , DIM_RETAILER_LOCATION_KEY
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
    WHERE PSA_DELETE_IND = 'N'
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

, FILTER_RL as (
    SELECT *
    FROM RENAME_RL
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_R
        ON RETAILER_ID = R_retailer_id
    LEFT JOIN FILTER_RL
        ON DIM_RETAILER_LOCATION_KEY = RL_retailer_location_id
)

---- FINAL LAYER ----
SELECT
          COALESCE(RETAILER_BK, '-1')          AS RETAILER_BK
        , RETAILER_NAME
        , COALESCE(RETAILER_LOCATION_BK, '-1') AS RETAILER_LOCATION_BK
        , RETAILER_LOCATION_NAME
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
        , DIM_RETAILER_LOCATION_KEY
        , IS_DELETED
        , {{ greatest_date(['PSA_LOAD_DTS', 'AP_PSA_LOAD_DTS', 'R_PSA_LOAD_DTS', 'RL_PSA_LOAD_DTS']) }} as PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(RETAILER_LOCATION_NAME as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_RETAILER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PRODUCT_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PRODUCT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RETAILER_NAME as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RETAILER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(RETAILER_LOCATION_NAME as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as RETAILER_LOCATION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(AVAILABILITY::text), '^^')
            , '||', IFNULL(TRIM(REGULAR_PRICE::text), '^^')
            , '||', IFNULL(TRIM(PROMOTION_TEXT::text), '^^')
            , '||', IFNULL(TRIM(PROMOTION_PRICE::text), '^^')
            , '||', IFNULL(TRIM(FIRST_PARTY_WON_BUY_BOX::text), '^^')
            , '||', IFNULL(TRIM(THIRD_PARTY_SELLER::text), '^^')
            , '||', IFNULL(TRIM(PRIME_EXCLUSIVE::text), '^^')
            , '||', IFNULL(TRIM(PROMO_TYPE::text), '^^')
            , '||', IFNULL(TRIM(IS_DELETED::text), '^^')
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
---- SRC LAYER ----
WITH
SRC_S              as ( SELECT DIM_AMZ_PRODUCT_SALE_KEY, DIM_DATE_KEY, DIM_AMZ_PRODUCT_KEY, DIM_AMZ_CATEGORY_KEY, ACCOUNT_PRODUCT_ID, PLATFORM, FIRST_PARTY_SALES, THIRD_PARTY_SALES, TOTAL_SALES, FIRST_PARTY_UNITS, THIRD_PARTY_UNITS, TOTAL_UNITS, REPORTED_IN_ARA, CREATED_AT, UPDATED_AT, PSA_LOAD_DTS, PSA_RECORD_SOURCE, PSA_DELETE_IND
                        FROM {{ source('profitero_share_moen', 'dim_amz_product_sale') }} as SRC
                        -- DEDUP: this is intentional exact-row dedup, NOT business-key dedup — partition on the ENTIRE row (all descriptive attrs) to collapse exact-duplicate reloads from the source. Earliest PSA load wins on true attribute change; identical payloads reduce to one row.
                        qualify 1 = row_number() over (partition by dim_amz_product_sale_key, dim_date_key, dim_amz_product_key, dim_amz_category_key, account_product_id, platform, first_party_sales, third_party_sales, total_sales, first_party_units, third_party_units, total_units, reported_in_ara, created_at, updated_at  order by psa_delete_ind, psa_load_dts)  ),
SRC_P              as ( SELECT DIM_AMZ_PRODUCT_KEY, AMZ_PRODUCT_ID, PSA_DELETE_IND
                        FROM {{ source('profitero_share_moen', 'dim_amz_product') }} as SRC
                        QUALIFY ROW_NUMBER() OVER (PARTITION BY DIM_AMZ_PRODUCT_KEY ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC) = 1 ),
SRC_C              as ( SELECT DIM_AMZ_CATEGORY_KEY, AMZ_CATEGORY_ID, PSA_DELETE_IND
                        FROM {{ source('profitero_share_moen', 'dim_amz_category') }} as SRC
                        QUALIFY ROW_NUMBER() OVER (PARTITION BY DIM_AMZ_CATEGORY_KEY ORDER BY UPDATED_AT DESC, PSA_LOAD_DTS DESC) = 1 ),
SRC_D              as ( SELECT DIM_DATE_KEY, DT_DATE
                        FROM {{ source('profitero_share_moen', 'dim_date') }} as SRC
                        WHERE PSA_DELETE_IND = 'N' ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM profitero_share_moen.dim_amz_product_sale )
SRC_P              as ( SELECT * FROM profitero_share_moen.dim_amz_product )
SRC_C              as ( SELECT * FROM profitero_share_moen.dim_amz_category )
SRC_D              as ( SELECT * FROM profitero_share_moen.dim_date )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        COALESCE(p.AMZ_PRODUCT_ID, '-1')                              as                                            ASIN_BK
      , COALESCE(c.AMZ_CATEGORY_ID, '-1')::TEXT                       as                                    SNS_CATEGORY_BK
      , d.DT_DATE                                                     as                                               DATE
      , CONVERT_TIMEZONE('UTC', s.UPDATED_AT)                         as                                           LOAD_DTS
      , p.AMZ_PRODUCT_ID                                              as                                               ASIN
      , c.AMZ_CATEGORY_ID::VARCHAR                                    as                                    SNS_CATEGORY_ID
      , s.PLATFORM
      , s.FIRST_PARTY_SALES
      , s.THIRD_PARTY_SALES
      , s.TOTAL_SALES
      , s.FIRST_PARTY_UNITS
      , s.THIRD_PARTY_UNITS
      , s.TOTAL_UNITS
      , s.REPORTED_IN_ARA
      , s.UPDATED_AT
      , NULL::BOOLEAN                                                  as                                         IS_DELETED
      , s.PSA_LOAD_DTS
      , s.PSA_RECORD_SOURCE
      , s.PSA_DELETE_IND
      , s.ACCOUNT_PRODUCT_ID
      , s.CREATED_AT
      , s.DIM_AMZ_PRODUCT_SALE_KEY
      , s.DIM_DATE_KEY
      , s.DIM_AMZ_PRODUCT_KEY
      , s.DIM_AMZ_CATEGORY_KEY
    FROM SRC_S s
    INNER JOIN SRC_P p ON s.DIM_AMZ_PRODUCT_KEY = p.DIM_AMZ_PRODUCT_KEY and p.PSA_DELETE_IND = 'N'
    INNER JOIN SRC_C c ON s.DIM_AMZ_CATEGORY_KEY = c.DIM_AMZ_CATEGORY_KEY and c.PSA_DELETE_IND = 'N'
    INNER JOIN SRC_D d ON s.DIM_DATE_KEY = d.DIM_DATE_KEY
    WHERE s.PSA_DELETE_IND = 'N'
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
    WHERE REC_SRC = 'US.PROFITERO_SHARE_MOEN.DIM_AMZ_PRODUCT_SALE'
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        ASIN_BK
      , SNS_CATEGORY_BK
      , DATE
      , LOAD_DTS
      , ASIN
      , SNS_CATEGORY_ID
      , PLATFORM
      , FIRST_PARTY_SALES
      , THIRD_PARTY_SALES
      , TOTAL_SALES
      , FIRST_PARTY_UNITS
      , THIRD_PARTY_UNITS
      , TOTAL_UNITS
      , REPORTED_IN_ARA
      , CREATED_AT
      , UPDATED_AT
      , IS_DELETED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , DIM_AMZ_PRODUCT_SALE_KEY
      , DIM_DATE_KEY
      , DIM_AMZ_PRODUCT_KEY
      , DIM_AMZ_CATEGORY_KEY
      , ACCOUNT_PRODUCT_ID
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
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_a
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ASIN_BK
        , SNS_CATEGORY_BK
        , DATE
        , LOAD_DTS
        , ASIN
        , SNS_CATEGORY_ID
        , PLATFORM
        , FIRST_PARTY_SALES
        , THIRD_PARTY_SALES
        , TOTAL_SALES
        , FIRST_PARTY_UNITS
        , THIRD_PARTY_UNITS
        , TOTAL_UNITS
        , REPORTED_IN_ARA
        , CREATED_AT
        , UPDATED_AT
        , IS_DELETED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , DIM_AMZ_PRODUCT_SALE_KEY
        , DIM_DATE_KEY
        , DIM_AMZ_PRODUCT_KEY
        , DIM_AMZ_CATEGORY_KEY
        , ACCOUNT_PRODUCT_ID
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            IFNULL(TRIM(PLATFORM::TEXT),           '^^'),
            IFNULL(TRIM(FIRST_PARTY_SALES::TEXT),  '^^'),
            IFNULL(TRIM(THIRD_PARTY_SALES::TEXT),  '^^'),
            IFNULL(TRIM(TOTAL_SALES::TEXT),        '^^'),
            IFNULL(TRIM(FIRST_PARTY_UNITS::TEXT),  '^^'),
            IFNULL(TRIM(THIRD_PARTY_UNITS::TEXT),  '^^'),
            IFNULL(TRIM(TOTAL_UNITS::TEXT),        '^^'),
            IFNULL(TRIM(DIM_AMZ_PRODUCT_SALE_KEY::TEXT),        '^^'), 
            IFNULL(TRIM(DIM_DATE_KEY::TEXT),        '^^'), 
            IFNULL(TRIM(DIM_AMZ_PRODUCT_KEY::TEXT),        '^^'), 
            IFNULL(TRIM(DIM_AMZ_CATEGORY_KEY::TEXT),        '^^'), 
            IFNULL(TRIM(ACCOUNT_PRODUCT_ID::TEXT),        '^^'), 
            IFNULL(TRIM(REPORTED_IN_ARA::TEXT),    '^^')
          ))) as HASHDIFF
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(ASIN_BK AS VARCHAR)),           ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(SNS_CATEGORY_BK AS VARCHAR)),   ''), '^^'),
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)),              ''), '^^')
          ))) as ASIN_SNS_CATEGORY_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(ASIN_BK AS VARCHAR)),           ''), '^^'), 
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)),              ''), '^^')
          ))) as ASIN_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(SNS_CATEGORY_BK AS VARCHAR)),   ''), '^^'), 
            COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)),              ''), '^^')
          ))) as SNS_CATEGORY_HK
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_CS             as ( SELECT * FROM {{ ref('im_fact_competitive_share_weekly') }} as SRC  ),
SRC_D              as ( SELECT * FROM {{ ref('im_competitive_share_dim_brand_v2') }} as SRC  )

/*
SRC_CS             as ( SELECT * FROM infomart_prod.im_fact_competitive_share_weekly )
, SRC_D              as ( SELECT * FROM infomart_prod.IM_COMPETITIVE_SHARE_DIM_BRAND_V2 )
*/
---- LOGIC LAYER ----

, LOGIC_CS as (
    SELECT 
        BRAND_ID
      , PRODUCT_NAME
      , UPC
      , MODEL
      , DATE
      , ASIN
      , PLATFORM
      , SUM_FIRST_PARTY_SALES
      , SUM_THIRD_PARTY_SALES
      , SUM_TOTAL_SALES
      , SUM_FIRST_PARTY_UNITS
      , SUM_THIRD_PARTY_UNITS
      , SUM_TOTAL_UNITS
      , BRAND_BK
      , RETAILER
      , BUSINESS_UNIT
      , STORES       
      , SOURCE
    FROM SRC_CS
)

, LOGIC_D as (
    SELECT
        OWNER
      , SUBBRAND
      , BRAND_BK                                                     as                                         D_BRAND_BK
      , BRAND                                                        as                                            D_BRAND
    FROM SRC_D
)
---- RENAME LAYER ----

, RENAME_CS as (
    SELECT
        BRAND_ID
      , PRODUCT_NAME
      , UPC
      , MODEL
      , DATE
      , ASIN as RPC
      , PLATFORM
      , SUM_FIRST_PARTY_SALES
      , SUM_THIRD_PARTY_SALES
      , SUM_TOTAL_SALES
      , SUM_FIRST_PARTY_UNITS
      , SUM_THIRD_PARTY_UNITS
      , SUM_TOTAL_UNITS
      , BRAND_BK
      , RETAILER
      , BUSINESS_UNIT
      , STORES       
      , SOURCE
    FROM LOGIC_CS
)

, RENAME_D as (
    SELECT
        OWNER
      , SUBBRAND
      , D_BRAND_BK
      , D_BRAND
    FROM LOGIC_D
)
---- FILTER LAYER ----

, FILTER_CS as (
    SELECT *
    FROM RENAME_CS
)

, FILTER_D as (
    SELECT *
    FROM RENAME_D
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_CS
    LEFT JOIN FILTER_D
        ON BRAND_BK = D_BRAND_BK
)

---- FINAL LAYER ----
SELECT
          BRAND_ID
        , PRODUCT_NAME
        , UPC
        , MODEL
        , DATE
        , RPC
        , PLATFORM
        , SUM(SUM_FIRST_PARTY_SALES)            AS SUM_FIRST_PARTY_SALES
        , SUM(SUM_THIRD_PARTY_SALES)            AS SUM_THIRD_PARTY_SALES
        , SUM(SUM_TOTAL_SALES)                  AS SUM_TOTAL_SALES
        , SUM(SUM_FIRST_PARTY_UNITS)            AS SUM_FIRST_PARTY_UNITS
        , SUM(SUM_THIRD_PARTY_UNITS)            AS SUM_THIRD_PARTY_UNITS
        , SUM(SUM_TOTAL_UNITS)                  AS SUM_TOTAL_UNITS
        , BRAND_BK
        , OWNER
        , CASE WHEN SOURCE='DATAVATIONS' THEN BRAND_ID ELSE D_BRAND END as BRAND
        , SUBBRAND
        , RETAILER
        , BUSINESS_UNIT
        , SUM(STORES) STORES
        , SOURCE
FROM JOIN_RESULT
GROUP BY ALL

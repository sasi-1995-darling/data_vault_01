{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT BKCC, BRAND_BK, PRODUCT_BK, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_BK, RETAILER_HK, REVIEW_DATE_KEY, SOURCE, STAR_RATING, UKEY, UPDATED_AT_DATE_KEY FROM {{ ref('pb_product_review_v2') }} as SRC 
                        WHERE SOURCE IN ('DELIGHTED', 'BAZAARVOICE','SIMPLESAT') )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.PB_PRODUCT_REVIEW_V2 )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , PRODUCT_BK
      , RETAILER_BK
      , BKCC
      , REC_SRC
      , REVIEW_DATE_KEY
      , BRAND_BK
      , SOURCE
      , 'US'                                                         as                                            COUNTRY
      , STAR_RATING
      , UKEY
      , UPDATED_AT_DATE_KEY
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , PRODUCT_BK
      , RETAILER_BK
      , BKCC
      , REC_SRC
      , REVIEW_DATE_KEY
      , BRAND_BK
      , SOURCE
      , COUNTRY
      , STAR_RATING
      , UKEY
      , UPDATED_AT_DATE_KEY
    FROM LOGIC_PB
)
---- FILTER LAYER ----

, FILTER_PB as (
    SELECT *
    FROM RENAME_PB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PB
)

---- FINAL LAYER ----
SELECT
          PRODUCT_RETAILER_HK
        , PRODUCT_HK
        , RETAILER_HK
        , PRODUCT_BK
        , RETAILER_BK
        , BKCC
        , REC_SRC
        , REVIEW_DATE_KEY
        ,  AVG(CASE WHEN SOURCE IN ('DELIGHTED','SIMPLESAT') AND STAR_RATING in (10,9) then 5
                  WHEN SOURCE IN ('DELIGHTED','SIMPLESAT') AND STAR_RATING in (8,7) then 4
                  WHEN SOURCE IN ('DELIGHTED','SIMPLESAT') AND STAR_RATING in (6,5) then 3
                  WHEN SOURCE IN ('DELIGHTED','SIMPLESAT') AND STAR_RATING in (4,3) then 2
                  WHEN SOURCE IN ('DELIGHTED','SIMPLESAT') AND STAR_RATING in (2,1) then 1
                  WHEN SOURCE = 'BAZAARVOICE' AND STAR_RATING in (5) then 5
                  WHEN SOURCE = 'BAZAARVOICE' AND STAR_RATING in (4) then 4
                  WHEN SOURCE = 'BAZAARVOICE' AND STAR_RATING in (3) then 3
                  WHEN SOURCE = 'BAZAARVOICE' AND STAR_RATING in (2) then 2
                  WHEN SOURCE = 'BAZAARVOICE' AND STAR_RATING in (1) then 1
    else 0 end) as CUMULATIVE_STAR_RATING
        , COUNT(UKEY)                                                  as CUMULATIVE_REVIEWS
        , SUM(CASE WHEN SOURCE IN ('DELIGHTED','SIMPLESAT') AND STAR_RATING in (10,9) then 1 
                   WHEN SOURCE = 'BAZAARVOICE' AND STAR_RATING in (5) then 1
              else 0 end) as STAR_5
        , SUM(CASE WHEN SOURCE IN ('DELIGHTED','SIMPLESAT') AND STAR_RATING in (8,7) then 1 
                   WHEN SOURCE = 'BAZAARVOICE' AND STAR_RATING in (4) then 1
              else 0 end) as STAR_4
        , SUM(CASE WHEN SOURCE IN ('DELIGHTED','SIMPLESAT') AND STAR_RATING in (6,5) then 1 
                   WHEN SOURCE = 'BAZAARVOICE' AND STAR_RATING in (3) then 1
              else 0 end) as STAR_3
        , SUM(CASE WHEN SOURCE IN ('DELIGHTED','SIMPLESAT') AND STAR_RATING in (4,3) then 1 
                   WHEN SOURCE = 'BAZAARVOICE' AND STAR_RATING in (2) then 1
              else 0 end) as STAR_2
        , SUM(CASE WHEN SOURCE IN ('DELIGHTED','SIMPLESAT') AND STAR_RATING in (2,1) then 1 
                   WHEN SOURCE = 'BAZAARVOICE' AND STAR_RATING in (1) then 1
              else 0 end) as STAR_1
        , MAX(UPDATED_AT_DATE_KEY)                                     as UPDATED_AT
        , BRAND_BK
        , SOURCE
        , COUNTRY
FROM JOIN_RESULT
GROUP BY ALL
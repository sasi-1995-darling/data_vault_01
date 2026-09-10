{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LPR            as ( SELECT PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('lnk_product_retailer') }} as SRC  ),
SRC_HP             as ( SELECT BKCC, PRODUCT_BK, PRODUCT_HK FROM {{ ref('hub_product_v2') }} as SRC  ),
SRC_HR             as ( SELECT RETAILER_BK, RETAILER_HK FROM {{ ref('hub_retailer') }} as SRC  ),
SRC_LPRP           as ( SELECT * FROM {{ ref('lsat_product_rating__profitero_share') }} as SRC 
                        qualify 1= row_number() over(partition by product_retailer_hk, DATE order by UPDATED_AT DESC) ),
SRC_LPB            as ( SELECT BRAND_HK, PRODUCT_HK FROM {{ ref('lnk_product_brand') }} as SRC  ),
SRC_HB             as ( SELECT BRAND_BK, BRAND_HK FROM {{ ref('hub_brand_v2') }} as SRC  )

/*
SRC_LPR            as ( SELECT * FROM RAW_VAULT.LNK_PRODUCT_RETAILER )
SRC_HP             as ( SELECT * FROM RAW_VAULT.HUB_PRODUCT_V2 )
SRC_HR             as ( SELECT * FROM RAW_VAULT.HUB_RETAILER )
SRC_LPRP           as ( SELECT * FROM RAW_VAULT.LSAT_PRODUCT_RATING__PROFITERO_SHARE )
SRC_LPB            as ( SELECT * FROM RAW_VAULT.LNK_PRODUCT_BRAND )
SRC_HB             as ( SELECT * FROM RAW_VAULT.HUB_BRAND_V2 )
*/
---- LOGIC LAYER ----

, LOGIC_LPR as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , REC_SRC
    FROM SRC_LPR
)

, LOGIC_HP as (
    SELECT
        PRODUCT_HK                                                   as                                      HP_PRODUCT_HK
      , PRODUCT_BK
      , BKCC
    FROM SRC_HP
)

, LOGIC_HR as (
    SELECT
        RETAILER_HK                                                  as                                     HR_RETAILER_HK
      , RETAILER_BK
    FROM SRC_HR
)

, LOGIC_LPRP as (
    SELECT
        PRODUCT_RETAILER_HK                                          as                           LPRP_PRODUCT_RETAILER_HK
      , to_varchar(to_date(DATE), 'YYYYMMDD')                        as                                               DATE
      , COALESCE(CUMULATIVE_STAR_RATING,0)                           as                             CUMULATIVE_STAR_RATING
      , COALESCE(CUMULATIVE_REVIEWS,0)                               as                                 CUMULATIVE_REVIEWS
      , COALESCE(CUMULATIVE_5_STAR_REVIEWS,0)                        as                          CUMULATIVE_5_STAR_REVIEWS
      , COALESCE(CUMULATIVE_4_STAR_REVIEWS,0)                        as                          CUMULATIVE_4_STAR_REVIEWS
      , COALESCE(CUMULATIVE_3_STAR_REVIEWS,0)                        as                          CUMULATIVE_3_STAR_REVIEWS
      , COALESCE(CUMULATIVE_2_STAR_REVIEWS,0)                        as                          CUMULATIVE_2_STAR_REVIEWS
      , COALESCE(CUMULATIVE_1_STAR_REVIEWS,0)                        as                          CUMULATIVE_1_STAR_REVIEWS
      , to_varchar(to_date(UPDATED_AT), 'YYYYMMDD') as UPDATED_AT

    FROM SRC_LPRP
)

, LOGIC_LPB as (
    SELECT
        PRODUCT_HK                                                   as                                     LPB_PRODUCT_HK
      , BRAND_HK                                                     as                                       LPB_BRAND_HK
    FROM SRC_LPB
)

, LOGIC_HB as (
    SELECT
        BRAND_HK                                                     as                                        HB_BRAND_HK
      , BRAND_BK
    FROM SRC_HB
)
---- RENAME LAYER ----

, RENAME_LPR as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , REC_SRC
    FROM LOGIC_LPR
)

, RENAME_HP as (
    SELECT
        HP_PRODUCT_HK
      , PRODUCT_BK
      , BKCC
    FROM LOGIC_HP
)

, RENAME_HR as (
    SELECT
        HR_RETAILER_HK
      , RETAILER_BK
    FROM LOGIC_HR
)

, RENAME_LPRP as (
    SELECT
        LPRP_PRODUCT_RETAILER_HK
      , DATE
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , UPDATED_AT

    FROM LOGIC_LPRP
)

, RENAME_LPB as (
    SELECT
        LPB_PRODUCT_HK
      , LPB_BRAND_HK
    FROM LOGIC_LPB
)

, RENAME_HB as (
    SELECT
        HB_BRAND_HK
      , BRAND_BK
    FROM LOGIC_HB
)
---- FILTER LAYER ----

, FILTER_LPR as (
    SELECT *
    FROM RENAME_LPR
)

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_HR as (
    SELECT *
    FROM RENAME_HR
)

, FILTER_LPRP as (
    SELECT *
    FROM RENAME_LPRP
)

, FILTER_LPB as (
    SELECT *
    FROM RENAME_LPB
)

, FILTER_HB as (
    SELECT *
    FROM RENAME_HB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LPR
    INNER JOIN FILTER_HP
        ON FILTER_LPR.PRODUCT_HK = HP_PRODUCT_HK
    INNER JOIN FILTER_HR
        ON FILTER_LPR.RETAILER_HK = HR_RETAILER_HK
    INNER JOIN FILTER_LPRP
        ON FILTER_LPR.PRODUCT_RETAILER_HK = LPRP_PRODUCT_RETAILER_HK
    INNER JOIN FILTER_LPB
        ON HP_PRODUCT_HK = LPB_PRODUCT_HK
    INNER JOIN FILTER_HB
        ON LPB_BRAND_HK = HB_BRAND_HK
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
        , DATE
        , CUMULATIVE_STAR_RATING
        , CUMULATIVE_REVIEWS
        , CUMULATIVE_5_STAR_REVIEWS
        , CUMULATIVE_4_STAR_REVIEWS
        , CUMULATIVE_3_STAR_REVIEWS
        , CUMULATIVE_2_STAR_REVIEWS
        , CUMULATIVE_1_STAR_REVIEWS
        , CASE WHEN 
	(
		CUMULATIVE_1_STAR_REVIEWS - lag(CUMULATIVE_1_STAR_REVIEWS,1,CUMULATIVE_1_STAR_REVIEWS) 
            over (partition by  PRODUCT_RETAILER_HK
                                order by date
            )  
	) >=0 THEN
	(
		CUMULATIVE_1_STAR_REVIEWS - lag(CUMULATIVE_1_STAR_REVIEWS,1,CUMULATIVE_1_STAR_REVIEWS) 
            over (partition by  PRODUCT_RETAILER_HK
                                order by date
            ) 
          )
	ELSE 0 END as INCRE_1_STAR
        , CASE WHEN 
	(
		CUMULATIVE_2_STAR_REVIEWS - lag(CUMULATIVE_2_STAR_REVIEWS,1,CUMULATIVE_2_STAR_REVIEWS) 
            over (partition by  PRODUCT_RETAILER_HK
                                order by date
            )  
	) >=0 THEN
	(
		CUMULATIVE_2_STAR_REVIEWS - lag(CUMULATIVE_2_STAR_REVIEWS,1,CUMULATIVE_2_STAR_REVIEWS) 
            over (partition by  PRODUCT_RETAILER_HK
                                order by date
            ) 
          )
	ELSE 0 END as INCRE_2_STAR
        , CASE WHEN 
	(
		CUMULATIVE_3_STAR_REVIEWS - lag(CUMULATIVE_3_STAR_REVIEWS,1,CUMULATIVE_3_STAR_REVIEWS) 
            over (partition by  PRODUCT_RETAILER_HK
                                order by date
            )  
	) >=0 THEN
	(
		CUMULATIVE_3_STAR_REVIEWS - lag(CUMULATIVE_3_STAR_REVIEWS,1,CUMULATIVE_3_STAR_REVIEWS) 
            over (partition by  PRODUCT_RETAILER_HK
                                order by date
            ) 
          )
	ELSE 0 END as INCRE_3_STAR
        , CASE WHEN 
	(
		CUMULATIVE_4_STAR_REVIEWS - lag(CUMULATIVE_4_STAR_REVIEWS,1,CUMULATIVE_4_STAR_REVIEWS) 
            over (partition by  PRODUCT_RETAILER_HK
                                order by date
            )  
	) >=0 THEN
	(
		CUMULATIVE_4_STAR_REVIEWS - lag(CUMULATIVE_4_STAR_REVIEWS,1,CUMULATIVE_4_STAR_REVIEWS) 
            over (partition by  PRODUCT_RETAILER_HK
                                order by date
            ) 
          )
	ELSE 0 END as INCRE_4_STAR
        , CASE WHEN 
	(
		CUMULATIVE_5_STAR_REVIEWS - lag(CUMULATIVE_5_STAR_REVIEWS,1,CUMULATIVE_5_STAR_REVIEWS) 
            over (partition by  PRODUCT_RETAILER_HK
                                order by date
            )  
	) >=0 THEN
	(
		CUMULATIVE_5_STAR_REVIEWS - lag(CUMULATIVE_5_STAR_REVIEWS,1,CUMULATIVE_5_STAR_REVIEWS) 
            over (partition by  PRODUCT_RETAILER_HK
                                order by date
            ) 
          )
	ELSE 0 END as INCRE_5_STAR
        , UPDATED_AT
        , BRAND_BK
        , 'PROFITERO'                                                  as SOURCE
        , 'US'                                                         as COUNTRY
FROM JOIN_RESULT

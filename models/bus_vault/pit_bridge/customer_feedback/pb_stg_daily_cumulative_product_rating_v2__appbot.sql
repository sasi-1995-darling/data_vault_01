{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LPR            as ( SELECT * FROM {{ ref('lnk_product_retailer') }} as SRC  ),
SRC_HP             as ( SELECT * FROM {{ ref('hub_product_v2') }} as SRC  ),
SRC_SA             as ( SELECT * FROM {{ ref('sat_applist__appbot') }} as SRC 
                        qualify 1= row_number() over(partition by product_hk order by PSA_LOAD_DTS) ),
SRC_HR             as ( SELECT * FROM {{ ref('hub_retailer') }} as SRC  ),
SRC_LPRA           as ( SELECT * FROM {{ ref('lsat_product_rating__appbot') }} as SRC 
                        qualify 1= row_number() over(partition by product_retailer_hk, TO_DATE(CREATED_AT), COUNTRY order by CREATED_AT) ),
SRC_RBA            as ( SELECT * FROM {{ ref('ref_brand_appbot') }} as SRC  ),
SRC_HB             as ( SELECT * FROM {{ ref('hub_brand_v2') }} as SRC  )

/*
SRC_LPR            as ( SELECT * FROM RAW_VAULT.LNK_PRODUCT_RETAILER )
, SRC_HP             as ( SELECT * FROM RAW_VAULT.HUB_PRODUCT_V2 )
, SRC_SA             as ( SELECT * FROM RAW_VAULT.SAT_APPLIST__APPBOT )
, SRC_HR             as ( SELECT * FROM RAW_VAULT.HUB_RETAILER )
, SRC_LPRA           as ( SELECT * FROM RAW_VAULT.LSAT_PRODUCT_RATING__APPBOT )
, SRC_RBA            as ( SELECT * FROM bus_vault.ref_brand_appbot )
, SRC_HB             as ( SELECT * FROM RAW_VAULT.HUB_BRAND_V2 )
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

, LOGIC_SA as (
    SELECT
        NAME                                                         as                                            SA_NAME
      , PRODUCT_HK                                                   as                                      SA_PRODUCT_HK
    FROM SRC_SA
)

, LOGIC_HR as (
    SELECT
        RETAILER_HK                                                  as                                     HR_RETAILER_HK
      , RETAILER_BK
    FROM SRC_HR
)

, LOGIC_LPRA as (
    SELECT
        PRODUCT_RETAILER_HK                                          as                           LPRA_PRODUCT_RETAILER_HK
      , to_varchar(to_date(CREATED_AT), 'YYYYMMDD')                  as                                               DATE
      , AVG                                                          as                             CUMULATIVE_STAR_RATING
      , TOTAL                                                        as                                 CUMULATIVE_REVIEWS
      , STAR_5                                                       as                          CUMULATIVE_5_STAR_REVIEWS
      , STAR_4                                                       as                          CUMULATIVE_4_STAR_REVIEWS
      , STAR_3                                                       as                          CUMULATIVE_3_STAR_REVIEWS
      , STAR_2                                                       as                          CUMULATIVE_2_STAR_REVIEWS
      , STAR_1                                                       as                          CUMULATIVE_1_STAR_REVIEWS
      , STAR_5
      , STAR_4
      , STAR_3
      , STAR_2
      , STAR_1
      , to_varchar(to_date(CREATED_AT), 'YYYYMMDD')                  as                                         UPDATED_AT
      , COUNTRY
    FROM SRC_LPRA
)

, LOGIC_RBA as (
    SELECT
        APPBOT_PRODUCT
      , BRAND                                                        as                                          RBA_BRAND
    FROM SRC_RBA
)

, LOGIC_HB as (
    SELECT
        BRAND_HK
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

, RENAME_LPRA as (
    SELECT
        LPRA_PRODUCT_RETAILER_HK
      , DATE
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , STAR_5
      , STAR_4
      , STAR_3
      , STAR_2
      , STAR_1
      , UPDATED_AT
      , COUNTRY
    FROM LOGIC_LPRA
)

, RENAME_RBA as (
    SELECT
        APPBOT_PRODUCT
      , RBA_BRAND
    FROM LOGIC_RBA
)

, RENAME_HB as (
    SELECT
        BRAND_HK
      , BRAND_BK
    FROM LOGIC_HB
)

, RENAME_SA as (
    SELECT
        SA_NAME
      , SA_PRODUCT_HK
    FROM LOGIC_SA
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

, FILTER_SA as (
    SELECT *
    FROM RENAME_SA
)

, FILTER_HR as (
    SELECT *
    FROM RENAME_HR
)

, FILTER_LPRA as (
    SELECT *
    FROM RENAME_LPRA
)

, FILTER_RBA as (
    SELECT *
    FROM RENAME_RBA
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
    INNER JOIN FILTER_SA
        ON HP_PRODUCT_HK = SA_PRODUCT_HK
    INNER JOIN FILTER_HR
        ON FILTER_LPR.RETAILER_HK = HR_RETAILER_HK
    INNER JOIN FILTER_LPRA
        ON FILTER_LPR.PRODUCT_RETAILER_HK = LPRA_PRODUCT_RETAILER_HK
    INNER JOIN FILTER_RBA
        ON SA_NAME = APPBOT_PRODUCT
    INNER JOIN FILTER_HB
        ON RBA_BRAND = BRAND_BK
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
        , STAR_5
        , STAR_4
        , STAR_3
        , STAR_2
        , STAR_1
        , CASE WHEN 
	(
		STAR_1 - lag(STAR_1,1,STAR_1) 
            over (partition by  PRODUCT_RETAILER_HK, COUNTRY
                                order by date
            )  
	) >=0 THEN
	(
		STAR_1 - lag(STAR_1,1,STAR_1) 
            over (partition by  PRODUCT_RETAILER_HK, COUNTRY
                                order by date
            ) 
          )
	ELSE 0 END as INCRE_1_STAR
        , CASE WHEN 
	(
		STAR_2 - lag(STAR_2,1,STAR_2) 
            over (partition by  PRODUCT_RETAILER_HK, COUNTRY
                                order by date
            )  
	) >=0 THEN
	(
		STAR_2 - lag(STAR_2,1,STAR_2) 
            over (partition by  PRODUCT_RETAILER_HK, COUNTRY
                                order by date
            ) 
          )
	ELSE 0 END as INCRE_2_STAR
        , CASE WHEN 
	(
		STAR_3 - lag(STAR_3,1,STAR_3) 
            over (partition by  PRODUCT_RETAILER_HK, COUNTRY
                                order by date
            )  
	) >=0 THEN
	(
		STAR_3 - lag(STAR_3,1,STAR_3) 
            over (partition by  PRODUCT_RETAILER_HK, COUNTRY
                                order by date
            ) 
          )
	ELSE 0 END as INCRE_3_STAR
        , CASE WHEN 
	(
		STAR_4 - lag(STAR_4,1,STAR_4) 
            over (partition by  PRODUCT_RETAILER_HK, COUNTRY
                                order by date
            )  
	) >=0 THEN
	(
		STAR_4 - lag(STAR_4,1,STAR_4) 
            over (partition by  PRODUCT_RETAILER_HK, COUNTRY
                                order by date
            ) 
          )
	ELSE 0 END as INCRE_4_STAR
        , CASE WHEN 
	(
		STAR_5 - lag(STAR_5,1,STAR_5) 
            over (partition by  PRODUCT_RETAILER_HK, COUNTRY
                                order by date
            )  
	) >=0 THEN
	(
		STAR_5 - lag(STAR_5,1,STAR_5) 
            over (partition by  PRODUCT_RETAILER_HK, COUNTRY
                                order by date
            ) 
          )
	ELSE 0 END as INCRE_5_STAR
        , UPDATED_AT
        , BRAND_HK
        , BRAND_BK
        , 'APPBOT'                                                     as SOURCE
        , COUNTRY
FROM JOIN_RESULT
where 
    RETAILER_BK = 'iOS'
or
    (
    RETAILER_BK = 'Google Play'
    and
    COUNTRY = 'United States'
    )
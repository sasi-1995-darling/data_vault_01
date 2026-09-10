---- SRC LAYER ----
WITH
SRC_S1             as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers__winn_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S2             as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers__security_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S3             as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers__fypon_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S4             as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers__fiberon_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S5             as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers__thermatru_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S6             as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers__larson_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S7             as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers__appbot') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S8             as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_price_availability__profitero_winn') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S9             as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_price_availability__profitero_security') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S10            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_price_availability__profitero_thermatru') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S11            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_price_availability__profitero_fiberon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S12            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_price_availability__profitero_fypon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S13            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_price_availability__profitero_larson') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S14            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_competitive_products__profitero_fiberon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S15            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_competitive_products__profitero_fypon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S16            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_competitive_products__profitero_larson') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S17            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_competitive_products__profitero_security') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S18            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_competitive_products__profitero_thermatru') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S19            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_competitive_products__profitero_winn') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S20            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_pos_main_weekly__datavations') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S21            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S22            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S23            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers__fypon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S24            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers__fiberon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S25            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers__thermatru_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S26            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers__larson_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S27            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers_location__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S28            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers_location__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S29            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers_location__fypon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S30            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers_location__fiberon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S31            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers_location__thermatru_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 ),
SRC_S32            as ( SELECT BKCC, LOAD_DTS, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('v_psa_stg_retailers_location__larson_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY retailer_hk ORDER BY LOAD_DTS ))=1 )

/*
SRC_S1             as ( SELECT * FROM STAGING.v_psa_stg_retailers__winn_profitero )
SRC_S2             as ( SELECT * FROM STAGING.v_psa_stg_retailers__security_profitero )
SRC_S3             as ( SELECT * FROM STAGING.v_psa_stg_retailers__fypon_profitero )
SRC_S4             as ( SELECT * FROM STAGING.v_psa_stg_retailers__fiberon_profitero )
SRC_S5             as ( SELECT * FROM STAGING.v_psa_stg_retailers__thermatru_profitero )
SRC_S6             as ( SELECT * FROM STAGING.v_psa_stg_retailers__larson_profitero )
SRC_S7             as ( SELECT * FROM STAGING.v_psa_stg_retailers__appbot )
SRC_S8             as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_winn )
SRC_S9             as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_security )
SRC_S10            as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_thermatru )
SRC_S11            as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_fiberon )
SRC_S12            as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_fypon )
SRC_S13            as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_larson )
SRC_S14            as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_fiberon )
SRC_S15            as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_fypon )
SRC_S16            as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_larson )
SRC_S17            as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_security )
SRC_S18            as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_thermatru )
SRC_S19            as ( SELECT * FROM STAGING.v_psa_stg_competitive_products__profitero_winn )
SRC_S20            as ( SELECT * FROM STAGING.v_psa_stg_pos_main_weekly__datavations )
SRC_S21            as ( SELECT * FROM STAGING.v_psa_stg_retailers__winn_profitero_share )
SRC_S22            as ( SELECT * FROM STAGING.v_psa_stg_retailers__security_profitero_share )
SRC_S23            as ( SELECT * FROM STAGING.v_psa_stg_retailers__fypon_profitero_share )
SRC_S24            as ( SELECT * FROM STAGING.v_psa_stg_retailers__fiberon_profitero_share )
SRC_S25            as ( SELECT * FROM STAGING.v_psa_stg_retailers__thermatru_profitero_share )
SRC_S26            as ( SELECT * FROM STAGING.v_psa_stg_retailers__larson_profitero_share )
SRC_S27            as ( SELECT * FROM STAGING.v_psa_stg_retailers_location__winn_profitero_share )
SRC_S28            as ( SELECT * FROM STAGING.v_psa_stg_retailers_location__security_profitero_share )
SRC_S29            as ( SELECT * FROM STAGING.v_psa_stg_retailers_location__fypon_profitero_share )
SRC_S30            as ( SELECT * FROM STAGING.v_psa_stg_retailers_location__fiberon_profitero_share )
SRC_S31            as ( SELECT * FROM STAGING.v_psa_stg_retailers_location__thermatru_profitero_share )
SRC_S32            as ( SELECT * FROM STAGING.v_psa_stg_retailers_location__larson_profitero_share )
*/
---- LOGIC LAYER ----

, LOGIC_S1 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S1
)

, LOGIC_S2 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S2
)

, LOGIC_S3 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S3
)

, LOGIC_S4 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S4
)

, LOGIC_S5 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S5
)

, LOGIC_S6 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S6
)

, LOGIC_S7 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S7
)

, LOGIC_S8 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S8
)

, LOGIC_S9 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S9
)

, LOGIC_S10 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S10
)

, LOGIC_S11 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S11
)

, LOGIC_S12 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S12
)

, LOGIC_S13 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S13
)

, LOGIC_S14 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S14
)

, LOGIC_S15 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S15
)

, LOGIC_S16 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S16
)

, LOGIC_S17 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S17
)

, LOGIC_S18 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S18
)

, LOGIC_S19 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S19
)

, LOGIC_S20 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S20
)

, LOGIC_S21 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S21
)

, LOGIC_S22 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S22
)

, LOGIC_S23 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S23
)

, LOGIC_S24 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S24
)

, LOGIC_S25 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S25
)

, LOGIC_S26 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S26
)

, LOGIC_S27 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S27
)

, LOGIC_S28 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S28
)

, LOGIC_S29 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S29
)

, LOGIC_S30 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S30
)

, LOGIC_S31 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S31
)

, LOGIC_S32 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_S32
)
---- RENAME LAYER ----

, RENAME_S1 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S1
)

, RENAME_S2 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S2
)

, RENAME_S3 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S3
)

, RENAME_S4 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S4
)

, RENAME_S5 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S5
)

, RENAME_S6 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S6
)

, RENAME_S7 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S7
)

, RENAME_S8 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S8
)

, RENAME_S9 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S9
)

, RENAME_S10 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S10
)

, RENAME_S11 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S11
)

, RENAME_S12 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S12
)

, RENAME_S13 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S13
)

, RENAME_S14 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S14
)

, RENAME_S15 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S15
)

, RENAME_S16 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S16
)

, RENAME_S17 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S17
)

, RENAME_S18 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S18
)

, RENAME_S19 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S19
)

, RENAME_S20 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S20
)

, RENAME_S21 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S21
)

, RENAME_S22 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S22
)

, RENAME_S23 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S23
)

, RENAME_S24 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S24
)

, RENAME_S25 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S25
)

, RENAME_S26 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S26
)

, RENAME_S27 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S27
)

, RENAME_S28 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S28
)

, RENAME_S29 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S29
)

, RENAME_S30 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S30
)

, RENAME_S31 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S31
)

, RENAME_S32 as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_S32
)
---- FILTER LAYER ----

, FILTER_S1 as (
    SELECT *
    FROM RENAME_S1
)

, FILTER_S2 as (
    SELECT *
    FROM RENAME_S2
)

, FILTER_S3 as (
    SELECT *
    FROM RENAME_S3
)

, FILTER_S4 as (
    SELECT *
    FROM RENAME_S4
)

, FILTER_S5 as (
    SELECT *
    FROM RENAME_S5
)

, FILTER_S6 as (
    SELECT *
    FROM RENAME_S6
)

, FILTER_S7 as (
    SELECT *
    FROM RENAME_S7
)

, FILTER_S8 as (
    SELECT *
    FROM RENAME_S8
)

, FILTER_S9 as (
    SELECT *
    FROM RENAME_S9
)

, FILTER_S10 as (
    SELECT *
    FROM RENAME_S10
)

, FILTER_S11 as (
    SELECT *
    FROM RENAME_S11
)

, FILTER_S12 as (
    SELECT *
    FROM RENAME_S12
)

, FILTER_S13 as (
    SELECT *
    FROM RENAME_S13
)

, FILTER_S14 as (
    SELECT *
    FROM RENAME_S14
)

, FILTER_S15 as (
    SELECT *
    FROM RENAME_S15
)

, FILTER_S16 as (
    SELECT *
    FROM RENAME_S16
)

, FILTER_S17 as (
    SELECT *
    FROM RENAME_S17
)

, FILTER_S18 as (
    SELECT *
    FROM RENAME_S18
)

, FILTER_S19 as (
    SELECT *
    FROM RENAME_S19
)

, FILTER_S20 as (
    SELECT *
    FROM RENAME_S20
)

, FILTER_S21 as (
    SELECT *
    FROM RENAME_S21
)

, FILTER_S22 as (
    SELECT *
    FROM RENAME_S22
)

, FILTER_S23 as (
    SELECT *
    FROM RENAME_S23
)

, FILTER_S24 as (
    SELECT *
    FROM RENAME_S24
)

, FILTER_S25 as (
    SELECT *
    FROM RENAME_S25
)

, FILTER_S26 as (
    SELECT *
    FROM RENAME_S26
)

, FILTER_S27 as (
    SELECT *
    FROM RENAME_S27
)

, FILTER_S28 as (
    SELECT *
    FROM RENAME_S28
)

, FILTER_S29 as (
    SELECT *
    FROM RENAME_S29
)

, FILTER_S30 as (
    SELECT *
    FROM RENAME_S30
)

, FILTER_S31 as (
    SELECT *
    FROM RENAME_S31
)

, FILTER_S32 as (
    SELECT *
    FROM RENAME_S32
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_S1
    UNION ALL
    SELECT * FROM FILTER_S2
    UNION ALL
    SELECT * FROM FILTER_S3
    UNION ALL
    SELECT * FROM FILTER_S4
    UNION ALL
    SELECT * FROM FILTER_S5
    UNION ALL
    SELECT * FROM FILTER_S6
    UNION ALL
    SELECT * FROM FILTER_S7
    UNION ALL
    SELECT * FROM FILTER_S8
    UNION ALL
    SELECT * FROM FILTER_S9
    UNION ALL
    SELECT * FROM FILTER_S10
    UNION ALL
    SELECT * FROM FILTER_S11
    UNION ALL
    SELECT * FROM FILTER_S12
    UNION ALL
    SELECT * FROM FILTER_S13
    UNION ALL
    SELECT * FROM FILTER_S14
    UNION ALL
    SELECT * FROM FILTER_S15
    UNION ALL
    SELECT * FROM FILTER_S16
    UNION ALL
    SELECT * FROM FILTER_S17
    UNION ALL
    SELECT * FROM FILTER_S18
    UNION ALL
    SELECT * FROM FILTER_S19
    UNION ALL
    SELECT * FROM FILTER_S20
    UNION ALL
    SELECT * FROM FILTER_S21
    UNION ALL
    SELECT * FROM FILTER_S22
    UNION ALL
    SELECT * FROM FILTER_S23
    UNION ALL
    SELECT * FROM FILTER_S24
    UNION ALL
    SELECT * FROM FILTER_S25
    UNION ALL
    SELECT * FROM FILTER_S26
    UNION ALL
    SELECT * FROM FILTER_S27
    UNION ALL
    SELECT * FROM FILTER_S28
    UNION ALL
    SELECT * FROM FILTER_S29
    UNION ALL
    SELECT * FROM FILTER_S30
    UNION ALL
    SELECT * FROM FILTER_S31
    UNION ALL
    SELECT * FROM FILTER_S32
)

---- FINAL LAYER ----
SELECT
          RETAILER_HK
        , RETAILER_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.RETAILER_HK = JOIN_RESULT.RETAILER_HK
)
{% endif %}QUALIFY (ROW_NUMBER() OVER(PARTITION BY RETAILER_HK ORDER BY LOAD_DTS))=1
{% if not is_incremental() %} 
union all

SELECT MD5_BINARY(GR.VALUE)  retailer_HK
, GR.VALUE  AS retailer_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
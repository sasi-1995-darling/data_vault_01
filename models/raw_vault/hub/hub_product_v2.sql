---- SRC LAYER ----
WITH
SRC_PWI            as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_customer_products__winn_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PSE            as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_customer_products__security_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PFY            as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_customer_products__fypon_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PFI            as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_customer_products__fiberon_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PTT            as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_customer_products__thermatru_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PLR            as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_customer_products__larson_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_AA             as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_applist__appbot') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_HYD            as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_response__hyd_delighted') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_NAB            as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_response__naboo_delighted') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SWS            as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_response__sws_delighted') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_VAK            as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_response__vak_delighted') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_YALE           as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_response__yale_delighted') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_BZAV           as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_product__bazaarvoice') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_BZAVY          as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_product__bazaarvoice_yale') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrWINN         as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_price_availability__profitero_winn') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrSEC          as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_price_availability__profitero_security') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrTT           as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_price_availability__profitero_thermatru') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrFIB          as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_price_availability__profitero_fiberon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrFY           as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_price_availability__profitero_fypon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrLRSN         as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_price_availability__profitero_larson') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrSpWINN       as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_sns_products__profitero_winn') }} as SRC 
                        WHERE CUSTOMER_PRODUCT_ID IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_PrSpSEC        as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_sns_products__profitero_security') }} as SRC 
                        WHERE CUSTOMER_PRODUCT_ID IS NOT NULL
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_DRAS           as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_response_answer_selection__sws_delighted') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_DRA            as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_response_answer__sws_delighted') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PSWI           as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_customer_products__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PSSE           as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_customer_products__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PSFY           as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_customer_products__fypon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PSFI           as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_customer_products__fiberon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PSTT           as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_customer_products__thermatru_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PSLR           as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_customer_products__larson_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrSHWI         as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_price_availability__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrSHSE         as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_price_availability__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrSHTT         as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_price_availability__thermatru_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrSHFI         as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_price_availability__fiberon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrSHFY         as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_price_availability__fypon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PrSHLR         as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_price_availability__larson_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_AmPrWI         as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_amz_product__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_AmPrSE         as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_amz_product__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SSY            as ( SELECT BKCC, LOAD_DTS, PRODUCT_BK, PRODUCT_HK, REC_SRC FROM {{ ref('v_psa_stg_response__simplesat_yale') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_PWI            as ( SELECT * FROM STAGING.v_psa_stg_customer_products__winn_profitero )
SRC_PSE            as ( SELECT * FROM STAGING.v_psa_stg_customer_products__security_profitero )
SRC_PFY            as ( SELECT * FROM STAGING.v_psa_stg_customer_products__fypon_profitero )
SRC_PFI            as ( SELECT * FROM STAGING.v_psa_stg_customer_products__fiberon_profitero )
SRC_PTT            as ( SELECT * FROM STAGING.v_psa_stg_customer_products__thermatru_profitero )
SRC_PLR            as ( SELECT * FROM STAGING.v_psa_stg_customer_products__larson_profitero )
SRC_AA             as ( SELECT * FROM STAGING.v_psa_stg_applist__appbot )
SRC_HYD            as ( SELECT * FROM STAGING.v_psa_stg_response__hyd_delighted )
SRC_NAB            as ( SELECT * FROM STAGING.v_psa_stg_response__naboo_delighted )
SRC_SWS            as ( SELECT * FROM STAGING.v_psa_stg_response__sws_delighted )
SRC_VAK            as ( SELECT * FROM STAGING.v_psa_stg_response__vak_delighted )
SRC_YALE           as ( SELECT * FROM STAGING.v_psa_stg_response__yale_delighted )
SRC_BZAV           as ( SELECT * FROM STAGING.v_psa_stg_product__bazaarvoice )
SRC_BZAVY          as ( SELECT * FROM STAGING.v_psa_stg_product__bazaarvoice_yale )
SRC_PrWINN         as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_winn )
SRC_PrSEC          as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_security )
SRC_PrTT           as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_thermatru )
SRC_PrFIB          as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_fiberon )
SRC_PrFY           as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_fypon )
SRC_PrLRSN         as ( SELECT * FROM STAGING.v_psa_stg_price_availability__profitero_larson )
SRC_PrSpWINN       as ( SELECT * FROM STAGING.v_psa_stg_sns_products__profitero_winn )
SRC_PrSpSEC        as ( SELECT * FROM STAGING.v_psa_stg_sns_products__profitero_security )
SRC_DRAS           as ( SELECT * FROM STAGING.v_psa_stg_response_answer_selection__sws_delighted )
SRC_DRA            as ( SELECT * FROM STAGING.v_psa_stg_response_answer__sws_delighted )
SRC_PSWI           as ( SELECT * FROM STAGING.v_psa_stg_customer_products__winn_profitero_share )
SRC_PSSE           as ( SELECT * FROM STAGING.v_psa_stg_customer_products__security_profitero_share )
SRC_PSFY           as ( SELECT * FROM STAGING.v_psa_stg_customer_products__fypon_profitero_share )
SRC_PSFI           as ( SELECT * FROM STAGING.v_psa_stg_customer_products__fiberon_profitero_share )
SRC_PSTT           as ( SELECT * FROM STAGING.v_psa_stg_customer_products__thermatru_profitero_share )
SRC_PSLR           as ( SELECT * FROM STAGING.v_psa_stg_customer_products__larson_profitero_share )
SRC_SSY            as ( SELECT * FROM STAGING.v_psa_stg_response__simplesat_yale )
*/
---- LOGIC LAYER ----

, LOGIC_PWI as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PWI
)

, LOGIC_PSE as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PSE
)

, LOGIC_PFY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PFY
)

, LOGIC_PFI as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PFI
)

, LOGIC_PTT as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PTT
)

, LOGIC_PLR as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PLR
)

, LOGIC_AA as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AA
)

, LOGIC_HYD as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_HYD
)

, LOGIC_NAB as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_NAB
)

, LOGIC_SWS as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SWS
)

, LOGIC_VAK as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_VAK
)

, LOGIC_YALE as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_YALE
)

, LOGIC_BZAV as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_BZAV
)

, LOGIC_BZAVY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_BZAVY
)

, LOGIC_PrWINN as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrWINN
)

, LOGIC_PrSEC as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSEC
)

, LOGIC_PrTT as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrTT
)

, LOGIC_PrFIB as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrFIB
)

, LOGIC_PrFY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrFY
)

, LOGIC_PrLRSN as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrLRSN
)

, LOGIC_PrSpWINN as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSpWINN
)

, LOGIC_PrSpSEC as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSpSEC
)

, LOGIC_DRAS as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_DRAS
)

, LOGIC_DRA as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_DRA
)

, LOGIC_PSWI as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PSWI
)

, LOGIC_PSSE as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PSSE
)

, LOGIC_PSFY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PSFY
)

, LOGIC_PSFI as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PSFI
)

, LOGIC_PSTT as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PSTT
)

, LOGIC_PSLR as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PSLR
)

, LOGIC_PrSHWI as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSHWI
)

, LOGIC_PrSHSE as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSHSE
)

, LOGIC_PrSHTT as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSHTT
)

, LOGIC_PrSHFI as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSHFI
)

, LOGIC_PrSHFY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSHFY
)

, LOGIC_PrSHLR as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSHLR
)

, LOGIC_AmPrWI as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AmPrWI
)

, LOGIC_AmPrSE as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AmPrSE
)

, LOGIC_SSY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SSY
)
---- RENAME LAYER ----

, RENAME_PWI as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PWI
)

, RENAME_PSE as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PSE
)

, RENAME_PFY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PFY
)

, RENAME_PFI as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PFI
)

, RENAME_PTT as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PTT
)

, RENAME_PLR as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PLR
)

, RENAME_AA as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AA
)

, RENAME_HYD as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_HYD
)

, RENAME_NAB as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_NAB
)

, RENAME_SWS as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SWS
)

, RENAME_VAK as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_VAK
)

, RENAME_YALE as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_YALE
)

, RENAME_BZAV as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_BZAV
)

, RENAME_BZAVY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_BZAVY
)

, RENAME_PrWINN as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrWINN
)

, RENAME_PrSEC as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSEC
)

, RENAME_PrTT as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrTT
)

, RENAME_PrFIB as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrFIB
)

, RENAME_PrFY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrFY
)

, RENAME_PrLRSN as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrLRSN
)

, RENAME_PrSpWINN as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSpWINN
)

, RENAME_PrSpSEC as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSpSEC
)

, RENAME_DRAS as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_DRAS
)

, RENAME_DRA as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_DRA
)

, RENAME_PSWI as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PSWI
)

, RENAME_PSSE as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PSSE
)

, RENAME_PSFY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PSFY
)

, RENAME_PSFI as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PSFI
)

, RENAME_PSTT as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PSTT
)

, RENAME_PSLR as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PSLR
)

, RENAME_PrSHWI as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSHWI
)

, RENAME_PrSHSE as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSHSE
)

, RENAME_PrSHTT as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSHTT
)

, RENAME_PrSHFI as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSHFI
)

, RENAME_PrSHFY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSHFY
)

, RENAME_PrSHLR as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSHLR
)

, RENAME_AmPrWI as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AmPrWI
)

, RENAME_AmPrSE as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AmPrSE
)

, RENAME_SSY as (
    SELECT
        PRODUCT_HK
      , PRODUCT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SSY
)
---- FILTER LAYER ----

, FILTER_PWI as (
    SELECT *
    FROM RENAME_PWI
)

, FILTER_PSE as (
    SELECT *
    FROM RENAME_PSE
)

, FILTER_PFY as (
    SELECT *
    FROM RENAME_PFY
)

, FILTER_PFI as (
    SELECT *
    FROM RENAME_PFI
)

, FILTER_PTT as (
    SELECT *
    FROM RENAME_PTT
)

, FILTER_PLR as (
    SELECT *
    FROM RENAME_PLR
)

, FILTER_AA as (
    SELECT *
    FROM RENAME_AA
)

, FILTER_HYD as (
    SELECT *
    FROM RENAME_HYD
)

, FILTER_NAB as (
    SELECT *
    FROM RENAME_NAB
)

, FILTER_SWS as (
    SELECT *
    FROM RENAME_SWS
)

, FILTER_VAK as (
    SELECT *
    FROM RENAME_VAK
)

, FILTER_YALE as (
    SELECT *
    FROM RENAME_YALE
)

, FILTER_BZAV as (
    SELECT *
    FROM RENAME_BZAV
)

, FILTER_BZAVY as (
    SELECT *
    FROM RENAME_BZAVY
)

, FILTER_PrWINN as (
    SELECT *
    FROM RENAME_PrWINN
)

, FILTER_PrSEC as (
    SELECT *
    FROM RENAME_PrSEC
)

, FILTER_PrTT as (
    SELECT *
    FROM RENAME_PrTT
)

, FILTER_PrFIB as (
    SELECT *
    FROM RENAME_PrFIB
)

, FILTER_PrFY as (
    SELECT *
    FROM RENAME_PrFY
)

, FILTER_PrLRSN as (
    SELECT *
    FROM RENAME_PrLRSN
)

, FILTER_PrSpWINN as (
    SELECT *
    FROM RENAME_PrSpWINN
)

, FILTER_PrSpSEC as (
    SELECT *
    FROM RENAME_PrSpSEC
)

, FILTER_DRAS as (
    SELECT *
    FROM RENAME_DRAS
)

, FILTER_DRA as (
    SELECT *
    FROM RENAME_DRA
)

, FILTER_PSWI as (
    SELECT *
    FROM RENAME_PSWI
)

, FILTER_PSSE as (
    SELECT *
    FROM RENAME_PSSE
)

, FILTER_PSFY as (
    SELECT *
    FROM RENAME_PSFY
)

, FILTER_PSFI as (
    SELECT *
    FROM RENAME_PSFI
)

, FILTER_PSTT as (
    SELECT *
    FROM RENAME_PSTT
)

, FILTER_PSLR as (
    SELECT *
    FROM RENAME_PSLR
)

, FILTER_PrSHWI as (
    SELECT *
    FROM RENAME_PrSHWI
)

, FILTER_PrSHSE as (
    SELECT *
    FROM RENAME_PrSHSE
)

, FILTER_PrSHTT as (
    SELECT *
    FROM RENAME_PrSHTT
)

, FILTER_PrSHFI as (
    SELECT *
    FROM RENAME_PrSHFI
)

, FILTER_PrSHFY as (
    SELECT *
    FROM RENAME_PrSHFY
)

, FILTER_PrSHLR as (
    SELECT *
    FROM RENAME_PrSHLR
)

, FILTER_AmPrWI as (
    SELECT *
    FROM RENAME_AmPrWI
)

, FILTER_AmPrSE as (
    SELECT *
    FROM RENAME_AmPrSE
)

, FILTER_SSY as (
    SELECT *
    FROM RENAME_SSY
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PWI
    UNION ALL
    SELECT * FROM FILTER_PSE
    UNION ALL
    SELECT * FROM FILTER_PFY
    UNION ALL
    SELECT * FROM FILTER_PFI
    UNION ALL
    SELECT * FROM FILTER_PTT
    UNION ALL
    SELECT * FROM FILTER_PLR
    UNION ALL
    SELECT * FROM FILTER_AA
    UNION ALL
    SELECT * FROM FILTER_HYD
    UNION ALL
    SELECT * FROM FILTER_NAB
    UNION ALL
    SELECT * FROM FILTER_SWS
    UNION ALL
    SELECT * FROM FILTER_VAK
    UNION ALL
    SELECT * FROM FILTER_YALE
    UNION ALL
    SELECT * FROM FILTER_BZAV
    UNION ALL
    SELECT * FROM FILTER_BZAVY
    UNION ALL
    SELECT * FROM FILTER_PrWINN
    UNION ALL
    SELECT * FROM FILTER_PrSEC
    UNION ALL
    SELECT * FROM FILTER_PrTT
    UNION ALL
    SELECT * FROM FILTER_PrFIB
    UNION ALL
    SELECT * FROM FILTER_PrFY
    UNION ALL
    SELECT * FROM FILTER_PrLRSN
    UNION ALL
    SELECT * FROM FILTER_PrSpWINN
    UNION ALL
    SELECT * FROM FILTER_PrSpSEC
    UNION ALL
    SELECT * FROM FILTER_DRAS
    UNION ALL
    SELECT * FROM FILTER_DRA
    UNION ALL
    SELECT * FROM FILTER_PSWI
    UNION ALL
    SELECT * FROM FILTER_PSSE
    UNION ALL
    SELECT * FROM FILTER_PSFY
    UNION ALL
    SELECT * FROM FILTER_PSFI
    UNION ALL
    SELECT * FROM FILTER_PSTT
    UNION ALL
    SELECT * FROM FILTER_PSLR
    UNION ALL
    SELECT * FROM FILTER_PrSHWI
    UNION ALL
    SELECT * FROM FILTER_PrSHSE
    UNION ALL
    SELECT * FROM FILTER_PrSHTT
    UNION ALL
    SELECT * FROM FILTER_PrSHFI
    UNION ALL
    SELECT * FROM FILTER_PrSHFY
    UNION ALL
    SELECT * FROM FILTER_PrSHLR
    UNION ALL
    SELECT * FROM FILTER_AmPrWI
    UNION ALL
    SELECT * FROM FILTER_AmPrSE
    UNION ALL
    SELECT * FROM FILTER_SSY
)

---- FINAL LAYER ----
SELECT
          PRODUCT_HK
        , PRODUCT_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCT_HK = JOIN_RESULT.PRODUCT_HK
)
{% endif %}
QUALIFY ROW_NUMBER() OVER(PARTITION BY PRODUCT_HK ORDER BY LOAD_DTS DESC)=1
{% if not is_incremental() %}

union all

SELECT MD5_BINARY(GR.VALUE)  PRODUCT_HK
, GR.VALUE  AS PRODUCT_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
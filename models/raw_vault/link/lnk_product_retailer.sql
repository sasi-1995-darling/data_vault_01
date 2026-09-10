---- SRC LAYER ----
WITH
SRC_ReWin          as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_review__winn_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_RaWin          as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_rating__winn_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReSec          as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_review__security_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_RaSec          as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_rating__security_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReFy           as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_review__fypon_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_RaFy           as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_rating__fypon_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReFib          as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_review__fiberon_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_RaFib          as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_rating__fiberon_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReTT           as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_review__thermatru_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_RaTT           as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_rating__thermatru_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReLar          as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_review__larson_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_RaLar          as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_rating__larson_profitero') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReApp          as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_review__appbot') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_RaApp          as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_rating__appbot') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReWinPS        as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_review__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_RaWinPS        as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_rating__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CUSTOMER_PRODUCT_ID,RETAILER_BK ORDER BY LOAD_DTS))=1 ),
SRC_ReSecPS        as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_review__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_RaSecPS        as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_rating__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReFyPS         as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_review__fypon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_RaFyPS         as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_rating__fypon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReFibPS        as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_review__fiberon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_RaFibPS        as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_rating__fiberon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReTTPS         as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_review__thermatru_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_RaTTPS         as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_rating__thermatru_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_ReLarPS        as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_review__larson_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_RaLarPS        as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_prod_retailer_rating__larson_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_PrWinPS        as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_price_availability__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_ID, RETAILER_LOCATION_NAME ORDER BY LOAD_DTS))=1 ),
SRC_PrSecPS        as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_price_availability__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_PrFyPS         as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_price_availability__fypon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_PrFibPS        as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_price_availability__fiberon_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_PrTTPS         as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_price_availability__thermatru_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 ),
SRC_PrLarPS        as ( SELECT LOAD_DTS, PRODUCT_HK, PRODUCT_RETAILER_HK, REC_SRC, RETAILER_HK FROM {{ ref('v_psa_stg_price_availability__larson_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1 )

/*
SRC_ReWin          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__winn_profitero )
SRC_RaWin          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__winn_profitero )
SRC_ReSec          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__security_profitero )
SRC_RaSec          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__security_profitero )
SRC_ReFy           as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__fypon_profitero )
SRC_RaFy           as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__fypon_profitero )
SRC_ReFib          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__fiberon_profitero )
SRC_RaFib          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__fiberon_profitero )
SRC_ReTT           as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__thermatru_profitero )
SRC_RaTT           as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__thermatru_profitero )
SRC_ReLar          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__larson_profitero )
SRC_RaLar          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__larson_profitero )
SRC_ReApp          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__appbot )
SRC_RaApp          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__appbot )
SRC_ReWinPS        as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__winn_profitero_share )
SRC_RaWinPS        as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__winn_profitero_share )
SRC_ReSecPS        as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__security_profitero_share )
SRC_RaSecPS        as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__security_profitero_share )
SRC_ReFyPS         as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__fypon_profitero_share )
SRC_RaFyPS         as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__fypon_profitero_share )
SRC_ReFibPS        as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__fiberon_profitero_share )
SRC_RaFibPS        as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__fiberon_profitero_share )
SRC_ReTTPS         as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__thermatru_profitero_share )
SRC_RaTTPS         as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__thermatru_profitero_share )
SRC_ReLarPS        as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_review__larson_profitero_share )
SRC_RaLarPS        as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__larson_profitero_share )
*/
---- LOGIC LAYER ----

, LOGIC_ReWin as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReWin
)

, LOGIC_RaWin as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RaWin
)

, LOGIC_ReSec as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReSec
)

, LOGIC_RaSec as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RaSec
)

, LOGIC_ReFy as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReFy
)

, LOGIC_RaFy as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RaFy
)

, LOGIC_ReFib as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReFib
)

, LOGIC_RaFib as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RaFib
)

, LOGIC_ReTT as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReTT
)

, LOGIC_RaTT as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RaTT
)

, LOGIC_ReLar as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReLar
)

, LOGIC_RaLar as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RaLar
)

, LOGIC_ReApp as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReApp
)

, LOGIC_RaApp as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RaApp
)

, LOGIC_ReWinPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReWinPS
)

, LOGIC_RaWinPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RaWinPS
)

, LOGIC_ReSecPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReSecPS
)

, LOGIC_RaSecPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RaSecPS
)

, LOGIC_ReFyPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReFyPS
)

, LOGIC_RaFyPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RaFyPS
)

, LOGIC_ReFibPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReFibPS
)

, LOGIC_RaFibPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RaFibPS
)

, LOGIC_ReTTPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReTTPS
)

, LOGIC_RaTTPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RaTTPS
)

, LOGIC_ReLarPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ReLarPS
)

, LOGIC_RaLarPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RaLarPS
)

, LOGIC_PrWinPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrWinPS
)

, LOGIC_PrSecPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSecPS
)

, LOGIC_PrFyPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrFyPS
)

, LOGIC_PrFibPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrFibPS
)

, LOGIC_PrTTPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrTTPS
)

, LOGIC_PrLarPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrLarPS
)

, LOGIC_PrWinPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrWinPS
)

, LOGIC_PrSecPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrSecPS
)

, LOGIC_PrFyPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrFyPS
)

, LOGIC_PrFibPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrFibPS
)

, LOGIC_PrTTPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrTTPS
)

, LOGIC_PrLarPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PrLarPS
)
---- RENAME LAYER ----

, RENAME_ReWin as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReWin
)

, RENAME_RaWin as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RaWin
)

, RENAME_ReSec as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReSec
)

, RENAME_RaSec as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RaSec
)

, RENAME_ReFy as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReFy
)

, RENAME_RaFy as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RaFy
)

, RENAME_ReFib as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReFib
)

, RENAME_RaFib as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RaFib
)

, RENAME_ReTT as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReTT
)

, RENAME_RaTT as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RaTT
)

, RENAME_ReLar as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReLar
)

, RENAME_RaLar as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RaLar
)

, RENAME_ReApp as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReApp
)

, RENAME_RaApp as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RaApp
)

, RENAME_ReWinPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReWinPS
)

, RENAME_RaWinPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RaWinPS
)

, RENAME_ReSecPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReSecPS
)

, RENAME_RaSecPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RaSecPS
)

, RENAME_ReFyPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReFyPS
)

, RENAME_RaFyPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RaFyPS
)

, RENAME_ReFibPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReFibPS
)

, RENAME_RaFibPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RaFibPS
)

, RENAME_ReTTPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReTTPS
)

, RENAME_RaTTPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RaTTPS
)

, RENAME_ReLarPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ReLarPS
)

, RENAME_RaLarPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RaLarPS
)

, RENAME_PrWinPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrWinPS
)

, RENAME_PrSecPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSecPS
)

, RENAME_PrFyPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrFyPS
)

, RENAME_PrFibPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrFibPS
)

, RENAME_PrTTPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrTTPS
)

, RENAME_PrLarPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrLarPS
)

, RENAME_PrWinPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrWinPS
)

, RENAME_PrSecPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrSecPS
)

, RENAME_PrFyPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrFyPS
)

, RENAME_PrFibPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrFibPS
)

, RENAME_PrTTPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrTTPS
)

, RENAME_PrLarPS as (
    SELECT
        PRODUCT_RETAILER_HK
      , PRODUCT_HK
      , RETAILER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PrLarPS
)
---- FILTER LAYER ----

, FILTER_ReWin as (
    SELECT *
    FROM RENAME_ReWin
)

, FILTER_RaWin as (
    SELECT *
    FROM RENAME_RaWin
)

, FILTER_ReSec as (
    SELECT *
    FROM RENAME_ReSec
)

, FILTER_RaSec as (
    SELECT *
    FROM RENAME_RaSec
)

, FILTER_ReFy as (
    SELECT *
    FROM RENAME_ReFy
)

, FILTER_RaFy as (
    SELECT *
    FROM RENAME_RaFy
)

, FILTER_ReFib as (
    SELECT *
    FROM RENAME_ReFib
)

, FILTER_RaFib as (
    SELECT *
    FROM RENAME_RaFib
)

, FILTER_ReTT as (
    SELECT *
    FROM RENAME_ReTT
)

, FILTER_RaTT as (
    SELECT *
    FROM RENAME_RaTT
)

, FILTER_ReLar as (
    SELECT *
    FROM RENAME_ReLar
)

, FILTER_RaLar as (
    SELECT *
    FROM RENAME_RaLar
)

, FILTER_ReApp as (
    SELECT *
    FROM RENAME_ReApp
)

, FILTER_RaApp as (
    SELECT *
    FROM RENAME_RaApp
)

, FILTER_ReWinPS as (
    SELECT *
    FROM RENAME_ReWinPS
)

, FILTER_RaWinPS as (
    SELECT *
    FROM RENAME_RaWinPS
)

, FILTER_ReSecPS as (
    SELECT *
    FROM RENAME_ReSecPS
)

, FILTER_RaSecPS as (
    SELECT *
    FROM RENAME_RaSecPS
)

, FILTER_ReFyPS as (
    SELECT *
    FROM RENAME_ReFyPS
)

, FILTER_RaFyPS as (
    SELECT *
    FROM RENAME_RaFyPS
)

, FILTER_ReFibPS as (
    SELECT *
    FROM RENAME_ReFibPS
)

, FILTER_RaFibPS as (
    SELECT *
    FROM RENAME_RaFibPS
)

, FILTER_ReTTPS as (
    SELECT *
    FROM RENAME_ReTTPS
)

, FILTER_RaTTPS as (
    SELECT *
    FROM RENAME_RaTTPS
)

, FILTER_ReLarPS as (
    SELECT *
    FROM RENAME_ReLarPS
)

, FILTER_RaLarPS as (
    SELECT *
    FROM RENAME_RaLarPS
)

, FILTER_PrWinPS as (
    SELECT *
    FROM RENAME_PrWinPS
)

, FILTER_PrSecPS as (
    SELECT *
    FROM RENAME_PrSecPS
)

, FILTER_PrFyPS as (
    SELECT *
    FROM RENAME_PrFyPS
)

, FILTER_PrFibPS as (
    SELECT *
    FROM RENAME_PrFibPS
)

, FILTER_PrTTPS as (
    SELECT *
    FROM RENAME_PrTTPS
)

, FILTER_PrLarPS as (
    SELECT *
    FROM RENAME_PrLarPS
)

, FILTER_PrWinPS as (
    SELECT *
    FROM RENAME_PrWinPS
)

, FILTER_PrSecPS as (
    SELECT *
    FROM RENAME_PrSecPS
)

, FILTER_PrFyPS as (
    SELECT *
    FROM RENAME_PrFyPS
)

, FILTER_PrFibPS as (
    SELECT *
    FROM RENAME_PrFibPS
)

, FILTER_PrTTPS as (
    SELECT *
    FROM RENAME_PrTTPS
)

, FILTER_PrLarPS as (
    SELECT *
    FROM RENAME_PrLarPS
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_ReWin
    UNION ALL
    SELECT * FROM FILTER_RaWin
    UNION ALL
    SELECT * FROM FILTER_ReSec
    UNION ALL
    SELECT * FROM FILTER_RaSec
    UNION ALL
    SELECT * FROM FILTER_ReFy
    UNION ALL
    SELECT * FROM FILTER_RaFy
    UNION ALL
    SELECT * FROM FILTER_ReFib
    UNION ALL
    SELECT * FROM FILTER_RaFib
    UNION ALL
    SELECT * FROM FILTER_ReTT
    UNION ALL
    SELECT * FROM FILTER_RaTT
    UNION ALL
    SELECT * FROM FILTER_ReLar
    UNION ALL
    SELECT * FROM FILTER_RaLar
    UNION ALL
    SELECT * FROM FILTER_ReApp
    UNION ALL
    SELECT * FROM FILTER_RaApp
    UNION ALL
    SELECT * FROM FILTER_ReWinPS
    UNION ALL
    SELECT * FROM FILTER_RaWinPS
    UNION ALL
    SELECT * FROM FILTER_ReSecPS
    UNION ALL
    SELECT * FROM FILTER_RaSecPS
    UNION ALL
    SELECT * FROM FILTER_ReFyPS
    UNION ALL
    SELECT * FROM FILTER_RaFyPS
    UNION ALL
    SELECT * FROM FILTER_ReFibPS
    UNION ALL
    SELECT * FROM FILTER_RaFibPS
    UNION ALL
    SELECT * FROM FILTER_ReTTPS
    UNION ALL
    SELECT * FROM FILTER_RaTTPS
    UNION ALL
    SELECT * FROM FILTER_ReLarPS
    UNION ALL
    SELECT * FROM FILTER_RaLarPS
    UNION ALL
    SELECT * FROM FILTER_PrWinPS
    UNION ALL
    SELECT * FROM FILTER_PrSecPS
    UNION ALL
    SELECT * FROM FILTER_PrFyPS
    UNION ALL
    SELECT * FROM FILTER_PrFibPS
    UNION ALL
    SELECT * FROM FILTER_PrTTPS
    UNION ALL
    SELECT * FROM FILTER_PrLarPS
    UNION ALL
    SELECT * FROM FILTER_PrWinPS
    UNION ALL
    SELECT * FROM FILTER_PrSecPS
    UNION ALL
    SELECT * FROM FILTER_PrFyPS
    UNION ALL
    SELECT * FROM FILTER_PrFibPS
    UNION ALL
    SELECT * FROM FILTER_PrTTPS
    UNION ALL
    SELECT * FROM FILTER_PrLarPS
)

---- FINAL LAYER ----
SELECT
          PRODUCT_RETAILER_HK
        , PRODUCT_HK
        , RETAILER_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCT_RETAILER_HK = JOIN_RESULT.PRODUCT_RETAILER_HK
)
{% endif %}
--this is to consolidate records coming from 2 diff tables with the same bkcc
QUALIFY (ROW_NUMBER() OVER(PARTITION BY PRODUCT_RETAILER_HK ORDER BY LOAD_DTS))=1
{% if not is_incremental() %}

union all
SELECT 
 MD5_BINARY(GR.VALUE) AS PRODUCT_RETAILER_HK
, MD5_BINARY(GR.VALUE) AS PRODUCT_HK
, MD5_BINARY(GR.VALUE) AS RETAILER_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
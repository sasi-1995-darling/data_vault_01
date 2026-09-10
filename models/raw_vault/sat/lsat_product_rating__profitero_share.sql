---- SRC LAYER ----
WITH
SRC_RaWin          as ( SELECT * FROM {{ ref('v_psa_stg_prod_retailer_rating__winn_profitero_share') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_RaSec          as ( SELECT * FROM {{ ref('v_psa_stg_prod_retailer_rating__security_profitero_share') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_RaFy           as ( SELECT * FROM {{ ref('v_psa_stg_prod_retailer_rating__fypon_profitero_share') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_RaFib          as ( SELECT * FROM {{ ref('v_psa_stg_prod_retailer_rating__fiberon_profitero_share') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_RaTT           as ( SELECT * FROM {{ ref('v_psa_stg_prod_retailer_rating__thermatru_profitero_share') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   ),
SRC_RaLar          as ( SELECT * FROM {{ ref('v_psa_stg_prod_retailer_rating__larson_profitero_share') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_RaWin          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__winn_profitero_share )
SRC_RaSec          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__security_profitero_share )
SRC_RaFy           as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__fypon_profitero_share )
SRC_RaFib          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__fiberon_profitero_share )
SRC_RaTT           as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__thermatru_profitero_share )
SRC_RaLar          as ( SELECT * FROM STAGING.v_psa_stg_prod_retailer_rating__larson_profitero_share )
*/
---- LOGIC LAYER ----

, LOGIC_RaWin as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
      , SOURCE_UPDATED_AT
      , UPDATED_AT
      , CUMULATIVE_RATINGS
      , BKCC
      , REC_SRC
      , HASHDIFF
      , DIM_ACCOUNT_PRODUCT_KEY
    FROM SRC_RaWin
)

, LOGIC_RaSec as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
      , SOURCE_UPDATED_AT
      , UPDATED_AT
      , CUMULATIVE_RATINGS
      , BKCC
      , REC_SRC
      , HASHDIFF
      , DIM_ACCOUNT_PRODUCT_KEY
    FROM SRC_RaSec
)

, LOGIC_RaFy as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
      , SOURCE_UPDATED_AT
      , UPDATED_AT
      , CUMULATIVE_RATINGS
      , BKCC
      , REC_SRC
      , HASHDIFF
      , DIM_ACCOUNT_PRODUCT_KEY
    FROM SRC_RaFy
)

, LOGIC_RaFib as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
      , SOURCE_UPDATED_AT
      , UPDATED_AT
      , CUMULATIVE_RATINGS
      , BKCC
      , REC_SRC
      , HASHDIFF
      , DIM_ACCOUNT_PRODUCT_KEY
    FROM SRC_RaFib
)

, LOGIC_RaTT as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
      , SOURCE_UPDATED_AT
      , UPDATED_AT
      , CUMULATIVE_RATINGS
      , BKCC
      , REC_SRC
      , HASHDIFF
      , DIM_ACCOUNT_PRODUCT_KEY
    FROM SRC_RaTT
)

, LOGIC_RaLar as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
      , SOURCE_UPDATED_AT
      , UPDATED_AT
      , CUMULATIVE_RATINGS
      , BKCC
      , REC_SRC
      , HASHDIFF
      , DIM_ACCOUNT_PRODUCT_KEY
    FROM SRC_RaLar
)
---- RENAME LAYER ----

, RENAME_RaWin as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
      , SOURCE_UPDATED_AT
      , UPDATED_AT
      , CUMULATIVE_RATINGS
      , BKCC
      , REC_SRC
      , HASHDIFF
      , DIM_ACCOUNT_PRODUCT_KEY
    FROM LOGIC_RaWin
)

, RENAME_RaSec as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
      , SOURCE_UPDATED_AT
      , UPDATED_AT
      , CUMULATIVE_RATINGS
      , BKCC
      , REC_SRC
      , HASHDIFF
      , DIM_ACCOUNT_PRODUCT_KEY
    FROM LOGIC_RaSec
)

, RENAME_RaFy as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
      , SOURCE_UPDATED_AT
      , UPDATED_AT
      , CUMULATIVE_RATINGS
      , BKCC
      , REC_SRC
      , HASHDIFF
      , DIM_ACCOUNT_PRODUCT_KEY
    FROM LOGIC_RaFy
)

, RENAME_RaFib as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
      , SOURCE_UPDATED_AT
      , UPDATED_AT
      , CUMULATIVE_RATINGS
      , BKCC
      , REC_SRC
      , HASHDIFF
      , DIM_ACCOUNT_PRODUCT_KEY
    FROM LOGIC_RaFib
)

, RENAME_RaTT as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
      , SOURCE_UPDATED_AT
      , UPDATED_AT
      , CUMULATIVE_RATINGS
      , BKCC
      , REC_SRC
      , HASHDIFF
      , DIM_ACCOUNT_PRODUCT_KEY
    FROM LOGIC_RaTT
)

, RENAME_RaLar as (
    SELECT
        PRODUCT_RETAILER_HK
      , LOAD_DTS
      , DATE
      , CUSTOMER_PRODUCT_ID
      , PRODUCT_ID
      , CUMULATIVE_STAR_RATING
      , CUMULATIVE_REVIEWS
      , CUMULATIVE_5_STAR_REVIEWS
      , CUMULATIVE_4_STAR_REVIEWS
      , CUMULATIVE_3_STAR_REVIEWS
      , CUMULATIVE_2_STAR_REVIEWS
      , CUMULATIVE_1_STAR_REVIEWS
      , RETAILER_ID
      , SOURCE_UPDATED_AT
      , UPDATED_AT
      , CUMULATIVE_RATINGS
      , BKCC
      , REC_SRC
      , HASHDIFF
      , DIM_ACCOUNT_PRODUCT_KEY
    FROM LOGIC_RaLar
)
---- FILTER LAYER ----

, FILTER_RaWin as (
    SELECT *
    FROM RENAME_RaWin
)

, FILTER_RaSec as (
    SELECT *
    FROM RENAME_RaSec
)

, FILTER_RaFy as (
    SELECT *
    FROM RENAME_RaFy
)

, FILTER_RaFib as (
    SELECT *
    FROM RENAME_RaFib
)

, FILTER_RaTT as (
    SELECT *
    FROM RENAME_RaTT
)

, FILTER_RaLar as (
    SELECT *
    FROM RENAME_RaLar
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_RaWin
    UNION ALL
    SELECT * FROM FILTER_RaSec
    UNION ALL
    SELECT * FROM FILTER_RaFy
    UNION ALL
    SELECT * FROM FILTER_RaFib
    UNION ALL
    SELECT * FROM FILTER_RaTT
    UNION ALL
    SELECT * FROM FILTER_RaLar
)

---- FINAL LAYER ----
SELECT
          PRODUCT_RETAILER_HK
        , LOAD_DTS
        , DATE
        , CUSTOMER_PRODUCT_ID
        , PRODUCT_ID
        , CUMULATIVE_STAR_RATING
        , CUMULATIVE_REVIEWS
        , CUMULATIVE_5_STAR_REVIEWS
        , CUMULATIVE_4_STAR_REVIEWS
        , CUMULATIVE_3_STAR_REVIEWS
        , CUMULATIVE_2_STAR_REVIEWS
        , CUMULATIVE_1_STAR_REVIEWS
        , RETAILER_ID
        , SOURCE_UPDATED_AT
        , UPDATED_AT
        , CUMULATIVE_RATINGS
        , DIM_ACCOUNT_PRODUCT_KEY
        , BKCC
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PRODUCT_RETAILER_HK = JOIN_RESULT.PRODUCT_RETAILER_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by PRODUCT_RETAILER_HK, HASHDIFF order by UPDATED_AT DESC, LOAD_DTS DESC) 
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS PRODUCT_RETAILER_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, DATE('1900-01-01') as DATE
, null as CUSTOMER_PRODUCT_ID
, null as PRODUCT_ID
, null as CUMULATIVE_STAR_RATING
, null as CUMULATIVE_REVIEWS
, null as CUMULATIVE_5_STAR_REVIEWS
, null as CUMULATIVE_4_STAR_REVIEWS
, null as CUMULATIVE_3_STAR_REVIEWS
, null as CUMULATIVE_2_STAR_REVIEWS
, null as CUMULATIVE_1_STAR_REVIEWS
, null as RETAILER_ID
, null as SOURCE_UPDATED_AT
, null as UPDATED_AT
, null as CUMULATIVE_REVIEWS
, TO_NUMBER(GR.VALUE,38,0) as DIM_ACCOUNT_PRODUCT_KEY
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}
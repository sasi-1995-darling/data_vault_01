---- SRC LAYER ----
WITH
SRC_SWINN          as ( SELECT * FROM {{ ref('v_psa_stg_sns_categories__profitero_winn') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SNS_CATEGORY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SSEC           as ( SELECT * FROM {{ ref('v_psa_stg_sns_categories__profitero_security') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SNS_CATEGORY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SALWIN         as ( SELECT * FROM {{ ref('v_psa_stg_sns_sales__profitero_winn') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SNS_CATEGORY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_SALSEC         as ( SELECT * FROM {{ ref('v_psa_stg_sns_sales__profitero_security') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SNS_CATEGORY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_winnprofiteroshare            as ( SELECT SNS_CATEGORY_HK, SNS_CATEGORY_BK, LOAD_DTS, BKCC, REC_SRC FROM {{ ref('v_psa_stg_amz_category__winn_profitero_share') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SNS_CATEGORY_BK, BKCC ORDER BY LOAD_DTS)) = 1
),
SRC_securityprofiteroshare            as ( SELECT SNS_CATEGORY_HK, SNS_CATEGORY_BK, LOAD_DTS, BKCC, REC_SRC FROM {{ ref('v_psa_stg_amz_category__security_profitero_share') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SNS_CATEGORY_BK, BKCC ORDER BY LOAD_DTS)) = 1
), 
SRC_ShSlWIN        as ( SELECT * FROM {{ ref('v_psa_stg_amz_product_sale__winn_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SNS_CATEGORY_HK ORDER BY LOAD_DTS ))=1 ),
SRC_ShSlSEC        as ( SELECT * FROM {{ ref('v_psa_stg_amz_product_sale__security_profitero_share') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SNS_CATEGORY_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_SWINN          as ( SELECT * FROM STAGING.v_psa_stg_sns_categories__profitero_winn )
, SRC_SSEC           as ( SELECT * FROM STAGING.v_psa_stg_sns_categories__profitero_security )
, SRC_SALWIN         as ( SELECT * FROM STAGING.v_psa_stg_sns_sales__profitero_winn )
, SRC_SALSEC         as ( SELECT * FROM STAGING.v_psa_stg_sns_sales__profitero_security )
*/
---- LOGIC LAYER ----

, LOGIC_SWINN as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SWINN
)

, LOGIC_SSEC as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SSEC
)

, LOGIC_SALWIN as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SALWIN
)

, LOGIC_SALSEC as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SALSEC
)

, LOGIC_winnprofiteroshare as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_winnprofiteroshare
)

, LOGIC_securityprofiteroshare as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_securityprofiteroshare
)

, LOGIC_ShSlWIN as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ShSlWIN
)

, LOGIC_ShSlSEC as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ShSlSEC
)
---- RENAME LAYER ----

, RENAME_SWINN as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SWINN
)

, RENAME_SSEC as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SSEC
)

, RENAME_SALWIN as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SALWIN
)

, RENAME_SALSEC as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SALSEC
)

, RENAME_winnprofiteroshare as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_winnprofiteroshare
)

, RENAME_securityprofiteroshare as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_securityprofiteroshare
)

, RENAME_ShSlWIN as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ShSlWIN
)

, RENAME_ShSlSEC as (
    SELECT
        SNS_CATEGORY_HK
      , SNS_CATEGORY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ShSlSEC
)
---- FILTER LAYER ----

, FILTER_SWINN as (
    SELECT *
    FROM RENAME_SWINN
)

, FILTER_SSEC as (
    SELECT *
    FROM RENAME_SSEC
)

, FILTER_SALWIN as (
    SELECT *
    FROM RENAME_SALWIN
)

, FILTER_SALSEC as (
    SELECT *
    FROM RENAME_SALSEC
)

, FILTER_winnprofiteroshare as (
    SELECT *
    FROM RENAME_winnprofiteroshare
)

, FILTER_securityprofiteroshare as (
    SELECT *
    FROM RENAME_securityprofiteroshare
)

, FILTER_ShSlWIN as (
    SELECT *
    FROM RENAME_ShSlWIN
)

, FILTER_ShSlSEC as (
    SELECT *
    FROM RENAME_ShSlSEC
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SWINN
    UNION ALL
    SELECT * FROM FILTER_SSEC
    UNION ALL
    SELECT * FROM FILTER_SALWIN
    UNION ALL
    SELECT * FROM FILTER_SALSEC
    UNION ALL
    SELECT * FROM FILTER_winnprofiteroshare
    UNION ALL
    SELECT * FROM FILTER_securityprofiteroshare
    UNION ALL
    SELECT * FROM FILTER_ShSlWIN
    UNION ALL
    SELECT * FROM FILTER_ShSlSEC
)

---- FINAL LAYER ----
SELECT
          SNS_CATEGORY_HK
        , SNS_CATEGORY_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.SNS_CATEGORY_HK = JOIN_RESULT.SNS_CATEGORY_HK
)
{% endif %}
QUALIFY ROW_NUMBER() OVER(PARTITION BY SNS_CATEGORY_HK ORDER BY LOAD_DTS DESC)=1
{% if not is_incremental() %}
union all

SELECT MD5_BINARY(GR.VALUE::varchar)  SNS_CATEGORY_HK
, GR.VALUE::varchar  AS SNS_CATEGORY_BK
, DECODE(GR.VALUE::varchar, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
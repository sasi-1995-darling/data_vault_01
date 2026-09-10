{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['DATE', 'ASIN_HK', 'SNS_CATEGORY_HK'],
    transient = true,
    on_schema_change = 'sync_all_columns',
    full_refresh = var('force_full_refresh', false),
    tags = ['materialization_override', 'large_volume', 'hub']
  )
}}
-- Intentional materialization override to avoid performance bottlenecks caused by chained ephemeral models.



-- Pre-deduplicated sales (both business units, latest per partition)
WITH sns_sales AS (
    SELECT
        SNS_CATEGORY_HK,
        ASIN_HK,
        DATE,
        LOAD_DTS,
        ASIN,
        PLATFORM,
        FIRST_PARTY_SALES,
        THIRD_PARTY_SALES,
        TOTAL_SALES,
        FIRST_PARTY_UNITS,
        THIRD_PARTY_UNITS,
        TOTAL_UNITS,
        REPORTED_IN_ARA,
        IS_DELETED,
        PSA_LOAD_DTS,
        BKCC,
        BUSINESS_UNIT
    FROM (
        SELECT ASIN, ASIN_HK, BKCC, DATE, FIRST_PARTY_SALES, FIRST_PARTY_UNITS, IS_DELETED, LOAD_DTS, PLATFORM, PSA_LOAD_DTS, REC_SRC, REPORTED_IN_ARA, SNS_CATEGORY_HK, SNS_CATEGORY_ID, THIRD_PARTY_SALES, THIRD_PARTY_UNITS, TOTAL_SALES, TOTAL_UNITS, 'WINN' AS BUSINESS_UNIT
        FROM {{ ref('lsat_sns_sales__profitero_winn') }}
        {% if is_incremental() %}
        WHERE LOAD_DTS >= DATEADD(DAY, -3, CURRENT_DATE())
        {% endif %}

        UNION ALL

        SELECT ASIN, ASIN_HK, BKCC, DATE, FIRST_PARTY_SALES, FIRST_PARTY_UNITS, IS_DELETED, LOAD_DTS, PLATFORM, PSA_LOAD_DTS, REC_SRC, REPORTED_IN_ARA, SNS_CATEGORY_HK, SNS_CATEGORY_ID, THIRD_PARTY_SALES, THIRD_PARTY_UNITS, TOTAL_SALES, TOTAL_UNITS, 'Security' AS BUSINESS_UNIT
        FROM {{ ref('lsat_sns_sales__profitero_security') }}
        {% if is_incremental() %}
        WHERE LOAD_DTS >= DATEADD(DAY, -3, CURRENT_DATE())
        {% endif %}
    )
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY date, asin_hk, sns_category_hk
        ORDER BY load_dts DESC
    ) = 1
)
TABLE sns_sales
{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'SNS_CATEGORY_HK',
    transient = true,
    on_schema_change = 'sync_all_columns',
    full_refresh = var('force_full_refresh', false),
    tags = ['materialization_override', 'large_volume', 'hub']
  )
}}
-- Intentional materialization override to avoid performance bottlenecks caused by chained ephemeral models.



-- Pre-deduplicated categories (latest per sns_category_hk)
WITH sns_categories AS (
    SELECT
         SNS_CATEGORY_HK
        , ID
        , LOAD_DTS
        , NAME
        , TYPE
        , IS_DELETED
        , UPDATED_AT
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
    FROM (
        SELECT  ID
        , LOAD_DTS
        , NAME
        , TYPE
        , IS_DELETED
        , UPDATED_AT
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , SNS_CATEGORY_HK
        , BKCC
        , REC_SRC
        FROM {{ ref('sat_sns_categories__profitero_winn') }}
        {% if is_incremental() %}
        WHERE LOAD_DTS >= DATEADD(DAY, -3, CURRENT_DATE())
        {% endif %}

        UNION ALL
        
        SELECT  ID
        , LOAD_DTS
        , NAME
        , TYPE
        , IS_DELETED
        , UPDATED_AT
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , SNS_CATEGORY_HK
        , BKCC
        , REC_SRC
        FROM {{ ref('sat_sns_categories__profitero_security') }}
        {% if is_incremental() %}
        WHERE LOAD_DTS >= DATEADD(DAY, -3, CURRENT_DATE())
        {% endif %}
    )
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY sns_category_hk
        ORDER BY load_dts DESC
    ) = 1
)

TABLE sns_categories
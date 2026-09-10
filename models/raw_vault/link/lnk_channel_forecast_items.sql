---- SRC LAYER ----
WITH
SRC_v1             as ( SELECT ITEM_HK, LOAD_DTS, REC_SRC, STORE_HK, CHANNEL_FORECAST_ITEMS_LHK FROM {{ ref('v_psa_stg_channel_forecast_items_inc__amazon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CHANNEL_FORECAST_ITEMS_LHK ORDER BY LOAD_DTS ))=1 ),
SRC_v2             as ( SELECT ITEM_HK, LOAD_DTS, REC_SRC, STORE_HK, CHANNEL_FORECAST_ITEMS_LHK FROM {{ ref('v_psa_stg_channel_forecast_items_anaheim__amazon') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY CHANNEL_FORECAST_ITEMS_LHK ORDER BY LOAD_DTS ))=1 )

/*
SRC_v1             as ( SELECT * FROM STAGING.v_psa_stg_channel_forecast_items_inc__amazon )
SRC_v2             as ( SELECT * FROM STAGING.v_psa_stg_channel_forecast_items_anaheim__amazon )
*/
---- LOGIC LAYER ----

, LOGIC_v1 as (
    SELECT
        CHANNEL_FORECAST_ITEMS_LHK
      , ITEM_HK
      , STORE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_v1
)

, LOGIC_v2 as (
    SELECT
        CHANNEL_FORECAST_ITEMS_LHK
      , ITEM_HK
      , STORE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_v2
)
---- RENAME LAYER ----

, RENAME_v1 as (
    SELECT
        CHANNEL_FORECAST_ITEMS_LHK
      , ITEM_HK
      , STORE_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_v1
)

, RENAME_v2 as (
    SELECT
        CHANNEL_FORECAST_ITEMS_LHK
      , ITEM_HK
      , STORE_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_v2
)
---- FILTER LAYER ----

, FILTER_v1 as (
    SELECT *
    FROM RENAME_v1
)

, FILTER_v2 as (
    SELECT *
    FROM RENAME_v2
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_v1
    UNION all
    SELECT *
    FROM FILTER_v2
)

---- FINAL LAYER ----
SELECT
          CHANNEL_FORECAST_ITEMS_LHK
        , ITEM_HK
        , STORE_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
SELECT 1 
FROM {{ this }} existing
WHERE existing.CHANNEL_FORECAST_ITEMS_LHK= JOIN_RESULT.CHANNEL_FORECAST_ITEMS_LHK
)
{% endif %}
qualify 1 = row_number() over (partition by CHANNEL_FORECAST_ITEMS_LHK order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS CHANNEL_FORECAST_ITEMS_LHK,
MD5_BINARY(GR.VALUE) AS ITEM_HK,
MD5_BINARY(GR.VALUE) AS STORE_HK,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

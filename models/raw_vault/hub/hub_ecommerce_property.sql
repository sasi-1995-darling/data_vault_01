---- SRC LAYER ----
WITH
SRC_GAPTCH         as ( SELECT BKCC, ECOMMERCE_PROPERTY_BK, ECOMMERCE_PROPERTY_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_ecommerce_property_traffic_by_channel_history__winn_google_analytics') }} as SRC  ),
SRC_GAEPH          as ( SELECT BKCC, ECOMMERCE_PROPERTY_BK, ECOMMERCE_PROPERTY_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_ecommerce_properties_history__winn_google_analytics') }} as SRC  ),
SRC_GAPTC          as ( SELECT BKCC, ECOMMERCE_PROPERTY_BK, ECOMMERCE_PROPERTY_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_ecommerce_property_traffic_by_channel__winn_google_analytics') }} as SRC  ),
SRC_GAEP           as ( SELECT BKCC, ECOMMERCE_PROPERTY_BK, ECOMMERCE_PROPERTY_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_ecommerce_properties__winn_google_analytics') }} as SRC  )

/*
SRC_GAPTCH         as ( SELECT * FROM STAGING.v_psa_stg_ecommerce_property_traffic_by_channel_history__winn_google_analytics )
SRC_GAEPH          as ( SELECT * FROM STAGING.v_psa_stg_ecommerce_properties_history__winn_google_analytics )
SRC_GAPTC          as ( SELECT * FROM STAGING.v_psa_stg_ecommerce_property_traffic_by_channel__winn_google_analytics )
SRC_GAEP           as ( SELECT * FROM STAGING.v_psa_stg_ecommerce_properties__winn_google_analytics )
*/
---- LOGIC LAYER ----

, LOGIC_GAPTCH as (
    SELECT
        ECOMMERCE_PROPERTY_HK
      , ECOMMERCE_PROPERTY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_GAPTCH
)

, LOGIC_GAEPH as (
    SELECT
        ECOMMERCE_PROPERTY_HK
      , ECOMMERCE_PROPERTY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_GAEPH
)

, LOGIC_GAPTC as (
    SELECT
        ECOMMERCE_PROPERTY_HK
      , ECOMMERCE_PROPERTY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_GAPTC
)

, LOGIC_GAEP as (
    SELECT
        ECOMMERCE_PROPERTY_HK
      , ECOMMERCE_PROPERTY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_GAEP
)
---- RENAME LAYER ----

, RENAME_GAPTCH as (
    SELECT
        ECOMMERCE_PROPERTY_HK
      , ECOMMERCE_PROPERTY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_GAPTCH
)

, RENAME_GAEPH as (
    SELECT
        ECOMMERCE_PROPERTY_HK
      , ECOMMERCE_PROPERTY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_GAEPH
)

, RENAME_GAPTC as (
    SELECT
        ECOMMERCE_PROPERTY_HK
      , ECOMMERCE_PROPERTY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_GAPTC
)

, RENAME_GAEP as (
    SELECT
        ECOMMERCE_PROPERTY_HK
      , ECOMMERCE_PROPERTY_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_GAEP
)
---- FILTER LAYER ----

, FILTER_GAPTCH as (
    SELECT *
    FROM RENAME_GAPTCH
)

, FILTER_GAEPH as (
    SELECT *
    FROM RENAME_GAEPH
)

, FILTER_GAPTC as (
    SELECT *
    FROM RENAME_GAPTC
)

, FILTER_GAEP as (
    SELECT *
    FROM RENAME_GAEP
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_GAPTCH
    UNION ALL
    SELECT * FROM FILTER_GAEPH
    UNION ALL
    SELECT * FROM FILTER_GAPTC
    UNION ALL
    SELECT * FROM FILTER_GAEP
)

---- FINAL LAYER ----
SELECT
          ECOMMERCE_PROPERTY_HK
        , ECOMMERCE_PROPERTY_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ECOMMERCE_PROPERTY_HK = JOIN_RESULT.ECOMMERCE_PROPERTY_HK
)
{% endif %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
qualify 1 = row_number() over (partition by ECOMMERCE_PROPERTY_BK, BKCC order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ECOMMERCE_PROPERTY_HK,
GR.VALUE::text AS ECOMMERCE_PROPERTY_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

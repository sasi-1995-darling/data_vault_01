---- SRC LAYER ----
WITH
SRC_SOHWSH         as ( SELECT BKCC, CONSUMER_BK, CONSUMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_dtc_order_header__winn_shopify') }} as SRC  ),
SRC_UEIOSS         as ( SELECT BKCC, CONSUMER_BK, CONSUMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_user_engagement_ios_screen') }} as SRC  ),
SRC_UEANT          as ( SELECT BKCC, CONSUMER_BK, CONSUMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_user_engagement_android_track') }} as SRC  ),
SRC_UEANS          as ( SELECT BKCC, CONSUMER_BK, CONSUMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_user_engagement_android_screen') }} as SRC  ),
SRC_UEIOST         as ( SELECT BKCC, CONSUMER_BK, CONSUMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_user_engagement_ios_track') }} as SRC  ),
SRC_UEANSF         as ( SELECT BKCC, CONSUMER_BK, CONSUMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_user_engagement_android_screen_flo') }} as SRC  ),
SRC_UEANTF         as ( SELECT BKCC, CONSUMER_BK, CONSUMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_user_engagement_android_track_flo') }} as SRC  ),
SRC_UEIOSSF        as ( SELECT BKCC, CONSUMER_BK, CONSUMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_user_engagement_ios_screen_flo') }} as SRC  ),
SRC_UEIOSTF        as ( SELECT BKCC, CONSUMER_BK, CONSUMER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_user_engagement_ios_track_flo') }} as SRC  )

/*
SRC_SOHWSH         as ( SELECT * FROM STAGING.v_psa_stg_dtc_order_header__winn_shopify )
SRC_UEIOSS         as ( SELECT * FROM STAGING.v_psa_stg_user_engagement_ios_screen )
SRC_UEANT          as ( SELECT * FROM STAGING.v_psa_stg_user_engagement_android_track )
SRC_UEANS          as ( SELECT * FROM STAGING.v_psa_stg_user_engagement_android_screen )
SRC_UEIOST         as ( SELECT * FROM STAGING.v_psa_stg_user_engagement_ios_track )
SRC_UEANSF         as ( SELECT * FROM STAGING.v_psa_stg_user_engagement_android_screen_flo )
SRC_UEANTF         as ( SELECT * FROM STAGING.v_psa_stg_user_engagement_android_track_flo )
SRC_UEIOSSF        as ( SELECT * FROM STAGING.v_psa_stg_user_engagement_ios_screen_flo )
SRC_UEIOSTF        as ( SELECT * FROM STAGING.v_psa_stg_user_engagement_ios_track_flo )
*/
---- LOGIC LAYER ----

, LOGIC_SOHWSH as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SOHWSH
)

, LOGIC_UEIOSS as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_UEIOSS
)

, LOGIC_UEANT as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_UEANT
)

, LOGIC_UEANS as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_UEANS
)

, LOGIC_UEIOST as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_UEIOST
)

, LOGIC_UEANSF as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_UEANSF
)

, LOGIC_UEANTF as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_UEANTF
)

, LOGIC_UEIOSSF as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_UEIOSSF
)

, LOGIC_UEIOSTF as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_UEIOSTF
)
---- RENAME LAYER ----

, RENAME_SOHWSH as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SOHWSH
)

, RENAME_UEIOSS as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_UEIOSS
)

, RENAME_UEANT as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_UEANT
)

, RENAME_UEANS as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_UEANS
)

, RENAME_UEIOST as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_UEIOST
)

, RENAME_UEANSF as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_UEANSF
)

, RENAME_UEANTF as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_UEANTF
)

, RENAME_UEIOSSF as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_UEIOSSF
)

, RENAME_UEIOSTF as (
    SELECT
        CONSUMER_HK
      , CONSUMER_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_UEIOSTF
)
---- FILTER LAYER ----

, FILTER_SOHWSH as (
    SELECT *
    FROM RENAME_SOHWSH
)

, FILTER_UEIOSS as (
    SELECT *
    FROM RENAME_UEIOSS
)

, FILTER_UEANT as (
    SELECT *
    FROM RENAME_UEANT
)

, FILTER_UEANS as (
    SELECT *
    FROM RENAME_UEANS
)

, FILTER_UEIOST as (
    SELECT *
    FROM RENAME_UEIOST
)

, FILTER_UEANSF as (
    SELECT *
    FROM RENAME_UEANSF
)

, FILTER_UEANTF as (
    SELECT *
    FROM RENAME_UEANTF
)

, FILTER_UEIOSSF as (
    SELECT *
    FROM RENAME_UEIOSSF
)

, FILTER_UEIOSTF as (
    SELECT *
    FROM RENAME_UEIOSTF
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SOHWSH
    UNION ALL
    SELECT * FROM FILTER_UEIOSS
    UNION ALL
    SELECT * FROM FILTER_UEANT
    UNION ALL
    SELECT * FROM FILTER_UEANS
    UNION ALL
    SELECT * FROM FILTER_UEIOST
    UNION ALL
    SELECT * FROM FILTER_UEANSF
    UNION ALL
    SELECT * FROM FILTER_UEANTF
    UNION ALL
    SELECT * FROM FILTER_UEIOSSF
    UNION ALL
    SELECT * FROM FILTER_UEIOSTF
)

---- FINAL LAYER ----
SELECT
          CONSUMER_HK
        , CONSUMER_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.CONSUMER_HK = JOIN_RESULT.CONSUMER_HK
)
{% endif %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per BKs and BKCC. */
qualify 1 = row_number() over (partition by CONSUMER_HK order by LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS CONSUMER_HK,
GR.VALUE::text AS CONSUMER_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

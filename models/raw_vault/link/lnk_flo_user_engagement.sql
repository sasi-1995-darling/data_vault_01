---- SRC LAYER ----
WITH
SRC_LFU            as ( SELECT ENGAGEMENT_USER_HK, FLO_USER_ENGAGEMENT_HK, FLO_USER_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_flo_user') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY FLO_USER_ENGAGEMENT_HK ORDER BY LOAD_DTS))=1 )

/*
SRC_LFU            as ( SELECT * FROM STAGING.v_psa_stg_flo_user )
*/
---- LOGIC LAYER ----

, LOGIC_LFU as (
    SELECT
        FLO_USER_ENGAGEMENT_HK
      , FLO_USER_HK
      , ENGAGEMENT_USER_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_LFU
)
---- RENAME LAYER ----

, RENAME_LFU as (
    SELECT
        FLO_USER_ENGAGEMENT_HK
      , FLO_USER_HK
      , ENGAGEMENT_USER_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_LFU
)
---- FILTER LAYER ----

, FILTER_LFU as (
    SELECT *
    FROM RENAME_LFU
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_LFU
)

---- FINAL LAYER ----
SELECT
          FLO_USER_ENGAGEMENT_HK
        , FLO_USER_HK
        , ENGAGEMENT_USER_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.FLO_USER_ENGAGEMENT_HK = JOIN_RESULT.FLO_USER_ENGAGEMENT_HK
)
{% endif %}
--this is to consolidate records coming from 2 diff tables with the same bkcc
QUALIFY (ROW_NUMBER() OVER(PARTITION BY FLO_USER_ENGAGEMENT_HK ORDER BY LOAD_DTS))=1
{% if not is_incremental() %}

union all
SELECT 
 MD5_BINARY(GR.VALUE) AS FLO_USER_ENGAGEMENT_HK
, MD5_BINARY(GR.VALUE) AS FLO_USER_HK
, MD5_BINARY(GR.VALUE) AS ENGAGEMENT_USER_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
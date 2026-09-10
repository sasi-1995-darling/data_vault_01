---- SRC LAYER ----
WITH
SRC_QMUR           as ( SELECT * FROM {{ ref('v_psa_stg_quality_causes') }} as SRC
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY QUALITY_CAUSES_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_QMFE           as ( SELECT * FROM STAGING.v_psa_stg_quality_notifications_items )
, SRC_QMUR           as ( SELECT * FROM STAGING.v_psa_stg_quality_causes )
*/
---- LOGIC LAYER ----

, LOGIC_QMUR as (
    SELECT
        QUALITY_ISSUE_CAUSES_HK
      , QUALITY_CAUSES_HK                                                                                                                                                               
      , QUALITY_CAUSES_BK
      , QUALITY_ISSUE_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_QMUR
)
---- RENAME LAYER ----

, RENAME_QMUR as (
    SELECT
        QUALITY_ISSUE_CAUSES_HK
      , QUALITY_CAUSES_HK
      , QUALITY_CAUSES_BK
      , QUALITY_ISSUE_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_QMUR
)
---- FILTER LAYER ----

, FILTER_QMUR as (
    SELECT *
    FROM RENAME_QMUR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_QMUR
)

---- FINAL LAYER ----
SELECT
          QUALITY_ISSUE_CAUSES_HK
        , QUALITY_CAUSES_HK
        , QUALITY_ISSUE_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.QUALITY_ISSUE_CAUSES_HK = JOIN_RESULT.QUALITY_ISSUE_CAUSES_HK
)
{% endif %}

{% if not is_incremental() %}
union all
SELECT 
MD5_BINARY(GR.VALUE) as QUALITY_ISSUE_CAUSES_HK
, MD5_BINARY(GR.VALUE) as QUALITY_CAUSES_HK
, MD5_BINARY(GR.VALUE) as QUALITY_ISSUE_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
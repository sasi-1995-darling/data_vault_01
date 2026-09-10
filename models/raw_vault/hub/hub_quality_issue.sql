---- SRC LAYER ----
WITH
SRC_SQA            as ( SELECT QUALITY_ISSUE_HK , QUALITY_ISSUE_BK , LOAD_DTS , REC_SRC , BKCC FROM {{ ref('v_psa_stg_quality_notifications_items') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY QUALITY_ISSUE_BK ORDER BY LOAD_DTS ))=1 )

/*
SRC_SQA            as ( SELECT * FROM STAGING.v_psa_stg_quality_notifications_items )
*/
---- LOGIC LAYER ----

, LOGIC_SQA as (
    SELECT
       QUALITY_ISSUE_HK 
      , QUALITY_ISSUE_BK
      , LOAD_DTS
      , REC_SRC
      , BKCC
    FROM SRC_SQA
)
---- RENAME LAYER ----

, RENAME_SQA as (
    SELECT
        QUALITY_ISSUE_HK
      , QUALITY_ISSUE_BK
      , LOAD_DTS
      , REC_SRC
      , BKCC
    FROM LOGIC_SQA
)
---- FILTER LAYER ----

, FILTER_SQA as (
    SELECT *
    FROM RENAME_SQA
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SQA
)

---- FINAL LAYER ----
SELECT
         QUALITY_ISSUE_HK 
        , QUALITY_ISSUE_BK
        , LOAD_DTS
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.QUALITY_ISSUE_HK= JOIN_RESULT.QUALITY_ISSUE_HK
)
{% endif %}
 QUALIFY ROW_NUMBER() OVER(PARTITION BY QUALITY_ISSUE_BK, BKCC ORDER BY LOAD_DTS)=1
{% if not is_incremental() %}
union all
SELECT MD5_BINARY(GR.VALUE)  QUALITY_ISSUE_HK
, GR.VALUE  AS QUALITY_ISSUE_BK
, CONVERT_TIMEZONE('UTC','1900-01-01') as LOAD_DTS 
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
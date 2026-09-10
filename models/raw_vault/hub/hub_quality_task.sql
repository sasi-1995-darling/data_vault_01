---- SRC LAYER ----
WITH
SRC_QMSM           as ( SELECT QUALITY_TASKS_HK , QUALITY_TASKS_BK , BKCC , LOAD_DTS , REC_SRC FROM {{ ref('v_psa_stg_quality_notifications_task') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY QUALITY_TASKS_BK ORDER BY LOAD_DTS desc ))=1 )

/*
SRC_QMSM           as ( SELECT * FROM STAGING.V_PSA_STG_QUALITY_NOTIFICATIONS_TASK )
*/
---- LOGIC LAYER ----

, LOGIC_QMSM as (
    SELECT
        QUALITY_TASKS_HK
      , QUALITY_TASKS_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_QMSM
)
---- RENAME LAYER ----

, RENAME_QMSM as (
    SELECT
        QUALITY_TASKS_HK
      , QUALITY_TASKS_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_QMSM
)
---- FILTER LAYER ----

, FILTER_QMSM as (
    SELECT *
    FROM RENAME_QMSM
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_QMSM
)

---- FINAL LAYER ----
SELECT
          QUALITY_TASKS_HK
        , QUALITY_TASKS_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.QUALITY_TASKS_HK = JOIN_RESULT.QUALITY_TASKS_HK
)
{% endif %}
QUALIFY ROW_NUMBER() OVER(PARTITION BY QUALITY_TASKS_BK, BKCC ORDER BY LOAD_DTS)=1
{% if not is_incremental() %}
union all

SELECT MD5_BINARY(GR.VALUE)  QUALITY_TASKS_HK
, GR.VALUE   AS QUALITY_TASKS_BK
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, CONVERT_TIMEZONE('UTC','1900-01-01') as LOAD_DTS 
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
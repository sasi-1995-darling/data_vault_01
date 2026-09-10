---- SRC LAYER ----
WITH
SRC_QMSM           as ( SELECT * FROM {{ ref('v_psa_stg_quality_notifications_task') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY QUALITY_TASKS_HK ORDER BY LOAD_DTS ))=1 )

/*
SRC_QMEL           as ( SELECT * FROM STAGING.V_PSA_STG_QUALITY_NOTIFICATIONS )
, SRC_QMSM           as ( SELECT * FROM STAGING.v_psa_stg_quality_notifications_task )
*/
---- LOGIC LAYER ----

, LOGIC_QMSM as (
    SELECT
        QUALITY_TASKS_HK
      , QUALITY_NOTIFICATION_TASK_HK                                                       
      , QUALITY_TASKS_BK
      , QUALITY_NOTIFICATION_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_QMSM
)
---- RENAME LAYER ----

, RENAME_QMSM as (
    SELECT
        QUALITY_TASKS_HK
      , QUALITY_NOTIFICATION_TASK_HK
      , QUALITY_TASKS_BK
      , QUALITY_NOTIFICATION_HK
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
        , QUALITY_NOTIFICATION_TASK_HK
        , QUALITY_NOTIFICATION_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.QUALITY_NOTIFICATION_TASK_HK = JOIN_RESULT.QUALITY_NOTIFICATION_TASK_HK
)
{% endif %}

{% if not is_incremental() %}
union all
SELECT 
MD5_BINARY(GR.VALUE) as QUALITY_TASKS_HK
, MD5_BINARY(GR.VALUE) as QUALITY_NOTIFICATION_TASK_HK
, MD5_BINARY(GR.VALUE) as QUALITY_NOTIFICATION_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
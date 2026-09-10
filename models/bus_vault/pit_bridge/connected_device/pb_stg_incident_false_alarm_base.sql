{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HI             as ( SELECT INCIDENT_BK, INCIDENT_HK FROM {{ ref('hub_incident') }} as SRC  ),
SRC_SID            as ( SELECT ALARM_ID, CREATE_AT, ICD_ID, INCIDENT_HK, STATUS FROM {{ ref('sat_incident_details__flo_prod') }} as SRC 
                        qualify 1= row_number() over(partition by INCIDENT_HK order by LOAD_DTS DESC) ),
SRC_LAF            as ( SELECT ALERT_FEEDBACK_HK, INCIDENT_HK FROM {{ ref('lnk_alert_feedback') }} as SRC  ),
SRC_SAF            as ( SELECT ALERT_FEEDBACK_HK, CAUSE, CREATED_AT, LOAD_DTS FROM {{ ref('lsat_alert_feedback__flo_dynamodb') }} as SRC 
                        qualify 1= row_number() over(partition by ALERT_FEEDBACK_HK order by LOAD_DTS DESC) ),
SRC_HP             as ( SELECT PAIRED_DEVICE_BK, PAIRED_DEVICE_HK FROM {{ ref('hub_paired_device') }} as SRC  ),
SRC_LCD            as ( SELECT DEVICE_HK, LOAD_DTS, PAIRED_DEVICE_HK FROM {{ ref('lnk_icd_device') }} as SRC  ),
SRC_HD             as ( SELECT DEVICE_BK, DEVICE_HK FROM {{ ref('hub_device_v2') }} as SRC  )

/*
SRC_HI             as ( SELECT * FROM raw_vault.HUB_INCIDENT )
SRC_SID            as ( SELECT * FROM raw_vault.SAT_INCIDENT_DETAILS__FLO_PROD )
SRC_LAF            as ( SELECT * FROM raw_vault.LNK_ALERT_FEEDBACK )
SRC_SAF            as ( SELECT * FROM raw_vault.LSAT_ALERT_FEEDBACK__FLO_DYNAMODB )
SRC_HP             as ( SELECT * FROM raw_vault.HUB_PAIRED_DEVICE )
SRC_LCD            as ( SELECT * FROM raw_vault.LNK_ICD_DEVICE )
SRC_HD             as ( SELECT * FROM raw_vault.HUB_DEVICE_V2 )
*/
---- LOGIC LAYER ----

, LOGIC_HI as (
    SELECT
        INCIDENT_HK                                                  as                                     HI_INCIDENT_HK
      , INCIDENT_BK                                                  as                                        INCIDENT_ID
    FROM SRC_HI
)

, LOGIC_SID as (
    SELECT
        INCIDENT_HK                                                  as                                    SID_INCIDENT_HK
      , CASE
            WHEN REGEXP_LIKE(TO_VARCHAR(CREATE_AT), '^[0-9]+$') THEN
            CASE
            WHEN LENGTH(TO_VARCHAR(CREATE_AT)) >= 19 THEN TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(CREATE_AT)) / 1000000000)
            WHEN LENGTH(TO_VARCHAR(CREATE_AT)) >= 16 THEN TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(CREATE_AT)) / 1000000)
            WHEN LENGTH(TO_VARCHAR(CREATE_AT)) >= 13 THEN TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(CREATE_AT)) / 1000)
            ELSE TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(CREATE_AT)))
            END
            ELSE TRY_TO_TIMESTAMP_NTZ(TO_VARCHAR(CREATE_AT))
        END                                                          as                                INCIDENT_CREATED_AT
      , TRY_TO_NUMBER(TO_VARCHAR(ALARM_ID))                          as                                       ALARM_ID_NUM
      , TRY_TO_NUMBER(TO_VARCHAR(STATUS))                            as                                         STATUS_NUM
      , ICD_ID
      , CREATE_AT
      , ALARM_ID
      , STATUS
      , ICD_ID                                                       as                                         SID_ICD_ID
    FROM SRC_SID
)

, LOGIC_LAF as (
    SELECT
        INCIDENT_HK                                                  as                                    LAF_INCIDENT_HK
      , ALERT_FEEDBACK_HK
    FROM SRC_LAF
)

, LOGIC_SAF as (
    SELECT
        ALERT_FEEDBACK_HK                                            as                              SAF_ALERT_FEEDBACK_HK
      , TRY_TO_NUMBER(TO_VARCHAR(CAUSE))                             as                                          CAUSE_NUM
      , CREATED_AT
      , LOAD_DTS                                                     as                                       SAF_LOAD_DTS
      , CAUSE
    FROM SRC_SAF
)

, LOGIC_HP as (
    SELECT
        PAIRED_DEVICE_BK                                             as                                HP_PAIRED_DEVICE_BK
      , PAIRED_DEVICE_HK                                             as                                HP_PAIRED_DEVICE_HK
    FROM SRC_HP
)

, LOGIC_LCD as (
    SELECT
        PAIRED_DEVICE_HK                                             as                               LCD_PAIRED_DEVICE_HK
      , LOAD_DTS                                                     as                                       LCD_LOAD_DTS
      , DEVICE_HK                                                    as                                      LCD_DEVICE_HK
    FROM SRC_LCD
)

, LOGIC_HD as (
    SELECT
        DEVICE_HK                                                    as                                       HD_DEVICE_HK
      , DEVICE_BK                                                    as                                          DEVICE_ID
    FROM SRC_HD
)
---- RENAME LAYER ----

, RENAME_HI as (
    SELECT
        HI_INCIDENT_HK
      , INCIDENT_ID
    FROM LOGIC_HI
)

, RENAME_SID as (
    SELECT
        SID_INCIDENT_HK
      , INCIDENT_CREATED_AT
      , ALARM_ID_NUM
      , STATUS_NUM
      , ICD_ID
      , CREATE_AT
      , ALARM_ID
      , STATUS
      , SID_ICD_ID
    FROM LOGIC_SID
)

, RENAME_LAF as (
    SELECT
        LAF_INCIDENT_HK
      , ALERT_FEEDBACK_HK
    FROM LOGIC_LAF
)

, RENAME_SAF as (
    SELECT
        SAF_ALERT_FEEDBACK_HK
      , CAUSE_NUM
      , CREATED_AT
      , SAF_LOAD_DTS
      , CAUSE
    FROM LOGIC_SAF
)

, RENAME_HP as (
    SELECT
        HP_PAIRED_DEVICE_BK
      , HP_PAIRED_DEVICE_HK
    FROM LOGIC_HP
)

, RENAME_LCD as (
    SELECT
        LCD_PAIRED_DEVICE_HK
      , LCD_LOAD_DTS
      , LCD_DEVICE_HK
    FROM LOGIC_LCD
)

, RENAME_HD as (
    SELECT
        HD_DEVICE_HK
      , DEVICE_ID
    FROM LOGIC_HD
)
---- FILTER LAYER ----

, FILTER_HI as (
    SELECT *
    FROM RENAME_HI
)

, FILTER_SID as (
    SELECT *
    FROM RENAME_SID
)

, FILTER_LAF as (
    SELECT *
    FROM RENAME_LAF
)

, FILTER_SAF as (
    SELECT *
    FROM RENAME_SAF
)

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_LCD as (
    SELECT *
    FROM RENAME_LCD
)

, FILTER_HD as (
    SELECT *
    FROM RENAME_HD
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HI
    INNER JOIN FILTER_SID
        ON HI_INCIDENT_HK = SID_INCIDENT_HK
    LEFT JOIN FILTER_LAF
        ON HI_INCIDENT_HK = LAF_INCIDENT_HK
    LEFT JOIN FILTER_SAF
        ON ALERT_FEEDBACK_HK = SAF_ALERT_FEEDBACK_HK
    INNER JOIN FILTER_HP
        ON SID_ICD_ID = HP_PAIRED_DEVICE_BK
    LEFT JOIN FILTER_LCD
        ON HP_PAIRED_DEVICE_HK = LCD_PAIRED_DEVICE_HK
    LEFT JOIN FILTER_HD
        ON LCD_DEVICE_HK = HD_DEVICE_HK
)

---- FINAL LAYER ----
SELECT
          INCIDENT_ID
        , INCIDENT_CREATED_AT
        , ALARM_ID_NUM
        , STATUS_NUM
        , CAUSE_NUM
        , CASE
  WHEN CAUSE_NUM IS NULL THEN 1
  WHEN CAUSE_NUM NOT IN (5, 6, 11) THEN 1
  ELSE 0
END as IS_FALSE_ALARM
        , DEVICE_ID
        , ROW_NUMBER() OVER (
  PARTITION BY COALESCE(ALERT_FEEDBACK_HK, HI_INCIDENT_HK)
  ORDER BY
    CASE
      WHEN REGEXP_LIKE(TO_VARCHAR(CREATED_AT), '^[0-9]+$') THEN
        CASE
          WHEN LENGTH(TO_VARCHAR(CREATED_AT)) >= 19 THEN TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(CREATED_AT)) / 1000000000)
          WHEN LENGTH(TO_VARCHAR(CREATED_AT)) >= 16 THEN TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(CREATED_AT)) / 1000000)
          WHEN LENGTH(TO_VARCHAR(CREATED_AT)) >= 13 THEN TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(CREATED_AT)) / 1000)
          ELSE TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(CREATED_AT)))
        END
      ELSE TRY_TO_TIMESTAMP_NTZ(TO_VARCHAR(CREATED_AT))
    END DESC NULLS LAST,
    SAF_LOAD_DTS DESC
) as RN_LATEST_FEEDBACK_PER_INCIDENT
        , ROW_NUMBER() OVER (
  PARTITION BY HI_INCIDENT_HK
  ORDER BY LCD_LOAD_DTS DESC NULLS LAST
) as RN_DEVICE_MAP_PER_INCIDENT
        , 'Dancing_Seal'                                               as BKCC
        , 'US.FLO_PROD.INCIDENTS_ALERT_FEEDBACK'                       as REC_SRC
FROM JOIN_RESULT
WHERE ALARM_ID_NUM IN (70,71,72,73,74)
AND STATUS_NUM IN (3,4)
AND INCIDENT_CREATED_AT IS NOT NULL
AND DEVICE_ID IS NOT NULL

qualify
RN_LATEST_FEEDBACK_PER_INCIDENT = 1
AND RN_DEVICE_MAP_PER_INCIDENT = 1
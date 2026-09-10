{#
  PIT Bridge: Critical Alert Device Event
  ----------------------------------------
  For each critical alert, captures:
    1. The shutoff that followed within 10 minutes (if any)
    2. The first valve reopen after the shutoff (if any)
    3. Customer feedback on the alert (if any)
  Output: one row per critical alert.

  Sources: Raw Vault (hub/sat/link) + dimension for user mapping.
  Replaces manual SQL query against DL tables + DW.MASTER.DEVICE_AGG_VIEW.
#}

---- SRC LAYER ----
WITH
-- Incident hub: INCIDENT_HK ↔ INCIDENT_BK (= incident ID)
SRC_HI  AS (
    SELECT INCIDENT_HK, INCIDENT_BK, BKCC, REC_SRC
    FROM {{ ref('hub_incident') }}
),

-- Incident satellite: latest attributes per incident
SRC_SID AS (
    SELECT INCIDENT_HK, ALARM_ID, CREATE_AT, ICD_ID, STATUS
    FROM {{ ref('sat_incident_details__flo_prod') }}
    QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY INCIDENT_HK ORDER BY LOAD_DTS DESC)
),

-- Paired device hub: ICD_ID = PAIRED_DEVICE_BK
SRC_HP  AS (
    SELECT PAIRED_DEVICE_HK, PAIRED_DEVICE_BK
    FROM {{ ref('hub_paired_device') }}
),

-- ICD → Device link: maps PAIRED_DEVICE_HK → DEVICE_HK
SRC_LCD AS (
    SELECT PAIRED_DEVICE_HK, DEVICE_HK
    FROM {{ ref('lnk_icd_device') }}
),

-- Device hub: DEVICE_HK → DEVICE_BK (= DEVICE_ID)
SRC_HD  AS (
    SELECT DEVICE_HK, DEVICE_BK
    FROM {{ ref('hub_device_v2') }}
),

-- Paired device → Location link: latest location per paired device
SRC_LPL AS (
    SELECT PAIRED_DEVICE_HK, DEVICE_LOCATION_HK
    FROM {{ ref('lnk_paired_device_location') }}
    QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY PAIRED_DEVICE_HK ORDER BY LOAD_DTS DESC)
),

-- Device location satellite: latest ACCOUNT_ID per location
SRC_SDL AS (
    SELECT DEVICE_LOCATION_HK, ACCOUNT_ID
    FROM {{ ref('sat_device_location_details__flo_dynamodb') }}
    QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY DEVICE_LOCATION_HK ORDER BY LOAD_DTS DESC)
),

-- Account hub: ACCOUNT_ID → DEVICE_ACCOUNT_HK
SRC_HDA AS (
    SELECT DEVICE_ACCOUNT_HK, DEVICE_ACCOUNT_BK
    FROM {{ ref('hub_device_account') }}
),

-- Account satellite: latest OWNER_USER_ID per account
SRC_SDA AS (
    SELECT DEVICE_ACCOUNT_HK, OWNER_USER_ID
    FROM {{ ref('sat_device_account_details__flo_dynamodb') }}
    QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY DEVICE_ACCOUNT_HK ORDER BY LOAD_DTS DESC)
),

-- Flo user hub: OWNER_USER_ID → USER_ID
SRC_HFU AS (
    SELECT FLO_USER_BK
    FROM {{ ref('hub_flo_user') }}
),

-- Alert feedback link: INCIDENT_HK → ALERT_FEEDBACK_HK
SRC_LAF AS (
    SELECT INCIDENT_HK, ALERT_FEEDBACK_HK
    FROM {{ ref('lnk_alert_feedback') }}
),

-- Alert feedback satellite: latest feedback attributes per feedback record
SRC_SAF AS (
    SELECT ALERT_FEEDBACK_HK, SHOULD_ACCEPT_AS_NORMAL, CAUSE,
           PLUMBING_FAILURE, PLUMBING_FAILURE_OTHER, CREATED_AT, LOAD_DTS
    FROM {{ ref('lsat_alert_feedback__flo_dynamodb') }}
    QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY ALERT_FEEDBACK_HK ORDER BY LOAD_DTS DESC)
)

---- LOGIC LAYER ----

-- Base: all incidents with device + user mapping
-- Joins: hub_incident → sat_incident_details → hub_paired_device (on ICD_ID)
--       → lnk_icd_device → hub_device_v2 (DEVICE_ID)
--       → lnk_paired_device_location → sat_device_location_details (ACCOUNT_ID)
--       → hub_device_account → sat_device_account_details (OWNER_USER_ID) → hub_flo_user
, INCIDENTS_BASE AS (
    SELECT
        HI.INCIDENT_HK,
        HI.INCIDENT_BK                                              AS INCIDENT_ID,
        HI.BKCC,
        HI.REC_SRC,
        -- Parse CREATE_AT: can be numeric epoch (ms/us/ns) or timestamp string
        CASE
            WHEN REGEXP_LIKE(TO_VARCHAR(SID.CREATE_AT), '^[0-9]+$') THEN
                CASE
                    WHEN LENGTH(TO_VARCHAR(SID.CREATE_AT)) >= 19
                        THEN TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(SID.CREATE_AT)) / 1000000000)
                    WHEN LENGTH(TO_VARCHAR(SID.CREATE_AT)) >= 16
                        THEN TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(SID.CREATE_AT)) / 1000000)
                    WHEN LENGTH(TO_VARCHAR(SID.CREATE_AT)) >= 13
                        THEN TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(SID.CREATE_AT)) / 1000)
                    ELSE TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(SID.CREATE_AT)))
                END
            ELSE TRY_TO_TIMESTAMP_NTZ(TO_VARCHAR(SID.CREATE_AT))
        END                                                         AS INCIDENT_TIMESTAMP,
        TRY_TO_NUMBER(TO_VARCHAR(SID.ALARM_ID))                     AS ALARM_ID,
        HD.DEVICE_BK                                                AS DEVICE_ID,
        HFU.FLO_USER_BK                                             AS USER_ID
    FROM SRC_HI HI
    INNER JOIN SRC_SID SID
        ON HI.INCIDENT_HK = SID.INCIDENT_HK
    INNER JOIN SRC_HP HP                                            -- ICD_ID = PAIRED_DEVICE_BK
        ON SID.ICD_ID = HP.PAIRED_DEVICE_BK
    LEFT JOIN SRC_LCD LCD                                           -- paired device → device mapping
        ON HP.PAIRED_DEVICE_HK = LCD.PAIRED_DEVICE_HK
    LEFT JOIN SRC_HD HD                                             -- device hub for DEVICE_ID
        ON LCD.DEVICE_HK = HD.DEVICE_HK
    LEFT JOIN SRC_LPL LPL                                          -- latest location per paired device
        ON HP.PAIRED_DEVICE_HK = LPL.PAIRED_DEVICE_HK
    LEFT JOIN SRC_SDL SDL                                           -- location → account ID
        ON LPL.DEVICE_LOCATION_HK = SDL.DEVICE_LOCATION_HK
    LEFT JOIN SRC_HDA HDA                                           -- account ID → account hash key
        ON SDL.ACCOUNT_ID = HDA.DEVICE_ACCOUNT_BK
    LEFT JOIN SRC_SDA SDA                                           -- account → owner user
        ON HDA.DEVICE_ACCOUNT_HK = SDA.DEVICE_ACCOUNT_HK
    LEFT JOIN SRC_HFU HFU                                           -- owner user → user ID
        ON SDA.OWNER_USER_ID = HFU.FLO_USER_BK
    WHERE HD.DEVICE_BK IS NOT NULL                                  -- exclude unmapped devices
    -- dedup and prefer real device over ghost; tiebreak alphabetically for determinism.
    QUALIFY 1 = ROW_NUMBER() OVER (
        PARTITION BY HI.INCIDENT_HK
        ORDER BY CASE WHEN HD.DEVICE_BK = '-1' THEN 1 ELSE 0 END, HD.DEVICE_BK
    )
)

-- Critical alerts: alarm_id IN (10, 11, 26, 70, 71, 72, 73, 74)
, CRITICAL_ALERTS AS (
    SELECT INCIDENT_HK, INCIDENT_ID, DEVICE_ID, USER_ID, INCIDENT_TIMESTAMP, ALARM_ID, BKCC, REC_SRC
    FROM INCIDENTS_BASE
    WHERE ALARM_ID IN (10, 11, 26, 70, 71, 72, 73, 74)
)

-- Shutoffs: alarm_id IN (51, 52, 53, 55, 80–89)
, SHUTOFFS AS (
    SELECT
        INCIDENT_ID     AS SHUTOFF_ID,
        DEVICE_ID,
        INCIDENT_TIMESTAMP AS SHUTOFF_TIMESTAMP
    FROM INCIDENTS_BASE
    WHERE ALARM_ID IN (51, 52, 53, 55, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89)
)

-- Valve opens: alarm_id IN (35, 47), classified as app/manual
, VALVE_OPENS AS (
    SELECT
        INCIDENT_ID     AS VALVE_OPEN_ID,
        DEVICE_ID,
        INCIDENT_TIMESTAMP AS VALVE_OPEN_TIMESTAMP,
        CASE
            WHEN ALARM_ID = 35 THEN 'app'
            WHEN ALARM_ID = 47 THEN 'manual'
            ELSE 'other'
        END             AS VALVE_OPEN_TYPE
    FROM INCIDENTS_BASE
    WHERE ALARM_ID IN (35, 47)
)

-- Feedback: latest feedback per incident
, FEEDBACK AS (
    SELECT
        LAF.INCIDENT_HK,
        SAF.SHOULD_ACCEPT_AS_NORMAL                                 AS FEEDBACK_NORMAL,
        SAF.CAUSE                                                   AS FEEDBACK_LABEL,
        SAF.PLUMBING_FAILURE,
        SAF.PLUMBING_FAILURE_OTHER,
        CASE
            WHEN REGEXP_LIKE(TO_VARCHAR(SAF.CREATED_AT), '^[0-9]+$') THEN
                CASE
                    WHEN LENGTH(TO_VARCHAR(SAF.CREATED_AT)) >= 19
                        THEN TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(SAF.CREATED_AT)) / 1000000000)
                    WHEN LENGTH(TO_VARCHAR(SAF.CREATED_AT)) >= 16
                        THEN TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(SAF.CREATED_AT)) / 1000000)
                    WHEN LENGTH(TO_VARCHAR(SAF.CREATED_AT)) >= 13
                        THEN TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(SAF.CREATED_AT)) / 1000)
                    ELSE TO_TIMESTAMP_NTZ(TO_NUMBER(TO_VARCHAR(SAF.CREATED_AT)))
                END
            ELSE TRY_TO_TIMESTAMP_NTZ(TO_VARCHAR(SAF.CREATED_AT))
        END                                                         AS FEEDBACK_TIMESTAMP
    FROM SRC_LAF LAF
    INNER JOIN SRC_SAF SAF
        ON LAF.ALERT_FEEDBACK_HK = SAF.ALERT_FEEDBACK_HK
    QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY LAF.INCIDENT_HK ORDER BY SAF.LOAD_DTS DESC)
)

-- Match first shutoff within 10 minutes of each critical alert
, ALERT_SHUTOFF AS (
    SELECT
        CA.INCIDENT_HK,
        CA.INCIDENT_ID,
        CA.DEVICE_ID,
        CA.USER_ID,
        CA.INCIDENT_TIMESTAMP,
        CA.ALARM_ID,
        CA.BKCC,
        CA.REC_SRC,
        S.SHUTOFF_ID,
        S.SHUTOFF_TIMESTAMP
    FROM CRITICAL_ALERTS CA
    LEFT JOIN SHUTOFFS S
        ON  S.DEVICE_ID = CA.DEVICE_ID
        AND S.SHUTOFF_TIMESTAMP BETWEEN CA.INCIDENT_TIMESTAMP
                                    AND DATEADD('MINUTE', 10, CA.INCIDENT_TIMESTAMP)
    -- Keep first shutoff per critical alert (earliest timestamp, tiebreak on ID for determinism)
    QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY CA.INCIDENT_ID ORDER BY S.SHUTOFF_TIMESTAMP NULLS LAST, S.SHUTOFF_ID)
)

-- Match first valve open after the shutoff
, ALERT_SHUTOFF_VALVE AS (
    SELECT
        A_S.INCIDENT_HK,
        A_S.INCIDENT_ID,
        A_S.DEVICE_ID,
        A_S.USER_ID,
        A_S.INCIDENT_TIMESTAMP,
        A_S.ALARM_ID,
        A_S.BKCC,
        A_S.REC_SRC,
        A_S.SHUTOFF_ID,
        A_S.SHUTOFF_TIMESTAMP,
        V.VALVE_OPEN_ID,
        V.VALVE_OPEN_TYPE,
        V.VALVE_OPEN_TIMESTAMP
    FROM ALERT_SHUTOFF A_S
    LEFT JOIN VALVE_OPENS V
        ON  V.DEVICE_ID = A_S.DEVICE_ID
        AND A_S.SHUTOFF_TIMESTAMP IS NOT NULL                       -- only match if there was a shutoff
        AND V.VALVE_OPEN_TIMESTAMP > A_S.SHUTOFF_TIMESTAMP
    -- Keep first valve open after shutoff (tiebreak on ID for determinism)
    QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY A_S.INCIDENT_ID ORDER BY V.VALVE_OPEN_TIMESTAMP NULLS LAST, V.VALVE_OPEN_ID)
)

---- JOIN LAYER ----
, JOIN_RESULT AS (
    SELECT
        ASV.DEVICE_ID,
        ASV.USER_ID,
        ASV.INCIDENT_ID,
        ASV.INCIDENT_TIMESTAMP,
        ASV.ALARM_ID                                                AS CRITICAL_ALARM_ID,
        ASV.BKCC,
        ASV.REC_SRC,
        ASV.SHUTOFF_ID,
        ASV.SHUTOFF_TIMESTAMP,
        ASV.VALVE_OPEN_ID,
        ASV.VALVE_OPEN_TYPE,
        ASV.VALVE_OPEN_TIMESTAMP,
        FB.FEEDBACK_NORMAL,
        FB.PLUMBING_FAILURE,
        FB.PLUMBING_FAILURE_OTHER,
        FB.FEEDBACK_LABEL,
        -- Filter out source anomalies where feedback predates incident 
        CASE
            WHEN FB.FEEDBACK_TIMESTAMP < ASV.INCIDENT_TIMESTAMP THEN NULL
            ELSE FB.FEEDBACK_TIMESTAMP
        END                                                         AS FEEDBACK_TIMESTAMP
    FROM ALERT_SHUTOFF_VALVE ASV
    LEFT JOIN FEEDBACK FB
        ON ASV.INCIDENT_HK = FB.INCIDENT_HK
)

---- FINAL LAYER ----
SELECT
      ROW_NUMBER() OVER (ORDER BY INCIDENT_TIMESTAMP, INCIDENT_ID)  AS SEQ_ID
    , CURRENT_DATE                                                  AS SNAPSHOTDATE
    , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())                  AS PB_LOAD_DTS
    , DEVICE_ID
    , USER_ID
    , INCIDENT_ID
    , INCIDENT_TIMESTAMP
    , CRITICAL_ALARM_ID
    , SHUTOFF_ID
    , SHUTOFF_TIMESTAMP
    , VALVE_OPEN_ID
    , VALVE_OPEN_TYPE
    , VALVE_OPEN_TIMESTAMP
    , FEEDBACK_NORMAL
    , PLUMBING_FAILURE
    , PLUMBING_FAILURE_OTHER
    , FEEDBACK_LABEL
    , FEEDBACK_TIMESTAMP
    , BKCC
    , REC_SRC
FROM JOIN_RESULT
{{ config(alias='fact_critical_alert_device_event') }}
{#
  Info Mart: Critical Alert Device Event
  ----------------------------------------
  Partner-ready view of critical alert events.
  One row per critical alert showing the full picture:
    - The alert itself
    - The shutoff that followed (within 10 minutes)
    - When and how the valve was reopened
    - Customer feedback on the alert
  Sources from bus_vault.fact_critical_alert_device_event.
#}

---- SRC LAYER ----
WITH
SRC AS (
    SELECT DEVICE_ID, USER_ID, INCIDENT_ID, INCIDENT_TIMESTAMP, CRITICAL_ALARM_ID,
           SHUTOFF_ID, SHUTOFF_TIMESTAMP, VALVE_OPEN_ID, VALVE_OPEN_TYPE,
           VALVE_OPEN_TIMESTAMP, FEEDBACK_NORMAL, PLUMBING_FAILURE,
           PLUMBING_FAILURE_OTHER, FEEDBACK_LABEL, FEEDBACK_TIMESTAMP,
           BKCC, REC_SRC
    FROM {{ ref('fact_critical_alert_device_event') }}
)


---- LOGIC LAYER ----
, LOGIC AS (
    SELECT
        DEVICE_ID
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
    FROM SRC
)

---- JOIN LAYER ----
, JOIN_RESULT AS (
    SELECT *
    FROM LOGIC
)

---- FINAL LAYER ----
SELECT
      DEVICE_ID
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

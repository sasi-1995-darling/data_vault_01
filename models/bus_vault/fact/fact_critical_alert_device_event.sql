{#
  Fact: Critical Alert Device Event
  -----------------------------------
  Thin wrapper on pb_critical_alert_device_event.
  One row per critical alert with associated shutoff, valve reopen, and feedback.
  No business logic — all logic lives in the PIT Bridge layer.
#}

---- SRC LAYER ----
WITH
SRC AS (
    SELECT DEVICE_ID, USER_ID, INCIDENT_ID, INCIDENT_TIMESTAMP, CRITICAL_ALARM_ID,
           SHUTOFF_ID, SHUTOFF_TIMESTAMP, VALVE_OPEN_ID, VALVE_OPEN_TYPE,
           VALVE_OPEN_TIMESTAMP, FEEDBACK_NORMAL, PLUMBING_FAILURE,
           PLUMBING_FAILURE_OTHER, FEEDBACK_LABEL, FEEDBACK_TIMESTAMP,
           BKCC, REC_SRC
    FROM {{ ref('pb_critical_alert_device_event') }}
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

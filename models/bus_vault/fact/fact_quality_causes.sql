---- SRC LAYER ----
WITH
SRC_P              as ( SELECT * FROM {{ ref('pit_quality_causes_current') }} as SRC  )

/*
SRC_P              as ( SELECT * FROM RAW_VAULT.PIT_QUALITY_CAUSES )
*/
---- LOGIC LAYER ----

, LOGIC_P as (
    SELECT
        NOTIFICATION_BK
      , ISSUE_BK
      , CAUSE_BK
      , NOTIFICATION_ISSUE_CAUSE_BK
      , CATALOG_TYPE
      , CODE_GROUP
      , ACTIVITY_CODE
      , ACTIVITY_CREATION_DATE__YYYYMMDD
      , ACTIVITY_UPDATE_DATE__YYYYMMDD
      , CAUSE_TEXT
      , CAUSE_ASSEMBLY
      , BKCC
      , REC_SRC
      , IS_DELETED
    FROM SRC_P
)
---- RENAME LAYER ----

, RENAME_P as (
    SELECT
        NOTIFICATION_BK
      , ISSUE_BK
      , CAUSE_BK
      , NOTIFICATION_ISSUE_CAUSE_BK
      , CATALOG_TYPE
      , CODE_GROUP
      , ACTIVITY_CODE
      , ACTIVITY_CREATION_DATE__YYYYMMDD
      , ACTIVITY_UPDATE_DATE__YYYYMMDD
      , CAUSE_TEXT
      , CAUSE_ASSEMBLY
      , BKCC
      , REC_SRC
      , IS_DELETED
    FROM LOGIC_P
)
---- FILTER LAYER ----

, FILTER_P as (
    SELECT *
    FROM RENAME_P
    )

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_P
)

---- FINAL LAYER ----
SELECT
        NOTIFICATION_ISSUE_CAUSE_BK
        , NOTIFICATION_BK
        , ISSUE_BK
        , CAUSE_BK
        , CATALOG_TYPE
        , CODE_GROUP
        , ACTIVITY_CODE
        , ACTIVITY_CREATION_DATE__YYYYMMDD
        , ACTIVITY_UPDATE_DATE__YYYYMMDD
        , CAUSE_TEXT
        , CAUSE_ASSEMBLY
        , BKCC
        , REC_SRC           
        , IS_DELETED
FROM JOIN_RESULT

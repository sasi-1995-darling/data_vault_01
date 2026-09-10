---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT BKCC, CREATED_TIME, DEVICE_BK, IS_CONNECTED, IS_ONLINE, LAST_CLOUD_CONTACT_TS, MAKE, MODEL, PAIRED_DEVICE_BK, REC_SRC, UPDATED_TIME FROM {{ ref('pb_device_status') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.PB_DEVICE_STATUS )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
    SELECT
        PAIRED_DEVICE_BK
      , DEVICE_BK
      , BKCC
      , REC_SRC
      , MAKE
      , MODEL
      , IS_CONNECTED
      , IS_ONLINE
      , LAST_CLOUD_CONTACT_TS
      , CREATED_TIME
      , UPDATED_TIME
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
    SELECT
        PAIRED_DEVICE_BK
      , DEVICE_BK
      , BKCC
      , REC_SRC
      , MAKE
      , MODEL
      , IS_CONNECTED
      , IS_ONLINE
      , LAST_CLOUD_CONTACT_TS
      , CREATED_TIME
      , UPDATED_TIME
    FROM LOGIC_PB
)
---- FILTER LAYER ----

, FILTER_PB as (
    SELECT *
    FROM RENAME_PB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PB
)

---- FINAL LAYER ----
SELECT
          PAIRED_DEVICE_BK
        , DEVICE_BK
        , BKCC
        , REC_SRC
        , MAKE
        , MODEL
        , IS_CONNECTED
        , IS_ONLINE
        , LAST_CLOUD_CONTACT_TS
        , CREATED_TIME
        , UPDATED_TIME
FROM JOIN_RESULT

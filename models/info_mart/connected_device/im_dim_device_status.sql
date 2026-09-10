{{ config(alias='dim_device_status') }}
---- SRC LAYER ----
WITH
SRC_DDS            as ( SELECT BKCC, CREATED_TIME, DEVICE_BK, IS_CONNECTED, IS_ONLINE, LAST_CLOUD_CONTACT_TS, MAKE, MODEL, PAIRED_DEVICE_BK, REC_SRC, UPDATED_TIME FROM {{ ref('dim_device_status') }} as SRC  )

/*
SRC_DDS            as ( SELECT * FROM BUS_VAULT.DIM_DEVICE_STATUS )
*/
---- LOGIC LAYER ----

, LOGIC_DDS as (
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
    FROM SRC_DDS
)
---- RENAME LAYER ----

, RENAME_DDS as (
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
    FROM LOGIC_DDS
)
---- FILTER LAYER ----

, FILTER_DDS as (
    SELECT *
    FROM RENAME_DDS
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_DDS
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

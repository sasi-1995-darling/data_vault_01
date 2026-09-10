---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT BKCC, CREATED_AT, DEVICE_LOCATION_BK, EVENT, EVENT_DESCRIPTION, PAIRED_DEVICE_BK, REC_SRC, SOURCE FROM {{ ref('pb_device_event') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.PB_DEVICE_EVENT )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
    SELECT
        PAIRED_DEVICE_BK
      , DEVICE_LOCATION_BK
      , BKCC
      , REC_SRC
      , EVENT
      , EVENT_DESCRIPTION
      , CREATED_AT
      , SOURCE
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
    SELECT
        PAIRED_DEVICE_BK
      , DEVICE_LOCATION_BK
      , BKCC
      , REC_SRC
      , EVENT
      , EVENT_DESCRIPTION
      , CREATED_AT
      , SOURCE
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
        , DEVICE_LOCATION_BK
        , BKCC
        , REC_SRC
        , EVENT
        , EVENT_DESCRIPTION
        , CREATED_AT
        , SOURCE
FROM JOIN_RESULT

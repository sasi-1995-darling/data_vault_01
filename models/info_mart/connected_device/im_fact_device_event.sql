{{ config(alias='fact_device_event') }}
---- SRC LAYER ----
WITH
SRC_FDE            as ( SELECT BKCC, CREATED_AT, DEVICE_LOCATION_BK, EVENT, EVENT_DESCRIPTION, PAIRED_DEVICE_BK, REC_SRC, SOURCE FROM {{ ref('fact_device_event') }} as SRC  )

/*
SRC_FDE            as ( SELECT * FROM BUS_VAULT.FACT_DEVICE_EVENT )
*/
---- LOGIC LAYER ----

, LOGIC_FDE as (
    SELECT
        PAIRED_DEVICE_BK
      , DEVICE_LOCATION_BK
      , BKCC
      , REC_SRC
      , EVENT
      , EVENT_DESCRIPTION
      , CREATED_AT
      , SOURCE
    FROM SRC_FDE
)
---- RENAME LAYER ----

, RENAME_FDE as (
    SELECT
        PAIRED_DEVICE_BK
      , DEVICE_LOCATION_BK
      , BKCC
      , REC_SRC
      , EVENT
      , EVENT_DESCRIPTION
      , CREATED_AT
      , SOURCE
    FROM LOGIC_FDE
)
---- FILTER LAYER ----

, FILTER_FDE as (
    SELECT *
    FROM RENAME_FDE
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_FDE
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

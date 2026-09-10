---- SRC LAYER ----
WITH
SRC_PBDE           as ( SELECT BKCC, CREATED_AT, DEVICE_LOCATION_BK, DEVICE_LOCATION_HK, EVENT, EVENT_DESCRIPTION, PAIRED_DEVICE_BK, PAIRED_DEVICE_HK, PAIRED_DEVICE_LOCATION_HK, REC_SRC, SOURCE FROM {{ ref('pb_stg_device_event') }} as SRC  )

/*
SRC_PBDE           as ( SELECT * FROM BUS_VAULT.PB_STG_DEVICE_EVENT )
*/
---- LOGIC LAYER ----

, LOGIC_PBDE as (
    SELECT
        PAIRED_DEVICE_LOCATION_HK
      , PAIRED_DEVICE_HK
      , DEVICE_LOCATION_HK
      , PAIRED_DEVICE_BK
      , DEVICE_LOCATION_BK
      , BKCC
      , REC_SRC
      , EVENT
      , EVENT_DESCRIPTION
      , CREATED_AT
      , SOURCE
    FROM SRC_PBDE
)
---- RENAME LAYER ----

, RENAME_PBDE as (
    SELECT
        PAIRED_DEVICE_LOCATION_HK
      , PAIRED_DEVICE_HK
      , DEVICE_LOCATION_HK
      , PAIRED_DEVICE_BK
      , DEVICE_LOCATION_BK
      , BKCC
      , REC_SRC
      , EVENT
      , EVENT_DESCRIPTION
      , CREATED_AT
      , SOURCE
    FROM LOGIC_PBDE
)
---- FILTER LAYER ----

, FILTER_PBDE as (
    SELECT *
    FROM RENAME_PBDE
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PBDE
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , PAIRED_DEVICE_LOCATION_HK
        , PAIRED_DEVICE_HK
        , DEVICE_LOCATION_HK
        , PAIRED_DEVICE_BK
        , DEVICE_LOCATION_BK
        , BKCC
        , REC_SRC
        , EVENT
        , EVENT_DESCRIPTION
        , CREATED_AT
        , SOURCE
FROM JOIN_RESULT

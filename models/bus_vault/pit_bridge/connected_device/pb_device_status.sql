---- SRC LAYER ----
WITH
SRC_PBDS           as ( SELECT BKCC, CREATED_TIME, DEVICE_BK, DEVICE_HK, ICD_DEVICE_HK, IS_CONNECTED, IS_ONLINE, LAST_CLOUD_CONTACT_TS, MAKE, MODEL, PAIRED_DEVICE_BK, PAIRED_DEVICE_HK, REC_SRC, UPDATED_TIME FROM {{ ref('pb_stg_device_status') }} as SRC  )

/*
SRC_PBDS           as ( SELECT * FROM BUS_VAULT.PB_STG_DEVICE_STATUS )
*/
---- LOGIC LAYER ----

, LOGIC_PBDS as (
    SELECT
        ICD_DEVICE_HK
      , PAIRED_DEVICE_HK
      , DEVICE_HK
      , PAIRED_DEVICE_BK
      , DEVICE_BK
      , BKCC
      , REC_SRC
      , MAKE
      , MODEL
      , IS_CONNECTED
      , IS_ONLINE
      , LAST_CLOUD_CONTACT_TS
      , DATE_TRUNC('minute', CREATED_TIME)                           as                                       CREATED_TIME
      , DATE_TRUNC('minute', UPDATED_TIME)                           as                                       UPDATED_TIME
      , CREATED_TIME                                                 as                                   raw_CREATED_TIME
      , UPDATED_TIME                                                 as                                   raw_UPDATED_TIME
    FROM SRC_PBDS
)
---- RENAME LAYER ----

, RENAME_PBDS as (
    SELECT
        ICD_DEVICE_HK
      , PAIRED_DEVICE_HK
      , DEVICE_HK
      , PAIRED_DEVICE_BK
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
      , raw_CREATED_TIME
      , raw_UPDATED_TIME
    FROM LOGIC_PBDS
)
---- FILTER LAYER ----

, FILTER_PBDS as (
    SELECT *
    FROM RENAME_PBDS
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PBDS
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , ICD_DEVICE_HK
        , PAIRED_DEVICE_HK
        , DEVICE_HK
        , PAIRED_DEVICE_BK
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

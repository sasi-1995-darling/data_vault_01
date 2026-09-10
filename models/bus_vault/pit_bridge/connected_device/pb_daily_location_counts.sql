{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['snapshotdate','bkcc','rec_src','location_id'],
    full_refresh=var('force_full_refresh', false)
) }}

---- SRC LAYER ----
WITH
SRC_LOC            as ( SELECT BKCC, FIVETRAN_DELETED, IS_ACTIVE_FLO_PROTECT, IS_SWD_DEVICE, IS_SWS_DEVICE, LOCATION_ID, REC_SRC FROM {{ ref('pb_stg_location_details') }} as SRC  )

/*
SRC_LOC            as ( SELECT * FROM BUS_VAULT.PB_STG_LOCATION_DETAILS )
*/
---- LOGIC LAYER ----

, LOGIC_LOC as (
    SELECT
        BKCC
      , REC_SRC
      , LOCATION_ID
      , SUM(CASE WHEN FIVETRAN_DELETED = FALSE THEN COALESCE(IS_SWS_DEVICE, 0) ELSE 0 END) as                                     SWS_DEVICE_CNT
      , SUM(CASE WHEN FIVETRAN_DELETED = FALSE THEN COALESCE(IS_SWD_DEVICE, 0) ELSE 0 END) as                                     SWD_DEVICE_CNT
      , MAX(CASE WHEN FIVETRAN_DELETED = FALSE THEN IS_ACTIVE_FLO_PROTECT ELSE 0 END) as                          IS_ACTIVE_FLO_PROTECT_LOC
      , MAX( CASE WHEN FIVETRAN_DELETED = FALSE THEN 1 ELSE 0 END )  as                      HAS_NON_DELETED_PAIRED_DEVICE
    FROM SRC_LOC
        GROUP BY 
        LOCATION_ID, 
        BKCC, 
        REC_SRC
)
---- RENAME LAYER ----

, RENAME_LOC as (
    SELECT
        BKCC
      , REC_SRC
      , LOCATION_ID
      , SWS_DEVICE_CNT
      , SWD_DEVICE_CNT
      , IS_ACTIVE_FLO_PROTECT_LOC
      , HAS_NON_DELETED_PAIRED_DEVICE
    FROM LOGIC_LOC
)
---- FILTER LAYER ----

, FILTER_LOC as (
    SELECT *
    FROM RENAME_LOC
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_LOC
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PB_LOAD_DTS
        , BKCC
        , REC_SRC
        , LOCATION_ID
        , SWS_DEVICE_CNT
        , SWD_DEVICE_CNT
        , IS_ACTIVE_FLO_PROTECT_LOC
        , HAS_NON_DELETED_PAIRED_DEVICE
FROM JOIN_RESULT
where LOCATION_ID is not null
{% if is_incremental() %}
  -- only re-write today on reruns; keep prior days intact
  AND CURRENT_DATE >= (SELECT COALESCE(MAX(SNAPSHOTDATE), '1900-01-01'::DATE) FROM {{ this }})
{% endif %}
{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_LDL            as ( SELECT PAIRED_DEVICE_LOCATION_HK, PAIRED_DEVICE_HK, DEVICE_LOCATION_HK, REC_SRC FROM {{ ref('lnk_paired_device_location') }} as SRC  ),
SRC_HD             as ( SELECT PAIRED_DEVICE_HK, PAIRED_DEVICE_BK, BKCC FROM {{ ref('hub_paired_device') }} as SRC  ),
SRC_HL             as ( SELECT DEVICE_LOCATION_HK, DEVICE_LOCATION_BK FROM {{ ref('hub_device_location') }} as SRC  ),
SRC_SDE            as ( SELECT PAIRED_DEVICE_EVENT_HK, EVENT, LOAD_DTS, CREATED_AT FROM {{ ref('sat_paired_device_event__flo_dynamodb') }} as SRC 
                        qualify 1= row_number() over(partition by PAIRED_DEVICE_EVENT_HK, EVENT order by LOAD_DTS DESC) ),
SRC_SPD            as ( SELECT PAIRED_DEVICE_HK, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, LOAD_DTS FROM {{ ref('sat_paired_device__flo_dynamodb') }} as SRC 
                        WHERE _FIVETRAN_DELETED = TRUE 
                        qualify 1= row_number() over(partition by PAIRED_DEVICE_HK order by LOAD_DTS DESC) )

/*
SRC_LDL            as ( SELECT * FROM raw_vault.LNK_PAIRED_DEVICE_LOCATION )
SRC_HD             as ( SELECT * FROM raw_vault.HUB_PAIRED_DEVICE )
SRC_HL             as ( SELECT * FROM raw_vault.HUB_DEVICE_LOCATION )
SRC_SDE            as ( SELECT * FROM raw_vault.SAT_PAIRED_DEVICE_EVENT__FLO_DYNAMODB )
SRC_SPD            as ( SELECT * FROM raw_vault.SAT_PAIRED_DEVICE__FLO_DYNAMODB )
*/
---- LOGIC LAYER ----

, LOGIC_LDL as (
    SELECT
        PAIRED_DEVICE_LOCATION_HK
      , PAIRED_DEVICE_HK
      , DEVICE_LOCATION_HK
      , REC_SRC
    FROM SRC_LDL
)

, LOGIC_HD as (
    SELECT
        PAIRED_DEVICE_HK                                             as                                HD_PAIRED_DEVICE_HK
      , PAIRED_DEVICE_BK
      , BKCC
    FROM SRC_HD
)

, LOGIC_HL as (
    SELECT
        DEVICE_LOCATION_HK                                           as                              HL_DEVICE_LOCATION_HK
      , DEVICE_LOCATION_BK
    FROM SRC_HL
)

, LOGIC_SDE as (
    SELECT
        PAIRED_DEVICE_EVENT_HK                                       as                         SDE_PAIRED_DEVICE_EVENT_HK
      , EVENT                                                        as                                          SDE_EVENT
      , LOAD_DTS                                                     as                                       SDE_LOAD_DTS
      , CREATED_AT                                                   as                                     SDE_CREATED_AT
    FROM SRC_SDE
)

, LOGIC_SPD as (
    SELECT
        PAIRED_DEVICE_HK                                             as                               SPD_PAIRED_DEVICE_HK
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , LOAD_DTS                                                     as                                       SPD_LOAD_DTS
    FROM SRC_SPD
)
---- RENAME LAYER ----

, RENAME_LDL as (
    SELECT
        PAIRED_DEVICE_LOCATION_HK
      , PAIRED_DEVICE_HK
      , DEVICE_LOCATION_HK
      , REC_SRC
    FROM LOGIC_LDL
)

, RENAME_HD as (
    SELECT
        HD_PAIRED_DEVICE_HK
      , PAIRED_DEVICE_BK
      , BKCC
    FROM LOGIC_HD
)

, RENAME_HL as (
    SELECT
        HL_DEVICE_LOCATION_HK
      , DEVICE_LOCATION_BK
    FROM LOGIC_HL
)

, RENAME_SDE as (
    SELECT
        SDE_PAIRED_DEVICE_EVENT_HK
      , SDE_EVENT
      , SDE_LOAD_DTS
      , SDE_CREATED_AT
    FROM LOGIC_SDE
)

, RENAME_SPD as (
    SELECT
        SPD_PAIRED_DEVICE_HK
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , SPD_LOAD_DTS
    FROM LOGIC_SPD
)
---- FILTER LAYER ----

, FILTER_LDL as (
    SELECT *
    FROM RENAME_LDL
)

, FILTER_HD as (
    SELECT *
    FROM RENAME_HD
)

, FILTER_HL as (
    SELECT *
    FROM RENAME_HL
)

, FILTER_SDE as (
    SELECT *
    FROM RENAME_SDE
)

, FILTER_SPD as (
    SELECT *
    FROM RENAME_SPD
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LDL
    INNER JOIN FILTER_HD
        ON PAIRED_DEVICE_HK = HD_PAIRED_DEVICE_HK
    INNER JOIN FILTER_HL
        ON DEVICE_LOCATION_HK = HL_DEVICE_LOCATION_HK
    INNER JOIN FILTER_SDE
        ON PAIRED_DEVICE_HK = SDE_PAIRED_DEVICE_EVENT_HK
    LEFT JOIN FILTER_SPD
        ON PAIRED_DEVICE_HK = SPD_PAIRED_DEVICE_HK
)

---- FINAL LAYER ----
SELECT
          PAIRED_DEVICE_LOCATION_HK
        , PAIRED_DEVICE_HK
        , DEVICE_LOCATION_HK
        , PAIRED_DEVICE_BK
        , DEVICE_LOCATION_BK
        , BKCC
        , REC_SRC
        , CASE WHEN  _FIVETRAN_DELETED = TRUE THEN 4 ELSE SDE_EVENT END as EVENT
        , CASE WHEN _FIVETRAN_DELETED = TRUE THEN _FIVETRAN_SYNCED ELSE SDE_CREATED_AT END as CREATED_AT
        , 'FLO'                                                        as SOURCE
        , CASE WHEN _FIVETRAN_DELETED = TRUE THEN 'UNPAIRED' 
WHEN SDE_EVENT = 1 THEN 'PAIRED' 
WHEN SDE_EVENT = 2 THEN 'INSTALLED' 
WHEN SDE_EVENT = 3 THEN 'LEARNING OFF' 
ELSE 'UNKNOWN' END as EVENT_DESCRIPTION
        , SDE_CREATED_AT
FROM JOIN_RESULT
qualify 1= row_number() over(partition by PAIRED_DEVICE_LOCATION_HK,PAIRED_DEVICE_HK,DEVICE_LOCATION_HK, EVENT order by CREATED_AT DESC)
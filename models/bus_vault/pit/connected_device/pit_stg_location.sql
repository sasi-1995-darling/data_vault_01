{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HL             as ( SELECT DEVICE_LOCATION_HK, DEVICE_LOCATION_BK, BKCC, REC_SRC FROM {{ ref('hub_device_location') }} as SRC  ),
SRC_SL             as ( SELECT LOCATION_ID, ACCOUNT_ID, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, REVERT_SCHEDULED_AT, DEVICE_LOCATION_HK, COUNTRY, ADDRESS, STORIES, BATHROOM_AMENITIES, CITY, LOCATION_SIZE_CATEGORY, TIMEZONE, GALVANIZED_PLUMBING, KITCHEN_AMENITIES, LOCATION_TYPE, GALLONS_PER_DAY_GOAL, IS_PROFILE_COMPLETE, OUTDOOR_AMENITIES, POSTALCODE, STATE, OCCUPANTS, WATER_SHUTOFF_KNOWN, EXPANSION_TANK, TANKLESS, WATER_FILTERING_SYSTEM, WHOLE_HOUSE_HUMIDIFIER, HOT_WATER_RECIRCULATION, LOCATION_NAME, ADDRESS_2, LOCATION_SIZE, WELL_SYSTEM, WATER_SOFTENER, PROFILE_COMPLETED, CONSUMPTION, BATHROOMS, IS_USING_AWAY_SCHEDULE, PROFILE, IS_IRRIGATION_SCHEDULE_ENABLED, REVERT_MINUTES, REVERT_MODE, TARGET_SYSTEM_MODE, AREAS, _MERGED_INTO_LOCATION_ID, PARENT_LOCATION_ID, LOCATION_CLASS, GEO_POSITIONING FROM {{ ref('sat_device_location_details__flo_dynamodb') }} as SRC 
                        qualify 1= row_number() over(partition by DEVICE_LOCATION_HK order by LOAD_DTS DESC) )

/*
SRC_HL             as ( SELECT * FROM RAW_VAULT.HUB_DEVICE_LOCATION )
SRC_SL             as ( SELECT * FROM RAW_VAULT.SAT_DEVICE_LOCATION_DETAILS__FLO_DYNAMODB )
*/
---- LOGIC LAYER ----

, LOGIC_HL as (
    SELECT
        DEVICE_LOCATION_HK
      , DEVICE_LOCATION_BK
      , BKCC
      , REC_SRC
    FROM SRC_HL
)

, LOGIC_SL as (
    SELECT
        LOCATION_ID
      , ACCOUNT_ID
      , _FIVETRAN_DELETED
      , CASE WHEN UPPER(COUNTRY) = 'UNITEDSTATES' THEN 'US'
            WHEN UPPER(COUNTRY) = 'UNITED STATES' THEN 'US'
            WHEN UPPER(COUNTRY) = 'USA' THEN 'US'
            WHEN UPPER(COUNTRY) = 'CANADA' THEN 'CA'
            WHEN UPPER(COUNTRY) = 'POLAND' THEN 'PL'
            WHEN UPPER(COUNTRY) = 'POLAND-1' THEN 'PL'
            WHEN UPPER(COUNTRY) = 'CREATE_FLO_ACCOUNT=FALSE' THEN ''
            WHEN UPPER(COUNTRY) = 'STRING' THEN ''
            WHEN UPPER(COUNTRY) IS NULL THEN ''
            ELSE
            UPPER(COUNTRY)
        END                                                          as                                            COUNTRY
      , COALESCE( UPPER(ADDRESS), '')                                as                                            ADDRESS
      , COALESCE( STORIES, 0)                                        as                                            STORIES
      , COALESCE( BATHROOM_AMENITIES, '')                            as                                 BATHROOM_AMENITIES
      , COALESCE( UPPER(CITY), '')                                   as                                               CITY
      , COALESCE( LOCATION_SIZE_CATEGORY, 0)                         as                             LOCATION_SIZE_CATEGORY
      , COALESCE( TIMEZONE, '')                                      as                                           TIMEZONE
      , COALESCE( GALVANIZED_PLUMBING, 0)                            as                                GALVANIZED_PLUMBING
      , COALESCE( KITCHEN_AMENITIES, '')                             as                                  KITCHEN_AMENITIES
      , COALESCE( LOCATION_TYPE, '')                                 as                                      LOCATION_TYPE
      , COALESCE( GALLONS_PER_DAY_GOAL, 0)                           as                               GALLONS_PER_DAY_GOAL
      , COALESCE( IS_PROFILE_COMPLETE, FALSE)                        as                                IS_PROFILE_COMPLETE
      , COALESCE( OUTDOOR_AMENITIES, '')                             as                                  OUTDOOR_AMENITIES
      , COALESCE( POSTALCODE, '')                                    as                                         POSTALCODE
      , COALESCE( UPPER(STATE), '')                                  as                                              STATE
      , COALESCE( OCCUPANTS, 0)                                      as                                          OCCUPANTS
      , COALESCE( WATER_SHUTOFF_KNOWN, 0)                            as                                WATER_SHUTOFF_KNOWN
      , _FIVETRAN_SYNCED
      , COALESCE( EXPANSION_TANK, 0)                                 as                                     EXPANSION_TANK
      , COALESCE( TANKLESS, 0)                                       as                                           TANKLESS
      , COALESCE( WATER_FILTERING_SYSTEM, 0)                         as                             WATER_FILTERING_SYSTEM
      , COALESCE( WHOLE_HOUSE_HUMIDIFIER, 0)                         as                             WHOLE_HOUSE_HUMIDIFIER
      , COALESCE( HOT_WATER_RECIRCULATION, 0)                        as                            HOT_WATER_RECIRCULATION
      , COALESCE( LOCATION_NAME, '')                                 as                                      LOCATION_NAME
      , COALESCE( UPPER(ADDRESS_2), '')                              as                                          ADDRESS_2
      , COALESCE( LOCATION_SIZE, 0)                                  as                                      LOCATION_SIZE
      , COALESCE( WELL_SYSTEM, 0)                                    as                                        WELL_SYSTEM
      , COALESCE( WATER_SOFTENER, 0)                                 as                                     WATER_SOFTENER
      , COALESCE( PROFILE_COMPLETED, FALSE)                          as                                  PROFILE_COMPLETED
      , COALESCE( CONSUMPTION, '')                                   as                                        CONSUMPTION
      , COALESCE( BATHROOMS, 0)                                      as                                          BATHROOMS
      , COALESCE( IS_USING_AWAY_SCHEDULE, FALSE)                     as                             IS_USING_AWAY_SCHEDULE
      , COALESCE( PROFILE, '')                                       as                                            PROFILE
      , COALESCE( IS_IRRIGATION_SCHEDULE_ENABLED, FALSE)             as                     IS_IRRIGATION_SCHEDULE_ENABLED
      , COALESCE( REVERT_MINUTES, 0)                                 as                                     REVERT_MINUTES
      , COALESCE( REVERT_MODE, '')                                   as                                        REVERT_MODE
      , REVERT_SCHEDULED_AT
      , COALESCE( TARGET_SYSTEM_MODE, '')                            as                                 TARGET_SYSTEM_MODE
      , COALESCE( AREAS, '')                                         as                                              AREAS
      , COALESCE( _MERGED_INTO_LOCATION_ID, '')                      as                            MERGED_INTO_LOCATION_ID
      , COALESCE( PARENT_LOCATION_ID, '')                            as                                 PARENT_LOCATION_ID
      , COALESCE( LOCATION_CLASS, '')                                as                                     LOCATION_CLASS
      , COALESCE(GEO_POSITIONING:coordinates:latitude::FLOAT,0.0)    as                                           LATITUDE
      , COALESCE(GEO_POSITIONING:coordinates:longitude::FLOAT,0.0)   as                                          LONGITUDE
      , DEVICE_LOCATION_HK                                           as                              SL_DEVICE_LOCATION_HK
      , COUNTRY                                                      as                                        RAW_COUNTRY
      , ADDRESS                                                      as                                        RAW_ADDRESS
      , STORIES                                                      as                                        RAW_STORIES
      , BATHROOM_AMENITIES                                           as                             RAW_BATHROOM_AMENITIES
      , CITY                                                         as                                           RAW_CITY
      , LOCATION_SIZE_CATEGORY                                       as                         RAW_LOCATION_SIZE_CATEGORY
      , TIMEZONE                                                     as                                       RAW_TIMEZONE
      , GALVANIZED_PLUMBING                                          as                            RAW_GALVANIZED_PLUMBING
      , KITCHEN_AMENITIES                                            as                              RAW_KITCHEN_AMENITIES
      , LOCATION_TYPE                                                as                                  RAW_LOCATION_TYPE
      , GALLONS_PER_DAY_GOAL                                         as                           RAW_GALLONS_PER_DAY_GOAL
      , IS_PROFILE_COMPLETE                                          as                            RAW_IS_PROFILE_COMPLETE
      , OUTDOOR_AMENITIES                                            as                              RAW_OUTDOOR_AMENITIES
      , POSTALCODE                                                   as                                     RAW_POSTALCODE
      , STATE                                                        as                                          RAW_STATE
      , OCCUPANTS                                                    as                                      RAW_OCCUPANTS
      , WATER_SHUTOFF_KNOWN                                          as                            RAW_WATER_SHUTOFF_KNOWN
      , EXPANSION_TANK                                               as                                 RAW_EXPANSION_TANK
      , TANKLESS                                                     as                                       RAW_TANKLESS
      , WATER_FILTERING_SYSTEM                                       as                         RAW_WATER_FILTERING_SYSTEM
      , WHOLE_HOUSE_HUMIDIFIER                                       as                         RAW_WHOLE_HOUSE_HUMIDIFIER
      , HOT_WATER_RECIRCULATION                                      as                        RAW_HOT_WATER_RECIRCULATION
      , LOCATION_NAME                                                as                                  RAW_LOCATION_NAME
      , ADDRESS_2                                                    as                                      RAW_ADDRESS_2
      , LOCATION_SIZE                                                as                                  RAW_LOCATION_SIZE
      , WELL_SYSTEM                                                  as                                    RAW_WELL_SYSTEM
      , WATER_SOFTENER                                               as                                 RAW_WATER_SOFTENER
      , PROFILE_COMPLETED                                            as                              RAW_PROFILE_COMPLETED
      , CONSUMPTION                                                  as                                    RAW_CONSUMPTION
      , BATHROOMS                                                    as                                      RAW_BATHROOMS
      , IS_USING_AWAY_SCHEDULE                                       as                         RAW_IS_USING_AWAY_SCHEDULE
      , PROFILE                                                      as                                        RAW_PROFILE
      , IS_IRRIGATION_SCHEDULE_ENABLED                               as                 RAW_IS_IRRIGATION_SCHEDULE_ENABLED
      , REVERT_MINUTES                                               as                                 RAW_REVERT_MINUTES
      , REVERT_MODE                                                  as                                    RAW_REVERT_MODE
      , TARGET_SYSTEM_MODE                                           as                             RAW_TARGET_SYSTEM_MODE
      , AREAS                                                        as                                          RAW_AREAS
      , _MERGED_INTO_LOCATION_ID                                     as                        RAW_MERGED_INTO_LOCATION_ID
      , PARENT_LOCATION_ID                                           as                             RAW_PARENT_LOCATION_ID
      , LOCATION_CLASS                                               as                                 RAW_LOCATION_CLASS
      , GEO_POSITIONING
    FROM SRC_SL
)
---- RENAME LAYER ----

, RENAME_HL as (
    SELECT
        DEVICE_LOCATION_HK
      , DEVICE_LOCATION_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_HL
)

, RENAME_SL as (
    SELECT
        LOCATION_ID
      , ACCOUNT_ID
      , _FIVETRAN_DELETED
      , COUNTRY
      , ADDRESS
      , STORIES
      , BATHROOM_AMENITIES
      , CITY
      , LOCATION_SIZE_CATEGORY
      , TIMEZONE
      , GALVANIZED_PLUMBING
      , KITCHEN_AMENITIES
      , LOCATION_TYPE
      , GALLONS_PER_DAY_GOAL
      , IS_PROFILE_COMPLETE
      , OUTDOOR_AMENITIES
      , POSTALCODE
      , STATE
      , OCCUPANTS
      , WATER_SHUTOFF_KNOWN
      , _FIVETRAN_SYNCED
      , EXPANSION_TANK
      , TANKLESS
      , WATER_FILTERING_SYSTEM
      , WHOLE_HOUSE_HUMIDIFIER
      , HOT_WATER_RECIRCULATION
      , LOCATION_NAME
      , ADDRESS_2
      , LOCATION_SIZE
      , WELL_SYSTEM
      , WATER_SOFTENER
      , PROFILE_COMPLETED
      , CONSUMPTION
      , BATHROOMS
      , IS_USING_AWAY_SCHEDULE
      , PROFILE
      , IS_IRRIGATION_SCHEDULE_ENABLED
      , REVERT_MINUTES
      , REVERT_MODE
      , REVERT_SCHEDULED_AT
      , TARGET_SYSTEM_MODE
      , AREAS
      , MERGED_INTO_LOCATION_ID
      , PARENT_LOCATION_ID
      , LOCATION_CLASS
      , LATITUDE
      , LONGITUDE
      , SL_DEVICE_LOCATION_HK
      , RAW_COUNTRY
      , RAW_ADDRESS
      , RAW_STORIES
      , RAW_BATHROOM_AMENITIES
      , RAW_CITY
      , RAW_LOCATION_SIZE_CATEGORY
      , RAW_TIMEZONE
      , RAW_GALVANIZED_PLUMBING
      , RAW_KITCHEN_AMENITIES
      , RAW_LOCATION_TYPE
      , RAW_GALLONS_PER_DAY_GOAL
      , RAW_IS_PROFILE_COMPLETE
      , RAW_OUTDOOR_AMENITIES
      , RAW_POSTALCODE
      , RAW_STATE
      , RAW_OCCUPANTS
      , RAW_WATER_SHUTOFF_KNOWN
      , RAW_EXPANSION_TANK
      , RAW_TANKLESS
      , RAW_WATER_FILTERING_SYSTEM
      , RAW_WHOLE_HOUSE_HUMIDIFIER
      , RAW_HOT_WATER_RECIRCULATION
      , RAW_LOCATION_NAME
      , RAW_ADDRESS_2
      , RAW_LOCATION_SIZE
      , RAW_WELL_SYSTEM
      , RAW_WATER_SOFTENER
      , RAW_PROFILE_COMPLETED
      , RAW_CONSUMPTION
      , RAW_BATHROOMS
      , RAW_IS_USING_AWAY_SCHEDULE
      , RAW_PROFILE
      , RAW_IS_IRRIGATION_SCHEDULE_ENABLED
      , RAW_REVERT_MINUTES
      , RAW_REVERT_MODE
      , RAW_TARGET_SYSTEM_MODE
      , RAW_AREAS
      , RAW_MERGED_INTO_LOCATION_ID
      , RAW_PARENT_LOCATION_ID
      , RAW_LOCATION_CLASS
      , GEO_POSITIONING
    FROM LOGIC_SL
)
---- FILTER LAYER ----

, FILTER_HL as (
    SELECT *
    FROM RENAME_HL
)

, FILTER_SL as (
    SELECT *
    FROM RENAME_SL
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HL
    INNER JOIN FILTER_SL
        ON DEVICE_LOCATION_HK = SL_DEVICE_LOCATION_HK
)

---- FINAL LAYER ----
SELECT
          DEVICE_LOCATION_HK
        , DEVICE_LOCATION_BK
        , BKCC
        , REC_SRC
        , LOCATION_ID
        , ACCOUNT_ID
        , _FIVETRAN_DELETED
        , COUNTRY
        , ADDRESS
        , STORIES
        , BATHROOM_AMENITIES
        , CITY
        , LOCATION_SIZE_CATEGORY
        , TIMEZONE
        , GALVANIZED_PLUMBING
        , KITCHEN_AMENITIES
        , LOCATION_TYPE
        , GALLONS_PER_DAY_GOAL
        , IS_PROFILE_COMPLETE
        , OUTDOOR_AMENITIES
        , POSTALCODE
        , STATE
        , OCCUPANTS
        , WATER_SHUTOFF_KNOWN
        , _FIVETRAN_SYNCED
        , EXPANSION_TANK
        , TANKLESS
        , WATER_FILTERING_SYSTEM
        , WHOLE_HOUSE_HUMIDIFIER
        , HOT_WATER_RECIRCULATION
        , LOCATION_NAME
        , ADDRESS_2
        , LOCATION_SIZE
        , WELL_SYSTEM
        , WATER_SOFTENER
        , PROFILE_COMPLETED
        , CONSUMPTION
        , BATHROOMS
        , IS_USING_AWAY_SCHEDULE
        , PROFILE
        , IS_IRRIGATION_SCHEDULE_ENABLED
        , REVERT_MINUTES
        , REVERT_MODE
        , REVERT_SCHEDULED_AT
        , TARGET_SYSTEM_MODE
        , AREAS
        , MERGED_INTO_LOCATION_ID
        , PARENT_LOCATION_ID
        , LOCATION_CLASS
        , LATITUDE
        , LONGITUDE
FROM JOIN_RESULT

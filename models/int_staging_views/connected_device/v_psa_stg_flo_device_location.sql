---- SRC LAYER ----
WITH
SRC_D1             as ( SELECT ACCOUNT_ID, ADDRESS, ADDRESS_2, AREAS, BATHROOMS, BATHROOM_AMENITIES, CITY, CONSUMPTION, COUNTRY, EXPANSION_TANK, GALLONS_PER_DAY_GOAL, GALVANIZED_PLUMBING, GEO_POSITIONING, HOT_WATER_RECIRCULATION, IS_IRRIGATION_SCHEDULE_ENABLED, IS_PROFILE_COMPLETE, IS_USING_AWAY_SCHEDULE, KITCHEN_AMENITIES, LOCATION_CLASS, LOCATION_ID, LOCATION_NAME, LOCATION_SIZE, LOCATION_SIZE_CATEGORY, LOCATION_TYPE, OCCUPANTS, OUTDOOR_AMENITIES, PARENT_LOCATION_ID, POSTALCODE, PROFILE, PROFILE_COMPLETED, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REVERT_MINUTES, REVERT_MODE, REVERT_SCHEDULED_AT, STATE, STORIES, TANKLESS, TARGET_SYSTEM_MODE, TIMEZONE, WATER_FILTERING_SYSTEM, WATER_SHUTOFF_KNOWN, WATER_SOFTENER, WELL_SYSTEM, WHOLE_HOUSE_HUMIDIFIER, _FIVETRAN_DELETED, _FIVETRAN_SYNCED, _MERGED_INTO_LOCATION_ID FROM {{ source('flo_dynamodb', 'prod_location') }} as SRC  ),
SRC_A1             as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_D1             as ( SELECT * FROM flo_dynamodb.prod_location )
SRC_A1             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_D1 as (
    SELECT
        LOCATION_ID                                                  as                                 DEVICE_LOCATION_BK
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
      , _MERGED_INTO_LOCATION_ID
      , PARENT_LOCATION_ID
      , LOCATION_CLASS
      , GEO_POSITIONING
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM SRC_D1
)

, LOGIC_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A1
)
---- RENAME LAYER ----

, RENAME_D1 as (
    SELECT
        DEVICE_LOCATION_BK
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
      , _MERGED_INTO_LOCATION_ID
      , PARENT_LOCATION_ID
      , LOCATION_CLASS
      , GEO_POSITIONING
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
    FROM LOGIC_D1
)

, RENAME_A1 as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A1
)
---- FILTER LAYER ----

, FILTER_D1 as (
    SELECT *
    FROM RENAME_D1
)

, FILTER_A1 as (
    SELECT *
    FROM RENAME_A1
    WHERE rec_src = 'US.FLO_DYNAMODB.PROD_LOCATION'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D1
    INNER JOIN FILTER_A1
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          DEVICE_LOCATION_BK
        , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as LOAD_DTS
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
        , _MERGED_INTO_LOCATION_ID
        , PARENT_LOCATION_ID
        , LOCATION_CLASS
        , GEO_POSITIONING
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DEVICE_LOCATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEVICE_LOCATION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS::text), '^^') 
            , '||', IFNULL(TRIM(STORIES::text), '^^') 
            , '||', IFNULL(TRIM(BATHROOM_AMENITIES::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_SIZE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(TIMEZONE::text), '^^') 
            , '||', IFNULL(TRIM(GALVANIZED_PLUMBING::text), '^^') 
            , '||', IFNULL(TRIM(KITCHEN_AMENITIES::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(GALLONS_PER_DAY_GOAL::text), '^^') 
            , '||', IFNULL(TRIM(IS_PROFILE_COMPLETE::text), '^^') 
            , '||', IFNULL(TRIM(OUTDOOR_AMENITIES::text), '^^') 
            , '||', IFNULL(TRIM(POSTALCODE::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(OCCUPANTS::text), '^^') 
            , '||', IFNULL(TRIM(WATER_SHUTOFF_KNOWN::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_SYNCED::text), '^^') 
            , '||', IFNULL(TRIM(EXPANSION_TANK::text), '^^') 
            , '||', IFNULL(TRIM(TANKLESS::text), '^^') 
            , '||', IFNULL(TRIM(WATER_FILTERING_SYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(WHOLE_HOUSE_HUMIDIFIER::text), '^^') 
            , '||', IFNULL(TRIM(HOT_WATER_RECIRCULATION::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_2::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_SIZE::text), '^^') 
            , '||', IFNULL(TRIM(WELL_SYSTEM::text), '^^') 
            , '||', IFNULL(TRIM(WATER_SOFTENER::text), '^^') 
            , '||', IFNULL(TRIM(PROFILE_COMPLETED::text), '^^') 
            , '||', IFNULL(TRIM(CONSUMPTION::text), '^^') 
            , '||', IFNULL(TRIM(BATHROOMS::text), '^^') 
            , '||', IFNULL(TRIM(IS_USING_AWAY_SCHEDULE::text), '^^') 
            , '||', IFNULL(TRIM(PROFILE::text), '^^') 
            , '||', IFNULL(TRIM(IS_IRRIGATION_SCHEDULE_ENABLED::text), '^^') 
            , '||', IFNULL(TRIM(REVERT_MINUTES::text), '^^') 
            , '||', IFNULL(TRIM(REVERT_MODE::text), '^^') 
            , '||', IFNULL(TRIM(REVERT_SCHEDULED_AT::text), '^^') 
            , '||', IFNULL(TRIM(TARGET_SYSTEM_MODE::text), '^^') 
            , '||', IFNULL(TRIM(AREAS::text), '^^') 
            , '||', IFNULL(TRIM(_MERGED_INTO_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PARENT_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(GEO_POSITIONING::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_hub            as ( SELECT BKCC, CAPACITY_BK, CAPACITY_HK, REC_SRC FROM {{ ref('hub_capacity') }} as SRC  ),
SRC_sat            as ( SELECT AZNOR, BEGZT, ENDZT, KALID, KAPAR, MEINS, NAME, NGRAD, PAUSE, PLANR, POOLK, PSA_DELETE_IND, VERSA, WERKS, CAPACITY_HK FROM {{ ref('sat_capacity__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by kapid order by load_dts DESC) ),
SRC_msat           as ( SELECT KTEXT, SPRAS, CAPACITY_HK FROM {{ ref('msat_capacity_description__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by kapid, spras order by load_dts DESC) ),
SRC_msat_int       as ( SELECT DATUB, CAPACITY_HK, VERSN FROM {{ ref('msat_capacity_interval__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by kapid, versn, datub order by load_dts DESC) )

/*
SRC_hub            as ( SELECT * FROM RAW_VAULT.hub_capacity )
SRC_sat            as ( SELECT * FROM RAW_VAULT.sat_capacity__winn_sap )
SRC_msat           as ( SELECT * FROM RAW_VAULT.msat_capacity_description__winn_sap )
SRC_msat_int       as ( SELECT * FROM RAW_VAULT.msat_capacity_interval__winn_sap )
SRC_msat_uom       as ( SELECT * FROM RAW_VAULT.msat_capacity_uom__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_hub as (
    SELECT
        CAPACITY_HK
      , CAPACITY_BK
      , REC_SRC
      , BKCC
    FROM SRC_hub
)

, LOGIC_sat as (
    SELECT
       NGRAD                                                        as                              CAP_UTIL_RATE_PERCENT
      , WERKS                                                        as                                           PLANT_BK
      , BEGZT                                                        as                              START_TIME_IN_SECONDS
      , ENDZT                                                        as                                END_TIME_IN_SECONDS
      , AZNOR                                                        as                        AZNOR_NUM_OF_INDIVIDUAL_CAP
      , KALID                                                        as                                FACTORY_CALENDAR_ID
      , VERSA                                                        as                                      AVAIL_CAP_VER
      , KAPAR                                                        as                                       CAP_CATEGORY
      , MEINS                                                        as                               CAP_MEASUREMENT_UNIT
      , PAUSE                                                        as                   CUMULATIVE_BREAK_TIME_IN_SECONDS
      , PLANR                                                        as                                  CAP_PLANNER_GROUP
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
      , CAPACITY_HK                                                  as                            sat_CAPACITY_HK
    FROM SRC_sat
)

, LOGIC_msat as (
    SELECT
        KTEXT                                                        as                                     CAP_SHORT_TEXT
      , SPRAS
      , CAPACITY_HK                                                  as                                     msat_CAPACITY_HK
    FROM SRC_msat
)

, LOGIC_msat_int as (
    SELECT
        DATUB                                                        as                                      VALID_TO_DATE 
      , CAPACITY_HK                                                  as                                msat_int_CAPACITY_HK
      , VERSN                                                        as                                AVAILABLE_CAPACITY_VERSION
    FROM SRC_msat_int
)
---- RENAME LAYER ----

, RENAME_hub as (
    SELECT
        CAPACITY_HK
      , CAPACITY_BK
      , REC_SRC
      , BKCC
    FROM LOGIC_hub
)

, RENAME_sat as (
    SELECT
       CAP_UTIL_RATE_PERCENT
      , PLANT_BK
      , START_TIME_IN_SECONDS
      , END_TIME_IN_SECONDS
      , AZNOR_NUM_OF_INDIVIDUAL_CAP
      , FACTORY_CALENDAR_ID
      , AVAIL_CAP_VER
      , CAP_CATEGORY
      , CAP_MEASUREMENT_UNIT
      , CUMULATIVE_BREAK_TIME_IN_SECONDS
      , CAP_PLANNER_GROUP
      , SAT_WINN_PSA_DELETE_IND
      , sat_CAPACITY_HK
    FROM LOGIC_sat
)

, RENAME_msat as (
    SELECT
        CAP_SHORT_TEXT,
        SPRAS,
        msat_CAPACITY_HK
    FROM LOGIC_msat
)

, RENAME_msat_int as (
    SELECT
        VALID_TO_DATE
      , msat_int_CAPACITY_HK
      , AVAILABLE_CAPACITY_VERSION
    FROM LOGIC_msat_int
)
---- FILTER LAYER ----

, FILTER_hub as (
    SELECT *
    FROM RENAME_hub
)

, FILTER_sat as (
    SELECT *
    FROM RENAME_sat
)

, FILTER_msat as (
    SELECT *
    FROM RENAME_msat
    WHERE SPRAS = 'E'
)

, FILTER_msat_int as (
    SELECT *
    FROM RENAME_msat_int
)


---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *,COALESCE(NULLIF(VALID_TO_DATE, ''), '99991231')::INTEGER as VALID_TO_DATE__YYYYMMDD
    FROM FILTER_hub
    INNER JOIN FILTER_sat
        ON FILTER_hub.CAPACITY_HK = FILTER_sat.sat_CAPACITY_HK  --kako
    LEFT JOIN FILTER_msat
        ON FILTER_hub.CAPACITY_HK = FILTER_msat.msat_CAPACITY_HK
    LEFT JOIN FILTER_msat_int
        ON FILTER_hub.CAPACITY_HK = FILTER_msat_int.msat_int_CAPACITY_HK       
)

---- FINAL LAYER ----
SELECT
          'PIT_CAPACITY'                                                as PB_REC_SRC
        , CURRENT_TIMESTAMP                                             as SNAPSHOT_DTS
        , CAPACITY_HK
        , CAPACITY_BK
        , REC_SRC
        , BKCC
        , CAP_UTIL_RATE_PERCENT                                         as CAPACITY_UTILITY_RATE_PERCENT
        , PLANT_BK
        , START_TIME_IN_SECONDS
        , END_TIME_IN_SECONDS
        , AZNOR_NUM_OF_INDIVIDUAL_CAP                                   as AZNOR_NUM_OF_INDIVIDUAL_CAPACITY
        , FACTORY_CALENDAR_ID
        , AVAIL_CAP_VER                                                 as ACTIVE_AVAILABLE_CAPACITY_VERSION  
        , CAP_CATEGORY                                                  as CAPACITY_CATEGORY
        , CAP_MEASUREMENT_UNIT                                          as CAPACITY_MEASUREMENT_UNIT
        , CUMULATIVE_BREAK_TIME_IN_SECONDS
        , CAP_PLANNER_GROUP                                             as CAPACITY_PLANNER_GROUP
        , SAT_WINN_PSA_DELETE_IND
        , CAP_SHORT_TEXT                                                as CAPACITY_SHORT_TEXT
        , VALID_TO_DATE__YYYYMMDD
        , AVAILABLE_CAPACITY_VERSION                                    
        , END_TIME_IN_SECONDS - START_TIME_IN_SECONDS                   as TOTAL_TIME_SECONDS
        , START_TIME_IN_SECONDS + CUMULATIVE_BREAK_TIME_IN_SECONDS      as TOTAL_DOWNTIME_SECONDS
        , TOTAL_TIME_SECONDS / 60                                               as TOTAL_TIME_MINUTES
        , TOTAL_TIME_SECONDS / 3600                                             as TOTAL_TIME_HOURS
        , 5*(TOTAL_TIME_SECONDS / 3600)                                         as TOTAL_TIME_HOUR_PER_WEEK
        , TOTAL_TIME_SECONDS * AZNOR_NUM_OF_INDIVIDUAL_CAP                      as TOTAL_UPTIME_PER_DAY
FROM JOIN_RESULT
WHERE VALID_TO_DATE__YYYYMMDD > 0 
  and VALID_TO_DATE__YYYYMMDD >= TO_NUMBER(TO_CHAR(CURRENT_DATE(), 'YYYYMMDD'))
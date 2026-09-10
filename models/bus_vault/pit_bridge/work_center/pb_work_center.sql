---- SRC LAYER ----
WITH
SRC_hub            as ( SELECT BKCC, PLANT_BK, REC_SRC, WORK_CENTER_BK, WORK_CENTER_HK FROM {{ ref('hub_work_center') }} as SRC  ),
SRC_sat            as ( SELECT WORK_CENTER_HK,ARBPL, BEGDA, ENDDA, KAPID, PLANV, PSA_DELETE_IND, STAND, VERAN, VERWE, WERKS FROM {{ ref('sat_work_center__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by WORK_CENTER_HK, WERKS order by load_dts DESC) ),
SRC_msat           as ( SELECT KTEXT, SPRAS, WORK_CENTER_HK FROM {{ ref('msat_work_center__winn_sap') }} as SRC
                        WHERE SPRAS = 'E'
                        qualify 1= row_number() over(partition by WORK_CENTER_HK, spras order by load_dts DESC) ),
SRC_lsat           as ( SELECT LNK_WORK_CENTER_CAPACITY_HK,CANUM, KAPID FROM {{ ref('lsat_work_center_capacity__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by LNK_WORK_CENTER_CAPACITY_HK order by load_dts DESC) ),
SRC_lnk           as ( SELECT WORK_CENTER_HK, LNK_WORK_CENTER_CAPACITY_HK FROM {{ ref('lnk_work_center_capacity') }} as SRC 
                        qualify 1= row_number() over(partition by WORK_CENTER_HK order by load_dts DESC) )


/*
SRC_hub            as ( SELECT * FROM RAW_VAULT.hub_work_center ) 
SRC_sat            as ( SELECT * FROM RAW_VAULT.sat_work_center__winn_sap )
SRC_msat           as ( SELECT * FROM RAW_VAULT.msat_work_center__winn_sap )
SRC_lsat           as ( SELECT * FROM RAW_VAULT.lsat_work_center_capacity__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_hub as (
    SELECT
        WORK_CENTER_HK
      , WORK_CENTER_BK
      , PLANT_BK
      , REC_SRC
      , BKCC
    FROM SRC_hub
)

, LOGIC_sat as (
    SELECT
        WORK_CENTER_HK                                               as                                 SAT_WORK_CENTER_HK
      , KAPID                                                        as                                        CAPACITY_ID
      , ARBPL                                                        as                                        WORK_CENTER
      , WERKS                                                        as                                              PLANT
      , VERWE                                                        as                               WORK_CENTER_CATEGORY
      , STAND                                                        as                               WORK_CENTER_LOCATION
      , VERAN                                                        as                                  WORK_CENTER_OWNER
      , PLANV                                                        as                                TASK_LIST_USAGE_KEY
      , BEGDA                                                        as                                         START_DATE
      , ENDDA                                                        as                                           END_DATE
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_sat
)

, LOGIC_msat as (
    SELECT
       WORK_CENTER_HK as MSAT_WORK_CENTER_HK 
    ,  KTEXT                                                        as                                  SHORT_DESCRIPTION
    ,  SPRAS
    FROM SRC_msat
)

, LOGIC_lsat as (
    SELECT
        KAPID                                                        as                                            CAPACITY_ID_WORK_CENTER_CAPACITY
      , CANUM                                                        as                                            CAPACITY_NUMBER
      , LNK_WORK_CENTER_CAPACITY_HK
    FROM SRC_lsat
)

, LOGIC_lnk as (
    SELECT
        WORK_CENTER_HK as lnk_wc_hk
      , LNK_WORK_CENTER_CAPACITY_HK as lnk_wcc_lhk
    FROM SRC_lnk
)
---- RENAME LAYER ----

, RENAME_hub as (
    SELECT
        WORK_CENTER_HK
      , WORK_CENTER_BK
      , PLANT_BK
      , REC_SRC
      , BKCC
    FROM LOGIC_hub
)

, RENAME_sat as (
    SELECT
        CAPACITY_ID
      , WORK_CENTER
      , SAT_WORK_CENTER_HK
      , PLANT
      , WORK_CENTER_CATEGORY
      , WORK_CENTER_LOCATION
      , WORK_CENTER_OWNER
      , TASK_LIST_USAGE_KEY
      , START_DATE
      , END_DATE
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_sat
)

, RENAME_msat as (
    SELECT
        SHORT_DESCRIPTION
        , SPRAS
        , MSAT_WORK_CENTER_HK
    FROM LOGIC_msat
)

, RENAME_lsat as (
    SELECT
        CAPACITY_ID_WORK_CENTER_CAPACITY
      , CAPACITY_NUMBER
      , LNK_WORK_CENTER_CAPACITY_HK
    FROM LOGIC_lsat
)

, RENAME_lnk as (
    SELECT
        lnk_wc_hk
      , lnk_wcc_lhk
    FROM LOGIC_lnk
)
---- FILTER LAYER ----

, FILTER_hub as (
    SELECT *
    FROM RENAME_hub
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED' /* This filter is to exclude the ghost records */
)

, FILTER_sat as (
    SELECT *
    FROM RENAME_sat
)

, FILTER_msat as (
    SELECT *
    FROM RENAME_msat
)

, FILTER_lsat as (
    SELECT *
    FROM RENAME_lsat
)

, FILTER_lnk as (
    SELECT *
    FROM RENAME_lnk
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_lnk 
    INNER JOIN FILTER_hub
        ON FILTER_hub.WORK_CENTER_HK = FILTER_lnk.lnk_wc_hk
    INNER JOIN FILTER_lsat
        ON FILTER_lnk.lnk_wcc_lhk = FILTER_lsat.LNK_WORK_CENTER_CAPACITY_HK                 
    LEFT JOIN FILTER_sat
        ON FILTER_hub.WORK_CENTER_HK = FILTER_sat.SAT_WORK_CENTER_HK         
    LEFT JOIN FILTER_msat
        ON FILTER_hub.WORK_CENTER_HK = FILTER_msat.MSAT_WORK_CENTER_HK      

)

---- FINAL LAYER ----
SELECT
          CURRENT_TIMESTAMP as SNAPSHOT_DTS
        , 'PB_WORK_CENTER' as PB_REC_SRC
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )  as PB_LOAD_DTS
        , WORK_CENTER_HK
        , WORK_CENTER_BK
        , PLANT_BK
        , REC_SRC
        , BKCC
        , CAPACITY_ID
        , WORK_CENTER
        , PLANT
        , WORK_CENTER_CATEGORY
        , WORK_CENTER_LOCATION
        , WORK_CENTER_OWNER
        , TASK_LIST_USAGE_KEY
        , START_DATE :: INTEGER AS START_DATE__YYYYMMDD
        , END_DATE :: INTEGER AS END_DATE__YYYYMMDD
        , SHORT_DESCRIPTION
        , CAPACITY_ID_WORK_CENTER_CAPACITY
        , CAPACITY_NUMBER
        , CASE  WHEN BKCC = 'Hiding_Tiger' THEN SAT_WINN_PSA_DELETE_IND
           END as IS_DELETED 
FROM JOIN_RESULT
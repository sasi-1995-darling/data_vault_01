---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_quality_task') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_quality_task__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY QUALITY_TASKS_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_QUALITY_TASK )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_QUALITY_TASK__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_QUALITY_TASK'                                           as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , QUALITY_TASKS_HK
      , BKCC
      , REC_SRC
      , QUALITY_TASKS_HK                                      as                                        H_QUALITY_TASKS_HK
      , QUALITY_TASKS_BK                                      as                                      TASK_NOTIFICATION_BK
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        QUALITY_TASKS_HK                                            
      , QMNUM                                                       
      , MANUM                                                       
      , MNKAT                                                       
      , MNGRP                                                       
      , MNCOD                                                                                                             
      , OBJNR                                                       
      , MMENGE                                                      
      , MMGEIN                                                      
      , CAST(ERDAT AS INTEGER)                                       as                              TASK_CREATION_DATE__YYYYMMDD
      , CAST(AEDAT AS INTEGER)                                       as                                TASK_UPDATE_DATE__YYYYMMDD
      , CAST(PSTER AS INTEGER)                                       as                              PLANNED_START_DATE__YYYYMMDD
      , CAST(PETER AS INTEGER)                                       as                             PLANNED_FINISH_DATE__YYYYMMDD
      , PSA_DELETE_IND
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , QUALITY_TASKS_HK
      , BKCC
      , REC_SRC
      , H_QUALITY_TASKS_HK
      , TASK_NOTIFICATION_BK
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
       QUALITY_TASKS_HK                                              as                          SAT_WINN_QUALITY_TASKS_HK
      , QMNUM                                                        as                                    NOTIFICATION_BK
      , MANUM                                                        as                                            TASK_BK
      , MNKAT                                                        as                                       CATALOG_TYPE
      , MNGRP                                                        as                                         CODE_GROUP
      , MNCOD                                                        as                                          TASK_CODE                                                      
      , OBJNR                                                        as                                      OBJECT_NUMBER
      , MMENGE                                                       as                                           QUANTITY
      , MMGEIN                                                       as                                       QUANTITY_UOM
      , TASK_CREATION_DATE__YYYYMMDD
      , TASK_UPDATE_DATE__YYYYMMDD
      , PLANNED_START_DATE__YYYYMMDD
      , PLANNED_FINISH_DATE__YYYYMMDD
      , PSA_DELETE_IND
    FROM LOGIC_SAT_WINN
)
---- FILTER LAYER ----

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_H
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_H.QUALITY_TASKS_HK = FILTER_SAT_WINN.SAT_WINN_QUALITY_TASKS_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , QUALITY_TASKS_HK
        , TASK_NOTIFICATION_BK
        , NOTIFICATION_BK
        , TASK_BK
        , CATALOG_TYPE
        , CODE_GROUP
        , TASK_CODE
        , TASK_CREATION_DATE__YYYYMMDD
        , TASK_UPDATE_DATE__YYYYMMDD
        , PLANNED_START_DATE__YYYYMMDD
        , PLANNED_FINISH_DATE__YYYYMMDD
        , OBJECT_NUMBER
        , QUANTITY
        , QUANTITY_UOM
        , BKCC
        , REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_quality_activity') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_quality_activity__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY QUALITY_ACTIVITY_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_QUALITY_TASK )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_QUALITY_ACTIVITY__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_QUALITY_ACTIVITY'                                       as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP)                   as                                       PIT_LOAD_DTS
      , QUALITY_ACTIVITY_HK
      , QUALITY_ACTIVITY_BK                                          as                            NOTIFICATION_ACTIVITY_BK
      , BKCC
      , REC_SRC
    FROM SRC_H
)

 , LOGIC_SAT_WINN as (
    SELECT
        QMNUM                                                        
      , MANUM                                                        
      , MNKAT                                                        
      , MNGRP                                                        
      , MNCOD                                                        
      , MATXT                                                        
      , MNGFA                                                        
      , FUNKTION                                                     
      , ZZAMOUNT1                                                    
      , ZZAMOUNT2                                                    
      , CAST(ERDAT AS INTEGER)                                       as              ACTIVITY_CREATION_DATE___YYYYMMDD
      , CAST(AEDAT AS INTEGER)                                       as                ACTIVITY_UPDATE_DATE___YYYYMMDD
      , CAST(PSTER AS INTEGER)                                       as                  PLANNED_START_DATE___YYYYMMDD
      , CAST(PETER AS INTEGER)                                       as                 PLANNED_FINISH_DATE___YYYYMMDD
      , QUALITY_ACTIVITY_HK                                         
      , PSA_DELETE_IND
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , QUALITY_ACTIVITY_HK
      , NOTIFICATION_ACTIVITY_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
      QMNUM                                                        as                                NOTIFICATION_BK
      , MANUM                                                        as                                    ACTIVITY_BK
      , MNKAT                                                        as                                   CATALOG_TYPE
      , MNGRP                                                        as                                     CODE_GROUP
      , MNCOD                                                        as                                  ACTIVITY_CODE
      , MATXT                                                        as                                  ACTIVITY_TEXT
      , MNGFA                                                        as                                QUANTITY_FACTOR
      , FUNKTION                                                     as                                  FUNCTION_KEYS
      , ZZAMOUNT1                                                    as                              ACTIVITY_AMOUNT_1
      , ZZAMOUNT2                                                    as                              ACTIVITY_AMOUNT_2
      , ACTIVITY_CREATION_DATE___YYYYMMDD
      , ACTIVITY_UPDATE_DATE___YYYYMMDD
      , PLANNED_START_DATE___YYYYMMDD
      , PLANNED_FINISH_DATE___YYYYMMDD
      , QUALITY_ACTIVITY_HK                                          as                   SAT_WINN_QUALITY_ACTIVITY_HK
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
        ON FILTER_H.QUALITY_ACTIVITY_HK = FILTER_SAT_WINN.SAT_WINN_QUALITY_ACTIVITY_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , QUALITY_ACTIVITY_HK
        , NOTIFICATION_ACTIVITY_BK
        , NOTIFICATION_BK
        , ACTIVITY_BK
        , CATALOG_TYPE
        , CODE_GROUP
        , ACTIVITY_CODE
        , ACTIVITY_TEXT
        , QUANTITY_FACTOR
        , FUNCTION_KEYS
        , ACTIVITY_AMOUNT_1
        , ACTIVITY_AMOUNT_2
        , ACTIVITY_CREATION_DATE___YYYYMMDD
        , ACTIVITY_UPDATE_DATE___YYYYMMDD
        , PLANNED_START_DATE___YYYYMMDD
        , PLANNED_FINISH_DATE___YYYYMMDD
        , BKCC
        , REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END   as                                     IS_DELETED
FROM JOIN_RESULT

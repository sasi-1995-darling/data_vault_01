---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_quality_causes') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_quality_causes__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY QUALITY_CAUSES_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_QUALITY_CAUSES )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_QUALITY_CAUSES__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_QUALITY_CAUSES'                                         as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , QUALITY_CAUSES_HK
      , QUALITY_CAUSES_BK                                            as                        NOTIFICATION_ISSUE_CAUSE_BK
      , BKCC
      , REC_SRC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        QMNUM                                                        
      , FENUM                                                        
      , URNUM                                                        
      , URKAT                                                        
      , URGRP                                                        
      , URCOD                                                        
      , URTXT                                                        
      , BAUTL                                                        
      , CAST(ERDAT AS INTEGER)                                       as                   ACTIVITY_CREATION_DATE__YYYYMMDD
      , CAST(AEDAT AS INTEGER)                                       as                     ACTIVITY_UPDATE_DATE__YYYYMMDD
      , QUALITY_CAUSES_HK                                           
      , PSA_DELETE_IND
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , QUALITY_CAUSES_HK
      , NOTIFICATION_ISSUE_CAUSE_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        QMNUM                                                        as                                    NOTIFICATION_BK
      , FENUM                                                        as                                           ISSUE_BK
      , URNUM                                                        as                                           CAUSE_BK
      , URKAT                                                        as                                       CATALOG_TYPE
      , URGRP                                                        as                                         CODE_GROUP
      , URCOD                                                        as                                      ACTIVITY_CODE
      , URTXT                                                        as                                         CAUSE_TEXT
      , BAUTL                                                        as                                     CAUSE_ASSEMBLY
      , ACTIVITY_CREATION_DATE__YYYYMMDD
      , ACTIVITY_UPDATE_DATE__YYYYMMDD
      , QUALITY_CAUSES_HK                                            as                         SAT_WINN_QUALITY_CAUSES_HK
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
        ON FILTER_H.QUALITY_CAUSES_HK = FILTER_SAT_WINN.SAT_WINN_QUALITY_CAUSES_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , QUALITY_CAUSES_HK
        , NOTIFICATION_ISSUE_CAUSE_BK
        , NOTIFICATION_BK
        , ISSUE_BK
        , CAUSE_BK
        , CATALOG_TYPE
        , CODE_GROUP
        , ACTIVITY_CODE
        , CAUSE_TEXT
        , CAUSE_ASSEMBLY
        , ACTIVITY_CREATION_DATE__YYYYMMDD
        , ACTIVITY_UPDATE_DATE__YYYYMMDD
        , BKCC
        , REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END     as             IS_DELETED
FROM JOIN_RESULT

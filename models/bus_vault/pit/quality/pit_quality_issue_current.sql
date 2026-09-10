---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_quality_issue') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_quality_issue__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY QUALITY_ISSUE_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_QUALITY_ISSUE )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_QUALITY_ISSUE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_QUALITY_ISSUE'                                          as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , QUALITY_ISSUE_BK                                             as                              ISSUE_NOTIFICATION_BK                                           
      , QUALITY_ISSUE_HK
      , BKCC
      , REC_SRC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
 SELECT 
        QUALITY_ISSUE_HK                                             
      , QMNUM                                                        
      , FENUM                                                        
      , FEKAT                                                        
      , FEGRP                                                        
      , FECOD                                                        
      , OTKAT                                                        
      , OTGRP                                                        
      , FEQKLAS                                                      
      , CASE WHEN FMGFRD = 0 AND FMGEIG > 0 THEN FMGEIG ELSE FMGFRD END as                                 DEFECTIVE_QUANTITY
      , FMGEIN                                                       
      , ANZFEHLER                                                    
      , FEHLBEW                                                      
      , MERKNR                                                       
      , PROBENR                                                      
      , ARBPL                                                        
      , ARBPLWERK                                                    
      , ZZFAILURE_MODE                                               
      , ZZINSTALLDATE                                                
      , ZZPAFNO                                                      
      , ZZITEMKAT1                                                   
      , ZZITEMGRP1                                                   
      , ZZITEMCOD1                                                   
      , ZZITEMKAT2                                                   
      , ZZITEMGRP2                                                   
      , ZZITEMCOD2                                                   
      , CAST(ERDAT AS INTEGER)                                       as                          ACTIVITY_CREATION_DATE__YYYYMMDD
      , CAST(AEDAT AS INTEGER)                                       as                            ACTIVITY_UPDATE_DATE__YYYYMMDD
      , PSA_DELETE_IND 
      FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , ISSUE_NOTIFICATION_BK 
      , QUALITY_ISSUE_HK
      , BKCC
      , REC_SRC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        QUALITY_ISSUE_HK                                             as                          SAT_WINN_QUALITY_ISSUE_HK
      , QMNUM                                                        as                                    NOTIFICATION_BK
      , FENUM                                                        as                                           ISSUE_BK
      , FEKAT                                                        as                                       CATALOG_TYPE
      , FEGRP                                                        as                                         CODE_GROUP
      , FECOD                                                        as                                      ACTIVITY_CODE
      , OTKAT                                                        as                                 PARTS_CATALOG_TYPE
      , OTGRP                                                        as                                   PARTS_CODE_GROUP
      , FEQKLAS                                                      as                                       DEFECT_CLASS
      , DEFECTIVE_QUANTITY
      , FMGEIN                                                       as                                           ITEM_UOM
      , ANZFEHLER                                                    as                            NUMBER_OF_DEFECTS_FOUND
      , FEHLBEW                                                      as                                   DEFECT_VALUATION
      , MERKNR                                                       as                                    INSPECTION_TYPE
      , PROBENR                                                      as                           INSPECTION_SAMPLE_NUMBER
      , ARBPL                                                        as                              WORK_CENTER_OBJECT_ID
      , ARBPLWERK                                                    as                                           PLANT_ID
      , ZZFAILURE_MODE                                               as                                       FAILURE_MODE
      , ZZINSTALLDATE                                                as                                       INSTALL_DATE
      , ZZPAFNO                                                      as                            PERSONAL_ACTION_FORM_NO
      , ZZITEMKAT1                                                   as                                    ITEM_CATEGORY_1
      , ZZITEMGRP1                                                   as                                       ITEM_GROUP_1
      , ZZITEMCOD1                                                   as                                        ITEM_CODE_1
      , ZZITEMKAT2                                                   as                                    ITEM_CATEGORY_2
      , ZZITEMGRP2                                                   as                                       ITEM_GROUP_2
      , ZZITEMCOD2                                                   as                                        ITEM_CODE_2
      , ACTIVITY_CREATION_DATE__YYYYMMDD
      , ACTIVITY_UPDATE_DATE__YYYYMMDD
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
        ON FILTER_H.QUALITY_ISSUE_HK = FILTER_SAT_WINN.SAT_WINN_QUALITY_ISSUE_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , QUALITY_ISSUE_HK
        , ISSUE_NOTIFICATION_BK
        , NOTIFICATION_BK
        , ISSUE_BK
        , CATALOG_TYPE
        , CODE_GROUP
        , ACTIVITY_CODE
        , ACTIVITY_CREATION_DATE__YYYYMMDD
        , ACTIVITY_UPDATE_DATE__YYYYMMDD
        , PARTS_CATALOG_TYPE
        , PARTS_CODE_GROUP
        , DEFECT_CLASS
        , DEFECTIVE_QUANTITY
        , ITEM_UOM
        , NUMBER_OF_DEFECTS_FOUND
        , DEFECT_VALUATION
        , INSPECTION_TYPE
        , INSPECTION_SAMPLE_NUMBER
        , WORK_CENTER_OBJECT_ID
        , PLANT_ID
        , FAILURE_MODE
        , INSTALL_DATE
        , PERSONAL_ACTION_FORM_NO
        , ITEM_CATEGORY_1
        , ITEM_GROUP_1
        , ITEM_CODE_1
        , ITEM_CATEGORY_2
        , ITEM_GROUP_2
        , ITEM_CODE_2
        , BKCC
        , REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED
FROM JOIN_RESULT

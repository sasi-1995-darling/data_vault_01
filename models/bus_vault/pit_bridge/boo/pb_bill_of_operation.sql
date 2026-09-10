---- SRC LAYER ----
WITH
SRC_BB             as ( SELECT LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK, TASK_LIST_GROUP_COUNTER, CHILD_OP_HK FROM {{ ref('bridge_boo_hierarchy') }} as SRC  ),
SRC_LT             as ( SELECT ITEM_HK, LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK, PLANT_HK, REC_SRC FROM {{ ref('lnk_plant_tasklist_item_assignment') }} as SRC  ),
SRC_HI             as ( SELECT ITEM_BK, ITEM_HK, BKCC FROM {{ ref('hub_item_v1') }} as SRC  ),
SRC_HP             as ( SELECT PLANT_BK, PLANT_HK FROM {{ ref('hub_plant_v1') }} as SRC  ),
SRC_ST             as ( SELECT ARBID, BMSCH, LAR01, LAR02, LAR03, VGE02, VGE03, MEINH, STEUS, TASKLIST_OPERATION_HK, VGE01, VGW01, VGW02, VGW03, VORNR, PSA_DELETE_IND FROM {{ ref('sat_tasklist_operation__winn_sap') }} as SRC
                        qualify 1= row_number() over(partition by TASKLIST_OPERATION_HK order by LOAD_DTS DESC) )

/*
SRC_BB             as ( SELECT * FROM RAW_VAULT.BRIDGE_BOO_HIERARCHY )
SRC_LT             as ( SELECT * FROM RAW_VAULT.LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT )
SRC_HI             as ( SELECT * FROM RAW_VAULT.HUB_ITEM_V1 )
SRC_HP             as ( SELECT * FROM RAW_VAULT.HUB_PLANT_V1 )
SRC_ST             as ( SELECT * FROM RAW_VAULT.SAT_TASKLIST_OPERATION__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_BB as (
    SELECT
        LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK
      , CHILD_OP_HK
      , TASK_LIST_GROUP_COUNTER                                                   as                             TASKLIST_GROUP_COUNTER
    FROM SRC_BB
)

, LOGIC_LT as (
    SELECT
       'PB_BILL_OF_OPERATION'                                       as                                         PB_REC_SRC
      , REC_SRC
      , PLANT_HK
      , ITEM_HK
      , LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK
    FROM SRC_LT
)

, LOGIC_HI as (
    SELECT
        ITEM_BK
      , ITEM_HK                                                     as                                         HI_ITEM_HK
      , BKCC                                                     
    FROM SRC_HI
)

, LOGIC_HP as (
    SELECT
        PLANT_HK                                                     as                                        HP_PLANT_HK
      , PLANT_BK
    FROM SRC_HP
)

, LOGIC_ST as (
    SELECT
        TASKLIST_OPERATION_HK
      , VORNR                                                        as                                       OPERATION_ID
      , ARBID                                                        as                                          OBJECT_ID
      , STEUS                                                        as                                         CONTROLLER
      , BMSCH                                                        as                                      BASE_QUANTITY
      , MEINH                                                        as                                                UOM
      , LAR01                                                        as                                    ACTIVITY_TYPE_1
      , VGE01                                                        as                                         UOM_TYPE_1
      , VGW01                                                        as                                        TIME_TYPE_1
      , LAR02                                                        as                                    ACTIVITY_TYPE_2
      , VGE02                                                        as                                         UOM_TYPE_2
      , VGW02                                                        as                                        TIME_TYPE_2
      , LAR03                                                        as                                    ACTIVITY_TYPE_3
      , VGE03                                                        as                                         UOM_TYPE_3
      , VGW03                                                        as                                        TIME_TYPE_3
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_ST
)
---- RENAME LAYER ----

, RENAME_LT as (
    SELECT
        PB_REC_SRC
      , REC_SRC
      , PLANT_HK
      , ITEM_HK
      , LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK
    FROM LOGIC_LT
)

, RENAME_BB as (
    SELECT
        LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK
      , CHILD_OP_HK
      , TASKLIST_GROUP_COUNTER
    FROM LOGIC_BB
)

, RENAME_HI as (
    SELECT
        ITEM_BK
      , HI_ITEM_HK
      , BKCC
    FROM LOGIC_HI
)

, RENAME_HP as (
    SELECT
        HP_PLANT_HK
      , PLANT_BK
    FROM LOGIC_HP
)

, RENAME_ST as (
    SELECT
        TASKLIST_OPERATION_HK
      , OPERATION_ID
      , OBJECT_ID
      , CONTROLLER
      , BASE_QUANTITY
      , UOM
      , ACTIVITY_TYPE_1
      , UOM_TYPE_1
      , TIME_TYPE_1
      , ACTIVITY_TYPE_2
      , UOM_TYPE_2
      , TIME_TYPE_2
      , ACTIVITY_TYPE_3
      , UOM_TYPE_3
      , TIME_TYPE_3
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_ST
)
---- FILTER LAYER ----

, FILTER_BB as (
    SELECT *
    FROM RENAME_BB
)

, FILTER_LT as (
    SELECT *
    FROM RENAME_LT
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED' /* This filter is to exclude the ghost records */
)

, FILTER_HI as (
    SELECT *
    FROM RENAME_HI
)

, FILTER_HP as (
    SELECT *
    FROM RENAME_HP
)

, FILTER_ST as (
    SELECT *
    FROM RENAME_ST
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_BB
    INNER JOIN FILTER_LT
        ON FILTER_BB.LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK = FILTER_LT.LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK
    LEFT JOIN FILTER_HI
        ON FILTER_LT.ITEM_HK = FILTER_HI.HI_ITEM_HK
    LEFT JOIN FILTER_HP
        ON FILTER_LT.PLANT_HK = FILTER_HP.HP_PLANT_HK
    LEFT JOIN FILTER_ST
        ON FILTER_BB.CHILD_OP_HK = FILTER_ST.TASKLIST_OPERATION_HK
)

---- FINAL LAYER ----
SELECT DISTINCT
          CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PIT_LOAD_DTS
        , BKCC
        , PB_REC_SRC
        , REC_SRC
        , PLANT_HK
        , ITEM_HK
        , CHILD_OP_HK
        , ITEM_BK
        , PLANT_BK
        , OPERATION_ID
        , OBJECT_ID
        , CONTROLLER
        , BASE_QUANTITY
        , UOM
        , ACTIVITY_TYPE_1
        , UOM_TYPE_1
        , TIME_TYPE_1
        , ACTIVITY_TYPE_2
        , UOM_TYPE_2
        , TIME_TYPE_2
        , ACTIVITY_TYPE_3
        , UOM_TYPE_3
        , TIME_TYPE_3
        , TASKLIST_GROUP_COUNTER
        , CASE  
            WHEN BKCC = 'Hiding_Tiger' 
            THEN SAT_WINN_PSA_DELETE_IND
            ELSE 'N'
          END as IS_DELETED 
FROM JOIN_RESULT

---- SRC LAYER ----
WITH
SRC_Asgn as ( 
    SELECT 
        LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK, 
        TASKLIST_GROUP_HK,
        ITEM_HK, 
        PLANT_HK 
    FROM {{ ref('lnk_plant_tasklist_item_assignment') }} 
),
SRC_Asgn_Sat as ( 
    SELECT 
        LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK, 
        PLNAL, 
        LOAD_DTS,
        PSA_DELETE_IND
    FROM {{ ref('lmsat_task_material_assignment__winn_sap') }} 
    WHERE PSA_DELETE_IND != 'X'
    qualify row_number() over (partition by LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK order by LOAD_DTS desc) = 1
),
SRC_Op_Lnk as ( 
    SELECT 
        LNK_TASKLIST_OPERATION_HK,
        TASKLIST_GROUP_HK, 
        TASKLIST_OPERATION_HK 
    FROM {{ ref('lnk_tasklist_group_operation') }} 
),
SRC_Op_Sat as ( 
    SELECT 
        LNK_TASKLIST_OPERATION_HK, 
        PLNAL, 
        LOAD_DTS,
        PSA_DELETE_IND
    FROM {{ ref('lmsat_tasklist_group_operation__winn_sap') }} 
    WHERE PSA_DELETE_IND != 'X'
    qualify row_number() over (partition by LNK_TASKLIST_OPERATION_HK order by LOAD_DTS desc) = 1
),
SRC_Op_Attr as ( 
    SELECT 
        SAT.TASKLIST_OPERATION_HK, 
        SAT.VPLNR, 
        SAT.VPLTY,
        SAT.PLNTY, 
        SAT.VORNR,
        SAT.ARBID,
        SAT.STEUS,
        SAT.BMSCH,
        SAT.MEINH,
        SAT.LAR01,
        SAT.VGE01,
        SAT.VGW01,
        SAT.LAR02,
        SAT.VGE02,
        SAT.VGW02,
        SAT.LAR03,
        SAT.VGE03,
        SAT.VGW03, 
        SAT.LOAD_DTS,
        SAT.PSA_DELETE_IND,
        HUB.BKCC,
        -- Create the child tasklist group hash key (the recursion pointer)
        MD5_BINARY(
            UPPER(TRIM(SAT.VPLTY)) || '||' || 
            UPPER(TRIM(SAT.VPLNR)) || '||' || 
            UPPER(TRIM(HUB.BKCC))
        ) as CHILD_TASKLIST_GROUP_HK
    FROM {{ ref('sat_tasklist_operation__winn_sap') }} SAT
    INNER JOIN {{ ref('hub_tasklist_operation') }} HUB
        ON SAT.TASKLIST_OPERATION_HK = HUB.TASKLIST_OPERATION_HK
    WHERE SAT.PSA_DELETE_IND != 'X'
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY SAT.TASKLIST_OPERATION_HK 
        ORDER BY SAT.LOAD_DTS DESC
    ) = 1
),
SRC_Item as ( 
    SELECT 
        ITEM_HK, 
        ITEM_BK
    FROM {{ ref("hub_item_v1")}}
),
SRC_Item_Sat as ( 
    SELECT 
        ITEM_HK, 
        EAN11,
        LOAD_DTS,
        PSA_DELETE_IND
    FROM {{ ref("sat_item_master__moen_sap_v1")}}
    WHERE PSA_DELETE_IND != 'X'
    qualify row_number() over (partition by ITEM_HK order by LOAD_DTS desc) = 1
),
SRC_Plant as ( 
    SELECT 
        Plant_HK, 
        Plant_BK
    FROM {{ ref("hub_plant_v1")}}
),
SRC_Plant_Sat as ( 
    SELECT 
        Plant_HK, 
        NAME1,
        LOAD_DTS,
        GLDELFLAG
    FROM {{ ref("sat_plant__moen_sap")}}
    WHERE GLDELFLAG != 'X'
    qualify row_number() over (partition by Plant_HK order by LOAD_DTS desc) = 1
),
-- Parent Operation (Routing Header - Type N or R)
LOGIC_Op_Parent as (
    SELECT
        OL.LNK_TASKLIST_OPERATION_HK         as PARENT_OP_LNK_HK,
        OL.TASKLIST_GROUP_HK                 as PARENT_GROUP_HK,
        OL.TASKLIST_OPERATION_HK             as PARENT_OP_HK,
        OS.PLNAL                             as PARENT_PLNAL,
        OA.VPLTY                             as PARENT_VPLTY,
        OA.PLNTY                             as PARENT_PLNTY,
        OA.CHILD_TASKLIST_GROUP_HK           as CHILD_GROUP_HK_POINTER,
        OA.LOAD_DTS                          as PARENT_LOAD_DTS
    FROM SRC_Op_Lnk OL
    INNER JOIN SRC_Op_Sat OS
        ON OL.LNK_TASKLIST_OPERATION_HK = OS.LNK_TASKLIST_OPERATION_HK
    INNER JOIN SRC_Op_Attr OA
        ON OL.TASKLIST_OPERATION_HK = OA.TASKLIST_OPERATION_HK
    --WHERE OA.VPLTY IN ('N', 'R')  -- Parent types only (retaining reference as this was removed in development)
),
-- Child Operation (Sub-Operation - Type S or M)
LOGIC_Op_Child as (
    SELECT
        OL.LNK_TASKLIST_OPERATION_HK         as CHILD_OP_LNK_HK,
        OL.TASKLIST_GROUP_HK                 as CHILD_GROUP_HK,
        OL.TASKLIST_OPERATION_HK             as CHILD_OP_HK,
        OS.PLNAL                             as CHILD_PLNAL,
        OA.VPLTY                             as CHILD_VPLTY,
        OA.PLNTY                             as CHILD_PLNTY, 
        OA.VORNR                             AS OPERATION_ID,
        OA.ARBID                             AS OBJECT_ID,
        OA.STEUS                             AS CONTROLLER, 
        OA.BMSCH                             AS BASE_QUANTITY,
        OA.MEINH                             AS UOM,
        OA.LAR01                             AS ACTIVITY_TYPE_1,
        OA.VGE01                             AS UOM_TYPE_1,
        OA.VGW01                             AS TIME_TYPE_1,
        OA.LAR02                             AS ACTIVITY_TYPE_2,
        OA.VGE02                             AS UOM_TYPE_2,
        OA.VGW02                             AS TIME_TYPE_2,
        OA.LAR03                             AS ACTIVITY_TYPE_3,
        OA.VGE03                             AS UOM_TYPE_3,
        OA.VGW03                             AS TIME_TYPE_3,      
        OA.LOAD_DTS                          AS Child_Load_DTS
    FROM SRC_Op_Lnk OL
    INNER JOIN SRC_Op_Sat OS
        ON OL.LNK_TASKLIST_OPERATION_HK = OS.LNK_TASKLIST_OPERATION_HK
    INNER JOIN SRC_Op_Attr OA
        ON OL.TASKLIST_OPERATION_HK = OA.TASKLIST_OPERATION_HK
    --WHERE OA.VPLTY IN ('S', 'M')  -- Child types only
)
---- RENAME LAYER ----
, RENAME_Asgn       as ( SELECT * FROM Src_Asgn )
, RENAME_Asgn_Sat   as ( SELECT * FROM Src_Asgn_Sat )
, RENAME_Item       as ( SELECT * FROM Src_Item )
, RENAME_Item_Sat   as ( SELECT * FROM Src_Item_Sat )
, RENAME_Plant      as ( SELECT * FROM Src_Plant )
, RENAME_Plant_Sat  as ( SELECT * FROM Src_Plant_Sat )
, RENAME_Op_Parent  as ( SELECT * FROM LOGIC_Op_Parent )
, RENAME_Op_Child   as ( SELECT * FROM LOGIC_Op_Child )

---- FILTER LAYER ----
, FILTER_Asgn       as ( SELECT * FROM RENAME_Asgn )
, FILTER_Asgn_Sat   as ( SELECT * FROM RENAME_Asgn_Sat )
, FILTER_Item       as ( SELECT * FROM RENAME_Item )
, FILTER_Item_Sat   as ( SELECT * FROM RENAME_Item_Sat )
, FILTER_Plant      as ( SELECT * FROM RENAME_Plant)
, FILTER_Plant_Sat  as ( SELECT * FROM RENAME_Plant_Sat )
, FILTER_Op_Parent  as ( SELECT * FROM RENAME_Op_Parent )
, FILTER_Op_Child   as ( SELECT * FROM RENAME_Op_Child )

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT
        A.LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK,
        A_SAT.PLNAL AS TASK_LIST_GROUP_COUNTER,
        P.PARENT_OP_HK,
        C.CHILD_OP_HK,
        C.CHILD_PLNAL                        as OP_PLNAL,
        GREATEST(P.PARENT_LOAD_DTS, C.CHILD_LOAD_DTS) as DRVD_HIERARCHY_DATE,    
        I.ITEM_BK AS MATERIAL,
        Pl.PLANT_BK AS PLANT,
        C.OPERATION_ID,
        C.OBJECT_ID,
        C.CONTROLLER, 
        C.BASE_QUANTITY,
        C.UOM,
        C.ACTIVITY_TYPE_1,
        C.UOM_TYPE_1,
        C.TIME_TYPE_1,
        C.ACTIVITY_TYPE_2,
        C.UOM_TYPE_2,
        C.TIME_TYPE_2,
        C.ACTIVITY_TYPE_3,
        C.UOM_TYPE_3,
        C.TIME_TYPE_3,
        C.CHILD_LOAD_DTS AS VALID_FROM
    
    FROM FILTER_Asgn A
    JOIN FILTER_Asgn_Sat A_SAT
      ON A.LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK = A_SAT.LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK
    -- Join to Parent Operation
    JOIN FILTER_Op_Parent P
      ON A.TASKLIST_GROUP_HK = P.PARENT_GROUP_HK
    -- THE RECURSIVE JOIN: Parent's child pointer → Child's group
    JOIN FILTER_Op_Child C
      ON P.CHILD_GROUP_HK_POINTER = C.CHILD_GROUP_HK
    JOIN FILTER_Item I
      ON A.Item_HK = I.Item_HK
    JOIN FILTER_Plant Pl
      ON A.Plant_HK = Pl.Plant_HK
)

---- FINAL LAYER ----
SELECT
    CURRENT_TIMESTAMP()                              as SNAPSHOT_DTS,
    'BRIDGE_BOO_HIERARCHY'                           as BRIDGE_REC_SRC,
    CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())     as BRIDGE_LOAD_DTS,
    LNK_PLANT_TASKLIST_ITEM_ASSIGNMENT_HK,
    PARENT_OP_HK,
    CHILD_OP_HK,
    TASK_LIST_GROUP_COUNTER,
    OP_PLNAL,
    DRVD_HIERARCHY_DATE,
    MATERIAL,
    PLANT,
    OPERATION_ID,
    OBJECT_ID,
    CONTROLLER, 
    BASE_QUANTITY,
    UOM,
    ACTIVITY_TYPE_1,
    UOM_TYPE_1,
    TIME_TYPE_1,
    ACTIVITY_TYPE_2,
    UOM_TYPE_2,
    TIME_TYPE_2,
    ACTIVITY_TYPE_3,
    UOM_TYPE_3,
    TIME_TYPE_3,
    VALID_FROM
    

FROM JOIN_RESULT
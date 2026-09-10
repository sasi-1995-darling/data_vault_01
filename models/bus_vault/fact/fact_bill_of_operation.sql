---- SRC LAYER ----
WITH
SRC_D              as ( SELECT ACTIVITY_TYPE_1, ACTIVITY_TYPE_2, ACTIVITY_TYPE_3, BASE_QUANTITY, BKCC, CONTROLLER, ITEM_BK, ITEM_HK, OBJECT_ID, OPERATION_ID, PLANT_BK, PLANT_HK, CHILD_OP_HK, REC_SRC, TASKLIST_GROUP_COUNTER, TIME_TYPE_1, TIME_TYPE_2, TIME_TYPE_3, UOM, UOM_TYPE_1, UOM_TYPE_2, UOM_TYPE_3, IS_DELETED FROM {{ ref('pb_bill_of_operation') }} as SRC  )

/*
SRC_D              as ( SELECT * FROM BUS_VAULT.pb_bill_of_operation )
*/
---- LOGIC LAYER ----

, LOGIC_D as (
    SELECT
        REC_SRC
      , PLANT_HK
      , ITEM_HK
      , TASKLIST_GROUP_COUNTER
      , ITEM_BK
      , PLANT_BK
      , CHILD_OP_HK
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
      , BKCC
      , IS_DELETED
    FROM SRC_D
)
---- RENAME LAYER ----

, RENAME_D as (
    SELECT
        REC_SRC
      , PLANT_HK
      , ITEM_HK
      , TASKLIST_GROUP_COUNTER
      , ITEM_BK
      , PLANT_BK
      , CHILD_OP_HK
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
      , BKCC
      , IS_DELETED
    FROM LOGIC_D
)
---- FILTER LAYER ----

, FILTER_D as (
    SELECT *
    FROM RENAME_D
    WHERE IS_DELETED = 'N' OR IS_DELETED IS NULL
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D
)

---- FINAL LAYER ----
SELECT
          REC_SRC
        , PLANT_HK
        , ITEM_HK
        , TASKLIST_GROUP_COUNTER
        , ITEM_BK
        , PLANT_BK
        , CHILD_OP_HK
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
        , BKCC
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP()) as LOAD_DTS
FROM JOIN_RESULT

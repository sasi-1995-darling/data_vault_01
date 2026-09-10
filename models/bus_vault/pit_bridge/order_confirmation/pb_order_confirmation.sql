---- SRC LAYER ----
WITH
SRC_LR             as ( SELECT CAPACITY_HK, CONFIRMATION_UOM_HK, COST_CENTER_HK, MATERIAL_BASE_UOM_HK, ORDER_CONFIRMATION_HK, PRODUCTION_ORDER_CONFIRMATION_LHK, PRODUCTION_ORDER_HK, ROUTING_HK FROM {{ ref('lnk_production_order_confirmation') }} as SRC  ),
SRC_HR             as ( SELECT BKCC, PRODUCTION_ORDER_BK, PRODUCTION_ORDER_HK FROM {{ ref('hub_production_order') }} as SRC  ),
SRC_HRL            as ( SELECT CONFIRMATION_COUNTER_BK, CONFIRMATION_NUMBER_BK, ORDER_CONFIRMATION_HK FROM {{ ref('hub_order_confirmation') }} as SRC  ),
SRC_CAP            as ( SELECT CAPACITY_BK, CAPACITY_HK FROM {{ ref('hub_capacity') }} as SRC  ),
SRC_COST           as ( SELECT COST_CENTER_BK, COST_CENTER_HK FROM {{ ref('hub_cost_center') }} as SRC  ),
SRC_UOM            as ( SELECT UOM_BK, UOM_HK FROM {{ ref('hub_uom') }} as SRC  ),
SRC_UOM1           as ( SELECT UOM_BK, UOM_HK FROM {{ ref('hub_uom') }} as SRC  ),
SRC_ROUT           as ( SELECT ROUTING_BK, ROUTING_HK FROM {{ ref('hub_routing') }} as SRC  ),
SRC_LSR            as ( SELECT BMENGE, GAMNG, GASMG, GLTRI, GLTRS, GSTRI, GSTRS, PRODUCTION_ORDER_HK FROM {{ ref('sat_production_order__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by PRODUCTION_ORDER_HK order by LOAD_DTS DESC) ),
SRC_SR             as ( SELECT IERD, IERZ, ISDD, ISDZ, ORDER_CONFIRMATION_HK, SMENG, arbid FROM {{ ref('sat_order_confirmation__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by ORDER_CONFIRMATION_HK order by LOAD_DTS DESC) )

/*
SRC_LR             as ( SELECT * FROM RAW_VAULT.lnk_production_order_confirmation )
SRC_HR             as ( SELECT * FROM RAW_VAULT.hub_production_order )
SRC_HRL            as ( SELECT * FROM RAW_VAULT.hub_order_confirmation )
SRC_CAP            as ( SELECT * FROM RAW_VAULT.hub_capacity )
SRC_COST           as ( SELECT * FROM RAW_VAULT.hub_cost_center )
SRC_UOM            as ( SELECT * FROM RAW_VAULT.hub_UOM )
SRC_UOM1           as ( SELECT * FROM RAW_VAULT.hub_UOM )
SRC_ROUT           as ( SELECT * FROM RAW_VAULT.hub_routing )
SRC_LSR            as ( SELECT * FROM RAW_VAULT.sat_production_order__winn_sap )
SRC_SR             as ( SELECT * FROM RAW_VAULT.sat_order_confirmation__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_LR as (
    SELECT
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                        PB_LOAD_DTS
      , 'PB_ORDER_CONFIRMATION'                                   as                                         PB_REC_SRC
      , PRODUCTION_ORDER_HK
      , ORDER_CONFIRMATION_HK
      , COST_CENTER_HK
      , CAPACITY_HK
      , MATERIAL_BASE_UOM_HK
      , CONFIRMATION_UOM_HK
      , ROUTING_HK
      , PRODUCTION_ORDER_CONFIRMATION_LHK
    FROM SRC_LR
)

, LOGIC_HR as (
    SELECT
        PRODUCTION_ORDER_HK                                          as                             HR_PRODUCTION_ORDER_HK
      , PRODUCTION_ORDER_BK
      , BKCC
    FROM SRC_HR
)

, LOGIC_HRL as (
    SELECT
        CONFIRMATION_NUMBER_BK
      , CONFIRMATION_COUNTER_BK
      , ORDER_CONFIRMATION_HK                                        as                          HRL_ORDER_CONFIRMATION_HK
    FROM SRC_HRL
)

, LOGIC_CAP as (
    SELECT
        CAPACITY_HK                                                  as                                    CAP_CAPACITY_HK
      , CAPACITY_BK
    FROM SRC_CAP
)

, LOGIC_COST as (
    SELECT
        COST_CENTER_HK                                               as                                COST_COST_CENTER_HK
      , COST_CENTER_BK
    FROM SRC_COST
)

, LOGIC_UOM as (
    SELECT
        UOM_HK                                                       as                           UOM_MATERIAL_BASE_UOM_HK
      , UOM_BK                                                       as                               MATERIAL_BASE_UOM_BK
    FROM SRC_UOM
)

, LOGIC_UOM1 as (
    SELECT
        UOM_HK                                                       as                           UOM1_CONFIRMATION_UOM_HK
      , UOM_BK                                                       as                                CONFIRMATION_UOM_BK
    FROM SRC_UOM1
)

, LOGIC_ROUT as (
    SELECT
        ROUTING_HK                                                   as                                    ROUT_ROUTING_HK
      , ROUTING_BK
    FROM SRC_ROUT
)

, LOGIC_LSR as (
    SELECT
        PRODUCTION_ORDER_HK                                          as                            LSR_PRODUCTION_ORDER_HK
      , NULLIF(TRIM(GSTRS), '')::INTEGER                             as                     scheduled_start_date__YYYYMMDD
      , NULLIF(TRIM(GLTRS), '')::INTEGER                             as                    scheduled_finish_date__YYYYMMDD
      , NULLIF(TRIM(GSTRI), '')::INTEGER                             as                        actual_start_date__YYYYMMDD
      , NULLIF(TRIM(GLTRI), '')::INTEGER                             as                       actual_finish_date__YYYYMMDD
      , GASMG                                                        as                  total_scrap_quantity_in_the_order
      , GAMNG                                                        as                               total_order_quantity
      , BMENGE                                                       as                                      Base_Quantity
      , GSTRS
      , GLTRS
      , GSTRI
      , GLTRI
    FROM SRC_LSR
)

, LOGIC_SR as (
    SELECT
        ORDER_CONFIRMATION_HK                                        as                           SR_ORDER_CONFIRMATION_HK
      , arbid                                                        as                             confirmation_object_id
      , NULLIF(TRIM(ISDD), '')::INTEGER                              as        CONFIRMED_START_DATE_OF_EXECUTION__YYYYMMDD
      , ISDZ                             as       CONFIRMED_TIME_FOR_START_EXECUTION
      , NULLIF(TRIM(IERD), '')::INTEGER                              as       CONFIRMED_FINISH_DATE_OF_EXECUTION__YYYYMMDD
      , IERZ                             as   CONFIRMED_TIME_FOR_FINISH_OF_EXECUTION
      , SMENG                                                        as                                 OPERATION_QUANTITY
      , ISDD
      , ISDZ
      , IERD
      , IERZ
    FROM SRC_SR
)
---- RENAME LAYER ----

, RENAME_LR as (
    SELECT
        PB_LOAD_DTS
      , PB_REC_SRC
      , PRODUCTION_ORDER_HK
      , ORDER_CONFIRMATION_HK
      , COST_CENTER_HK
      , CAPACITY_HK
      , MATERIAL_BASE_UOM_HK
      , CONFIRMATION_UOM_HK
      , ROUTING_HK
      , PRODUCTION_ORDER_CONFIRMATION_LHK
    FROM LOGIC_LR
)

, RENAME_HRL as (
    SELECT
        CONFIRMATION_NUMBER_BK
      , CONFIRMATION_COUNTER_BK
      , HRL_ORDER_CONFIRMATION_HK
    FROM LOGIC_HRL
)

, RENAME_HR as (
    SELECT
        HR_PRODUCTION_ORDER_HK
      , PRODUCTION_ORDER_BK
      , BKCC
    FROM LOGIC_HR
)

, RENAME_SR as (
    SELECT
        SR_ORDER_CONFIRMATION_HK
      , confirmation_object_id
      , CONFIRMED_START_DATE_OF_EXECUTION__YYYYMMDD
      , CONFIRMED_TIME_FOR_START_EXECUTION
      , CONFIRMED_FINISH_DATE_OF_EXECUTION__YYYYMMDD
      , CONFIRMED_TIME_FOR_FINISH_OF_EXECUTION
      , OPERATION_QUANTITY
      , ISDD
      , ISDZ
      , IERD
      , IERZ
    FROM LOGIC_SR
)

, RENAME_LSR as (
    SELECT
        LSR_PRODUCTION_ORDER_HK
      , scheduled_start_date__YYYYMMDD
      , scheduled_finish_date__YYYYMMDD
      , actual_start_date__YYYYMMDD
      , actual_finish_date__YYYYMMDD
      , total_scrap_quantity_in_the_order
      , total_order_quantity
      , Base_Quantity
      , GSTRS
      , GLTRS
      , GSTRI
      , GLTRI
    FROM LOGIC_LSR
)

, RENAME_COST as (
    SELECT
        COST_COST_CENTER_HK
      , COST_CENTER_BK
    FROM LOGIC_COST
)

, RENAME_CAP as (
    SELECT
        CAP_CAPACITY_HK
      , CAPACITY_BK
    FROM LOGIC_CAP
)

, RENAME_UOM as (
    SELECT
        UOM_MATERIAL_BASE_UOM_HK
      , MATERIAL_BASE_UOM_BK
    FROM LOGIC_UOM
)

, RENAME_UOM1 as (
    SELECT
        UOM1_CONFIRMATION_UOM_HK
      , CONFIRMATION_UOM_BK
    FROM LOGIC_UOM1
)

, RENAME_ROUT as (
    SELECT
        ROUT_ROUTING_HK
      , ROUTING_BK
    FROM LOGIC_ROUT
)
---- FILTER LAYER ----

, FILTER_LR as (
    SELECT *
    FROM RENAME_LR
)

, FILTER_HR as (
    SELECT *
    FROM RENAME_HR
)

, FILTER_HRL as (
    SELECT *
    FROM RENAME_HRL
)

, FILTER_CAP as (
    SELECT *
    FROM RENAME_CAP
)

, FILTER_COST as (
    SELECT *
    FROM RENAME_COST
)

, FILTER_UOM as (
    SELECT *
    FROM RENAME_UOM
)

, FILTER_UOM1 as (
    SELECT *
    FROM RENAME_UOM1
)

, FILTER_ROUT as (
    SELECT *
    FROM RENAME_ROUT
)

, FILTER_LSR as (
    SELECT *
    FROM RENAME_LSR
)

, FILTER_SR as (
    SELECT *
    FROM RENAME_SR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_LR
    INNER JOIN FILTER_HR
        ON FILTER_LR.PRODUCTION_ORDER_HK = FILTER_HR.HR_PRODUCTION_ORDER_HK
    LEFT JOIN FILTER_HRL
        ON FILTER_LR.ORDER_CONFIRMATION_HK = FILTER_HRL.HRL_ORDER_CONFIRMATION_HK
    LEFT JOIN FILTER_CAP
        ON FILTER_LR.CAPACITY_HK = FILTER_CAP.CAP_CAPACITY_HK
    LEFT JOIN FILTER_COST
        ON FILTER_LR.COST_CENTER_HK = FILTER_COST.COST_COST_CENTER_HK
    LEFT JOIN FILTER_UOM
        ON FILTER_LR.MATERIAL_BASE_UOM_HK = FILTER_UOM.UOM_MATERIAL_BASE_UOM_HK
    LEFT JOIN FILTER_UOM1
        ON FILTER_LR.CONFIRMATION_UOM_HK = FILTER_UOM1.UOM1_CONFIRMATION_UOM_HK
    LEFT JOIN FILTER_ROUT
        ON FILTER_LR.ROUTING_HK = FILTER_ROUT.ROUT_ROUTING_HK
    LEFT JOIN FILTER_LSR
        ON FILTER_LR.PRODUCTION_ORDER_HK = FILTER_LSR.LSR_PRODUCTION_ORDER_HK
    LEFT JOIN FILTER_SR
        ON FILTER_LR.ORDER_CONFIRMATION_HK = FILTER_SR.SR_ORDER_CONFIRMATION_HK
)

---- FINAL LAYER ----
SELECT
          row_number() over(order by 1)                                as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , PB_LOAD_DTS
        , PB_REC_SRC
        , PRODUCTION_ORDER_HK
        , ORDER_CONFIRMATION_HK
        , COST_CENTER_HK
        , CAPACITY_HK
        , MATERIAL_BASE_UOM_HK
        , CONFIRMATION_UOM_HK
        , ROUTING_HK
        , CONFIRMATION_NUMBER_BK
        , CONFIRMATION_COUNTER_BK
        , PRODUCTION_ORDER_BK
        , BKCC
        , SCHEDULED_START_DATE__YYYYMMDD
        , SCHEDULED_FINISH_DATE__YYYYMMDD
        , ACTUAL_START_DATE__YYYYMMDD
        , ACTUAL_FINISH_DATE__YYYYMMDD
        , TOTAL_SCRAP_QUANTITY_IN_THE_ORDER
        , TOTAL_ORDER_QUANTITY
        , BASE_QUANTITY
        , CONFIRMATION_OBJECT_ID
        , CONFIRMED_START_DATE_OF_EXECUTION__YYYYMMDD
        , CONFIRMED_TIME_FOR_START_EXECUTION
        , CONFIRMED_FINISH_DATE_OF_EXECUTION__YYYYMMDD
        , CONFIRMED_TIME_FOR_FINISH_OF_EXECUTION
        , OPERATION_QUANTITY
        , COST_CENTER_BK
        , CAPACITY_BK
        , MATERIAL_BASE_UOM_BK
        , CONFIRMATION_UOM_BK
        , ROUTING_BK
        , PRODUCTION_ORDER_CONFIRMATION_LHK
FROM JOIN_RESULT

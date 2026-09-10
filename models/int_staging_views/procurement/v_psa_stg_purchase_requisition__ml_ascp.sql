---- SRC LAYER ----
WITH
SRC_mlsup          as ( SELECT * FROM {{ source('mlc_ascp', 'msc_supplies') }} as SRC 
                        /*Filter the Purchase Requisition, order_type = 2  */
                        where order_type = 2 ),
SRC_a              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_mlitm          as ( SELECT * FROM {{ source('mlc_ascp', 'msc_system_items') }} as SRC 
                         qualify 1= row_number()over(partition by inventory_item_id, organization_id order by pm_snapshot_date desc)  ),
SRC_mltp           as ( SELECT * FROM {{ source('mlc_ascp', 'msc_trading_partners') }} as SRC 
                         qualify 1= row_number()over(partition by partner_id order by pm_snapshot_date desc)  )

/*
SRC_mlsup          as ( SELECT * FROM mlc_ascp.msc_supplies )
, SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_mlitm          as ( SELECT * FROM mlc_ascp.msc_system_items )
, SRC_mltp           as ( SELECT * FROM mlc_ascp.msc_trading_partners )
*/
---- LOGIC LAYER ----

, LOGIC_mlsup as (
    SELECT
        CONCAT_WS('||', ORDER_NUMBER,PURCH_LINE_NUM)                 as                            PURCHASE_REQUISITION_BK
      , ORDER_NUMBER
      , PURCH_LINE_NUM
      , TRANSACTION_ID
      , PLAN_ID
      , ORGANIZATION_ID
      , SR_INSTANCE_ID
      , INVENTORY_ITEM_ID
      , SCHEDULE_DESIGNATOR_ID
      , REVISION
      , UNIT_NUMBER
      , NEW_SCHEDULE_DATE
      , OLD_SCHEDULE_DATE
      , NEW_WIP_START_DATE
      , OLD_WIP_START_DATE
      , FIRST_UNIT_COMPLETION_DATE
      , LAST_UNIT_COMPLETION_DATE
      , FIRST_UNIT_START_DATE
      , LAST_UNIT_START_DATE
      , DISPOSITION_ID
      , DISPOSITION_STATUS_TYPE
      , ORDER_TYPE
      , SUPPLIER_ID
      , SUPPLIER_SITE_ID
      , NEW_ORDER_QUANTITY
      , OLD_ORDER_QUANTITY
      , NEW_ORDER_PLACEMENT_DATE
      , OLD_ORDER_PLACEMENT_DATE
      , RESCHEDULE_DAYS
      , RESCHEDULE_FLAG
      , SCHEDULE_COMPRESS_DAYS
      , NEW_PROCESSING_DAYS
      , QUANTITY_IN_PROCESS
      , IMPLEMENTED_QUANTITY
      , FIRM_PLANNED_TYPE
      , FIRM_QUANTITY
      , FIRM_DATE
      , IMPLEMENT_DEMAND_CLASS
      , IMPLEMENT_DATE
      , IMPLEMENT_QUANTITY
      , IMPLEMENT_FIRM
      , IMPLEMENT_WIP_CLASS_CODE
      , IMPLEMENT_JOB_NAME
      , IMPLEMENT_DOCK_DATE
      , IMPLEMENT_STATUS_CODE
      , IMPLEMENT_EMPLOYEE_ID
      , IMPLEMENT_UOM_CODE
      , IMPLEMENT_LOCATION_ID
      , IMPLEMENT_SOURCE_ORG_ID
      , IMPLEMENT_SR_INSTANCE_ID
      , IMPLEMENT_SUPPLIER_ID
      , IMPLEMENT_SUPPLIER_SITE_ID
      , IMPLEMENT_AS
      , RELEASE_STATUS
      , LOAD_TYPE
      , PROCESS_SEQ_ID
      , SCO_SUPPLY_FLAG
      , ALTERNATE_BOM_DESIGNATOR
      , ALTERNATE_ROUTING_DESIGNATOR
      , OPERATION_SEQ_NUM
      , BY_PRODUCT_USING_ASSY_ID
      , SOURCE_ORGANIZATION_ID
      , SOURCE_SR_INSTANCE_ID
      , SOURCE_SUPPLIER_SITE_ID
      , SOURCE_SUPPLIER_ID
      , SHIP_METHOD
      , WEIGHT_CAPACITY_USED
      , VOLUME_CAPACITY_USED
      , NEW_SHIP_DATE
      , NEW_DOCK_DATE
      , OLD_DOCK_DATE
      , LINE_ID
      , PROJECT_ID
      , TASK_ID
      , PLANNING_GROUP
      , IMPLEMENT_PROJECT_ID
      , IMPLEMENT_TASK_ID
      , IMPLEMENT_SCHEDULE_GROUP_ID
      , IMPLEMENT_BUILD_SEQUENCE
      , IMPLEMENT_ALTERNATE_BOM
      , IMPLEMENT_ALTERNATE_ROUTING
      , IMPLEMENT_UNIT_NUMBER
      , IMPLEMENT_LINE_ID
      , RELEASE_ERRORS
      , NUMBER1
      , SOURCE_ITEM_ID
      , SCHEDULE_GROUP_ID
      , BUILD_SEQUENCE
      , WIP_ENTITY_NAME
      , IMPLEMENT_PROCESSING_DAYS
      , DELIVERY_PRICE
      , LATE_SUPPLY_DATE
      , LATE_SUPPLY_QTY
      , LOT_NUMBER
      , SUBINVENTORY_CODE
      , QTY_SCRAPPED
      , EXPECTED_SCRAP_QTY
      , QTY_COMPLETED
      , DAILY_RATE
      , SCHEDULE_GROUP_NAME
      , UPDATED
      , SUBST_ITEM_FLAG
      , STATUS
      , APPLIED
      , EXPIRATION_QUANTITY
      , EXPIRATION_DATE
      , NON_NETTABLE_QTY
      , IMPLEMENT_WIP_START_DATE
      , REFRESH_NUMBER
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , CREATION_DATE
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , IMPLEMENT_DAILY_RATE
      , NEED_BY_DATE
      , SOURCE_SUPPLY_ID
      , SR_MTL_SUPPLY_ID
      , WIP_STATUS_CODE
      , DEMAND_CLASS
      , FROM_ORGANIZATION_ID
      , WIP_SUPPLY_TYPE
      , PO_LINE_ID
      , LOAD_FACTOR_RATE
      , ROUTING_SEQUENCE_ID
      , BILL_SEQUENCE_ID
      , COPRODUCTS_SUPPLY
      , CFM_ROUTING_FLAG
      , CUSTOMER_ID
      , SHIP_TO_SITE_ID
      , OLD_NEED_BY_DATE
      , OLD_DAILY_RATE
      , OLD_FIRST_UNIT_START_DATE
      , OLD_LAST_UNIT_COMPLETION_DATE
      , OLD_NEW_SCHEDULE_DATE
      , OLD_QTY_COMPLETED
      , OLD_NEW_ORDER_QUANTITY
      , OLD_FIRM_QUANTITY
      , OLD_FIRM_DATE
      , PLANNING_PARTNER_SITE_ID
      , PLANNING_TP_TYPE
      , OWNING_PARTNER_SITE_ID
      , OWNING_TP_TYPE
      , VMI_FLAG
      , EARLIEST_START_DATE
      , EARLIEST_COMPLETION_DATE
      , MIN_START_DATE
      , SCHEDULED_DEMAND_ID
      , EXPLOSION_DATE
      , SCO_SUPPLY_DATE
      , RECORD_SOURCE
      , SUPPLY_IS_SHARED
      , ULPSD
      , ULPCD
      , UEPSD
      , UEPCD
      , EACD
      , ORIGINAL_NEED_BY_DATE
      , ORIGINAL_QUANTITY
      , ACCEPTANCE_REQUIRED_FLAG
      , PROMISED_DATE
      , WIP_START_QUANTITY
      , END_ORDER_NUMBER
      , END_ORDER_LINE_NUMBER
      , ORDER_LINE_NUMBER
      , QUANTITY_PER_ASSEMBLY
      , QUANTITY_ISSUED
      , UNBUCKETED_DEMAND_DATE
      , SHIPMENT_ID
      , JOB_OP_SEQ_NUM
      , JUMP_OP_SEQ_NUM
      , SHIP_CALENDAR
      , RECEIVING_CALENDAR
      , INTRANSIT_CALENDAR
      , INTRANSIT_LEAD_TIME
      , OLD_SHIP_DATE
      , IMPLEMENT_SHIP_DATE
      , ORIG_SHIP_METHOD
      , ORIG_INTRANSIT_LEAD_TIME
      , PARENT_ID
      , DAYS_LATE
      , SCHEDULE_PRIORITY
      , PO_LINE_LOCATION_ID
      , PO_DISTRIBUTION_ID
      , WSM_FAULTY_NETWORK
      , IMPLEMENT_DEST_ORG_ID
      , IMPLEMENT_DEST_INST_ID
      , REQUESTED_START_DATE
      , REQUESTED_COMPLETION_DATE
      , ASSET_SERIAL_NUMBER
      , ASSET_ITEM_ID
      , TOP_TRANSACTION_ID
      , UNBUCKETED_NEW_SCHED_DATE
      , IMPLEMENT_SHIP_METHOD
      , ACTUAL_START_DATE
      , FIRM_SHIP_DATE
      , SCHEDULE_ORIGINATION_TYPE
      , UNBUCKETED_START_DATE
      , SR_CUSTOMER_ACCT_ID
      , ITEM_TYPE_ID
      , CUSTOMER_PRODUCT_ID
      , RO_STATUS_CODE
      , SR_REPAIR_GROUP_ID
      , SR_REPAIR_TYPE_ID
      , ITEM_TYPE_VALUE
      , ZONE_ID
      , RO_CREATION_DATE
      , REPAIR_LEAD_TIME
      , FIRM_START_DATE
      , REQ_LINE_ID
      , INTRANSIT_OWNING_ORG_ID
      , RELEASABLE
      , BATCH_ID
      , OTM_ARRIVAL_DATE
      , PS_SUPPLY_FLAG
      , CTB_FLAG
      , CTB_COMP_AVAIL_PERCENT
      , RTB_ORDER_QTY_PERCENT
      , CTB_EXPECTED_DATE
      , POTENTIAL_RTB_PERCENT
      , CTB_PRIORITY
      , DESCRIPTION
      , MAINTENANCE_OBJECT_SOURCE
      , PRODUCTION_SCHEDULE_ID
      , VISIT_ID
      , PRODUCES_TO_STOCK
      , PRODUCT_CLASSIFICATION
      , MAINTENANCE_REQT
      , ACTIVITY_TYPE
      , ACTIVITY_NAME
      , CLASS_CODE
      , SHUTDOWN_TYPE
      , TO_BE_EXPLODED
      , OBJECT_TYPE
      , MAINTENANCE_TYPE_CODE
      , ACTIVITY_ITEM_ID
      , ORIG_FIRM_DATE
      , ORIG_FIRM_QUANTITY
      , USE_WO_SUBSTITUTE
      , ASSET_NUMBER
      , MAINTENANCE_OBJECT_ID
      , MAINTENANCE_OBJECT_TYPE
      , OPERATING_FLEET
      , MAINTENANCE_REQUIREMENT
      , COLL_ORDER_TYPE
      , CTB_EXPECTED_DATE_BUY_COMPS
      , SUBSTITUTE_COMPONENTS_USED
      , RESERVED_QTY
      , PO_OR_REQ_HEADER_ID
      , ACTUAL_LEAD_TIME
      , MIN_LEAD_TIME
      , PIP_ITEM_ID
      , SUPP_CAPACITY_OVERLOAD
      , VOLUME_CAPACITY_OVERLOAD
      , WEIGHT_CAPACITY_OVERLOAD
      , PM_SNAPSHOT_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC',IFF(PSA_DELETE_IND = 'Y', PSA_LOAD_DTS, PM_SNAPSHOT_DATE)) as                                           LOAD_DTS
    FROM SRC_mlsup
)

, LOGIC_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_a
)

, LOGIC_mlitm as (
    SELECT
        INVENTORY_ITEM_ID                                            as                              ITM_INVENTORY_ITEM_ID
      , ORGANIZATION_ID                                              as                                ITM_ORGANIZATION_ID
      , ITEM_NAME
      , SPLIT_PART(ORGANIZATION_CODE, ':', 2)                        as                             DRVD_ORGANIZATION_CODE
    FROM SRC_mlitm
)

, LOGIC_mltp as (
    SELECT
        PARTNER_ID                                                   as                                      TP_PARTNER_ID
      , PARTNER_NUMBER
    FROM SRC_mltp
)
---- RENAME LAYER ----

, RENAME_mlsup as (
    SELECT
        PURCHASE_REQUISITION_BK
      , ORDER_NUMBER
      , PURCH_LINE_NUM
      , TRANSACTION_ID
      , PLAN_ID
      , ORGANIZATION_ID
      , SR_INSTANCE_ID
      , INVENTORY_ITEM_ID
      , SCHEDULE_DESIGNATOR_ID
      , REVISION
      , UNIT_NUMBER
      , NEW_SCHEDULE_DATE
      , OLD_SCHEDULE_DATE
      , NEW_WIP_START_DATE
      , OLD_WIP_START_DATE
      , FIRST_UNIT_COMPLETION_DATE
      , LAST_UNIT_COMPLETION_DATE
      , FIRST_UNIT_START_DATE
      , LAST_UNIT_START_DATE
      , DISPOSITION_ID
      , DISPOSITION_STATUS_TYPE
      , ORDER_TYPE
      , SUPPLIER_ID
      , SUPPLIER_SITE_ID
      , NEW_ORDER_QUANTITY
      , OLD_ORDER_QUANTITY
      , NEW_ORDER_PLACEMENT_DATE
      , OLD_ORDER_PLACEMENT_DATE
      , RESCHEDULE_DAYS
      , RESCHEDULE_FLAG
      , SCHEDULE_COMPRESS_DAYS
      , NEW_PROCESSING_DAYS
      , QUANTITY_IN_PROCESS
      , IMPLEMENTED_QUANTITY
      , FIRM_PLANNED_TYPE
      , FIRM_QUANTITY
      , FIRM_DATE
      , IMPLEMENT_DEMAND_CLASS
      , IMPLEMENT_DATE
      , IMPLEMENT_QUANTITY
      , IMPLEMENT_FIRM
      , IMPLEMENT_WIP_CLASS_CODE
      , IMPLEMENT_JOB_NAME
      , IMPLEMENT_DOCK_DATE
      , IMPLEMENT_STATUS_CODE
      , IMPLEMENT_EMPLOYEE_ID
      , IMPLEMENT_UOM_CODE
      , IMPLEMENT_LOCATION_ID
      , IMPLEMENT_SOURCE_ORG_ID
      , IMPLEMENT_SR_INSTANCE_ID
      , IMPLEMENT_SUPPLIER_ID
      , IMPLEMENT_SUPPLIER_SITE_ID
      , IMPLEMENT_AS
      , RELEASE_STATUS
      , LOAD_TYPE
      , PROCESS_SEQ_ID
      , SCO_SUPPLY_FLAG
      , ALTERNATE_BOM_DESIGNATOR
      , ALTERNATE_ROUTING_DESIGNATOR
      , OPERATION_SEQ_NUM
      , BY_PRODUCT_USING_ASSY_ID
      , SOURCE_ORGANIZATION_ID
      , SOURCE_SR_INSTANCE_ID
      , SOURCE_SUPPLIER_SITE_ID
      , SOURCE_SUPPLIER_ID
      , SHIP_METHOD
      , WEIGHT_CAPACITY_USED
      , VOLUME_CAPACITY_USED
      , NEW_SHIP_DATE
      , NEW_DOCK_DATE
      , OLD_DOCK_DATE
      , LINE_ID
      , PROJECT_ID
      , TASK_ID
      , PLANNING_GROUP
      , IMPLEMENT_PROJECT_ID
      , IMPLEMENT_TASK_ID
      , IMPLEMENT_SCHEDULE_GROUP_ID
      , IMPLEMENT_BUILD_SEQUENCE
      , IMPLEMENT_ALTERNATE_BOM
      , IMPLEMENT_ALTERNATE_ROUTING
      , IMPLEMENT_UNIT_NUMBER
      , IMPLEMENT_LINE_ID
      , RELEASE_ERRORS
      , NUMBER1
      , SOURCE_ITEM_ID
      , SCHEDULE_GROUP_ID
      , BUILD_SEQUENCE
      , WIP_ENTITY_NAME
      , IMPLEMENT_PROCESSING_DAYS
      , DELIVERY_PRICE
      , LATE_SUPPLY_DATE
      , LATE_SUPPLY_QTY
      , LOT_NUMBER
      , SUBINVENTORY_CODE
      , QTY_SCRAPPED
      , EXPECTED_SCRAP_QTY
      , QTY_COMPLETED
      , DAILY_RATE
      , SCHEDULE_GROUP_NAME
      , UPDATED
      , SUBST_ITEM_FLAG
      , STATUS
      , APPLIED
      , EXPIRATION_QUANTITY
      , EXPIRATION_DATE
      , NON_NETTABLE_QTY
      , IMPLEMENT_WIP_START_DATE
      , REFRESH_NUMBER
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , CREATION_DATE
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , IMPLEMENT_DAILY_RATE
      , NEED_BY_DATE
      , SOURCE_SUPPLY_ID
      , SR_MTL_SUPPLY_ID
      , WIP_STATUS_CODE
      , DEMAND_CLASS
      , FROM_ORGANIZATION_ID
      , WIP_SUPPLY_TYPE
      , PO_LINE_ID
      , LOAD_FACTOR_RATE
      , ROUTING_SEQUENCE_ID
      , BILL_SEQUENCE_ID
      , COPRODUCTS_SUPPLY
      , CFM_ROUTING_FLAG
      , CUSTOMER_ID
      , SHIP_TO_SITE_ID
      , OLD_NEED_BY_DATE
      , OLD_DAILY_RATE
      , OLD_FIRST_UNIT_START_DATE
      , OLD_LAST_UNIT_COMPLETION_DATE
      , OLD_NEW_SCHEDULE_DATE
      , OLD_QTY_COMPLETED
      , OLD_NEW_ORDER_QUANTITY
      , OLD_FIRM_QUANTITY
      , OLD_FIRM_DATE
      , PLANNING_PARTNER_SITE_ID
      , PLANNING_TP_TYPE
      , OWNING_PARTNER_SITE_ID
      , OWNING_TP_TYPE
      , VMI_FLAG
      , EARLIEST_START_DATE
      , EARLIEST_COMPLETION_DATE
      , MIN_START_DATE
      , SCHEDULED_DEMAND_ID
      , EXPLOSION_DATE
      , SCO_SUPPLY_DATE
      , RECORD_SOURCE
      , SUPPLY_IS_SHARED
      , ULPSD
      , ULPCD
      , UEPSD
      , UEPCD
      , EACD
      , ORIGINAL_NEED_BY_DATE
      , ORIGINAL_QUANTITY
      , ACCEPTANCE_REQUIRED_FLAG
      , PROMISED_DATE
      , WIP_START_QUANTITY
      , END_ORDER_NUMBER
      , END_ORDER_LINE_NUMBER
      , ORDER_LINE_NUMBER
      , QUANTITY_PER_ASSEMBLY
      , QUANTITY_ISSUED
      , UNBUCKETED_DEMAND_DATE
      , SHIPMENT_ID
      , JOB_OP_SEQ_NUM
      , JUMP_OP_SEQ_NUM
      , SHIP_CALENDAR
      , RECEIVING_CALENDAR
      , INTRANSIT_CALENDAR
      , INTRANSIT_LEAD_TIME
      , OLD_SHIP_DATE
      , IMPLEMENT_SHIP_DATE
      , ORIG_SHIP_METHOD
      , ORIG_INTRANSIT_LEAD_TIME
      , PARENT_ID
      , DAYS_LATE
      , SCHEDULE_PRIORITY
      , PO_LINE_LOCATION_ID
      , PO_DISTRIBUTION_ID
      , WSM_FAULTY_NETWORK
      , IMPLEMENT_DEST_ORG_ID
      , IMPLEMENT_DEST_INST_ID
      , REQUESTED_START_DATE
      , REQUESTED_COMPLETION_DATE
      , ASSET_SERIAL_NUMBER
      , ASSET_ITEM_ID
      , TOP_TRANSACTION_ID
      , UNBUCKETED_NEW_SCHED_DATE
      , IMPLEMENT_SHIP_METHOD
      , ACTUAL_START_DATE
      , FIRM_SHIP_DATE
      , SCHEDULE_ORIGINATION_TYPE
      , UNBUCKETED_START_DATE
      , SR_CUSTOMER_ACCT_ID
      , ITEM_TYPE_ID
      , CUSTOMER_PRODUCT_ID
      , RO_STATUS_CODE
      , SR_REPAIR_GROUP_ID
      , SR_REPAIR_TYPE_ID
      , ITEM_TYPE_VALUE
      , ZONE_ID
      , RO_CREATION_DATE
      , REPAIR_LEAD_TIME
      , FIRM_START_DATE
      , REQ_LINE_ID
      , INTRANSIT_OWNING_ORG_ID
      , RELEASABLE
      , BATCH_ID
      , OTM_ARRIVAL_DATE
      , PS_SUPPLY_FLAG
      , CTB_FLAG
      , CTB_COMP_AVAIL_PERCENT
      , RTB_ORDER_QTY_PERCENT
      , CTB_EXPECTED_DATE
      , POTENTIAL_RTB_PERCENT
      , CTB_PRIORITY
      , DESCRIPTION
      , MAINTENANCE_OBJECT_SOURCE
      , PRODUCTION_SCHEDULE_ID
      , VISIT_ID
      , PRODUCES_TO_STOCK
      , PRODUCT_CLASSIFICATION
      , MAINTENANCE_REQT
      , ACTIVITY_TYPE
      , ACTIVITY_NAME
      , CLASS_CODE
      , SHUTDOWN_TYPE
      , TO_BE_EXPLODED
      , OBJECT_TYPE
      , MAINTENANCE_TYPE_CODE
      , ACTIVITY_ITEM_ID
      , ORIG_FIRM_DATE
      , ORIG_FIRM_QUANTITY
      , USE_WO_SUBSTITUTE
      , ASSET_NUMBER
      , MAINTENANCE_OBJECT_ID
      , MAINTENANCE_OBJECT_TYPE
      , OPERATING_FLEET
      , MAINTENANCE_REQUIREMENT
      , COLL_ORDER_TYPE
      , CTB_EXPECTED_DATE_BUY_COMPS
      , SUBSTITUTE_COMPONENTS_USED
      , RESERVED_QTY
      , PO_OR_REQ_HEADER_ID
      , ACTUAL_LEAD_TIME
      , MIN_LEAD_TIME
      , PIP_ITEM_ID
      , SUPP_CAPACITY_OVERLOAD
      , VOLUME_CAPACITY_OVERLOAD
      , WEIGHT_CAPACITY_OVERLOAD
      , PM_SNAPSHOT_DATE
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_mlsup
)

, RENAME_a as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_a
)

, RENAME_mlitm as (
    SELECT
        ITM_INVENTORY_ITEM_ID
      , ITM_ORGANIZATION_ID
      , ITEM_NAME
      , DRVD_ORGANIZATION_CODE
    FROM LOGIC_mlitm
)

, RENAME_mltp as (
    SELECT
        TP_PARTNER_ID
      , PARTNER_NUMBER
    FROM LOGIC_mltp
)
---- FILTER LAYER ----

, FILTER_mlsup as (
    SELECT *
    FROM RENAME_mlsup
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USWIOC.ORCL.ASCPPRD.MSC_SUPPLIES'
)

, FILTER_mlitm as (
    SELECT *
    FROM RENAME_mlitm
)

, FILTER_mltp as (
    SELECT *
    FROM RENAME_mltp
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_mlsup
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_mlitm
        ON inventory_item_id = itm_inventory_item_id  AND organization_id = itm_organization_id
    LEFT JOIN FILTER_mltp
        ON supplier_id = tp_partner_id
)

---- FINAL LAYER ----
SELECT
          PURCHASE_REQUISITION_BK
        , ORDER_NUMBER
        , PURCH_LINE_NUM
        , TRANSACTION_ID
        , PLAN_ID
        , ORGANIZATION_ID
        , SR_INSTANCE_ID
        , INVENTORY_ITEM_ID
        , SCHEDULE_DESIGNATOR_ID
        , REVISION
        , UNIT_NUMBER
        , NEW_SCHEDULE_DATE
        , OLD_SCHEDULE_DATE
        , NEW_WIP_START_DATE
        , OLD_WIP_START_DATE
        , FIRST_UNIT_COMPLETION_DATE
        , LAST_UNIT_COMPLETION_DATE
        , FIRST_UNIT_START_DATE
        , LAST_UNIT_START_DATE
        , DISPOSITION_ID
        , DISPOSITION_STATUS_TYPE
        , ORDER_TYPE
        , SUPPLIER_ID
        , SUPPLIER_SITE_ID
        , NEW_ORDER_QUANTITY
        , OLD_ORDER_QUANTITY
        , NEW_ORDER_PLACEMENT_DATE
        , OLD_ORDER_PLACEMENT_DATE
        , RESCHEDULE_DAYS
        , RESCHEDULE_FLAG
        , SCHEDULE_COMPRESS_DAYS
        , NEW_PROCESSING_DAYS
        , QUANTITY_IN_PROCESS
        , IMPLEMENTED_QUANTITY
        , FIRM_PLANNED_TYPE
        , FIRM_QUANTITY
        , FIRM_DATE
        , IMPLEMENT_DEMAND_CLASS
        , IMPLEMENT_DATE
        , IMPLEMENT_QUANTITY
        , IMPLEMENT_FIRM
        , IMPLEMENT_WIP_CLASS_CODE
        , IMPLEMENT_JOB_NAME
        , IMPLEMENT_DOCK_DATE
        , IMPLEMENT_STATUS_CODE
        , IMPLEMENT_EMPLOYEE_ID
        , IMPLEMENT_UOM_CODE
        , IMPLEMENT_LOCATION_ID
        , IMPLEMENT_SOURCE_ORG_ID
        , IMPLEMENT_SR_INSTANCE_ID
        , IMPLEMENT_SUPPLIER_ID
        , IMPLEMENT_SUPPLIER_SITE_ID
        , IMPLEMENT_AS
        , RELEASE_STATUS
        , LOAD_TYPE
        , PROCESS_SEQ_ID
        , SCO_SUPPLY_FLAG
        , ALTERNATE_BOM_DESIGNATOR
        , ALTERNATE_ROUTING_DESIGNATOR
        , OPERATION_SEQ_NUM
        , BY_PRODUCT_USING_ASSY_ID
        , SOURCE_ORGANIZATION_ID
        , SOURCE_SR_INSTANCE_ID
        , SOURCE_SUPPLIER_SITE_ID
        , SOURCE_SUPPLIER_ID
        , SHIP_METHOD
        , WEIGHT_CAPACITY_USED
        , VOLUME_CAPACITY_USED
        , NEW_SHIP_DATE
        , NEW_DOCK_DATE
        , OLD_DOCK_DATE
        , LINE_ID
        , PROJECT_ID
        , TASK_ID
        , PLANNING_GROUP
        , IMPLEMENT_PROJECT_ID
        , IMPLEMENT_TASK_ID
        , IMPLEMENT_SCHEDULE_GROUP_ID
        , IMPLEMENT_BUILD_SEQUENCE
        , IMPLEMENT_ALTERNATE_BOM
        , IMPLEMENT_ALTERNATE_ROUTING
        , IMPLEMENT_UNIT_NUMBER
        , IMPLEMENT_LINE_ID
        , RELEASE_ERRORS
        , NUMBER1
        , SOURCE_ITEM_ID
        , SCHEDULE_GROUP_ID
        , BUILD_SEQUENCE
        , WIP_ENTITY_NAME
        , IMPLEMENT_PROCESSING_DAYS
        , DELIVERY_PRICE
        , LATE_SUPPLY_DATE
        , LATE_SUPPLY_QTY
        , LOT_NUMBER
        , SUBINVENTORY_CODE
        , QTY_SCRAPPED
        , EXPECTED_SCRAP_QTY
        , QTY_COMPLETED
        , DAILY_RATE
        , SCHEDULE_GROUP_NAME
        , UPDATED
        , SUBST_ITEM_FLAG
        , STATUS
        , APPLIED
        , EXPIRATION_QUANTITY
        , EXPIRATION_DATE
        , NON_NETTABLE_QTY
        , IMPLEMENT_WIP_START_DATE
        , REFRESH_NUMBER
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , CREATION_DATE
        , CREATED_BY
        , LAST_UPDATE_LOGIN
        , REQUEST_ID
        , PROGRAM_APPLICATION_ID
        , PROGRAM_ID
        , PROGRAM_UPDATE_DATE
        , IMPLEMENT_DAILY_RATE
        , NEED_BY_DATE
        , SOURCE_SUPPLY_ID
        , SR_MTL_SUPPLY_ID
        , WIP_STATUS_CODE
        , DEMAND_CLASS
        , FROM_ORGANIZATION_ID
        , WIP_SUPPLY_TYPE
        , PO_LINE_ID
        , LOAD_FACTOR_RATE
        , ROUTING_SEQUENCE_ID
        , BILL_SEQUENCE_ID
        , COPRODUCTS_SUPPLY
        , CFM_ROUTING_FLAG
        , CUSTOMER_ID
        , SHIP_TO_SITE_ID
        , OLD_NEED_BY_DATE
        , OLD_DAILY_RATE
        , OLD_FIRST_UNIT_START_DATE
        , OLD_LAST_UNIT_COMPLETION_DATE
        , OLD_NEW_SCHEDULE_DATE
        , OLD_QTY_COMPLETED
        , OLD_NEW_ORDER_QUANTITY
        , OLD_FIRM_QUANTITY
        , OLD_FIRM_DATE
        , PLANNING_PARTNER_SITE_ID
        , PLANNING_TP_TYPE
        , OWNING_PARTNER_SITE_ID
        , OWNING_TP_TYPE
        , VMI_FLAG
        , EARLIEST_START_DATE
        , EARLIEST_COMPLETION_DATE
        , MIN_START_DATE
        , SCHEDULED_DEMAND_ID
        , EXPLOSION_DATE
        , SCO_SUPPLY_DATE
        , RECORD_SOURCE
        , SUPPLY_IS_SHARED
        , ULPSD
        , ULPCD
        , UEPSD
        , UEPCD
        , EACD
        , ORIGINAL_NEED_BY_DATE
        , ORIGINAL_QUANTITY
        , ACCEPTANCE_REQUIRED_FLAG
        , PROMISED_DATE
        , WIP_START_QUANTITY
        , END_ORDER_NUMBER
        , END_ORDER_LINE_NUMBER
        , ORDER_LINE_NUMBER
        , QUANTITY_PER_ASSEMBLY
        , QUANTITY_ISSUED
        , UNBUCKETED_DEMAND_DATE
        , SHIPMENT_ID
        , JOB_OP_SEQ_NUM
        , JUMP_OP_SEQ_NUM
        , SHIP_CALENDAR
        , RECEIVING_CALENDAR
        , INTRANSIT_CALENDAR
        , INTRANSIT_LEAD_TIME
        , OLD_SHIP_DATE
        , IMPLEMENT_SHIP_DATE
        , ORIG_SHIP_METHOD
        , ORIG_INTRANSIT_LEAD_TIME
        , PARENT_ID
        , DAYS_LATE
        , SCHEDULE_PRIORITY
        , PO_LINE_LOCATION_ID
        , PO_DISTRIBUTION_ID
        , WSM_FAULTY_NETWORK
        , IMPLEMENT_DEST_ORG_ID
        , IMPLEMENT_DEST_INST_ID
        , REQUESTED_START_DATE
        , REQUESTED_COMPLETION_DATE
        , ASSET_SERIAL_NUMBER
        , ASSET_ITEM_ID
        , TOP_TRANSACTION_ID
        , UNBUCKETED_NEW_SCHED_DATE
        , IMPLEMENT_SHIP_METHOD
        , ACTUAL_START_DATE
        , FIRM_SHIP_DATE
        , SCHEDULE_ORIGINATION_TYPE
        , UNBUCKETED_START_DATE
        , SR_CUSTOMER_ACCT_ID
        , ITEM_TYPE_ID
        , CUSTOMER_PRODUCT_ID
        , RO_STATUS_CODE
        , SR_REPAIR_GROUP_ID
        , SR_REPAIR_TYPE_ID
        , ITEM_TYPE_VALUE
        , ZONE_ID
        , RO_CREATION_DATE
        , REPAIR_LEAD_TIME
        , FIRM_START_DATE
        , REQ_LINE_ID
        , INTRANSIT_OWNING_ORG_ID
        , RELEASABLE
        , BATCH_ID
        , OTM_ARRIVAL_DATE
        , PS_SUPPLY_FLAG
        , CTB_FLAG
        , CTB_COMP_AVAIL_PERCENT
        , RTB_ORDER_QTY_PERCENT
        , CTB_EXPECTED_DATE
        , POTENTIAL_RTB_PERCENT
        , CTB_PRIORITY
        , DESCRIPTION
        , MAINTENANCE_OBJECT_SOURCE
        , PRODUCTION_SCHEDULE_ID
        , VISIT_ID
        , PRODUCES_TO_STOCK
        , PRODUCT_CLASSIFICATION
        , MAINTENANCE_REQT
        , ACTIVITY_TYPE
        , ACTIVITY_NAME
        , CLASS_CODE
        , SHUTDOWN_TYPE
        , TO_BE_EXPLODED
        , OBJECT_TYPE
        , MAINTENANCE_TYPE_CODE
        , ACTIVITY_ITEM_ID
        , ORIG_FIRM_DATE
        , ORIG_FIRM_QUANTITY
        , USE_WO_SUBSTITUTE
        , ASSET_NUMBER
        , MAINTENANCE_OBJECT_ID
        , MAINTENANCE_OBJECT_TYPE
        , OPERATING_FLEET
        , MAINTENANCE_REQUIREMENT
        , COLL_ORDER_TYPE
        , CTB_EXPECTED_DATE_BUY_COMPS
        , SUBSTITUTE_COMPONENTS_USED
        , RESERVED_QTY
        , PO_OR_REQ_HEADER_ID
        , ACTUAL_LEAD_TIME
        , MIN_LEAD_TIME
        , PIP_ITEM_ID
        , SUPP_CAPACITY_OVERLOAD
        , VOLUME_CAPACITY_OVERLOAD
        , WEIGHT_CAPACITY_OVERLOAD
        , PM_SNAPSHOT_DATE
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , /* The supplier HK values are modified to handle the optional null default for the Hash key generation.
          This derived field prevents BKCC being included in the HK generation when the Supplier key is null/Blank */
            IFF(PARTNER_NUMBER IS NULL, '-2', CONCAT_WS('||', TRIM(PARTNER_NUMBER), BKCC)) as DRVD_SUPPLIER_BKCC
        ,     IFF( ITEM_NAME IS NULL, '-2', CONCAT_WS('||',  ITEM_NAME, BKCC)) as DRVD_ITEM_BKCC
        ,     IFF(DRVD_ORGANIZATION_CODE IS NULL, '-2', CONCAT_WS('||', DRVD_ORGANIZATION_CODE, BKCC)) as DRVD_PLANT_BKCC
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORDER_NUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PURCH_LINE_NUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PURCHASE_REQUISITION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_SUPPLIER_BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_ITEM_BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DRVD_PLANT_BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        ))) as PURCHASING_ORG_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        ))) as PURCHASING_RECORD_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(TRANSACTION_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SUPPLIER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITEM_NAME as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DRVD_ORGANIZATION_CODE as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST('-2' as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_PURCHASE_REQUISITION_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(TRANSACTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PLAN_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SR_INSTANCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(SCHEDULE_DESIGNATOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(REVISION::text), '^^') 
            , '||', IFNULL(TRIM(UNIT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(NEW_SCHEDULE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OLD_SCHEDULE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(NEW_WIP_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OLD_WIP_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FIRST_UNIT_COMPLETION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UNIT_COMPLETION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FIRST_UNIT_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UNIT_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(DISPOSITION_ID::text), '^^') 
            , '||', IFNULL(TRIM(DISPOSITION_STATUS_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLIER_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(NEW_ORDER_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(OLD_ORDER_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(NEW_ORDER_PLACEMENT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OLD_ORDER_PLACEMENT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(RESCHEDULE_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(RESCHEDULE_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(SCHEDULE_COMPRESS_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(NEW_PROCESSING_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_IN_PROCESS::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENTED_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_PLANNED_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_DEMAND_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_FIRM::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_WIP_CLASS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_JOB_NAME::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_DOCK_DATE::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_STATUS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_EMPLOYEE_ID::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_UOM_CODE::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_SOURCE_ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_SR_INSTANCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_SUPPLIER_ID::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_SUPPLIER_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_AS::text), '^^') 
            , '||', IFNULL(TRIM(RELEASE_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(LOAD_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PROCESS_SEQ_ID::text), '^^') 
            , '||', IFNULL(TRIM(SCO_SUPPLY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ALTERNATE_BOM_DESIGNATOR::text), '^^') 
            , '||', IFNULL(TRIM(ALTERNATE_ROUTING_DESIGNATOR::text), '^^') 
            , '||', IFNULL(TRIM(OPERATION_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(BY_PRODUCT_USING_ASSY_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_SR_INSTANCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_SUPPLIER_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_SUPPLIER_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(WEIGHT_CAPACITY_USED::text), '^^') 
            , '||', IFNULL(TRIM(VOLUME_CAPACITY_USED::text), '^^') 
            , '||', IFNULL(TRIM(NEW_SHIP_DATE::text), '^^') 
            , '||', IFNULL(TRIM(NEW_DOCK_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OLD_DOCK_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TASK_ID::text), '^^') 
            , '||', IFNULL(TRIM(PLANNING_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_TASK_ID::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_SCHEDULE_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_BUILD_SEQUENCE::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_ALTERNATE_BOM::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_ALTERNATE_ROUTING::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_UNIT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(RELEASE_ERRORS::text), '^^') 
            , '||', IFNULL(TRIM(NUMBER1::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(SCHEDULE_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(BUILD_SEQUENCE::text), '^^') 
            , '||', IFNULL(TRIM(WIP_ENTITY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_PROCESSING_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(LATE_SUPPLY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LATE_SUPPLY_QTY::text), '^^') 
            , '||', IFNULL(TRIM(LOT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SUBINVENTORY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(QTY_SCRAPPED::text), '^^') 
            , '||', IFNULL(TRIM(EXPECTED_SCRAP_QTY::text), '^^') 
            , '||', IFNULL(TRIM(QTY_COMPLETED::text), '^^') 
            , '||', IFNULL(TRIM(DAILY_RATE::text), '^^') 
            , '||', IFNULL(TRIM(SCHEDULE_GROUP_NAME::text), '^^') 
            , '||', IFNULL(TRIM(UPDATED::text), '^^') 
            , '||', IFNULL(TRIM(SUBST_ITEM_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(APPLIED::text), '^^') 
            , '||', IFNULL(TRIM(EXPIRATION_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(EXPIRATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(NON_NETTABLE_QTY::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_WIP_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REFRESH_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_DAILY_RATE::text), '^^') 
            , '||', IFNULL(TRIM(NEED_BY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_SUPPLY_ID::text), '^^') 
            , '||', IFNULL(TRIM(SR_MTL_SUPPLY_ID::text), '^^') 
            , '||', IFNULL(TRIM(WIP_STATUS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DEMAND_CLASS::text), '^^') 
            , '||', IFNULL(TRIM(FROM_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(WIP_SUPPLY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PO_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOAD_FACTOR_RATE::text), '^^') 
            , '||', IFNULL(TRIM(ROUTING_SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(BILL_SEQUENCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(COPRODUCTS_SUPPLY::text), '^^') 
            , '||', IFNULL(TRIM(CFM_ROUTING_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_ID::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(OLD_NEED_BY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OLD_DAILY_RATE::text), '^^') 
            , '||', IFNULL(TRIM(OLD_FIRST_UNIT_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OLD_LAST_UNIT_COMPLETION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OLD_NEW_SCHEDULE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OLD_QTY_COMPLETED::text), '^^') 
            , '||', IFNULL(TRIM(OLD_NEW_ORDER_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(OLD_FIRM_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(OLD_FIRM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PLANNING_PARTNER_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PLANNING_TP_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(OWNING_PARTNER_SITE_ID::text), '^^') 
            , '||', IFNULL(TRIM(OWNING_TP_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(VMI_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(EARLIEST_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(EARLIEST_COMPLETION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(MIN_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SCHEDULED_DEMAND_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXPLOSION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SCO_SUPPLY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(RECORD_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(SUPPLY_IS_SHARED::text), '^^') 
            , '||', IFNULL(TRIM(ULPSD::text), '^^') 
            , '||', IFNULL(TRIM(ULPCD::text), '^^') 
            , '||', IFNULL(TRIM(UEPSD::text), '^^') 
            , '||', IFNULL(TRIM(UEPCD::text), '^^') 
            , '||', IFNULL(TRIM(EACD::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_NEED_BY_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(ACCEPTANCE_REQUIRED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PROMISED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(WIP_START_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(END_ORDER_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(END_ORDER_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_LINE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_PER_ASSEMBLY::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_ISSUED::text), '^^') 
            , '||', IFNULL(TRIM(UNBUCKETED_DEMAND_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(JOB_OP_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(JUMP_OP_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_CALENDAR::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVING_CALENDAR::text), '^^') 
            , '||', IFNULL(TRIM(INTRANSIT_CALENDAR::text), '^^') 
            , '||', IFNULL(TRIM(INTRANSIT_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(OLD_SHIP_DATE::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_SHIP_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_SHIP_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_INTRANSIT_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(PARENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(DAYS_LATE::text), '^^') 
            , '||', IFNULL(TRIM(SCHEDULE_PRIORITY::text), '^^') 
            , '||', IFNULL(TRIM(PO_LINE_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PO_DISTRIBUTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(WSM_FAULTY_NETWORK::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_DEST_ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_DEST_INST_ID::text), '^^') 
            , '||', IFNULL(TRIM(REQUESTED_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REQUESTED_COMPLETION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ASSET_SERIAL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ASSET_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(TOP_TRANSACTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(UNBUCKETED_NEW_SCHED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENT_SHIP_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(ACTUAL_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_SHIP_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SCHEDULE_ORIGINATION_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(UNBUCKETED_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(SR_CUSTOMER_ACCT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_PRODUCT_ID::text), '^^') 
            , '||', IFNULL(TRIM(RO_STATUS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SR_REPAIR_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(SR_REPAIR_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_TYPE_VALUE::text), '^^') 
            , '||', IFNULL(TRIM(ZONE_ID::text), '^^') 
            , '||', IFNULL(TRIM(RO_CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REPAIR_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(FIRM_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(REQ_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTRANSIT_OWNING_ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(RELEASABLE::text), '^^') 
            , '||', IFNULL(TRIM(BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(OTM_ARRIVAL_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PS_SUPPLY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CTB_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CTB_COMP_AVAIL_PERCENT::text), '^^') 
            , '||', IFNULL(TRIM(RTB_ORDER_QTY_PERCENT::text), '^^') 
            , '||', IFNULL(TRIM(CTB_EXPECTED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(POTENTIAL_RTB_PERCENT::text), '^^') 
            , '||', IFNULL(TRIM(CTB_PRIORITY::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(MAINTENANCE_OBJECT_SOURCE::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCTION_SCHEDULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(VISIT_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCES_TO_STOCK::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_CLASSIFICATION::text), '^^') 
            , '||', IFNULL(TRIM(MAINTENANCE_REQT::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVITY_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVITY_NAME::text), '^^') 
            , '||', IFNULL(TRIM(CLASS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHUTDOWN_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(TO_BE_EXPLODED::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(MAINTENANCE_TYPE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ACTIVITY_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_FIRM_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_FIRM_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(USE_WO_SUBSTITUTE::text), '^^') 
            , '||', IFNULL(TRIM(ASSET_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(MAINTENANCE_OBJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(MAINTENANCE_OBJECT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(OPERATING_FLEET::text), '^^') 
            , '||', IFNULL(TRIM(MAINTENANCE_REQUIREMENT::text), '^^') 
            , '||', IFNULL(TRIM(COLL_ORDER_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CTB_EXPECTED_DATE_BUY_COMPS::text), '^^') 
            , '||', IFNULL(TRIM(SUBSTITUTE_COMPONENTS_USED::text), '^^') 
            , '||', IFNULL(TRIM(RESERVED_QTY::text), '^^') 
            , '||', IFNULL(TRIM(PO_OR_REQ_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(ACTUAL_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(MIN_LEAD_TIME::text), '^^') 
            , '||', IFNULL(TRIM(PIP_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(SUPP_CAPACITY_OVERLOAD::text), '^^') 
            , '||', IFNULL(TRIM(VOLUME_CAPACITY_OVERLOAD::text), '^^') 
            , '||', IFNULL(TRIM(WEIGHT_CAPACITY_OVERLOAD::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

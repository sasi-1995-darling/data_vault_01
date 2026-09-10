---- SRC LAYER ----
WITH
SRC_irml           as ( SELECT ACCT_PERIOD_ID, ACTUAL_COST, ATTRIBUTE1, ATTRIBUTE10, ATTRIBUTE11, ATTRIBUTE12, ATTRIBUTE13, ATTRIBUTE14, ATTRIBUTE15, ATTRIBUTE2, ATTRIBUTE3, ATTRIBUTE4, ATTRIBUTE5, ATTRIBUTE6, ATTRIBUTE7, ATTRIBUTE8, ATTRIBUTE9, ATTRIBUTE_CATEGORY, COGS_RECOGNITION_PERCENT, COMMON_BOM_SEQ_ID, COMMON_ROUTING_SEQ_ID, COMPLETION_TRANSACTION_ID, CONTENT_LPN_ID, COSTED_FLAG, COST_CATEGORY_ID, COST_GROUP_ID, COST_TYPE_ID, COST_UPDATE_ID, CREATED_BY, CREATION_DATE, CURRENCY_CODE, CURRENCY_CONVERSION_DATE, CURRENCY_CONVERSION_RATE, CURRENCY_CONVERSION_TYPE, CYCLE_COUNT_ID, DEPARTMENT_ID, DISTRIBUTION_ACCOUNT_ID, EMPLOYEE_CODE, ENCUMBRANCE_ACCOUNT, ENCUMBRANCE_AMOUNT, ERROR_CODE, ERROR_EXPLANATION, EXPENDITURE_TYPE, EXPENSE_ACCOUNT_ID, FINAL_COMPLETION_FLAG, FLOW_SCHEDULE, FOB_POINT, FREIGHT_CODE, INTERCOMPANY_COST, INTERCOMPANY_CURRENCY_CODE, INTERCOMPANY_PRICING_OPTION, INTRANSIT_ACCOUNT, INVENTORY_ITEM_ID, INVOICED_FLAG, LAST_UPDATED_BY, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN, LOCATOR_ID, LOGICAL_TRANSACTION, LOGICAL_TRANSACTIONS_CREATED, LOGICAL_TRX_TYPE_CODE, LPN_ID, MASTER_SCHEDULE_UPDATE_CODE, MATERIAL_ACCOUNT, MATERIAL_EXPENSE_ACCOUNT, MATERIAL_OVERHEAD_ACCOUNT, MOVEMENT_ID, MOVE_ORDER_LINE_ID, MOVE_TRANSACTION_ID, MVT_STAT_STATUS, NEW_COST, NUMBER_OF_CONTAINERS, OPERATION_SEQ_NUM, OPM_COSTED_FLAG, ORGANIZATION_ID, ORGANIZATION_TYPE, ORG_COST_GROUP_ID, ORIGINAL_TRANSACTION_TEMP_ID, OUTSIDE_PROCESSING_ACCOUNT, OVERCOMPLETION_PRIMARY_QTY, OVERCOMPLETION_TRANSACTION_ID, OVERCOMPLETION_TRANSACTION_QTY, OVERHEAD_ACCOUNT, OWNING_ORGANIZATION_ID, OWNING_TP_TYPE, PARENT_TRANSACTION_ID, PA_EXPENDITURE_ORG_ID, PERCENTAGE_CHANGE, PERIODIC_PRIMARY_QUANTITY, PHYSICAL_ADJUSTMENT_ID, PICKING_LINE_ID, PICK_RULE_ID, PICK_SLIP_DATE, PICK_SLIP_NUMBER, PICK_STRATEGY_ID, PLANNING_ORGANIZATION_ID, PLANNING_TP_TYPE, PM_COST_COLLECTED, PM_COST_COLLECTOR_GROUP_ID, PRIMARY_QUANTITY, PRIOR_COST, PRIOR_COSTED_QUANTITY, PROGRAM_APPLICATION_ID, PROGRAM_ID, PROGRAM_UPDATE_DATE, PROJECT_ID, PSA_DELETE_IND, PSA_LOAD_DTS, PUT_AWAY_RULE_ID, PUT_AWAY_STRATEGY_ID, QA_COLLECTION_ID, QUANTITY_ADJUSTED, RCV_TRANSACTION_ID, REASON_ID, RECEIVING_DOCUMENT, REPETITIVE_LINE_ID, REQUEST_ID, RESERVATION_ID, RESOURCE_ACCOUNT, REVISION, RMA_LINE_ID, SECONDARY_TRANSACTION_QUANTITY, SECONDARY_UOM_CODE, SHIPMENT_COSTED, SHIPMENT_NUMBER, SHIP_TO_LOCATION_ID, SHORTAGE_PROCESS_CODE, SOURCE_CODE, SOURCE_LINE_ID, SOURCE_PROJECT_ID, SOURCE_TASK_ID, SO_ISSUE_ACCOUNT_TYPE, SUBINVENTORY_CODE, TASK_GROUP_ID, TASK_ID, TO_PROJECT_ID, TO_TASK_ID, TRANSACTION_ACTION_ID, TRANSACTION_BATCH_ID, TRANSACTION_BATCH_SEQ, TRANSACTION_COST, TRANSACTION_DATE, TRANSACTION_EXTRACTED, TRANSACTION_GROUP_ID, TRANSACTION_GROUP_SEQ, TRANSACTION_ID, TRANSACTION_MODE, TRANSACTION_QUANTITY, TRANSACTION_REFERENCE, TRANSACTION_SET_ID, TRANSACTION_SOURCE_ID, TRANSACTION_SOURCE_NAME, TRANSACTION_SOURCE_TYPE_ID, TRANSACTION_TYPE_ID, TRANSACTION_UOM, TRANSFER_COST, TRANSFER_COST_DIST_ACCOUNT, TRANSFER_COST_GROUP_ID, TRANSFER_LOCATOR_ID, TRANSFER_LPN_ID, TRANSFER_ORGANIZATION_ID, TRANSFER_ORGANIZATION_TYPE, TRANSFER_OWNING_TP_TYPE, TRANSFER_PERCENTAGE, TRANSFER_PLANNING_TP_TYPE, TRANSFER_PRICE, TRANSFER_PRIOR_COSTED_QUANTITY, TRANSFER_SUBINVENTORY, TRANSFER_TRANSACTION_ID, TRANSPORTATION_COST, TRANSPORTATION_DIST_ACCOUNT, TRX_FLOW_HEADER_ID, TRX_SOURCE_DELIVERY_ID, TRX_SOURCE_LINE_ID, USSGL_TRANSACTION_CODE, VALUE_CHANGE, VARIANCE_AMOUNT, VENDOR_LOT_NUMBER, WAYBILL_AIRBILL, XFR_OWNING_ORGANIZATION_ID, XFR_PLANNING_ORGANIZATION_ID, XML_DOCUMENT_ID, _FIVETRAN_DELETED, _FIVETRAN_ID, _FIVETRAN_SYNCED FROM {{ source('ml_ebs_inv', 'mtl_material_transactions') }} as SRC ),
SRC_a              as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_itm            as ( SELECT INVENTORY_ITEM_ID, ORGANIZATION_ID, SEGMENT1 FROM {{ source('ml_ebs_inv', 'mtl_system_items_b') }} as SRC 
                        where organization_id = 1 
                        qualify 1= row_number()over(partition by inventory_item_id order by _fivetran_synced desc, psa_load_dts desc) ),
SRC_rcv            as ( SELECT PO_LINE_ID, TRANSACTION_ID, VENDOR_ID FROM {{ source('ml_ebs_po', 'rcv_transactions') }} as SRC 
                        qualify 1 = row_number()over (partition by transaction_id order by psa_load_dts desc) ),
SRC_po             as ( SELECT LINE_NUM, ORG_ID, PO_HEADER_ID, PO_LINE_ID FROM {{ source('ml_ebs_po', 'po_lines_all') }} as SRC 
                        qualify 1 = row_number()over (partition by po_line_id order by psa_load_dts desc) ),
SRC_sup            as ( SELECT SEGMENT1, VENDOR_ID FROM {{ source('ml_ebs_ap', 'ap_suppliers') }} as SRC 
                        qualify 1= row_number()over(partition by vendor_id order by _fivetran_synced desc, psa_load_dts desc) ),
SRC_p              as ( SELECT ORGANIZATION_CODE, ORGANIZATION_ID FROM {{ source('ml_ebs_inv', 'mtl_parameters') }} as SRC 
                        qualify 1 = row_number()over (partition by organization_id order by _fivetran_synced desc, psa_load_dts desc) )

/*
SRC_irml           as ( SELECT * FROM ml_ebs_inv.mtl_material_transactions )
SRC_a              as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_itm            as ( SELECT * FROM ml_ebs_inv.mtl_system_items_b )
SRC_rcv            as ( SELECT * FROM ml_ebs_po.rcv_transactions )
SRC_po             as ( SELECT * FROM ml_ebs_po.po_lines_all )
SRC_sup            as ( SELECT * FROM ml_ebs_ap.ap_suppliers )
SRC_p              as ( SELECT * FROM ml_ebs_inv.mtl_parameters )
*/
---- LOGIC LAYER ----

, LOGIC_irml as (
    SELECT
        ORGANIZATION_ID                                              as                                           PLANT_BK
      , TRANSACTION_ID
      , ORGANIZATION_ID
      , TRANSACTION_SOURCE_ID
      , COMMON_ROUTING_SEQ_ID
      , TRANSACTION_SET_ID
      , COST_GROUP_ID
      , VARIANCE_AMOUNT
      , ERROR_EXPLANATION
      , ATTRIBUTE10
      , CYCLE_COUNT_ID
      , ERROR_CODE
      , SECONDARY_UOM_CODE
      , SHIPMENT_COSTED
      , INTERCOMPANY_COST
      , TRANSACTION_BATCH_SEQ
      , PROJECT_ID
      , TO_PROJECT_ID
      , EXPENSE_ACCOUNT_ID
      , TRANSFER_OWNING_TP_TYPE
      , INVENTORY_ITEM_ID
      , LPN_ID
      , MOVE_ORDER_LINE_ID
      , ATTRIBUTE1
      , SOURCE_CODE
      , VALUE_CHANGE
      , PUT_AWAY_RULE_ID
      , TRANSACTION_UOM
      , TRANSFER_PRICE
      , LAST_UPDATE_LOGIN
      , PICKING_LINE_ID
      , USSGL_TRANSACTION_CODE
      , TRANSFER_SUBINVENTORY
      , EXPENDITURE_TYPE
      , SO_ISSUE_ACCOUNT_TYPE
      , OVERHEAD_ACCOUNT
      , PRIOR_COST
      , TRANSFER_LOCATOR_ID
      , TRANSACTION_EXTRACTED
      , ATTRIBUTE2
      , OVERCOMPLETION_TRANSACTION_QTY
      , PA_EXPENDITURE_ORG_ID
      , MATERIAL_OVERHEAD_ACCOUNT
      , TRANSPORTATION_DIST_ACCOUNT
      , TRANSFER_PLANNING_TP_TYPE
      , TRANSACTION_BATCH_ID
      , TRANSFER_ORGANIZATION_TYPE
      , PARENT_TRANSACTION_ID
      , _FIVETRAN_SYNCED
      , XFR_PLANNING_ORGANIZATION_ID
      , OPM_COSTED_FLAG
      , _FIVETRAN_ID
      , TRANSFER_COST_DIST_ACCOUNT
      , OWNING_TP_TYPE
      , PICK_STRATEGY_ID
      , RECEIVING_DOCUMENT
      , PERCENTAGE_CHANGE
      , NUMBER_OF_CONTAINERS
      , LOCATOR_ID
      , TRANSACTION_ACTION_ID
      , ORGANIZATION_TYPE
      , EMPLOYEE_CODE
      , REASON_ID
      , OWNING_ORGANIZATION_ID
      , CREATED_BY
      , ACTUAL_COST
      , PLANNING_ORGANIZATION_ID
      , REPETITIVE_LINE_ID
      , TRANSPORTATION_COST
      , ATTRIBUTE3
      , MATERIAL_ACCOUNT
      , TRANSFER_TRANSACTION_ID
      , PM_COST_COLLECTED
      , RESERVATION_ID
      , LOGICAL_TRANSACTION
      , SHIP_TO_LOCATION_ID
      , ATTRIBUTE15
      , COMMON_BOM_SEQ_ID
      , PRIOR_COSTED_QUANTITY
      , TRANSFER_ORGANIZATION_ID
      , INTRANSIT_ACCOUNT
      , COMPLETION_TRANSACTION_ID
      , LOGICAL_TRX_TYPE_CODE
      , INTERCOMPANY_CURRENCY_CODE
      , PLANNING_TP_TYPE
      , COGS_RECOGNITION_PERCENT
      , MASTER_SCHEDULE_UPDATE_CODE
      , QA_COLLECTION_ID
      , PERIODIC_PRIMARY_QUANTITY
      , ATTRIBUTE6
      , TRX_SOURCE_LINE_ID
      , REQUEST_ID
      , SOURCE_LINE_ID
      , CURRENCY_CONVERSION_TYPE
      , ATTRIBUTE4
      , LAST_UPDATE_DATE
      , OPERATION_SEQ_NUM
      , ATTRIBUTE7
      , PICK_RULE_ID
      , INVOICED_FLAG
      , CONTENT_LPN_ID
      , TRANSACTION_QUANTITY
      , TRANSFER_LPN_ID
      , TRANSACTION_SOURCE_TYPE_ID
      , ORIGINAL_TRANSACTION_TEMP_ID
      , OVERCOMPLETION_TRANSACTION_ID
      , ATTRIBUTE12
      , SHORTAGE_PROCESS_CODE
      , XFR_OWNING_ORGANIZATION_ID
      , ATTRIBUTE11
      , CURRENCY_CODE
      , DEPARTMENT_ID
      , COST_UPDATE_ID
      , PICK_SLIP_NUMBER
      , RCV_TRANSACTION_ID
      , ENCUMBRANCE_ACCOUNT
      , COST_TYPE_ID
      , MVT_STAT_STATUS
      , OVERCOMPLETION_PRIMARY_QTY
      , CREATION_DATE
      , LAST_UPDATED_BY
      , OUTSIDE_PROCESSING_ACCOUNT
      , DISTRIBUTION_ACCOUNT_ID
      , TRANSACTION_REFERENCE
      , NEW_COST
      , FLOW_SCHEDULE
      , TRX_SOURCE_DELIVERY_ID
      , MOVE_TRANSACTION_ID
      , ACCT_PERIOD_ID
      , TRANSACTION_MODE
      , SHIPMENT_NUMBER
      , TRANSACTION_DATE
      , VENDOR_LOT_NUMBER
      , FREIGHT_CODE
      , TRANSFER_COST
      , ATTRIBUTE9
      , PRIMARY_QUANTITY
      , FINAL_COMPLETION_FLAG
      , TO_TASK_ID
      , TRANSACTION_COST
      , FOB_POINT
      , REVISION
      , SUBINVENTORY_CODE
      , ATTRIBUTE13
      , LOGICAL_TRANSACTIONS_CREATED
      , _FIVETRAN_DELETED
      , CURRENCY_CONVERSION_RATE
      , QUANTITY_ADJUSTED
      , PUT_AWAY_STRATEGY_ID
      , ENCUMBRANCE_AMOUNT
      , SOURCE_PROJECT_ID
      , TRANSACTION_GROUP_SEQ
      , TASK_GROUP_ID
      , MATERIAL_EXPENSE_ACCOUNT
      , TRANSACTION_SOURCE_NAME
      , XML_DOCUMENT_ID
      , TRANSFER_PERCENTAGE
      , TRANSACTION_GROUP_ID
      , ATTRIBUTE14
      , ATTRIBUTE8
      , PROGRAM_UPDATE_DATE
      , MOVEMENT_ID
      , PICK_SLIP_DATE
      , PHYSICAL_ADJUSTMENT_ID
      , TASK_ID
      , WAYBILL_AIRBILL
      , RMA_LINE_ID
      , SOURCE_TASK_ID
      , PROGRAM_ID
      , TRANSFER_COST_GROUP_ID
      , TRANSACTION_TYPE_ID
      , ATTRIBUTE5
      , COST_CATEGORY_ID
      , ATTRIBUTE_CATEGORY
      , TRANSFER_PRIOR_COSTED_QUANTITY
      , INTERCOMPANY_PRICING_OPTION
      , CURRENCY_CONVERSION_DATE
      , PROGRAM_APPLICATION_ID
      , ORG_COST_GROUP_ID
      , SECONDARY_TRANSACTION_QUANTITY
      , RESOURCE_ACCOUNT
      , TRX_FLOW_HEADER_ID
      , COSTED_FLAG
      , PM_COST_COLLECTOR_GROUP_ID
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_irml
)

, LOGIC_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_a
)

, LOGIC_itm as (
    SELECT
        SEGMENT1                                                     as                                            ITEM_BK
      , SEGMENT1                                                     as                                       ITM_SEGMENT1
      , INVENTORY_ITEM_ID                                            as                              itm_INVENTORY_ITEM_ID
      , ORGANIZATION_ID                                              as                                ITM_ORGANIZATION_ID
    FROM SRC_itm
)

, LOGIC_rcv as (
    SELECT
        PO_LINE_ID
      , VENDOR_ID
      , TRANSACTION_ID                                               as                             RCV_RCV_TRANSACTION_ID
    FROM SRC_rcv
)

, LOGIC_po as (
    SELECT
        PO_HEADER_ID                                                 as                                       PO_HEADER_BK
      , ORG_ID                                                       as                                    LEGAL_ENTITY_BK
      , PO_HEADER_ID
      , LINE_NUM
      , ORG_ID
      , PO_LINE_ID                                                   as                                      PO_PO_LINE_ID
    FROM SRC_po
)

, LOGIC_sup as (
    SELECT
        SEGMENT1                                                     as                                        SUPPLIER_BK
      , SEGMENT1                                                     as                                       SUP_SEGMENT1
      , VENDOR_ID                                                    as                                      SUP_VENDOR_ID
    FROM SRC_sup
)

, LOGIC_p as (
    SELECT
        ORGANIZATION_CODE
      , ORGANIZATION_ID                                              as                                  P_ORGANIZATION_ID
    FROM SRC_p
)
---- RENAME LAYER ----

, RENAME_po as (
    SELECT
        PO_HEADER_BK
      , LEGAL_ENTITY_BK
      , PO_HEADER_ID
      , LINE_NUM
      , ORG_ID
      , PO_PO_LINE_ID
    FROM LOGIC_po
)

, RENAME_sup as (
    SELECT
        SUPPLIER_BK
      , SUP_SEGMENT1
      , SUP_VENDOR_ID
    FROM LOGIC_sup
)

, RENAME_itm as (
    SELECT
        ITEM_BK
      , ITM_SEGMENT1
      , itm_INVENTORY_ITEM_ID
      , ITM_ORGANIZATION_ID
    FROM LOGIC_itm
)

, RENAME_irml as (
    SELECT
        PLANT_BK
      , TRANSACTION_ID
      , ORGANIZATION_ID
      , TRANSACTION_SOURCE_ID
      , COMMON_ROUTING_SEQ_ID
      , TRANSACTION_SET_ID
      , COST_GROUP_ID
      , VARIANCE_AMOUNT
      , ERROR_EXPLANATION
      , ATTRIBUTE10
      , CYCLE_COUNT_ID
      , ERROR_CODE
      , SECONDARY_UOM_CODE
      , SHIPMENT_COSTED
      , INTERCOMPANY_COST
      , TRANSACTION_BATCH_SEQ
      , PROJECT_ID
      , TO_PROJECT_ID
      , EXPENSE_ACCOUNT_ID
      , TRANSFER_OWNING_TP_TYPE
      , INVENTORY_ITEM_ID
      , LPN_ID
      , MOVE_ORDER_LINE_ID
      , ATTRIBUTE1
      , SOURCE_CODE
      , VALUE_CHANGE
      , PUT_AWAY_RULE_ID
      , TRANSACTION_UOM
      , TRANSFER_PRICE
      , LAST_UPDATE_LOGIN
      , PICKING_LINE_ID
      , USSGL_TRANSACTION_CODE
      , TRANSFER_SUBINVENTORY
      , EXPENDITURE_TYPE
      , SO_ISSUE_ACCOUNT_TYPE
      , OVERHEAD_ACCOUNT
      , PRIOR_COST
      , TRANSFER_LOCATOR_ID
      , TRANSACTION_EXTRACTED
      , ATTRIBUTE2
      , OVERCOMPLETION_TRANSACTION_QTY
      , PA_EXPENDITURE_ORG_ID
      , MATERIAL_OVERHEAD_ACCOUNT
      , TRANSPORTATION_DIST_ACCOUNT
      , TRANSFER_PLANNING_TP_TYPE
      , TRANSACTION_BATCH_ID
      , TRANSFER_ORGANIZATION_TYPE
      , PARENT_TRANSACTION_ID
      , _FIVETRAN_SYNCED
      , XFR_PLANNING_ORGANIZATION_ID
      , OPM_COSTED_FLAG
      , _FIVETRAN_ID
      , TRANSFER_COST_DIST_ACCOUNT
      , OWNING_TP_TYPE
      , PICK_STRATEGY_ID
      , RECEIVING_DOCUMENT
      , PERCENTAGE_CHANGE
      , NUMBER_OF_CONTAINERS
      , LOCATOR_ID
      , TRANSACTION_ACTION_ID
      , ORGANIZATION_TYPE
      , EMPLOYEE_CODE
      , REASON_ID
      , OWNING_ORGANIZATION_ID
      , CREATED_BY
      , ACTUAL_COST
      , PLANNING_ORGANIZATION_ID
      , REPETITIVE_LINE_ID
      , TRANSPORTATION_COST
      , ATTRIBUTE3
      , MATERIAL_ACCOUNT
      , TRANSFER_TRANSACTION_ID
      , PM_COST_COLLECTED
      , RESERVATION_ID
      , LOGICAL_TRANSACTION
      , SHIP_TO_LOCATION_ID
      , ATTRIBUTE15
      , COMMON_BOM_SEQ_ID
      , PRIOR_COSTED_QUANTITY
      , TRANSFER_ORGANIZATION_ID
      , INTRANSIT_ACCOUNT
      , COMPLETION_TRANSACTION_ID
      , LOGICAL_TRX_TYPE_CODE
      , INTERCOMPANY_CURRENCY_CODE
      , PLANNING_TP_TYPE
      , COGS_RECOGNITION_PERCENT
      , MASTER_SCHEDULE_UPDATE_CODE
      , QA_COLLECTION_ID
      , PERIODIC_PRIMARY_QUANTITY
      , ATTRIBUTE6
      , TRX_SOURCE_LINE_ID
      , REQUEST_ID
      , SOURCE_LINE_ID
      , CURRENCY_CONVERSION_TYPE
      , ATTRIBUTE4
      , LAST_UPDATE_DATE
      , OPERATION_SEQ_NUM
      , ATTRIBUTE7
      , PICK_RULE_ID
      , INVOICED_FLAG
      , CONTENT_LPN_ID
      , TRANSACTION_QUANTITY
      , TRANSFER_LPN_ID
      , TRANSACTION_SOURCE_TYPE_ID
      , ORIGINAL_TRANSACTION_TEMP_ID
      , OVERCOMPLETION_TRANSACTION_ID
      , ATTRIBUTE12
      , SHORTAGE_PROCESS_CODE
      , XFR_OWNING_ORGANIZATION_ID
      , ATTRIBUTE11
      , CURRENCY_CODE
      , DEPARTMENT_ID
      , COST_UPDATE_ID
      , PICK_SLIP_NUMBER
      , RCV_TRANSACTION_ID
      , ENCUMBRANCE_ACCOUNT
      , COST_TYPE_ID
      , MVT_STAT_STATUS
      , OVERCOMPLETION_PRIMARY_QTY
      , CREATION_DATE
      , LAST_UPDATED_BY
      , OUTSIDE_PROCESSING_ACCOUNT
      , DISTRIBUTION_ACCOUNT_ID
      , TRANSACTION_REFERENCE
      , NEW_COST
      , FLOW_SCHEDULE
      , TRX_SOURCE_DELIVERY_ID
      , MOVE_TRANSACTION_ID
      , ACCT_PERIOD_ID
      , TRANSACTION_MODE
      , SHIPMENT_NUMBER
      , TRANSACTION_DATE
      , VENDOR_LOT_NUMBER
      , FREIGHT_CODE
      , TRANSFER_COST
      , ATTRIBUTE9
      , PRIMARY_QUANTITY
      , FINAL_COMPLETION_FLAG
      , TO_TASK_ID
      , TRANSACTION_COST
      , FOB_POINT
      , REVISION
      , SUBINVENTORY_CODE
      , ATTRIBUTE13
      , LOGICAL_TRANSACTIONS_CREATED
      , _FIVETRAN_DELETED
      , CURRENCY_CONVERSION_RATE
      , QUANTITY_ADJUSTED
      , PUT_AWAY_STRATEGY_ID
      , ENCUMBRANCE_AMOUNT
      , SOURCE_PROJECT_ID
      , TRANSACTION_GROUP_SEQ
      , TASK_GROUP_ID
      , MATERIAL_EXPENSE_ACCOUNT
      , TRANSACTION_SOURCE_NAME
      , XML_DOCUMENT_ID
      , TRANSFER_PERCENTAGE
      , TRANSACTION_GROUP_ID
      , ATTRIBUTE14
      , ATTRIBUTE8
      , PROGRAM_UPDATE_DATE
      , MOVEMENT_ID
      , PICK_SLIP_DATE
      , PHYSICAL_ADJUSTMENT_ID
      , TASK_ID
      , WAYBILL_AIRBILL
      , RMA_LINE_ID
      , SOURCE_TASK_ID
      , PROGRAM_ID
      , TRANSFER_COST_GROUP_ID
      , TRANSACTION_TYPE_ID
      , ATTRIBUTE5
      , COST_CATEGORY_ID
      , ATTRIBUTE_CATEGORY
      , TRANSFER_PRIOR_COSTED_QUANTITY
      , INTERCOMPANY_PRICING_OPTION
      , CURRENCY_CONVERSION_DATE
      , PROGRAM_APPLICATION_ID
      , ORG_COST_GROUP_ID
      , SECONDARY_TRANSACTION_QUANTITY
      , RESOURCE_ACCOUNT
      , TRX_FLOW_HEADER_ID
      , COSTED_FLAG
      , PM_COST_COLLECTOR_GROUP_ID
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_irml
)

, RENAME_p as (
    SELECT
        ORGANIZATION_CODE
      , P_ORGANIZATION_ID
    FROM LOGIC_p
)

, RENAME_rcv as (
    SELECT
        PO_LINE_ID
      , VENDOR_ID
      , RCV_RCV_TRANSACTION_ID
    FROM LOGIC_rcv
)

, RENAME_a as (
    SELECT
        BKCC
      , REC_SRC
    FROM LOGIC_a
)
---- FILTER LAYER ----

, FILTER_irml as (
    SELECT *
    FROM RENAME_irml
    WHERE TRANSACTION_TYPE_ID IN (18,71)
)

, FILTER_a as (
    SELECT *
    FROM RENAME_a
    WHERE rec_src = 'USWIOC.ORCL.EBSPRD.MTL_MATERIAL_TRANSACTIONS'
)

, FILTER_itm as (
    SELECT *
    FROM RENAME_itm
)

, FILTER_rcv as (
    SELECT *
    FROM RENAME_rcv
)

, FILTER_po as (
    SELECT *
    FROM RENAME_po
)

, FILTER_sup as (
    SELECT *
    FROM RENAME_sup
)

, FILTER_p as (
    SELECT *
    FROM RENAME_p
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_irml
    INNER JOIN FILTER_a
        ON '1' = '1'
    LEFT JOIN FILTER_itm
        ON FILTER_irml.INVENTORY_ITEM_ID = ITM_INVENTORY_ITEM_ID
    LEFT JOIN FILTER_rcv
        ON FILTER_irml.RCV_TRANSACTION_ID = RCV_RCV_TRANSACTION_ID
    LEFT JOIN FILTER_p
        ON FILTER_irml.ORGANIZATION_ID = P_ORGANIZATION_ID
    LEFT JOIN FILTER_po
        ON FILTER_rcv.PO_LINE_ID = PO_PO_LINE_ID
    LEFT JOIN FILTER_sup
        ON FILTER_rcv.VENDOR_ID = SUP_VENDOR_ID
)

---- FINAL LAYER ----
SELECT
          CONCAT_WS('||'          
          , COALESCE(PO_HEADER_ID::TEXT,'')
          , COALESCE(LINE_NUM::TEXT,'')
          , COALESCE(TRANSACTION_ID::TEXT,'')) as PO_ITEM_RECEIPT_BK
        , PO_HEADER_BK
        , SUPPLIER_BK
        , ITEM_BK
        , PLANT_BK
        , LEGAL_ENTITY_BK
        , PO_HEADER_ID
        , LINE_NUM
        , TRANSACTION_ID
        , SUP_SEGMENT1
        , ITM_SEGMENT1
        , ORGANIZATION_ID
        , ORG_ID
        , ORGANIZATION_CODE
        , PO_LINE_ID
        , TRANSACTION_SOURCE_ID
        , VENDOR_ID
        , COMMON_ROUTING_SEQ_ID
        , TRANSACTION_SET_ID
        , COST_GROUP_ID
        , VARIANCE_AMOUNT
        , ERROR_EXPLANATION
        , ATTRIBUTE10
        , CYCLE_COUNT_ID
        , ERROR_CODE
        , SECONDARY_UOM_CODE
        , SHIPMENT_COSTED
        , INTERCOMPANY_COST
        , TRANSACTION_BATCH_SEQ
        , PROJECT_ID
        , TO_PROJECT_ID
        , EXPENSE_ACCOUNT_ID
        , TRANSFER_OWNING_TP_TYPE
        , INVENTORY_ITEM_ID
        , LPN_ID
        , MOVE_ORDER_LINE_ID
        , ATTRIBUTE1
        , SOURCE_CODE
        , VALUE_CHANGE
        , PUT_AWAY_RULE_ID
        , TRANSACTION_UOM
        , TRANSFER_PRICE
        , LAST_UPDATE_LOGIN
        , PICKING_LINE_ID
        , USSGL_TRANSACTION_CODE
        , TRANSFER_SUBINVENTORY
        , EXPENDITURE_TYPE
        , SO_ISSUE_ACCOUNT_TYPE
        , OVERHEAD_ACCOUNT
        , PRIOR_COST
        , TRANSFER_LOCATOR_ID
        , TRANSACTION_EXTRACTED
        , ATTRIBUTE2
        , OVERCOMPLETION_TRANSACTION_QTY
        , PA_EXPENDITURE_ORG_ID
        , MATERIAL_OVERHEAD_ACCOUNT
        , TRANSPORTATION_DIST_ACCOUNT
        , TRANSFER_PLANNING_TP_TYPE
        , TRANSACTION_BATCH_ID
        , TRANSFER_ORGANIZATION_TYPE
        , PARENT_TRANSACTION_ID
        , _FIVETRAN_SYNCED
        , XFR_PLANNING_ORGANIZATION_ID
        , OPM_COSTED_FLAG
        , _FIVETRAN_ID
        , TRANSFER_COST_DIST_ACCOUNT
        , OWNING_TP_TYPE
        , PICK_STRATEGY_ID
        , RECEIVING_DOCUMENT
        , PERCENTAGE_CHANGE
        , NUMBER_OF_CONTAINERS
        , LOCATOR_ID
        , TRANSACTION_ACTION_ID
        , ORGANIZATION_TYPE
        , EMPLOYEE_CODE
        , REASON_ID
        , OWNING_ORGANIZATION_ID
        , CREATED_BY
        , ACTUAL_COST
        , PLANNING_ORGANIZATION_ID
        , REPETITIVE_LINE_ID
        , TRANSPORTATION_COST
        , ATTRIBUTE3
        , MATERIAL_ACCOUNT
        , TRANSFER_TRANSACTION_ID
        , PM_COST_COLLECTED
        , RESERVATION_ID
        , LOGICAL_TRANSACTION
        , SHIP_TO_LOCATION_ID
        , ATTRIBUTE15
        , COMMON_BOM_SEQ_ID
        , PRIOR_COSTED_QUANTITY
        , TRANSFER_ORGANIZATION_ID
        , INTRANSIT_ACCOUNT
        , COMPLETION_TRANSACTION_ID
        , LOGICAL_TRX_TYPE_CODE
        , INTERCOMPANY_CURRENCY_CODE
        , PLANNING_TP_TYPE
        , COGS_RECOGNITION_PERCENT
        , MASTER_SCHEDULE_UPDATE_CODE
        , QA_COLLECTION_ID
        , PERIODIC_PRIMARY_QUANTITY
        , ATTRIBUTE6
        , TRX_SOURCE_LINE_ID
        , REQUEST_ID
        , SOURCE_LINE_ID
        , CURRENCY_CONVERSION_TYPE
        , ATTRIBUTE4
        , LAST_UPDATE_DATE
        , OPERATION_SEQ_NUM
        , ATTRIBUTE7
        , PICK_RULE_ID
        , INVOICED_FLAG
        , CONTENT_LPN_ID
        , TRANSACTION_QUANTITY
        , TRANSFER_LPN_ID
        , TRANSACTION_SOURCE_TYPE_ID
        , ORIGINAL_TRANSACTION_TEMP_ID
        , OVERCOMPLETION_TRANSACTION_ID
        , ATTRIBUTE12
        , SHORTAGE_PROCESS_CODE
        , XFR_OWNING_ORGANIZATION_ID
        , ATTRIBUTE11
        , CURRENCY_CODE
        , DEPARTMENT_ID
        , COST_UPDATE_ID
        , PICK_SLIP_NUMBER
        , RCV_TRANSACTION_ID
        , ENCUMBRANCE_ACCOUNT
        , COST_TYPE_ID
        , MVT_STAT_STATUS
        , OVERCOMPLETION_PRIMARY_QTY
        , CREATION_DATE
        , LAST_UPDATED_BY
        , OUTSIDE_PROCESSING_ACCOUNT
        , DISTRIBUTION_ACCOUNT_ID
        , TRANSACTION_REFERENCE
        , NEW_COST
        , FLOW_SCHEDULE
        , TRX_SOURCE_DELIVERY_ID
        , MOVE_TRANSACTION_ID
        , ACCT_PERIOD_ID
        , TRANSACTION_MODE
        , SHIPMENT_NUMBER
        , TRANSACTION_DATE
        , VENDOR_LOT_NUMBER
        , FREIGHT_CODE
        , TRANSFER_COST
        , ATTRIBUTE9
        , PRIMARY_QUANTITY
        , FINAL_COMPLETION_FLAG
        , TO_TASK_ID
        , TRANSACTION_COST
        , FOB_POINT
        , REVISION
        , SUBINVENTORY_CODE
        , ATTRIBUTE13
        , LOGICAL_TRANSACTIONS_CREATED
        , _FIVETRAN_DELETED
        , CURRENCY_CONVERSION_RATE
        , QUANTITY_ADJUSTED
        , PUT_AWAY_STRATEGY_ID
        , ENCUMBRANCE_AMOUNT
        , SOURCE_PROJECT_ID
        , TRANSACTION_GROUP_SEQ
        , TASK_GROUP_ID
        , MATERIAL_EXPENSE_ACCOUNT
        , TRANSACTION_SOURCE_NAME
        , XML_DOCUMENT_ID
        , TRANSFER_PERCENTAGE
        , TRANSACTION_GROUP_ID
        , ATTRIBUTE14
        , ATTRIBUTE8
        , PROGRAM_UPDATE_DATE
        , MOVEMENT_ID
        , PICK_SLIP_DATE
        , PHYSICAL_ADJUSTMENT_ID
        , TASK_ID
        , WAYBILL_AIRBILL
        , RMA_LINE_ID
        , SOURCE_TASK_ID
        , PROGRAM_ID
        , TRANSFER_COST_GROUP_ID
        , TRANSACTION_TYPE_ID
        , ATTRIBUTE5
        , COST_CATEGORY_ID
        , ATTRIBUTE_CATEGORY
        , TRANSFER_PRIOR_COSTED_QUANTITY
        , INTERCOMPANY_PRICING_OPTION
        , CURRENCY_CONVERSION_DATE
        , PROGRAM_APPLICATION_ID
        , ORG_COST_GROUP_ID
        , SECONDARY_TRANSACTION_QUANTITY
        , RESOURCE_ACCOUNT
        , TRX_FLOW_HEADER_ID
        , COSTED_FLAG
        , PM_COST_COLLECTOR_GROUP_ID
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , LOAD_DTS
        , BKCC
        , REC_SRC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_HEADER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LINE_NUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(TRANSACTION_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SUP_SEGMENT1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ITM_SEGMENT1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORGANIZATION_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(ORG_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LNK_PO_RECEIPT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_HEADER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_HEADER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_HEADER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LINE_NUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PO_HEADER_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LINE_NUM as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(TRANSACTION_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PO_ITEM_RECEIPT_DK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SUP_SEGMENT1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SUPPLIER_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITM_SEGMENT1 as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORGANIZATION_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ORG_ID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as LEGAL_ENTITY_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_SOURCE_ID::text), '^^') 
            , '||', IFNULL(TRIM(COMMON_ROUTING_SEQ_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(COST_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(VARIANCE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ERROR_EXPLANATION::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE10::text), '^^') 
            , '||', IFNULL(TRIM(CYCLE_COUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ERROR_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_UOM_CODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_COSTED::text), '^^') 
            , '||', IFNULL(TRIM(INTERCOMPANY_COST::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_BATCH_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TO_PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(EXPENSE_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_OWNING_TP_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(INVENTORY_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(LPN_ID::text), '^^') 
            , '||', IFNULL(TRIM(MOVE_ORDER_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(VALUE_CHANGE::text), '^^') 
            , '||', IFNULL(TRIM(PUT_AWAY_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_UOM::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(PICKING_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(USSGL_TRANSACTION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_SUBINVENTORY::text), '^^') 
            , '||', IFNULL(TRIM(EXPENDITURE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(SO_ISSUE_ACCOUNT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(OVERHEAD_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(PRIOR_COST::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_LOCATOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_EXTRACTED::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(OVERCOMPLETION_TRANSACTION_QTY::text), '^^') 
            , '||', IFNULL(TRIM(PA_EXPENDITURE_ORG_ID::text), '^^') 
            , '||', IFNULL(TRIM(MATERIAL_OVERHEAD_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TRANSPORTATION_DIST_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_PLANNING_TP_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_ORGANIZATION_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PARENT_TRANSACTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(XFR_PLANNING_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(OPM_COSTED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_COST_DIST_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(OWNING_TP_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(PICK_STRATEGY_ID::text), '^^') 
            , '||', IFNULL(TRIM(RECEIVING_DOCUMENT::text), '^^') 
            , '||', IFNULL(TRIM(PERCENTAGE_CHANGE::text), '^^') 
            , '||', IFNULL(TRIM(NUMBER_OF_CONTAINERS::text), '^^') 
            , '||', IFNULL(TRIM(LOCATOR_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_ACTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORGANIZATION_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(EMPLOYEE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(REASON_ID::text), '^^') 
            , '||', IFNULL(TRIM(OWNING_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ACTUAL_COST::text), '^^') 
            , '||', IFNULL(TRIM(PLANNING_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(REPETITIVE_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSPORTATION_COST::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(MATERIAL_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_TRANSACTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PM_COST_COLLECTED::text), '^^') 
            , '||', IFNULL(TRIM(RESERVATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOGICAL_TRANSACTION::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_TO_LOCATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE15::text), '^^') 
            , '||', IFNULL(TRIM(COMMON_BOM_SEQ_ID::text), '^^') 
            , '||', IFNULL(TRIM(PRIOR_COSTED_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(INTRANSIT_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(COMPLETION_TRANSACTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(LOGICAL_TRX_TYPE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(INTERCOMPANY_CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(PLANNING_TP_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(COGS_RECOGNITION_PERCENT::text), '^^') 
            , '||', IFNULL(TRIM(MASTER_SCHEDULE_UPDATE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(QA_COLLECTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(PERIODIC_PRIMARY_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(TRX_SOURCE_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CONVERSION_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(OPERATION_SEQ_NUM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE7::text), '^^') 
            , '||', IFNULL(TRIM(PICK_RULE_ID::text), '^^') 
            , '||', IFNULL(TRIM(INVOICED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(CONTENT_LPN_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_LPN_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_SOURCE_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORIGINAL_TRANSACTION_TEMP_ID::text), '^^') 
            , '||', IFNULL(TRIM(OVERCOMPLETION_TRANSACTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE12::text), '^^') 
            , '||', IFNULL(TRIM(SHORTAGE_PROCESS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(XFR_OWNING_ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE11::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DEPARTMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(COST_UPDATE_ID::text), '^^') 
            , '||', IFNULL(TRIM(PICK_SLIP_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(RCV_TRANSACTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ENCUMBRANCE_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(COST_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(MVT_STAT_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(OVERCOMPLETION_PRIMARY_QTY::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(OUTSIDE_PROCESSING_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(DISTRIBUTION_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(NEW_COST::text), '^^') 
            , '||', IFNULL(TRIM(FLOW_SCHEDULE::text), '^^') 
            , '||', IFNULL(TRIM(TRX_SOURCE_DELIVERY_ID::text), '^^') 
            , '||', IFNULL(TRIM(MOVE_TRANSACTION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ACCT_PERIOD_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_MODE::text), '^^') 
            , '||', IFNULL(TRIM(SHIPMENT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(VENDOR_LOT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_COST::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE9::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(FINAL_COMPLETION_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TO_TASK_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_COST::text), '^^') 
            , '||', IFNULL(TRIM(FOB_POINT::text), '^^') 
            , '||', IFNULL(TRIM(REVISION::text), '^^') 
            , '||', IFNULL(TRIM(SUBINVENTORY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE13::text), '^^') 
            , '||', IFNULL(TRIM(LOGICAL_TRANSACTIONS_CREATED::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CONVERSION_RATE::text), '^^') 
            , '||', IFNULL(TRIM(QUANTITY_ADJUSTED::text), '^^') 
            , '||', IFNULL(TRIM(PUT_AWAY_STRATEGY_ID::text), '^^') 
            , '||', IFNULL(TRIM(ENCUMBRANCE_AMOUNT::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_PROJECT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_GROUP_SEQ::text), '^^') 
            , '||', IFNULL(TRIM(TASK_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(MATERIAL_EXPENSE_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_SOURCE_NAME::text), '^^') 
            , '||', IFNULL(TRIM(XML_DOCUMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_PERCENTAGE::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE8::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(MOVEMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(PICK_SLIP_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PHYSICAL_ADJUSTMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(TASK_ID::text), '^^') 
            , '||', IFNULL(TRIM(WAYBILL_AIRBILL::text), '^^') 
            , '||', IFNULL(TRIM(RMA_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_TASK_ID::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_COST_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(TRANSACTION_TYPE_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(COST_CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(TRANSFER_PRIOR_COSTED_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(INTERCOMPANY_PRICING_OPTION::text), '^^') 
            , '||', IFNULL(TRIM(CURRENCY_CONVERSION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APPLICATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORG_COST_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(SECONDARY_TRANSACTION_QUANTITY::text), '^^') 
            , '||', IFNULL(TRIM(RESOURCE_ACCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(TRX_FLOW_HEADER_ID::text), '^^') 
            , '||', IFNULL(TRIM(COSTED_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(PM_COST_COLLECTOR_GROUP_ID::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT

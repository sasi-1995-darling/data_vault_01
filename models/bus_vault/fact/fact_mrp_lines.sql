---- SRC LAYER ----
WITH
SRC_L              as ( SELECT * FROM {{ ref('pb_mrp_lines') }} as SRC  )

/*
SRC_L              as ( SELECT * FROM RAW_VAULT.PB_MRP_LINES )
*/
---- LOGIC LAYER ----

, LOGIC_L as (
    SELECT
        MRP_LINES_LHK 									as MRP_LINES_KEY
        ,MATERIAL_COMMITMENT_SEQUENCE_ID::INTEGER	 	as MATERIAL_COMMITMENT_SEQUENCE_INT
        ,MATERIAL_COMMITMENT_SOURCE_BKCC 				as MATERIAL_COMMITMENT_SOURCE_BKCC
        ,PLANT_HK 										as PLANT_KEY
        ,ITEM_HK 										as ITEM_KEY
        ,SUPPLIER_HK 									as SUPPLIER_KEY
        ,CUSTOMER_HK 									as CUSTOMER_KEY
        ,ELEMNT_DATA_HK 								as ELEMENT_KEY
        ,UOM_HK                                         as UOM_KEY
        ,PLANT_BK 										as PLANT_BK
        ,ITEM_BK 										as ITEM_BK
        ,MATERIAL_COMMITMENT_BK_TEXT 					as MATERIAL_COMMITMENT_BK_TEXT
        ,SUPPLIER_COUNTRY_CODE     						as COUNTRY_CODE_KEY
        ,SALESORGANIZATION_CODE   					    as SALES_ORGANIZATION_CODE_KEY
        ,DISTRIBUTIONCHANNEL_CODE 						as DISTRIBUTION_CHANNEL_CODE_KEY
        ,PURCHASINGGROUP_CODE 							as PURCHASING_CODE_KEY
        ,MRP_ELEMENT_INDICATOR 			                as MRP_ELEMENT_INDICATOR
        ,PLAN_RUN_DATE__YYYYMMDD 						as PLAN_RUN_DATE_KEY
        ,MATERIAL_COMMITMENT_FORECAST_DATE__YYYYMMDD 	as MATERIAL_COMMITMENT_FORECAST_DATE__YYYYMMDD
        ,AVAILABILITY_DATE__YYYYMMDD 		            as MATERIAL_COMMITMENT_DUE_DATE__YYYYMMDD
        ,FINISH_DATE__YYYYMMDD 		                    as MATERIAL_COMMITMENT_FINISH_DATE__YYYYMMDD
        ,MATERIAL_COMMITMENT_ACTUAL_SHIP_DATE__YYYYMMDD as MATERIAL_COMMITMENT_ACTUAL_SHIP_DATE__YYYYMMDD
        ,ORDER_PLANNED_QUANTITY 						as MATERIAL_COMMITMENT_ORDER_PLANNED_QUANTITY
        ,MATERIAL_COMMITMENT_QUANTITY_RATE 			    as MATERIAL_COMMITMENT_QUANTITY_RATE
        ,MATERIAL_COMMITMENT_DEMAND_QUANTITY 			as MATERIAL_COMMITMENT_DEMAND_QUANTITY
        ,MATERIAL_COMMITMENT_SUPPLY_QUANTITY 			as MATERIAL_COMMITMENT_SUPPLY_QUANTITY
        ,MATERIAL_LIST_PRICE 							as MATERIAL_COMMITMENT_LIST_PRICE
        ,MATERIAL_AVERAGE_UNIT_PRICE 					as MATERIAL_COMMITMENT_AVERAGE_UNIT_PRICE
        ,LIST_PRICE_RAW 								as LIST_PRICE_RAW
        ,BASE_UNITOFMEASURE_CODE 						as BASE_UNITOFMEASURE_CODE
        ,PURCHASINGGROUP_DESCRIPTION 					as PURCHASINGGROUP_DESCRIPTION
        ,PLANNING_SCENARIO              as PLANNING_SCENARIO
        ,AVAILABILITY_DATE__YYYYMMDD    as AVAILABILITY_DATE__YYYYMMDD
        ,MRP_LIST_ITEM                  as MRP_LIST_ITEM
        ,GLOBAL_REQUEST_ID              as GLOBAL_REQUEST_ID
        ,RECEIPT_ISSUE_INDICATOR        as RECEIPT_ISSUE_INDICATOR
        ,AVAILABILITY_FLAG              as AVAILABILITY_FLAG
        ,FINISH_DATE__YYYYMMDD          as FINISH_DATE__YYYYMMDD
        ,MRP_ELEMENT                    as MRP_ELEMENT
        ,EXCEPTION_MESSAGE_KEY          as EXCEPTION_MESSAGE_KEY
        ,EXCEPTION_MESSAGE              as EXCEPTION_MESSAGE
        ,RESCHEDULING_DATE__YYYYMMDD    as RESCHEDULING_DATE__YYYYMMDD
        ,RECEIPT_REQUIREMENT_QTY        as RECEIPT_REQUIREMENT_QTY
        ,AVAILABLE_QUANTITY             as AVAILABLE_QUANTITY
        ,TOTAL_AVAILABLE_QUANTITY       as TOTAL_AVAILABLE_QUANTITY
        ,AVAILABLE_TO_PROMISE_QUANTITY  as AVAILABLE_TO_PROMISE_QUANTITY
        ,PRODUCTION_VERSION             as PRODUCTION_VERSION
        ,STORAGE_LOCATION               as STORAGE_LOCATION
        ,MRP_RUN_DATE__YYYYMMDD         as MRP_RUN_DATE__YYYYMMDD
        ,MRP_RUN_TIME__HHMMSS           as MRP_RUN_TIME__HHMMSS
        ,JOB_DATE__YYYYMMDD             as JOB_DATE__YYYYMMDD
        ,JOB_TIME__HHMMSS               as JOB_TIME__HHMMSS
        ,STOCK_IN_TRANSIT               as STOCK_IN_TRANSIT
        ,PLANNING_SEGMENT_NUMBER        as PLANNING_SEGMENT_NUMBER
        ,SPECIAL_PROCUREMENT_TYPE       as SPECIAL_PROCUREMENT_TYPE
        ,REC_SRC
        ,SNAPSHOT_DTS
    FROM SRC_L
)
---- RENAME LAYER ----

, RENAME_L as (
    SELECT
              MRP_LINES_KEY
             ,MATERIAL_COMMITMENT_SEQUENCE_INT
             ,PLANT_KEY
             ,ITEM_KEY
             ,SUPPLIER_KEY
             ,CUSTOMER_KEY
             ,ELEMENT_KEY
             ,UOM_KEY
             ,PLANT_BK
             ,ITEM_BK
             ,MATERIAL_COMMITMENT_BK_TEXT
             ,COUNTRY_CODE_KEY
             ,SALES_ORGANIZATION_CODE_KEY
             ,DISTRIBUTION_CHANNEL_CODE_KEY
             ,PURCHASING_CODE_KEY
             ,PLAN_RUN_DATE_KEY
             ,MATERIAL_COMMITMENT_FORECAST_DATE__YYYYMMDD
             ,MATERIAL_COMMITMENT_DUE_DATE__YYYYMMDD
             ,MATERIAL_COMMITMENT_FINISH_DATE__YYYYMMDD
             ,MATERIAL_COMMITMENT_ACTUAL_SHIP_DATE__YYYYMMDD
             ,MATERIAL_COMMITMENT_ORDER_PLANNED_QUANTITY
             ,MATERIAL_COMMITMENT_QUANTITY_RATE
             ,MATERIAL_COMMITMENT_DEMAND_QUANTITY
             ,MATERIAL_COMMITMENT_SUPPLY_QUANTITY
             ,MATERIAL_COMMITMENT_LIST_PRICE
             ,MATERIAL_COMMITMENT_AVERAGE_UNIT_PRICE
             ,LIST_PRICE_RAW
             ,BASE_UNITOFMEASURE_CODE
             ,PURCHASINGGROUP_DESCRIPTION
             ,MATERIAL_COMMITMENT_SOURCE_BKCC
             ,Planning_Scenario
             ,Availability_Date__YYYYMMDD
             ,MRP_List_Item
             ,Global_Request_ID
             ,MRP_Element_Indicator
             ,Receipt_Issue_Indicator
             ,Availability_Flag
             ,Finish_Date__YYYYMMDD
             ,MRP_Element
             ,Exception_Message_Key
             ,Exception_Message
             ,Rescheduling_Date__YYYYMMDD
             ,Receipt_Requirement_Qty
             ,Available_Quantity
             ,Total_Available_Quantity
             ,Available_To_Promise_Quantity
             ,Production_Version
             ,Storage_Location
             ,MRP_Run_Date__YYYYMMDD
             ,MRP_Run_Time__HHMMSS
             ,Job_Date__YYYYMMDD
             ,Job_Time__HHMMSS
             ,Stock_in_Transit
             ,Planning_Segment_Number
             ,Special_Procurement_Type
             ,REC_SRC
             ,SNAPSHOT_DTS
    FROM LOGIC_L
)
---- FILTER LAYER ----

, FILTER_L as (
    SELECT *
    FROM RENAME_L
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_L
)

---- FINAL LAYER ----
SELECT
             MRP_LINES_KEY
             ,MATERIAL_COMMITMENT_SEQUENCE_INT
             ,PLANT_KEY
             ,ITEM_KEY
             ,SUPPLIER_KEY
             ,CUSTOMER_KEY
             ,ELEMENT_KEY
             ,UOM_KEY
             ,PLANT_BK
             ,ITEM_BK
             ,MATERIAL_COMMITMENT_BK_TEXT
             ,COUNTRY_CODE_KEY
             ,SALES_ORGANIZATION_CODE_KEY
             ,DISTRIBUTION_CHANNEL_CODE_KEY
             ,PURCHASING_CODE_KEY
             ,PLAN_RUN_DATE_KEY
             ,MATERIAL_COMMITMENT_FORECAST_DATE__YYYYMMDD
             ,MATERIAL_COMMITMENT_DUE_DATE__YYYYMMDD
             ,MATERIAL_COMMITMENT_FINISH_DATE__YYYYMMDD
             ,MATERIAL_COMMITMENT_ACTUAL_SHIP_DATE__YYYYMMDD
             ,MATERIAL_COMMITMENT_ORDER_PLANNED_QUANTITY
             ,MATERIAL_COMMITMENT_QUANTITY_RATE
             ,MATERIAL_COMMITMENT_DEMAND_QUANTITY
             ,MATERIAL_COMMITMENT_SUPPLY_QUANTITY
             ,MATERIAL_COMMITMENT_LIST_PRICE
             ,MATERIAL_COMMITMENT_AVERAGE_UNIT_PRICE
             ,LIST_PRICE_RAW
             ,BASE_UNITOFMEASURE_CODE
             ,PURCHASINGGROUP_DESCRIPTION
             ,MATERIAL_COMMITMENT_SOURCE_BKCC
             ,Planning_Scenario
             ,Availability_Date__YYYYMMDD
             ,MRP_List_Item
             ,Global_Request_ID
             ,MRP_Element_Indicator
             ,Receipt_Issue_Indicator
             ,Availability_Flag
             ,Finish_Date__YYYYMMDD
             ,MRP_Element
             ,Exception_Message_Key
             ,Exception_Message
             ,Rescheduling_Date__YYYYMMDD
             ,Receipt_Requirement_Qty
             ,Available_Quantity
             ,Total_Available_Quantity
             ,Available_To_Promise_Quantity
             ,Production_Version
             ,Storage_Location
             ,MRP_Run_Date__YYYYMMDD
             ,MRP_Run_Time__HHMMSS
             ,Job_Date__YYYYMMDD
             ,Job_Time__HHMMSS
             ,Stock_in_Transit
             ,Planning_Segment_Number
             ,Special_Procurement_Type
             ,REC_SRC
             ,SNAPSHOT_DTS
FROM JOIN_RESULT


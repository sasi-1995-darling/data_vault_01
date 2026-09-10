WITH
SRC_MrpL           as ( SELECT MRP_LINES_LHK, PLAN_PLANT2, AVAIL_DATE, ELEMNT_DATA, FINISH_DATE, MRP_ELEMNT, MRP_ELEMENT_IND, PLNGSEGNO,
                        REC_REQD_QTY, PLUS_MINUS, BASE_UOM, REC_SRC, PLAN_SCENARIO, MRP_ITEM, GLREQUEST, AVAILABLE, EXCMSGKEY, EXCMESSAGE,
                        RESCHED_DATE, AVAIL_QTY1, AVAIL_QTY2, ATP_QTY, PROD_VERSION, STORAGE_LOC, MRP_DATE, MRP_TIME, JOB_DATE, JOB_TIME,
                        STOCK_IN_TRANSIT, EXCLUDE, EXT_SPPROCTYPE
                        FROM  {{ ref('lmsat_mrp_lines__winn_sap') }} 
                        WHERE AVAILABLE = 'X'
                         AND EXCLUDE != 'X'
                        ) ,
SRC_lpl            as ( SELECT * FROM {{ ref('lnk_mrp_lines') }} as SRC ),
SRC_hub_item       as ( SELECT * FROM {{ ref('hub_item_v1') }}  as SRC ),
SRC_hub_plant      as ( SELECT * FROM {{ ref('hub_plant_v1') }} as SRC ),
SRC_hub_cust       as ( SELECT * FROM  {{ ref('hub_customer_v1') }} as SRC),
SRC_hub_sup        as ( SELECT * FROM {{ ref('hub_supplier_v2') }} as SRC ),
SRC_sh             as ( SELECT ZZRSD, VKORG, VTWEG, VBELN, WAERK, NETWR FROM {{ ref('sat_order_header__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by Vbeln order by load_dts DESC) ),
SRC_gp             as ( SELECT * FROM  {{ ref('ref_xref_gross_price') }} as SRC  
                        WHERE  GROSS_AUP IS NOT NULL),
SRC_spp            as ( SELECT  NAME1, lifnr, SUPPLIER_HK FROM {{ ref('sat_supplier__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by LIFNR order by load_dts DESC) ),
SRC_spp2           as ( SELECT  ZZRPT_COUNTRY, lifnr, SUPPLIER_HK FROM {{ ref('sat_supplier__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by LIFNR order by load_dts DESC) ),
SRC_scust          as ( SELECT  NAME1, KUNNR, CUSTOMER_HK FROM {{ ref('sat_customer__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by KUNNR order by load_dts DESC) ),
SRC_po             as ( SELECT  EKNAM, PURCHASING_ORG_HK FROM  {{ ref('sat_purchasing_org__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by EKGRP order by load_dts DESC) ),
SRC_lpip           as ( SELECT  * FROM  {{ ref('lnk_plant_item_purchasing_org') }} as SRC                           
                        qualify 1= row_number() over(partition by plant_hk, item_hk order by load_dts DESC)),
SRC_hub_po         as ( SELECT * FROM {{ ref('hub_purchasing_org') }} as SRC ),
SRC_curr           as ( SELECT FROM_CURRENCY, EXCHANGE_RATE FROM {{ ref('ref_sat_currency_rates__winn_sap') }} as SRC 
                        WHERE TO_CURRENCY = 'USD'
                          AND EXCHANGE_RATE_TYPE = 'CMRA'
                        qualify ROW_NUMBER() OVER (PARTITION BY FROM_CURRENCY ORDER BY CONVERSION_DATE DESC) = 1)


/*
SRC_MrpL           as ( SELECT * FROM RAW_VAULT.lmsat_mrp_lines__winn_sap )
, SRC_lpl            as ( SELECT * FROM RAW_VAULT.lnk_mrp_lines )
, SRC_hub_item       as ( SELECT * FROM RAW_VAULT.hub_item_v1 )
, SRC_hub_plant      as ( SELECT * FROM RAW_VAULT.hub_plant_v1 )
, SRC_sh             as ( SELECT * FROM RAW_VAULT.sat_order_header__winn_sap )
, SRC_spp            as ( SELECT * FROM RAW_VAULT.sat_supplier__winn_sap )
, SRC_spp2           as ( SELECT * FROM RAW_VAULT.sat_supplier__winn_sap )
, SRC_scust          as ( SELECT * FROM RAW_VAULT.sat_customer__winn_sap )
, SRC_po             as ( SELECT * FROM RAW_VAULT.sat_purchasing_org__winn_sap )
, SRC_lpip           as ( SELECT * FROM raw_vault.lnk_plant_item_purchasing_org )
, SRC_hub_po           as ( SELECT * FROM raw_vault.hub_purchasing_org )
*/
---- LOGIC LAYER ----

, LOGIC_MrpL as (
SELECT
        MRP_LINES_LHK
      , plan_plant2                                                  as                    PLANNING_PLANT
      , to_date(AVAIL_DATE,'YYYYMMDD')                               as                    FORECAST_DATETIME
      , CAST(CURRENT_DATE AS DATE)                                   as                    Plan_Run_Date
      , row_number() over(order by 1)                                as                    Material_Commitment_Sequence_ID
      , TRIM(SPLIT_PART(ELEMNT_DATA, '/', 1), '"')                   as                    ORDER_HEADER_ID
      , AVAIL_DATE                                                   as                    Availability_Date
      , FINISH_DATE                                                  as                    Finish_Date
      , MRP_ELEMNT                                                   as                    MRP_Element
      , ELEMNT_DATA                                                  as                    Material_Commitment_BK_Text
      , MRP_ELEMENT_IND                                              as                    MRP_Element_Indicator
      , IFF(MRP_ELEMNT ILIKE 'VSF%', 'External Demand - Forecast', IFF(MRP_ELEMNT ILIKE 'LSF%', 'Safety Stock',
            IFF(MRP_ELEMNT = 'LSF /O8_SHPCANC', 'Demand', '' )))     as                    Material_Commitment_Category
      , IFF(PLNGSEGNO IS NOT NULL AND PLNGSEGNO != '' AND MRP_ELEMNT like '%SubReq%', 0, REC_REQD_QTY) as Order_Planned_Quantity
      , IFF(PLUS_MINUS = '-', REC_REQD_QTY , 0)                      as                    Material_Commitment_Demand_Quantity
      , IFF(PLUS_MINUS = '+', REC_REQD_QTY , 0)                      as                    Material_Commitment_Supply_Quantity
      , case when PLUS_MINUS = '-' then  -Material_Commitment_Demand_Quantity
             when PLUS_MINUS = '+' then  Material_Commitment_Supply_Quantity
             when PLUS_MINUS = 'B' then  REC_REQD_QTY end             as                    Material_Commitment_Quantity_rate
      , BASE_UOM                                                     as                    Base_UnitofMeasure_Code
      , REC_SRC
      , PLAN_SCENARIO                                                as                    Planning_Scenario
      , MRP_ITEM                                                     as                    MRP_List_Item
      , GLREQUEST                                                    as                    Global_Request_ID
      , PLUS_MINUS                                                   as                    Receipt_Issue_Indicator
      , AVAILABLE                                                    as                    Availability_Flag
      , EXCMSGKEY                                                    as                    Exception_Message_Key
      , EXCMESSAGE                                                   as                    Exception_Message
      , RESCHED_DATE                                                 as                    Rescheduling_Date
      , REC_REQD_QTY                                                 as                    Receipt_Requirement_Qty
      , AVAIL_QTY1                                                   as                    Available_Quantity
      , AVAIL_QTY2                                                   as                    Total_Available_Quantity
      , ATP_QTY                                                      as                    Available_To_Promise_Quantity
      , PROD_VERSION                                                 as                    Production_Version
      , STORAGE_LOC                                                  as                    Storage_Location
      , MRP_DATE                                                     as                    MRP_Run_Date
      , MRP_TIME                                                     as                    MRP_Run_Time
      , JOB_DATE                                                     as                    Job_Date
      , JOB_TIME                                                     as                    Job_Time
      , STOCK_IN_TRANSIT                                             as                    Stock_in_Transit
      , PLNGSEGNO                                                    as                    Planning_Segment_Number
      , EXT_SPPROCTYPE                                               as                    Special_Procurement_Type
    FROM SRC_MrpL
)

, LOGIC_lpl as (
    SELECT
          MRP_LINES_LHK                                              as                     lpl_MRP_LINES_LHK  
        , item_hk
        , plant_hk
        , customer_hk
        , supplier_hk
        , elemnt_data_hk
        , uom_hk
    FROM SRC_lpl
)

, LOGIC_gp as (
    SELECT
          ITEM_ID                                                    as                     MATERIAL
        , AVG(GROSS_AUP)                                             as                     BV_AUP
    FROM SRC_gp
    GROUP BY
        ITEM_ID
)

, LOGIC_hub_item as (
    SELECT
          item_bk
        , item_hk                                                    as                     hub_item_hk
    FROM SRC_hub_item
)

, LOGIC_hub_plant as (
    SELECT
          plant_bk
        , plant_hk                                                   as                     hub_plant_hk
        , BKCC                                                       as                     Material_Commitment_Source_BKCC
    FROM SRC_hub_plant
)
, LOGIC_hub_cust as (
    SELECT
          customer_bk
        , customer_hk                                               as                      hub_customer_hk
    FROM SRC_hub_cust
)

, LOGIC_hub_sup as (
    SELECT
          Supplier_bk
        , supplier_hk                                               as                      hub_supplier_hk
    FROM SRC_hub_sup
)
, LOGIC_sh as (
    SELECT
        ZZRSD                                                        as                     Material_Commitment_Actual_Ship_Date
      , VKORG                                                        as                     Salesorganization_Code
      , VTWEG                                                        as                     Distributionchannel_Code
      , VBELN                                                        as                     ORDER_HEADER_ID
      , WAERK                                                        as                     CURRENCY
      , NETWR                                                        as                     NET_VALUE
    FROM SRC_sh
)

, LOGIC_spp as (
    SELECT
          NAME1                                                      as                     Supplier_Name
        , lifnr                                                      as                     vendor_no
        , SUPPLIER_HK                                                as                     spp_SUPPLIER_HK
    FROM SRC_spp
)

, LOGIC_spp2 as (
    SELECT
          ZZRPT_COUNTRY                                              as                     Supplier_Country_Code
        , lifnr                                                      as                     vendor_no
        , SUPPLIER_HK                                                as                     spp2_SUPPLIER_HK
    FROM SRC_spp2
)

, LOGIC_scust as (
    SELECT
        NAME1                                                        as                     Customer_Name
        , KUNNR                                                      as                     customer
        , CUSTOMER_HK                                                as                     scust_hub_customer_hk
    FROM SRC_scust
)

, LOGIC_po as (
    SELECT
          EKNAM                                                      as                     PurchasingGroup_Description        
        , PURCHASING_ORG_HK                       
    FROM SRC_po
)

, LOGIC_lpip as (
    SELECT
        PLANT_HK                                                       as                     lpip_PLANT_HK
      , ITEM_HK                                                        as                     lpip_ITEM_HK
	  , PURCHASING_ORG_HK                                              as                     lpip_PURCHASING_ORG_HK      
    FROM SRC_lpip
)

, LOGIC_hub_po as (
    SELECT          
          PURCHASING_ORG_BK                                            as                     PurchasingGroup_Code
        , PURCHASING_ORG_HK                                            as                     hub_PURCHASING_ORG_HK                     
    FROM SRC_hub_po
)

, LOGIC_curr as (
    SELECT
        FROM_CURRENCY                                                as                     CURRENCY
      , EXCHANGE_RATE
    FROM SRC_curr
    UNION ALL
    SELECT
        'USD'                                                        as                     FROM_CURRENCY
      , 1.0 AS EXCHANGE_RATE
)
---- RENAME LAYER ----

, RENAME_MrpL as (
    SELECT
        MRP_LINES_LHK
      , PLANNING_PLANT
      , ORDER_HEADER_ID
      , FORECAST_DATETIME
      , Plan_Run_Date
      , Material_Commitment_Sequence_ID
      , Material_Commitment_BK_Text
      , Material_Commitment_Category
      , Order_Planned_Quantity
      , Material_Commitment_Demand_Quantity
      , Material_Commitment_Supply_Quantity
      , Material_Commitment_Quantity_rate
      , Base_UnitofMeasure_Code
      , REC_SRC
      , Planning_Scenario
      , Availability_Date
      , MRP_List_Item
      , Global_Request_ID
      , MRP_Element_Indicator
      , Receipt_Issue_Indicator
      , Availability_Flag
      , Finish_Date
      , MRP_Element
      , Exception_Message_Key
      , Exception_Message
      , Rescheduling_Date
      , Receipt_Requirement_Qty
      , Available_Quantity
      , Total_Available_Quantity
      , Available_To_Promise_Quantity
      , Production_Version
      , Storage_Location
      , MRP_Run_Date
      , MRP_Run_Time
      , Job_Date
      , Job_Time
      , Stock_in_Transit
      , Planning_Segment_Number
      , Special_Procurement_Type
    FROM LOGIC_MrpL
)

, RENAME_lpl as (
    SELECT
        lpl_MRP_LINES_LHK
      , item_hk
      , plant_hk
      , customer_hk
      , supplier_hk
      , elemnt_data_hk
      , uom_hk
    FROM LOGIC_lpl
)
, RENAME_gp as (
    SELECT
        BV_AUP
      , material
    FROM LOGIC_gp
)

, RENAME_hub_plant as (
    SELECT
        Plant_BK
      , Hub_Plant_HK
      , Material_Commitment_Source_BKCC
    FROM LOGIC_hub_plant
)

, RENAME_hub_item as (
    SELECT
        Item_BK
      , Hub_Item_hk
    FROM LOGIC_hub_item
)
, RENAME_hub_cust as (
    SELECT
        customer_BK
      , Hub_customer_HK
    FROM LOGIC_hub_cust
)

, RENAME_hub_sup as (
    SELECT
        supplier_BK
      , Hub_supplier_hk
    FROM LOGIC_hub_sup
)

, RENAME_sh as (
    SELECT
        Material_Commitment_Actual_Ship_Date
      , Salesorganization_Code
      , Distributionchannel_Code
      , ORDER_HEADER_ID
      , CURRENCY
      , NET_VALUE
    FROM LOGIC_sh
)

, RENAME_cust as (
    SELECT
        Customer_Name
      , customer
      , scust_hub_customer_hk
    FROM LOGIC_scust
)

, RENAME_spp as (
    SELECT
        Supplier_Name
      , vendor_no
      , spp_SUPPLIER_HK
    FROM LOGIC_spp
)

, RENAME_spp2 as (
    SELECT
        Supplier_Country_Code
      , vendor_no
      , spp2_SUPPLIER_HK
    FROM LOGIC_spp2
)

, RENAME_po as (
    SELECT
        PurchasingGroup_Description
      , PURCHASING_ORG_HK
    FROM LOGIC_po
)

, RENAME_lpip as (
    SELECT
        lpip_PLANT_HK
      , lpip_ITEM_HK
      , lpip_PURCHASING_ORG_HK
    FROM LOGIC_lpip
)

, RENAME_hub_po as (
    SELECT
        PurchasingGroup_Code
      , hub_PURCHASING_ORG_HK
    FROM LOGIC_hub_po
)

, RENAME_curr as (
    SELECT
        CURRENCY
      , EXCHANGE_RATE
    FROM logic_curr
)
---- FILTER LAYER ----

, FILTER_MrpL as (
    SELECT *
    FROM RENAME_MrpL
)
, FILTER_Curr as (
    SELECT *
    FROM RENAME_curr
)
, FILTER_gp as (
    SELECT *
    FROM RENAME_gp
)
, FILTER_lpl as (
    SELECT *
    FROM RENAME_lpl
)

, FILTER_hub_item as (
    SELECT *
    FROM RENAME_hub_item
)

, FILTER_hub_plant as (
    SELECT *
    FROM RENAME_hub_plant
)
, FILTER_hub_cust as (
    SELECT *
    FROM RENAME_hub_cust
)

, FILTER_hub_sup as (
    SELECT *
    FROM RENAME_hub_sup
)

, FILTER_sh as (
    SELECT *
    FROM RENAME_sh
)

, FILTER_spp as (
    SELECT *
    FROM RENAME_spp
)

, FILTER_spp2 as (
    SELECT *
    FROM RENAME_spp2
)

, FILTER_scust as (
    SELECT *
    FROM RENAME_cust
)

, FILTER_po as (
    SELECT *
    FROM RENAME_po
)

, FILTER_lpip as (
    SELECT *
    FROM RENAME_lpip
)

, FILTER_hub_po as (
    SELECT *
    FROM RENAME_hub_po
)

-- ---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT
     *
     ,IFF(FILTER_sh.CURRENCY IS NOT NULL AND FILTER_Curr.EXCHANGE_RATE IS NOT NULL, FILTER_sh.NET_VALUE * FILTER_Curr.EXCHANGE_RATE, NULL)     AS DOLLAR_VALUE
    FROM FILTER_lpl 
    INNER JOIN FILTER_MrpL
        ON FILTER_MrpL.MRP_LINES_LHK = FILTER_lpl.lpl_MRP_LINES_LHK 
    INNER JOIN FILTER_hub_plant
        ON FILTER_lpl.plant_hk = FILTER_hub_plant.hub_plant_hk
    LEFT JOIN FILTER_hub_item
        ON FILTER_lpl.item_hk = FILTER_hub_item.hub_item_hk     
    LEFT JOIN FILTER_hub_cust
        ON FILTER_lpl.customer_hk = FILTER_hub_cust.hub_customer_hk 
    LEFT JOIN FILTER_gp
        ON FILTER_hub_item.item_bk = FILTER_gp.material 
    LEFT JOIN FILTER_hub_sup
        ON FILTER_lpl.supplier_hk = FILTER_hub_sup.hub_supplier_hk
    LEFT JOIN FILTER_sh
        ON FILTER_MrpL.ORDER_HEADER_ID = FILTER_sh.ORDER_HEADER_ID
    LEFT JOIN FILTER_Curr 
        ON FILTER_sh.CURRENCY = FILTER_Curr.CURRENCY  
    LEFT JOIN FILTER_spp        
        ON FILTER_hub_sup.hub_supplier_hk = FILTER_spp.spp_SUPPLIER_HK
    LEFT JOIN FILTER_spp2        
        ON FILTER_hub_sup.hub_supplier_hk = FILTER_spp2.spp2_SUPPLIER_HK
    LEFT JOIN FILTER_scust        
        ON FILTER_hub_cust.hub_customer_hk = FILTER_scust.scust_hub_customer_hk                
    LEFT JOIN FILTER_lpip
        ON  FILTER_lpip.lpip_PLANT_HK = FILTER_hub_plant.hub_plant_hk 
        AND FILTER_lpip.lpip_ITEM_HK = FILTER_hub_item.hub_item_hk 
    LEFT JOIN FILTER_hub_po
        ON FILTER_hub_po.hub_PURCHASING_ORG_HK = FILTER_lpip.lpip_PURCHASING_ORG_HK
    LEFT JOIN FILTER_po
        ON FILTER_po.PURCHASING_ORG_HK = FILTER_hub_po.hub_PURCHASING_ORG_HK    
)

---- FINAL LAYER ----
SELECT
          CURRENT_TIMESTAMP                                          as SNAPSHOT_DTS
        , 'PB_MRP_LINES'                                             as PB_REC_SRC
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                as PB_LOAD_DTS
        , MRP_LINES_LHK
        , MATERIAL_COMMITMENT_SOURCE_BKCC
        , PLANT_HK
        , PLANT_BK
        , ITEM_HK
        , ITEM_BK
        , SUPPLIER_HK
        , SUPPLIER_BK
        , CUSTOMER_HK
        , CUSTOMER_BK
        , ELEMNT_DATA_HK
        , UOM_HK
        , IFF(MRP_ELEMENT IN ('Order', 'IndReq', 'Deliv.'), -1 * DOLLAR_VALUE / NULLIF(Material_Commitment_Quantity_rate, 0), 0) AS MATERIAL_AVERAGE_UNIT_PRICE
        , IFF(MATERIAL_AVERAGE_UNIT_PRICE IS NOT NULL, MATERIAL_AVERAGE_UNIT_PRICE, BV_AUP) AS LIST_PRICE_RAW
        , IFF(LIST_PRICE_RAW = 'Infinity' OR LIST_PRICE_RAW = '-Infinity' OR LIST_PRICE_RAW = 'NaN', 0, LIST_PRICE_RAW) AS MATERIAL_LIST_PRICE
        , TO_CHAR(PLAN_RUN_DATE, 'YYYYMMDD')::NUMBER                as PLAN_RUN_DATE__YYYYMMDD
        , TO_CHAR(IFF(FORECAST_DATETIME < PLAN_RUN_DATE, PLAN_RUN_DATE, FORECAST_DATETIME),'YYYYMMDD')::NUMBER as MATERIAL_COMMITMENT_FORECAST_DATE__YYYYMMDD
        , MATERIAL_COMMITMENT_SEQUENCE_ID
        , TRY_CAST(AVAILABILITY_DATE as NUMBER)                                 as AVAILABILITY_DATE__YYYYMMDD
        , TRY_CAST(FINISH_DATE as NUMBER)                                 as FINISH_DATE__YYYYMMDD
        , TRY_CAST(MATERIAL_COMMITMENT_ACTUAL_SHIP_DATE as NUMBER)              as MATERIAL_COMMITMENT_ACTUAL_SHIP_DATE__YYYYMMDD
        , MRP_ELEMENT
        , MATERIAL_COMMITMENT_BK_TEXT
        , MRP_ELEMENT_INDICATOR
        , MATERIAL_COMMITMENT_CATEGORY
        , ORDER_PLANNED_QUANTITY
        , MATERIAL_COMMITMENT_DEMAND_QUANTITY
        , MATERIAL_COMMITMENT_SUPPLY_QUANTITY
        , MATERIAL_COMMITMENT_QUANTITY_RATE
        , CUSTOMER_NAME
        , SUPPLIER_NAME
        , SUPPLIER_COUNTRY_CODE
        , BASE_UNITOFMEASURE_CODE
        , SALESORGANIZATION_CODE
        , DISTRIBUTIONCHANNEL_CODE
        , ''                                                         as PLANNER_NAME
        , PURCHASINGGROUP_CODE
        , PURCHASINGGROUP_DESCRIPTION
        , PLANNING_PLANT
        , REC_SRC
        , PLANNING_SCENARIO
        , MRP_LIST_ITEM
        , GLOBAL_REQUEST_ID
        , RECEIPT_ISSUE_INDICATOR
        , AVAILABILITY_FLAG
        , EXCEPTION_MESSAGE_KEY
        , EXCEPTION_MESSAGE
        , TRY_CAST(RESCHEDULING_DATE AS NUMBER)                     as RESCHEDULING_DATE__YYYYMMDD
        , RECEIPT_REQUIREMENT_QTY
        , AVAILABLE_QUANTITY
        , TOTAL_AVAILABLE_QUANTITY
        , AVAILABLE_TO_PROMISE_QUANTITY
        , PRODUCTION_VERSION
        , STORAGE_LOCATION
        , TRY_CAST(MRP_RUN_DATE AS NUMBER)                          as MRP_RUN_DATE__YYYYMMDD
        , TRY_CAST(MRP_RUN_TIME AS NUMBER)                          as MRP_RUN_TIME__HHMMSS
        , TRY_CAST(JOB_DATE AS NUMBER)                              as JOB_DATE__YYYYMMDD
        , TRY_CAST(JOB_TIME AS NUMBER)                              as JOB_TIME__HHMMSS
        , STOCK_IN_TRANSIT
        , PLANNING_SEGMENT_NUMBER
        , SPECIAL_PROCUREMENT_TYPE
FROM JOIN_RESULT
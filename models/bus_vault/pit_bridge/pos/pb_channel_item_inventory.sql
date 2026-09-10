---- SRC LAYER ----
WITH
SRC_lnk as ( 
    SELECT 
         CHANNEL_ITEM_INVENTORY_LHK
        ,ITEM_HK
        ,STORE_HK
        ,REC_SRC 
    FROM {{ ref('lnk_channel_item_inventory') }} 
),
SRC_hub_item as ( 
    SELECT 
         ITEM_BK
        ,ITEM_HK 
    FROM {{ ref('hub_item_v1') }} 
),
SRC_hub_store as ( 
    SELECT 
         STORE_BK
        ,STORE_HK
        ,BKCC 
    FROM {{ ref('hub_store') }} 
),
SRC_sat_vc as ( 
    SELECT 
         CHANNEL_ITEM_INVENTORY_LHK
        ,ASIN
        ,report_end_date
        ,aged_90days_sellable_invamt
        ,aged_90days_sellable_invcurrcd
        ,aged_90days_sellable_invunits
        ,avg_vendor_leadtime_days
        ,net_received_inv_amt
        ,net_received_inv_currcd
        ,net_received_inv_units
        ,open_po_units
        ,unfilled_cust_ordrd_units
        ,sellable_oh_inv_amt
        ,sellable_oh_inv_units
        ,sellable_oh_inv_currcode
        ,unhealthy_inv_amt
        ,unhealthy_inv_units
        ,unhealthy_inv_currcode
        ,unsellable_oh_inv_amt
        ,unsellable_oh_inv_units
        ,unsellable_oh_inv_currcode
        ,PSA_DELETE_IND
        ,load_dts
    FROM {{ ref('lsat_channel_item_inventory_vc__amazon') }} 
    where report_end_date between '2023-01-01' and '2025-02-10' and vendorcentral_account = 'Moen Inc'
    qualify 1 = row_number() over(partition by CHANNEL_ITEM_INVENTORY_LHK order by load_dts DESC) 
),
SRC_sat_anaheim as ( 
    SELECT 
         CHANNEL_ITEM_INVENTORY_LHK
        ,asin
        ,end_date
        ,aged_90_plus_days_sellable_inventory_cost_amount
        ,aged_90_plus_days_sellable_inventory_cost_currency_code
        ,aged_90_plus_days_sellable_inventory_units
        ,average_vendor_lead_time_days
        ,net_received_inventory_cost_amount
        ,net_received_inventory_cost_currency_code
        ,net_received_inventory_units
        ,open_purchase_order_units
        ,unfilled_customer_ordered_units
        ,sellable_on_hand_inventory_cost_amount
        ,sellable_on_hand_inventory_units
        ,sellable_on_hand_inventory_cost_currency_code
        ,unhealthy_inventory_cost_amount
        ,unhealthy_inventory_units
        ,unhealthy_inventory_cost_currency_code
        ,unsellable_on_hand_inventory_cost_amount
        ,unsellable_on_hand_inventory_units
        ,unsellable_on_hand_inventory_cost_currency_code
        ,PSA_DELETE_IND
        ,load_dts
    FROM {{ ref('lsat_channel_item_inventory_vc__amazon_moen_anaheim') }} 
    where end_date >= '2025-02-11'
    qualify 1 = row_number() over(partition by CHANNEL_ITEM_INVENTORY_LHK order by load_dts DESC) 
),
SRC_sat_inc as ( 
    SELECT 
         CHANNEL_ITEM_INVENTORY_LHK
        ,asin
        ,end_date
        ,aged_90_plus_days_sellable_inventory_cost_amount
        ,aged_90_plus_days_sellable_inventory_cost_currency_code
        ,aged_90_plus_days_sellable_inventory_units
        ,average_vendor_lead_time_days
        ,net_received_inventory_cost_amount
        ,net_received_inventory_cost_currency_code
        ,net_received_inventory_units
        ,open_purchase_order_units
        ,unfilled_customer_ordered_units
        ,sellable_on_hand_inventory_cost_amount
        ,sellable_on_hand_inventory_units
        ,sellable_on_hand_inventory_cost_currency_code
        ,unhealthy_inventory_cost_amount
        ,unhealthy_inventory_units
        ,unhealthy_inventory_cost_currency_code
        ,unsellable_on_hand_inventory_cost_amount
        ,unsellable_on_hand_inventory_units
        ,unsellable_on_hand_inventory_cost_currency_code
        ,PSA_DELETE_IND
        ,load_dts
    FROM {{ ref('lsat_channel_item_inventory_vc__amazon_moen_inc') }} 
    where end_date >= '2025-02-11'
    qualify 1 = row_number() over(partition by CHANNEL_ITEM_INVENTORY_LHK order by load_dts DESC) 
)

---- LOGIC LAYER ----

, LOGIC_lnk as (
    SELECT
         CHANNEL_ITEM_INVENTORY_LHK
        ,ITEM_HK
        ,STORE_HK
        ,REC_SRC
        ,'PB_CHANNEL_ITEM_INVENTORY' as PB_REC_SRC
        ,CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP()) as PB_LOAD_DTS
    FROM SRC_lnk
)

, LOGIC_hub_item as (
    SELECT 
         ITEM_HK as hub_ITEM_HK
        ,ITEM_BK 
    FROM SRC_hub_item
)

, LOGIC_hub_store as (
    SELECT 
         STORE_HK as hub_STORE_HK
        ,STORE_BK
        ,BKCC 
    FROM SRC_hub_store
)

, LOGIC_sat_vc as (
    SELECT
         CHANNEL_ITEM_INVENTORY_LHK as LNK_HK
        ,ASIN
        ,report_end_date as REPORT_DATE
        ,aged_90days_sellable_invamt as AGED_90_AMT
        ,aged_90days_sellable_invcurrcd as AGED_90_CURR
        ,aged_90days_sellable_invunits as AGED_90_UNITS
        ,avg_vendor_leadtime_days as LEAD_TIME
        ,net_received_inv_amt as REC_AMT
        ,net_received_inv_currcd as REC_CURR
        ,net_received_inv_units as REC_UNITS
        ,open_po_units as OPEN_PO
        ,unfilled_cust_ordrd_units as UNFILLED
        ,sellable_oh_inv_amt as OH_AMT
        ,sellable_oh_inv_units as OH_UNITS
        ,sellable_oh_inv_currcode as OH_CURR
        ,unhealthy_inv_amt as UNHEALTHY_AMT
        ,unhealthy_inv_units as UNHEALTHY_UNITS
        ,unhealthy_inv_currcode as UNHEALTHY_CURR
        ,unsellable_oh_inv_amt as UNSELLABLE_AMT
        ,unsellable_oh_inv_units as UNSELLABLE_UNITS
        ,unsellable_oh_inv_currcode as UNSELLABLE_CURR
        ,PSA_DELETE_IND as DELETE_IND
    FROM SRC_sat_vc
)

, LOGIC_sat_anaheim as (
    SELECT
         CHANNEL_ITEM_INVENTORY_LHK as LNK_HK
        ,asin as ASIN
        ,end_date as REPORT_DATE
        ,aged_90_plus_days_sellable_inventory_cost_amount as AGED_90_AMT
        ,aged_90_plus_days_sellable_inventory_cost_currency_code as AGED_90_CURR
        ,aged_90_plus_days_sellable_inventory_units as AGED_90_UNITS
        ,average_vendor_lead_time_days as LEAD_TIME
        ,net_received_inventory_cost_amount as REC_AMT
        ,net_received_inventory_cost_currency_code as REC_CURR
        ,net_received_inventory_units as REC_UNITS
        ,open_purchase_order_units as OPEN_PO
        ,unfilled_customer_ordered_units as UNFILLED
        ,sellable_on_hand_inventory_cost_amount as OH_AMT
        ,sellable_on_hand_inventory_units as OH_UNITS
        ,sellable_on_hand_inventory_cost_currency_code as OH_CURR
        ,unhealthy_inventory_cost_amount as UNHEALTHY_AMT
        ,unhealthy_inventory_units as UNHEALTHY_UNITS
        ,unhealthy_inventory_cost_currency_code as UNHEALTHY_CURR
        ,unsellable_on_hand_inventory_cost_amount as UNSELLABLE_AMT
        ,unsellable_on_hand_inventory_units as UNSELLABLE_UNITS
        ,unsellable_on_hand_inventory_cost_currency_code as UNSELLABLE_CURR
        ,PSA_DELETE_IND as DELETE_IND
    FROM SRC_sat_anaheim
)

, LOGIC_sat_inc as (
    SELECT
         CHANNEL_ITEM_INVENTORY_LHK as LNK_HK
        ,asin as ASIN
        ,end_date as REPORT_DATE
        ,aged_90_plus_days_sellable_inventory_cost_amount as AGED_90_AMT
        ,aged_90_plus_days_sellable_inventory_cost_currency_code as AGED_90_CURR
        ,aged_90_plus_days_sellable_inventory_units as AGED_90_UNITS
        ,average_vendor_lead_time_days as LEAD_TIME
        ,net_received_inventory_cost_amount as REC_AMT
        ,net_received_inventory_cost_currency_code as REC_CURR
        ,net_received_inventory_units as REC_UNITS
        ,open_purchase_order_units as OPEN_PO
        ,unfilled_customer_ordered_units as UNFILLED
        ,sellable_on_hand_inventory_cost_amount as OH_AMT
        ,sellable_on_hand_inventory_units as OH_UNITS
        ,sellable_on_hand_inventory_cost_currency_code as OH_CURR
        ,unhealthy_inventory_cost_amount as UNHEALTHY_AMT
        ,unhealthy_inventory_units as UNHEALTHY_UNITS
        ,unhealthy_inventory_cost_currency_code as UNHEALTHY_CURR
        ,unsellable_on_hand_inventory_cost_amount as UNSELLABLE_AMT
        ,unsellable_on_hand_inventory_units as UNSELLABLE_UNITS
        ,unsellable_on_hand_inventory_cost_currency_code as UNSELLABLE_CURR
        ,PSA_DELETE_IND as DELETE_IND
    FROM SRC_sat_inc
)

---- RENAME LAYER ----

, RENAME_lnk as ( 
    SELECT 
         CHANNEL_ITEM_INVENTORY_LHK
        ,ITEM_HK
        ,STORE_HK
        ,REC_SRC
        ,PB_REC_SRC
        ,PB_LOAD_DTS 
    FROM LOGIC_lnk 
)

, RENAME_hub_item as ( 
    SELECT 
         hub_ITEM_HK
        ,ITEM_BK 
    FROM LOGIC_hub_item 
)

, RENAME_hub_store as ( 
    SELECT 
         hub_STORE_HK
        ,STORE_BK
        ,BKCC 
    FROM LOGIC_hub_store 
)

, RENAME_sat_vc as ( 
    SELECT 
         LNK_HK
        ,ASIN
        ,REPORT_DATE
        ,AGED_90_AMT
        ,AGED_90_CURR
        ,AGED_90_UNITS
        ,LEAD_TIME
        ,REC_AMT
        ,REC_CURR
        ,REC_UNITS
        ,OPEN_PO
        ,UNFILLED
        ,OH_AMT
        ,OH_UNITS
        ,OH_CURR
        ,UNHEALTHY_AMT
        ,UNHEALTHY_UNITS
        ,UNHEALTHY_CURR
        ,UNSELLABLE_AMT
        ,UNSELLABLE_UNITS
        ,UNSELLABLE_CURR
        ,DELETE_IND 
    FROM LOGIC_sat_vc 
)

, RENAME_sat_anaheim as ( 
    SELECT 
         LNK_HK
        ,ASIN
        ,REPORT_DATE
        ,AGED_90_AMT
        ,AGED_90_CURR
        ,AGED_90_UNITS
        ,LEAD_TIME
        ,REC_AMT
        ,REC_CURR
        ,REC_UNITS
        ,OPEN_PO
        ,UNFILLED
        ,OH_AMT
        ,OH_UNITS
        ,OH_CURR
        ,UNHEALTHY_AMT
        ,UNHEALTHY_UNITS
        ,UNHEALTHY_CURR
        ,UNSELLABLE_AMT
        ,UNSELLABLE_UNITS
        ,UNSELLABLE_CURR
        ,DELETE_IND 
    FROM LOGIC_sat_anaheim 
)

, RENAME_sat_inc as ( 
    SELECT 
         LNK_HK
        ,ASIN
        ,REPORT_DATE
        ,AGED_90_AMT
        ,AGED_90_CURR
        ,AGED_90_UNITS
        ,LEAD_TIME
        ,REC_AMT
        ,REC_CURR
        ,REC_UNITS
        ,OPEN_PO
        ,UNFILLED
        ,OH_AMT
        ,OH_UNITS
        ,OH_CURR
        ,UNHEALTHY_AMT
        ,UNHEALTHY_UNITS
        ,UNHEALTHY_CURR
        ,UNSELLABLE_AMT
        ,UNSELLABLE_UNITS
        ,UNSELLABLE_CURR
        ,DELETE_IND 
    FROM LOGIC_sat_inc 
)

---- FILTER LAYER ----

, FILTER_lnk as ( SELECT * FROM RENAME_lnk )
, FILTER_hub_item as ( SELECT * FROM RENAME_hub_item )
, FILTER_hub_store as ( SELECT * FROM RENAME_hub_store )

-- Union all sources together into a single unified stream
, UNIFIED_sat as (
    SELECT * FROM RENAME_sat_vc
    UNION ALL
    SELECT * FROM RENAME_sat_anaheim
    UNION ALL
    SELECT * FROM RENAME_sat_inc
)

---- JOIN LAYER ----

, JOIN_RESULT as (
    SELECT 
         l.CHANNEL_ITEM_INVENTORY_LHK
        ,l.ITEM_HK
        ,l.STORE_HK
        ,l.REC_SRC
        ,l.PB_REC_SRC
        ,l.PB_LOAD_DTS
        ,hi.ITEM_BK
        ,hs.STORE_BK
        ,hs.BKCC
        ,sat.ASIN
        ,sat.REPORT_DATE
        ,sat.AGED_90_AMT
        ,sat.AGED_90_CURR
        ,sat.AGED_90_UNITS
        ,sat.LEAD_TIME
        ,sat.REC_AMT
        ,sat.REC_CURR
        ,sat.REC_UNITS
        ,sat.OPEN_PO
        ,sat.UNFILLED
        ,sat.OH_AMT
        ,sat.OH_UNITS
        ,sat.OH_CURR
        ,sat.UNHEALTHY_AMT
        ,sat.UNHEALTHY_UNITS
        ,sat.UNHEALTHY_CURR
        ,sat.UNSELLABLE_AMT
        ,sat.UNSELLABLE_UNITS
        ,sat.UNSELLABLE_CURR
        ,sat.DELETE_IND
    FROM FILTER_lnk l
    LEFT JOIN FILTER_hub_item hi  ON l.ITEM_HK = hi.hub_ITEM_HK
    LEFT JOIN FILTER_hub_store hs ON l.STORE_HK = hs.hub_STORE_HK
    LEFT JOIN UNIFIED_sat sat      ON l.CHANNEL_ITEM_INVENTORY_LHK = sat.LNK_HK
)

---- FINAL LAYER ----

SELECT
      row_number() over(order by 1) as SEQ_ID
    , CURRENT_DATE as SNAPSHOTDATE
    , CHANNEL_ITEM_INVENTORY_LHK
    , PB_REC_SRC
    , PB_LOAD_DTS
    , REC_SRC
    , BKCC
    , ASIN
    , TO_CHAR(REPORT_DATE, 'YYYYMMDD')::INTEGER AS report_date__YYYYMMDD
    , AGED_90_AMT AS aged_90_plus_cost_amt
    , AGED_90_CURR AS aged_90_plus_currency_code
    , AGED_90_UNITS AS aged_90_plus_units
    , LEAD_TIME AS avg_vendor_lead_time_days
    , REC_AMT AS net_received_cost_amt
    , REC_CURR AS net_received_currency_code
    , REC_UNITS AS net_received_inventory_units
    , OPEN_PO AS open_po_units
    , UNFILLED AS unfilled_customer_ordered_units
    , OH_AMT AS sellable_on_hand_inventory_cost_amount
    , OH_UNITS AS sellable_oh_units
    , OH_CURR AS sellable_on_hand_inventory_cost_currency_code
    , UNHEALTHY_AMT AS unhealthy_cost_amt
    , UNHEALTHY_UNITS as unhealthy_units
    , UNHEALTHY_CURR AS unhealthy_inventory_cost_currency_code
    , UNSELLABLE_AMT AS unsellable_on_hand_inventory_cost_amount
    , UNSELLABLE_UNITS as unsellable_oh_units
    , UNSELLABLE_CURR AS unsellable_inventory_cost_currency_code
    , ITEM_HK
    , ITEM_BK
    , STORE_HK
    , STORE_BK
    , CASE 
        WHEN BKCC = 'Running_Horse' THEN DELETE_IND 
      END as IS_DELETED 
FROM JOIN_RESULT
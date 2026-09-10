{{
    config(
        tags = ['complex_model', 'large_volume', 'source_loading_restricted']
    )
}}
---- SRC LAYER ----
WITH
SRC_SPLML          as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_plant__ml_ebs') }} as SRC  ),
SRC_SPLMN          as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_plant__moen_sap') }} as SRC  ),
SRC_SITMN          as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_item_master__moen_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_SPLLR          as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_plant__lrsn_psft') }} as SRC  ),
SRC_SPLDSLR        as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_plant_descr__lrsn_psft') }} as SRC  ),
SRC_SITMLR         as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_item_master__lrsn_psft') }} as SRC  ),
SRC_SPLFB          as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_plant__fib_ocf') }} as SRC  ),
SRC_SITMFB         as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_plant_item__fib_ocf') }} as SRC  ),
SRC_SPLTTE         as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_plant__tt_e21') }} as SRC  ),
SRC_SITMTTE        as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_item_master__tt_e21') }} as SRC  ),
SRC_SPLTTGP        as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_plant__tt_gp') }} as SRC  ),
SRC_SPITTGP        as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_plant_item__tt_gp') }} as SRC  ),
SRC_SITMGP         as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_item_master__tt_gp') }} as SRC  ),
SRC_SPBPI          as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_bom_plant_item__winn_sap') }} as SRC  ),
SRC_SPIV           as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_item_version__winn_sap') }} as SRC  ),
SRC_BSPML          as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_bom_structures__ml_ebs') }} as SRC  ),
SRC_SCPLTMN        as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_item_special_procurement_plant__winn_sap') }} as SRC  ),
SRC_SCPLTMN_SAL    as ( SELECT BKCC, LOAD_DTS, PLANT_TRANSFER_BK, PLANT_TRANSFER_HK, REC_SRC FROM {{ ref('v_psa_stg_item_special_procurement_plant__winn_sap') }} as SRC  ),
SRC_SIPSP          as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_plant_item__moen_sap') }} as SRC  ),
SRC_MRPLINE        as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_mrp_lines__winn_sap') }} as SRC  ),
SRC_T001L          as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_goods_movement_storage_location__winn_sap') }} as SRC  ),
SRC_CE1NEW4        as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_copa_sales__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_AZCOPA         as ( {% if not is_incremental() %} SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_copa_sales_history__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY ZEXTRACTDATE ))=1 {% endif %} 
                        {% if is_incremental() %} SELECT * FROM {{ this }} WHERE FALSE {% endif %} 
                        /*To improve efficiency and performance; scan and load historical SAP BW AZCOPA table only on initial run */ ),
SRC_ZSERVLEVEL     as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_service_levels__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_WORK_LOCATION  as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_work_center_location__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_PC             as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_capacity_header__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_WCRR           as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_work_center_responsible_role__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_WC           as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_work_center_capacity__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_INVENTORY       as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_goods_movement__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY LOAD_DTS ))=1 ),
SRC_MV             as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_material_valuation__winn_sap') }} as SRC                                                                                                                                               
                         QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY LOAD_DTS ))=1 ),
SRC_SPLEMTK        as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_plant__emtk_ebs') }} as SRC  ),
SRC_WORK_CAPACITY       as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_work_center_capacity_allocation__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY LOAD_DTS ))=1 ),                                                                                                                  
SRC_RESERVATION    as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_TASKLIST_ITEM    as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_tasklist_assignment__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_TASKLIST_GROUP    as ( SELECT PLANNING_PLANT_HK, PLANNING_PLANT_BK, BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_tasklist_group__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_demand       as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_demand_planning__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY LOAD_DTS ))=1 ),
SRC_demand_2       as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_demand_planning_history__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY LOAD_DTS ))=1 ),
SRC_SOL            as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_order_item__winn_sap') }} as SRC
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY LOAD_DTS ))=1 ),
SRC_SINVLNWINN    as ( SELECT BKCC, LOAD_DTS, PLANT_BK, PLANT_HK, REC_SRC FROM {{ ref('v_psa_stg_sales_invoice_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY PLANT_BK ORDER BY LOAD_DTS ))=1 )
                        


/*
SRC_SPLML          as ( SELECT * FROM STAGING.v_psa_stg_plant__ml_ebs )
SRC_SPLMN          as ( SELECT * FROM STAGING.v_psa_stg_plant__moen_sap )
SRC_SITMN          as ( SELECT * FROM STAGING.v_psa_stg_item_master__moen_sap )
SRC_SPLLR          as ( SELECT * FROM STAGING.v_psa_stg_plant__lrsn_psft )
SRC_SPLDSLR        as ( SELECT * FROM STAGING.v_psa_stg_plant_descr__lrsn_psft )
SRC_SITMLR         as ( SELECT * FROM STAGING.v_psa_stg_item_master__lrsn_psft )
SRC_SPLFB          as ( SELECT * FROM STAGING.v_psa_stg_plant__fib_ocf )
SRC_SITMFB         as ( SELECT * FROM STAGING.v_psa_stg_plant_item__fib_ocf )
SRC_SPLTTE         as ( SELECT * FROM STAGING.v_psa_stg_plant__tt_e21 )
SRC_SITMTTE        as ( SELECT * FROM STAGING.v_psa_stg_item_master__tt_e21 )
SRC_SPLTTGP        as ( SELECT * FROM STAGING.v_psa_stg_plant__tt_gp )
SRC_SPITTGP        as ( SELECT * FROM STAGING.v_psa_stg_plant_item__tt_gp )
SRC_SITMGP         as ( SELECT * FROM STAGING.v_psa_stg_item_master__tt_gp )
SRC_SPBPI          as ( SELECT * FROM STAGING.v_psa_stg_bom_plant_item__winn_sap )
SRC_SPIV           as ( SELECT * FROM STAGING.v_psa_stg_item_version__winn_sap )
SRC_BSPML          as ( SELECT * FROM STAGING.v_psa_stg_bom_structures__ml_ebs )
SRC_SCPLTMN        as ( SELECT * FROM STAGING.v_psa_stg_item_special_procurement_plant__winn_sap )
SRC_SCPLTMN_SAL    as ( SELECT * FROM STAGING.v_psa_stg_item_special_procurement_plant__winn_sap )
SRC_SIPSP          as ( SELECT * FROM STAGING.v_psa_stg_plant_item__moen_sap )
SRC_MRPLINE        as ( SELECT * FROM STAGING.v_psa_stg_mrp_lines__winn_sap )
SRC_T001L          as ( SELECT * FROM STAGING.v_psa_stg_goods_movement_storage_location__winn_sap )
SRC_CE1NEW4        as ( SELECT * FROM STAGING.v_psa_stg_copa_sales__winn_sap )
SRC_AZCOPA         as ( SELECT * FROM STAGING.v_psa_stg_copa_sales_history__winn_sap )
SRC_ZSERVLEVEL     as ( SELECT * FROM STAGING.v_psa_stg_service_levels__winn_sap )
SRC_WORK_LOCATION  as ( SELECT * FROM STAGING.v_psa_stg_work_center_location__winn_sap )
SRC_INVENTORY        as ( SELECT * FROM STAGING.v_psa_stg_goods_movement__winn_sap )
SRC_SPLEMTK        as ( SELECT * FROM STAGING.v_psa_stg_plant__emtk_ebs )
SRC_RESERVATION    as ( SELECT * FROM STAGING.v_psa_stg_reservation_line__winn_sap )
SRC_WORK_CAPACITY  as ( SELECT * FROM STAGING.v_psa_stg_work_center_capacity_allocation__winn_sap )
SRC_TASKLIST_ITEM  as ( SELECT * FROM STAGING.v_psa_stg_tasklist_assignment__winn_sap )
SRC_demand  as ( SELECT * FROM STAGING.v_psa_stg_demand_planning__winn_sap )
SRC_demand_2  as ( SELECT * FROM STAGING.v_psa_stg_demand_planning_history__winn_sap )
SRC_SOL            as ( SELECT * FROM STAGING.v_psa_stg_order_item__winn_sap )
SRC_SINVLNWINN    as ( SELECT * FROM STAGING.v_psa_stg_sales_invoice_line__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_SPLML as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPLML
)

, LOGIC_SPLMN as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPLMN
)

, LOGIC_SITMN as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMN
)

, LOGIC_SPLLR as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPLLR
)

, LOGIC_SPLDSLR as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPLDSLR
)

, LOGIC_SITMLR as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMLR
)

, LOGIC_SPLFB as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPLFB
)

, LOGIC_SITMFB as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMFB
)

, LOGIC_SPLTTE as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPLTTE
)

, LOGIC_SITMTTE as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMTTE
)

, LOGIC_SPLTTGP as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPLTTGP
)

, LOGIC_SPITTGP as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPITTGP
)

, LOGIC_SITMGP as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMGP
)

, LOGIC_SPBPI as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPBPI
)

, LOGIC_SPIV as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPIV
)

, LOGIC_BSPML as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_BSPML
)

, LOGIC_SCPLTMN as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SCPLTMN
)

, LOGIC_SCPLTMN_SAL as (
    SELECT
        PLANT_TRANSFER_HK                                            as                                           PLANT_HK
      , PLANT_TRANSFER_BK                                            as                                           PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SCPLTMN_SAL
)

, LOGIC_SIPSP as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SIPSP
)

, LOGIC_MRPLINE as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_MRPLINE
)

, LOGIC_INVENTORY as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_INVENTORY
)

, LOGIC_T001L as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_T001L
)

, LOGIC_CE1NEW4 as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_CE1NEW4
)

, LOGIC_AZCOPA as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AZCOPA
)

, LOGIC_ZSERVLEVEL as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ZSERVLEVEL
)

, LOGIC_MV as (
  SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_MV)
               
, LOGIC_WORK_LOCATION as (
SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_WORK_LOCATION
)

, LOGIC_SPLEMTK as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPLEMTK
)


, LOGIC_PC as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
        FROM SRC_PC
)

, LOGIC_RESERVATION as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RESERVATION
)
, LOGIC_WCRR as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_WCRR
)

, LOGIC_WC as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_WC
)

, LOGIC_WORK_CAPACITY as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_WORK_CAPACITY
)

, LOGIC_TASKLIST_ITEM as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TASKLIST_ITEM
)

, LOGIC_TASKLIST_GROUP as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TASKLIST_GROUP
)

, LOGIC_TASKLIST_GROUP_1 as (
    SELECT
        PLANNING_PLANT_HK as PLANT_HK
      , PLANNING_PLANT_BK as PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TASKLIST_GROUP
)

, LOGIC_demand as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_demand
)

, LOGIC_demand_2 as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_demand_2
)

, LOGIC_SOL as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SOL
)

, LOGIC_SINVLNWINN as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVLNWINN
)
---- RENAME LAYER ----

, RENAME_SPLML as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPLML
)

, RENAME_SPLMN as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPLMN
)

, RENAME_SITMN as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMN
)

, RENAME_SPLLR as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPLLR
)

, RENAME_SPLDSLR as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPLDSLR
)

, RENAME_SITMLR as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMLR
)

, RENAME_SPLFB as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPLFB
)

, RENAME_SITMFB as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMFB
)

, RENAME_SPLTTE as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPLTTE
)

, RENAME_SITMTTE as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMTTE
)

, RENAME_SPLTTGP as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPLTTGP
)

, RENAME_SPITTGP as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPITTGP
)

, RENAME_SITMGP as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMGP
)

, RENAME_SPBPI as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPBPI
)

, RENAME_SPIV as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPIV
)

, RENAME_BSPML as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_BSPML
)

, RENAME_SCPLTMN as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SCPLTMN
)

, RENAME_SCPLTMN_SAL as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SCPLTMN_SAL
)

, RENAME_SIPSP as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SIPSP
)

, RENAME_MRPLINE as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_MRPLINE
)

, RENAME_INVENTORY as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_INVENTORY
)

, RENAME_T001L as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_T001L
)

, RENAME_CE1NEW4 as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_CE1NEW4
)

, RENAME_AZCOPA as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AZCOPA
)

, RENAME_ZSERVLEVEL as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ZSERVLEVEL
)

, RENAME_MV as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_MV)
  
, RENAME_WORK_LOCATION as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_WORK_LOCATION
)

, RENAME_SPLEMTK as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPLEMTK
)


, RENAME_PC as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PC
)

, RENAME_RESERVATION as (
        SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RESERVATION
)

, RENAME_WCRR as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_WCRR
)

, RENAME_WC as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_WC
)

, RENAME_WORK_CAPACITY as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_WORK_CAPACITY
)

, RENAME_TASKLIST_ITEM as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TASKLIST_ITEM
)

, RENAME_TASKLIST_GROUP as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TASKLIST_GROUP
)

, RENAME_TASKLIST_GROUP_1 as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TASKLIST_GROUP_1
)

, RENAME_demand as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_demand
)

, RENAME_demand_2 as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_demand_2
)

, RENAME_SOL as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SOL
)

, RENAME_SINVLNWINN as (
    SELECT
        PLANT_HK
      , PLANT_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVLNWINN
)
---- FILTER LAYER ----

, FILTER_SPLML as (
    SELECT *
    FROM RENAME_SPLML
)

, FILTER_SPLMN as (
    SELECT *
    FROM RENAME_SPLMN
)

, FILTER_SITMN as (
    SELECT *
    FROM RENAME_SITMN
)

, FILTER_SPLLR as (
    SELECT *
    FROM RENAME_SPLLR
)

, FILTER_SPLDSLR as (
    SELECT *
    FROM RENAME_SPLDSLR
)

, FILTER_SITMLR as (
    SELECT *
    FROM RENAME_SITMLR
)

, FILTER_SPLFB as (
    SELECT *
    FROM RENAME_SPLFB
)

, FILTER_SITMFB as (
    SELECT *
    FROM RENAME_SITMFB
)

, FILTER_SPLTTE as (
    SELECT *
    FROM RENAME_SPLTTE
)

, FILTER_SITMTTE as (
    SELECT *
    FROM RENAME_SITMTTE
)

, FILTER_SPLTTGP as (
    SELECT *
    FROM RENAME_SPLTTGP
)

, FILTER_SPITTGP as (
    SELECT *
    FROM RENAME_SPITTGP
)

, FILTER_SITMGP as (
    SELECT *
    FROM RENAME_SITMGP
)

, FILTER_SPBPI as (
    SELECT *
    FROM RENAME_SPBPI
)

, FILTER_SPIV as (
    SELECT *
    FROM RENAME_SPIV
)

, FILTER_BSPML as (
    SELECT *
    FROM RENAME_BSPML
)

, FILTER_SCPLTMN as (
    SELECT *
    FROM RENAME_SCPLTMN
)

, FILTER_SCPLTMN_SAL as (
    SELECT *
    FROM RENAME_SCPLTMN_SAL
)

, FILTER_SIPSP as (
    SELECT *
    FROM RENAME_SIPSP
)

, FILTER_MRPLINE as (
    SELECT *
    FROM RENAME_MRPLINE
)

, FILTER_INVENTORY as (
    SELECT *
    FROM RENAME_INVENTORY
)

, FILTER_T001L as (
    SELECT *
    FROM RENAME_T001L
)

, FILTER_CE1NEW4 as (
    SELECT *
    FROM RENAME_CE1NEW4
)

, FILTER_AZCOPA as (
    SELECT *
    FROM RENAME_AZCOPA
)

, FILTER_ZSERVLEVEL as (
    SELECT *
    FROM RENAME_ZSERVLEVEL
)

, FILTER_MV as (
    SELECT *
    FROM RENAME_MV)
  
, FILTER_WORK_LOCATION as (
    SELECT *
    FROM RENAME_WORK_LOCATION
)

, FILTER_PC as (
    SELECT *
    FROM RENAME_PC
)

, FILTER_WCRR as (
    SELECT *
    FROM RENAME_WCRR
)

, FILTER_WC as (
    SELECT *
    FROM RENAME_WC
)

, FILTER_WORK_CAPACITY as (
    SELECT *
    FROM RENAME_WORK_CAPACITY
)
, FILTER_SPLEMTK as (
    SELECT *
    FROM RENAME_SPLEMTK
)

, FILTER_RESERVATION as (
    SELECT *
    FROM RENAME_RESERVATION
)

, FILTER_TASKLIST_ITEM as (
    SELECT *
    FROM RENAME_TASKLIST_ITEM
)

, FILTER_TASKLIST_GROUP as (
    SELECT *
    FROM RENAME_TASKLIST_GROUP
)

, FILTER_TASKLIST_GROUP_1 as (
    SELECT *
    FROM RENAME_TASKLIST_GROUP_1
)

, FILTER_demand as (
    SELECT *
    FROM RENAME_demand
)

, FILTER_demand_2 as (
    SELECT *
    FROM RENAME_demand_2
)
, FILTER_SOL as (
    SELECT *
    FROM RENAME_SOL
)

, FILTER_SINVLNWINN as (
    SELECT *
    FROM RENAME_SINVLNWINN
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    /*This Jinja logic to intelligently bypass unnecessary full downstream refreshes */
    {% if target.name not in ['default', 'dev'] %}
    SELECT * FROM FILTER_SPLML
    UNION ALL
    SELECT * FROM FILTER_SPLMN
    UNION ALL
    SELECT * FROM FILTER_SITMN
    UNION ALL
    SELECT * FROM FILTER_SPLLR
    UNION ALL
    SELECT * FROM FILTER_SPLDSLR
    UNION ALL
    SELECT * FROM FILTER_SITMLR
    UNION ALL
    SELECT * FROM FILTER_SPLFB
    UNION ALL
    SELECT * FROM FILTER_SITMFB
    UNION ALL
    SELECT * FROM FILTER_SPLTTE
    UNION ALL
    SELECT * FROM FILTER_SITMTTE
    UNION ALL
    SELECT * FROM FILTER_SPLTTGP
    UNION ALL
    SELECT * FROM FILTER_SPITTGP
    UNION ALL
    SELECT * FROM FILTER_SITMGP
    UNION ALL
    SELECT * FROM FILTER_SPBPI
    UNION ALL
    SELECT * FROM FILTER_SPIV
    UNION ALL
    SELECT * FROM FILTER_BSPML
    UNION ALL
    SELECT * FROM FILTER_SCPLTMN
    UNION ALL
    SELECT * FROM FILTER_SCPLTMN_SAL
    UNION ALL
    SELECT * FROM FILTER_SIPSP
    UNION ALL
    SELECT * FROM FILTER_INVENTORY    
    UNION ALL
    SELECT * FROM FILTER_MRPLINE
    UNION ALL
    SELECT * FROM FILTER_T001L
    UNION ALL
    SELECT * FROM FILTER_CE1NEW4
    UNION ALL
    SELECT * FROM FILTER_AZCOPA
    UNION ALL
    SELECT * FROM FILTER_ZSERVLEVEL
    UNION ALL 
    SELECT * FROM FILTER_MV
    UNION ALL
    SELECT * FROM FILTER_SPLEMTK -- new source
    UNION ALL
    SELECT * FROM FILTER_WORK_LOCATION
    UNION ALL
    SELECT * FROM FILTER_PC
    UNION ALL
    SELECT * FROM FILTER_WCRR
    UNION ALL
    SELECT * FROM FILTER_WC
    UNION ALL
    SELECT * FROM FILTER_WORK_CAPACITY
    UNION ALL
	SELECT * FROM FILTER_RESERVATION
    UNION ALL
	SELECT * FROM FILTER_TASKLIST_ITEM
    UNION ALL
    SELECT * FROM FILTER_TASKLIST_GROUP
    UNION ALL
    SELECT * FROM FILTER_TASKLIST_GROUP_1
    UNION ALL
    {% endif %}
    SELECT * FROM FILTER_demand
    UNION ALL
    SELECT * FROM FILTER_demand_2
    UNION ALL
    SELECT * FROM FILTER_SOL
    UNION ALL
    SELECT * FROM FILTER_SINVLNWINN
)

---- FINAL LAYER ----
SELECT
          PLANT_HK
        , PLANT_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PLANT_HK = JOIN_RESULT.PLANT_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY PLANT_BK, BKCC ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS PLANT_HK,
GR.VALUE::text AS PLANT_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}

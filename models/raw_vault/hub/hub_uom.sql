
---- SRC LAYER ----
WITH
SRC_pc             as ( SELECT UOM_HK
                                , UOM_BK
                                , BKCC
                                , LOAD_DTS
                                , REC_SRC FROM {{ ref('v_psa_stg_capacity_header__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY UOM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_wc             as ( SELECT UOM_HK
                                , UOM_BK
                                , BKCC
                                , LOAD_DTS
                                , REC_SRC FROM {{ ref('v_psa_stg_work_center_capacity__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY UOM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_uom            as ( SELECT UOM_HK
                                , UOM_BK
                                , BKCC
                                , LOAD_DTS
                                , REC_SRC FROM {{ ref('v_psa_stg_uom__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY UOM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_mrpline        as ( SELECT UOM_HK
                                , UOM_BK
                                , BKCC
                                , LOAD_DTS
                                , REC_SRC FROM {{ ref('v_psa_stg_mrp_lines__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY UOM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_inventory       as ( SELECT UOM_HK
                                , UOM_BK
                                , BKCC
                                , LOAD_DTS
                                , REC_SRC FROM {{ ref('v_psa_stg_goods_movement__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY UOM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_tc20           as ( SELECT UOM_HK
                                , UOM_BK
                                , BKCC
                                , LOAD_DTS
                                , REC_SRC FROM {{ ref('v_psa_stg_work_center_formula_pattern__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY UOM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_reservation    as ( SELECT UOM_HK
                                , UOM_BK
                                , BKCC
                                , LOAD_DTS
                                , REC_SRC FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY UOM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_kape           as ( SELECT UOM_HK
                                , UOM_BK
                                , BKCC
                                , LOAD_DTS
                                , REC_SRC FROM {{ ref('v_psa_stg_capacity_uom__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY UOM_HK ORDER BY LOAD_DTS ))=1 ),
SRC_PROD_ORDER     as ( SELECT BKCC, LOAD_DTS, REC_SRC, BASE_UOM_HK, BASE_UOM_BK, PRODUCTION_ORDER_BASE_UOM_HK, PRODUCTION_ORDER_BASE_UOM_BK, BASE_QUANTITY_UOM_HK, BASE_QUANTITY_UOM_BK, PLANNED_ROUTING_UOM_HK, PLANNED_ROUTING_UOM_BK FROM {{ ref('v_psa_stg_production_order_header__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BASE_UOM_BK, PRODUCTION_ORDER_BASE_UOM_BK, BASE_QUANTITY_UOM_BK, PLANNED_ROUTING_UOM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_order_confirmation as ( SELECT MATERIAL_BASE_UOM_HK
                                , MATERIAL_BASE_UOM_BK
                                , CONFIRMATION_UOM_HK
                                , CONFIRMATION_UOM_BK
                                , BKCC
                                , LOAD_DTS
                                , REC_SRC FROM {{ ref('v_psa_stg_order_confirmation__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY MATERIAL_BASE_UOM_BK ORDER BY LOAD_DTS ))=1 ), 
SRC_demand    as ( SELECT UOM_HK
                                , UOM_BK
                                , BKCC
                                , LOAD_DTS
                                , REC_SRC FROM {{ ref('v_psa_stg_demand_planning__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY UOM_BK ORDER BY LOAD_DTS ))=1 ),       
SRC_demand_2   as ( SELECT UOM_HK
                                , UOM_BK
                                , BKCC
                                , LOAD_DTS
                                , REC_SRC FROM {{ ref('v_psa_stg_demand_planning_history__winn_sap') }} as SRC  
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY UOM_BK ORDER BY LOAD_DTS ))=1 )               

/*
SRC_uom            as ( SELECT * FROM STAGING.v_psa_stg_uom__winn_sap )
SRC_mrpline        as ( SELECT * FROM STAGING.v_psa_stg_mrp_lines__winn_sap )
SRC_inventory      as ( SELECT * FROM STAGING.v_psa_stg_goods_movement__winn_sap )
SRC_tc20           as ( SELECT * FROM STAGING.v_psa_stg_work_center_formula_pattern__winn_sap),
SRC_kape           as ( SELECT * FROM STAGING.v_psa_stg_capacity_uom__winn_sap),
SRC_reservation    as ( SELECT * FROM STAGING.v_psa_stg_reservation_line__winn_sap )
SRC_PROD_ORDER     as ( SELECT * FROM STAGING.v_psa_stg_production_order_header__winn_sap )
SRC_order_confirmation     as ( SELECT * FROM STAGING.v_psa_stg_order_confirmation__winn_sap )
SRC_demand     as ( SELECT * FROM STAGING.v_psa_stg_demand_planning__winn_sap )
SRC_demand_2     as ( SELECT * FROM STAGING.v_psa_stg_demand_planning_history__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_uom as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_uom
)

, LOGIC_mrpline as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_mrpline
)

, LOGIC_pc as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_pc
)
, LOGIC_inventory as (
     SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_inventory
)

, LOGIC_wc as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_wc
)

, LOGIC_tc20 as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_tc20
)

, LOGIC_kape as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_kape
)

, LOGIC_reservation as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_reservation
)

, LOGIC_PROD_ORDER as (
    SELECT
        BASE_UOM_HK as UOM_HK
      , BASE_UOM_BK as UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PROD_ORDER
)

, LOGIC_PROD_ORDER_2 as (
    SELECT
        PRODUCTION_ORDER_BASE_UOM_HK as UOM_HK
      , PRODUCTION_ORDER_BASE_UOM_BK as UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PROD_ORDER
)

, LOGIC_PROD_ORDER_3 as (
    SELECT
        BASE_QUANTITY_UOM_HK as UOM_HK
      , BASE_QUANTITY_UOM_BK as UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PROD_ORDER
)

, LOGIC_PROD_ORDER_4 as (
    SELECT
        PLANNED_ROUTING_UOM_HK as UOM_HK
      , PLANNED_ROUTING_UOM_BK as UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PROD_ORDER
)

, LOGIC_order_confirmation as (
    SELECT
        MATERIAL_BASE_UOM_HK as UOM_HK
      , MATERIAL_BASE_UOM_BK as UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_order_confirmation
)

, LOGIC_order_confirmation_1 as (
    SELECT
        CONFIRMATION_UOM_HK as UOM_HK
      , CONFIRMATION_UOM_BK as UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_order_confirmation
)

, LOGIC_demand as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_demand
)

, LOGIC_demand_2 as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_demand_2
)
---- RENAME LAYER ----

, RENAME_uom as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_uom
)

, RENAME_mrpline as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_mrpline
)

, RENAME_pc as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_pc
)

, RENAME_inventory as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_inventory
)

, RENAME_wc as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_wc
)

, RENAME_tc20 as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_tc20
)

, RENAME_kape as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_kape
)

, RENAME_reservation as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_reservation
)

, RENAME_PROD_ORDER as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PROD_ORDER
)

, RENAME_PROD_ORDER_2 as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PROD_ORDER_2
)

, RENAME_PROD_ORDER_3 as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PROD_ORDER_3
)

, RENAME_PROD_ORDER_4 as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PROD_ORDER_4
)

, RENAME_order_confirmation as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_order_confirmation
)

, RENAME_order_confirmation_1 as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_order_confirmation_1
)

, RENAME_demand as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_demand
)

, RENAME_demand_2 as (
    SELECT
        UOM_HK
      , UOM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_demand_2
)
---- FILTER LAYER ----

, FILTER_uom as (
    SELECT *
    FROM RENAME_uom
)

, FILTER_mrpline as (
    SELECT *
    FROM RENAME_mrpline
)

, FILTER_pc as (
    SELECT *
    FROM RENAME_pc
)

, FILTER_wc as (
    SELECT *
    FROM RENAME_wc
)

, FILTER_inventory as (
    SELECT *
    FROM RENAME_inventory
)

, FILTER_tc20 as (
    SELECT *
    FROM RENAME_tc20
)

, FILTER_kape as (
    SELECT *
    FROM RENAME_kape
)

, FILTER_reservation as (
    SELECT *
    FROM RENAME_reservation
)

, FILTER_PROD_ORDER as (
    SELECT *
    FROM RENAME_PROD_ORDER
)

, FILTER_PROD_ORDER_2 as (
    SELECT *
    FROM RENAME_PROD_ORDER_2
)

, FILTER_PROD_ORDER_3 as (
    SELECT *
    FROM RENAME_PROD_ORDER_3
)

, FILTER_PROD_ORDER_4 as (
    SELECT *
    FROM RENAME_PROD_ORDER_4
)

, FILTER_order_confirmation as (
    SELECT *
    FROM RENAME_order_confirmation
)

, FILTER_order_confirmation_1 as (
    SELECT *
    FROM RENAME_order_confirmation_1
)

, FILTER_demand as (
    SELECT *
    FROM RENAME_demand
)

, FILTER_demand_2 as (
    SELECT *
    FROM RENAME_demand_2
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_uom
    UNION ALL
    SELECT * 
    FROM FILTER_mrpline
    UNION ALL
    SELECT * 
    FROM FILTER_pc
    UNION ALL
    SELECT * 
    FROM FILTER_wc
    UNION ALL
    SELECT *
    FROM FILTER_inventory
    UNION ALL
    SELECT *
    FROM FILTER_tc20
    UNION ALL
    SELECT * 
    FROM FILTER_kape
    UNION ALL
    SELECT * 
    FROM FILTER_reservation
    UNION ALL
    SELECT * 
    FROM FILTER_PROD_ORDER
    UNION ALL
    SELECT * 
    FROM FILTER_PROD_ORDER_2
    UNION ALL
    SELECT * 
    FROM FILTER_PROD_ORDER_3
    UNION ALL
    SELECT * 
    FROM FILTER_PROD_ORDER_4
    UNION ALL
    SELECT *
    FROM FILTER_order_confirmation
    UNION ALL
    SELECT *
    FROM FILTER_order_confirmation_1
    UNION ALL
    SELECT *
    FROM FILTER_demand
    UNION ALL
    SELECT *
    FROM FILTER_demand_2
)

---- FINAL LAYER ----
SELECT
          UOM_HK
        , UOM_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.UOM_HK = JOIN_RESULT.UOM_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY UOM_BK, BKCC ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS UOM_HK,
GR.VALUE::text AS UOM_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
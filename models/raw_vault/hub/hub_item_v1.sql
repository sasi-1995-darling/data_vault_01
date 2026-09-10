{{
    config(
        tags = ['complex_model', 'large_volume', 'source_loading_restricted']
    )
}}
---- SRC LAYER ----
WITH
SRC_SITMML         as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_plant_item__ml_ebs') }} as SRC  ),
SRC_SITMN          as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_item_master__moen_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_SSHIPMN        as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_shipment__moen_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_SITMLR         as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_item_master__lrsn_psft') }} as SRC  ),
SRC_SINVLR         as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_item_inv__lrsn_psft') }} as SRC  ),
SRC_SPRDLR         as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_item_prod__lrsn_psft') }} as SRC  ),
SRC_SBILR          as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_bi_line__lrsn_psft') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY _FIVETRAN_SYNCED ))=1 ),
SRC_SPILR          as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_plant_item__lrsn_psft') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY _FIVETRAN_SYNCED ))=1 ),
SRC_SITMFB         as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_plant_item__fib_ocf') }} as SRC  ),
SRC_SINVLNFB       as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_invoice_line__fib_ocf') }} as SRC  ),
SRC_SITMTTE        as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_item_master__tt_e21') }} as SRC  ),
SRC_SPITMTTE       as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_plant_item__tt_e21') }} as SRC  ),
SRC_SITMTTGP       as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_item_master__tt_gp') }} as SRC  ),
SRC_SPITMTTGP      as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_plant_item__tt_gp') }} as SRC  ),
SRC_SPBPI          as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_bom_plant_item__winn_sap') }} as SRC  ),
SRC_SPBI           as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_bom_component_item__winn_sap') }} as SRC  ),
SRC_SPIV           as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_item_version__winn_sap') }} as SRC  ),
SRC_BSML           as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_bom_structures__ml_ebs') }} as SRC  ),
SRC_BCML           as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_bom_components__ml_ebs') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY _FIVETRAN_SYNCED ))=1 ),
SRC_MFGAML         as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_item_manufacturing_attributes__ml_ebs') }} as SRC  ),
SRC_SPLPRC         as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_plant_item__moen_sap') }} as SRC  ),
SRC_MRPLINE        as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_mrp_lines__winn_sap') }} as SRC  ),
SRC_CE1NEW4        as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_copa_sales__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_AZCOPA         as ( {% if not is_incremental() %} SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_copa_sales_history__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY ZEXTRACTDATE ))=1 {% endif %}
                        {% if is_incremental() %} SELECT * FROM {{ this }} WHERE FALSE {% endif %} 
                         /*To improve efficiency and performance; scan and load historical SAP BW AZCOPA table only on initial run */ ),
SRC_HOFRSALES      as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_legacy_hofrus_sales__hofr_ecl') }} as SRC  ),
SRC_ZSERVLEVEL     as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_service_levels__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_INVENTORY        as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_goods_movement__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_MV             as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_material_valuation__winn_sap')}}   as SRC ),                                             
SRC_SITMEMTK       as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_plant_item__emtk_ebs') }} as SRC  ),
SRC_RESERVATION    as ( SELECT  ITEM_ASSEMBLY_BK, ITEM_ASSEMBLY_HK ,BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_reservation_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY GLCHANGETIME ))=1 ),
SRC_PROD_ORDER     as ( SELECT  ROUTING_PLANNED_ITEM_HK, ROUTING_PLANNED_ITEM_BK, BOM_SPECIFIED_ITEM_HK, BOM_SPECIFIED_ITEM_BK, BKCC, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_production_order_header__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY BOM_SPECIFIED_ITEM_HK, ROUTING_PLANNED_ITEM_HK ORDER BY GLCHANGETIME ))=1 ),
SRC_TASKLIST_ITEM  as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_tasklist_assignment__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_TASKLIST_GROUP  as ( SELECT BKCC, ASSEMBLY_ITEM_BK, ASSEMBLY_ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_tasklist_group__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ASSEMBLY_ITEM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_DELIVERY_LINE_DETAIL as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_delivery_line_detail__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_demand       as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_demand_planning__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_demand_2       as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_demand_planning_history__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY LOAD_DTS ))=1 ),
SRC_SINVLNWINN    as ( SELECT BKCC, ITEM_BK, ITEM_HK, LOAD_DTS, REC_SRC FROM {{ ref('v_psa_stg_sales_invoice_line__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY ITEM_BK ORDER BY LOAD_DTS ))=1 )
  

---- LOGIC LAYER ----

, LOGIC_SITMML as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMML
)

, LOGIC_SITMN as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMN
)

, LOGIC_SSHIPMN as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SSHIPMN
)

, LOGIC_SITMLR as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMLR
)

, LOGIC_SINVLR as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVLR
)

, LOGIC_SPRDLR  as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPRDLR 
)

, LOGIC_SBILR as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SBILR
)

, LOGIC_SPILR as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPILR
)

, LOGIC_SITMFB as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMFB
)

, LOGIC_SINVLNFB as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVLNFB
)

, LOGIC_SITMTTE as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMTTE
)

, LOGIC_SPITMTTE as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPITMTTE
)

, LOGIC_SITMTTGP as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMTTGP
)

, LOGIC_SPITMTTGP as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPITMTTGP
)

, LOGIC_SPBPI as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPBPI
)

, LOGIC_SPBI as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPBI
)

, LOGIC_SPIV as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPIV
)

, LOGIC_BSML as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_BSML
)

, LOGIC_BCML as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_BCML
)

, LOGIC_MFGAML as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_MFGAML
)

, LOGIC_SPLPRC as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPLPRC
)

, LOGIC_MRPLINE as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_MRPLINE
)

, LOGIC_INVENTORY as (
SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_INVENTORY
)

, LOGIC_CE1NEW4 as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_CE1NEW4
)

, LOGIC_AZCOPA as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AZCOPA
)

, LOGIC_HOFRSALES as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_HOFRSALES
)

, LOGIC_MV as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_MV
)
, LOGIC_ZSERVLEVEL as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ZSERVLEVEL
)

, LOGIC_SITMEMTK as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMEMTK
)

, LOGIC_RESERVATION as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RESERVATION
)

, LOGIC_ASSEMBLY_ITEM as (
    SELECT
        ITEM_ASSEMBLY_HK as ITEM_HK
      , ITEM_ASSEMBLY_BK as ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_RESERVATION
)

, LOGIC_PROD_ORDER as (
    SELECT
        ROUTING_PLANNED_ITEM_HK as ITEM_HK
      , ROUTING_PLANNED_ITEM_BK as ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PROD_ORDER
)

, LOGIC_PROD_ORDER_2 as (
    SELECT
        BOM_SPECIFIED_ITEM_HK as ITEM_HK
      , BOM_SPECIFIED_ITEM_BK as ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_PROD_ORDER
)

, LOGIC_TASKLIST_ITEM as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TASKLIST_ITEM
)

, LOGIC_TASKLIST_GROUP as (
    SELECT
        ASSEMBLY_ITEM_HK as ITEM_HK
      , ASSEMBLY_ITEM_BK as ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_TASKLIST_GROUP
)

, LOGIC_DELIVERY_LINE_DETAIL as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_DELIVERY_LINE_DETAIL
)

, LOGIC_demand as (
    SELECT
        ITEM_HK
      , ITEM_bk
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_demand
)

, LOGIC_demand_2 as (
    SELECT
        ITEM_HK
      , ITEM_bk
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_demand_2
)

, LOGIC_SINVLNWINN as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SINVLNWINN
)
---- RENAME LAYER ----

, RENAME_SITMML as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMML
)

, RENAME_SITMN as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMN
)

, RENAME_SSHIPMN as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SSHIPMN
)

, RENAME_SITMLR as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMLR
)

, RENAME_SINVLR as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVLR
)

, RENAME_SPRDLR  as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPRDLR 
)

, RENAME_SBILR as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SBILR
)

, RENAME_SPILR as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPILR
)

, RENAME_SITMFB as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMFB
)

, RENAME_SINVLNFB as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVLNFB
)

, RENAME_SITMTTE as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMTTE
)

, RENAME_SPITMTTE as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPITMTTE
)

, RENAME_SITMTTGP as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMTTGP
)

, RENAME_SPITMTTGP as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPITMTTGP
)

, RENAME_SPBPI as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPBPI
)

, RENAME_SPBI as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPBI
)

, RENAME_SPIV as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPIV
)

, RENAME_BSML as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_BSML
)

, RENAME_BCML as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_BCML
)

, RENAME_MFGAML as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_MFGAML
)

, RENAME_SPLPRC as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPLPRC
)

, RENAME_MRPLINE as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_MRPLINE
)

, RENAME_INVENTORY as (
SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_INVENTORY
)

, RENAME_CE1NEW4 as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_CE1NEW4
)

, RENAME_AZCOPA as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AZCOPA
)

, RENAME_HOFRSALES as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_HOFRSALES
)

, RENAME_MV as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_MV
)
, RENAME_ZSERVLEVEL as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ZSERVLEVEL
)

, RENAME_SITMEMTK as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMEMTK
)

, RENAME_RESERVATION as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_RESERVATION
)


, RENAME_ASSEMBLY_ITEM as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ASSEMBLY_ITEM
)

, RENAME_PROD_ORDER as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PROD_ORDER
)

, RENAME_PROD_ORDER_2 as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_PROD_ORDER_2
)

, RENAME_TASKLIST_ITEM as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TASKLIST_ITEM
)

, RENAME_TASKLIST_GROUP as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_TASKLIST_GROUP
)

, RENAME_DELIVERY_LINE_DETAIL as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_DELIVERY_LINE_DETAIL
)

, RENAME_demand as (
    SELECT
        ITEM_HK
      , ITEM_bk
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_demand
)

, RENAME_demand_2 as (
    SELECT
        ITEM_HK
      , ITEM_bk
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_demand_2
)

, RENAME_SINVLNWINN as (
    SELECT
        ITEM_HK
      , ITEM_BK
      , BKCC
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SINVLNWINN
)
---- FILTER LAYER ----

, FILTER_SITMML as (
    SELECT *
    FROM RENAME_SITMML
)

, FILTER_SITMN as (
    SELECT *
    FROM RENAME_SITMN
)

, FILTER_SSHIPMN as (
    SELECT *
    FROM RENAME_SSHIPMN
)

, FILTER_SITMLR as (
    SELECT *
    FROM RENAME_SITMLR
)

, FILTER_SINVLR as (
    SELECT *
    FROM RENAME_SINVLR
)

, FILTER_SPRDLR  as (
    SELECT *
    FROM RENAME_SPRDLR 
)

, FILTER_SBILR as (
    SELECT *
    FROM RENAME_SBILR
)

, FILTER_SPILR as (
    SELECT *
    FROM RENAME_SPILR
)

, FILTER_SITMFB as (
    SELECT *
    FROM RENAME_SITMFB
)

, FILTER_SINVLNFB as (
    SELECT *
    FROM RENAME_SINVLNFB
)

, FILTER_SITMTTE as (
    SELECT *
    FROM RENAME_SITMTTE
)

, FILTER_SPITMTTE as (
    SELECT *
    FROM RENAME_SPITMTTE
)

, FILTER_SITMTTGP as (
    SELECT *
    FROM RENAME_SITMTTGP
)

, FILTER_SPITMTTGP as (
    SELECT *
    FROM RENAME_SPITMTTGP
)

, FILTER_SPBPI as (
    SELECT *
    FROM RENAME_SPBPI
)

, FILTER_SPBI as (
    SELECT *
    FROM RENAME_SPBI
)

, FILTER_SPIV as (
    SELECT *
    FROM RENAME_SPIV
)

, FILTER_BSML as (
    SELECT *
    FROM RENAME_BSML
)

, FILTER_BCML as (
    SELECT *
    FROM RENAME_BCML
)

, FILTER_MFGAML as (
    SELECT *
    FROM RENAME_MFGAML
)

, FILTER_SPLPRC as (
    SELECT *
    FROM RENAME_SPLPRC
)

, FILTER_MRPLINE as (
    SELECT *
    FROM RENAME_MRPLINE
)

, FILTER_INVENTORY as (
    SELECT *
    FROM RENAME_INVENTORY
)

, FILTER_CE1NEW4 as (
    SELECT *
    FROM RENAME_CE1NEW4
)

, FILTER_AZCOPA as (
    SELECT *
    FROM RENAME_AZCOPA
)

, FILTER_HOFRSALES as (
    SELECT *
    FROM RENAME_HOFRSALES
)

, FILTER_MV as (
    SELECT *
    FROM RENAME_MV
)

, FILTER_ZSERVLEVEL as (
    SELECT *
    FROM RENAME_ZSERVLEVEL
)

, FILTER_SITMEMTK as (
    SELECT *
    FROM RENAME_SITMEMTK
)

, FILTER_RESERVATION as (
    SELECT *
    FROM RENAME_RESERVATION
)

, FILTER_ASSEMBLY_ITEM as (
    SELECT *
    FROM RENAME_ASSEMBLY_ITEM
)

, FILTER_PROD_ORDER as (
    SELECT *
    FROM RENAME_PROD_ORDER
)

, FILTER_PROD_ORDER_2 as (
    SELECT *
    FROM RENAME_PROD_ORDER_2
)

, FILTER_TASKLIST_ITEM as (
    SELECT *
    FROM RENAME_TASKLIST_ITEM
)

, FILTER_TASKLIST_GROUP as (
    SELECT *
    FROM RENAME_TASKLIST_GROUP
)

, FILTER_DELIVERY_LINE_DETAIL as (
    SELECT *
    FROM RENAME_DELIVERY_LINE_DETAIL
)

, FILTER_demand as (
    SELECT *
    FROM RENAME_demand
)

, FILTER_demand_2 as (
    SELECT *
    FROM RENAME_demand_2
)

, FILTER_SINVLNWINN as (
    SELECT *
    FROM RENAME_SINVLNWINN
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    /*This Jinja logic to intelligently bypass unnecessary full downstream refreshes */
    {% if target.name not in ['default', 'dev'] %}
    SELECT * FROM FILTER_SITMML
    UNION ALL
    SELECT * FROM FILTER_SITMN
    UNION ALL
    SELECT * FROM FILTER_SSHIPMN
    UNION ALL
    SELECT * FROM FILTER_SITMLR
    UNION ALL
    SELECT * FROM FILTER_SINVLR
    UNION ALL
    SELECT * FROM FILTER_SPRDLR 
    UNION ALL
    SELECT * FROM FILTER_SBILR
    UNION ALL
    SELECT * FROM FILTER_SPILR
    UNION ALL
    SELECT * FROM FILTER_SITMFB
    UNION ALL
    SELECT * FROM FILTER_SINVLNFB
    UNION ALL
    SELECT * FROM FILTER_SITMTTE
    UNION ALL
    SELECT * FROM FILTER_SPITMTTE
    UNION ALL
    SELECT * FROM FILTER_SITMTTGP
    UNION ALL
    SELECT * FROM FILTER_SPITMTTGP
    UNION ALL
    SELECT * FROM FILTER_SPBPI
    UNION ALL
    SELECT * FROM FILTER_SPBI
    UNION ALL
    SELECT * FROM FILTER_SPIV
    UNION ALL
    SELECT * FROM FILTER_BSML
    UNION ALL
    SELECT * FROM FILTER_BCML
    UNION ALL
    SELECT * FROM FILTER_MFGAML
    UNION ALL
    SELECT * FROM FILTER_INVENTORY 
    UNION ALL
    SELECT * FROM FILTER_MRPLINE
    UNION ALL
    SELECT * FROM FILTER_CE1NEW4
    UNION ALL
    SELECT * FROM FILTER_AZCOPA
    UNION ALL
    SELECT * FROM FILTER_HOFRSALES
    UNION ALL 
    SELECT * FROM FILTER_MV
    UNION ALL
    SELECT * FROM FILTER_ZSERVLEVEL
    UNION ALL
    SELECT * FROM FILTER_SITMEMTK -- new source
    UNION ALL
    SELECT * FROM FILTER_RESERVATION
    UNION ALL
    SELECT * FROM FILTER_ASSEMBLY_ITEM
    UNION ALL
    SELECT * FROM FILTER_PROD_ORDER
    UNION ALL
    SELECT * FROM FILTER_PROD_ORDER_2
    UNION ALL
    {% endif %}
    SELECT * FROM FILTER_SPLPRC
    UNION ALL
    SELECT * FROM FILTER_TASKLIST_ITEM
    UNION ALL
    SELECT * FROM FILTER_TASKLIST_GROUP
    UNION ALL
    SELECT * FROM FILTER_DELIVERY_LINE_DETAIL
    UNION ALL
    SELECT * FROM FILTER_demand
    UNION ALL
    SELECT * FROM FILTER_demand_2
    UNION ALL
    SELECT * FROM FILTER_SINVLNWINN
)

---- FINAL LAYER ----
SELECT
          ITEM_HK
        , ITEM_BK
        , BKCC
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.ITEM_HK = JOIN_RESULT.ITEM_HK
)
{% endif %}
QUALIFY 1= ROW_NUMBER() OVER (PARTITION BY UPPER(TRIM(ITEM_BK)), BKCC ORDER BY LOAD_DTS)
{% if not is_incremental() %}

union all
SELECT 
MD5_BINARY(GR.VALUE) AS ITEM_HK,
GR.VALUE::text AS ITEM_BK,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}
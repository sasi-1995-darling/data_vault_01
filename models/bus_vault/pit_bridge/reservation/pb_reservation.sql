{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'delete+insert',
    unique_key = ['RESERVATION_BK', 'RESERVATION_LINE_BK', 'RESERVATION_RECORD_TYPE_DC'],
    cluster_by = ['RESERVATION_BK', 'BKCC'],
    full_refresh = var('force_full_refresh', false),
    on_schema_change = 'append_new_columns',
    tags = ['materialization_override', 'large_volume', 'pb']
  )
}}

/*
  GRAIN: RESERVATION_BK + RESERVATION_LINE_BK + ITEM_BK
  
  INCREMENTAL STRATEGY: delete+insert
    - On incremental runs, only rows where the upstream lsat has new/changed 
      records (based on LOAD_DTS watermark) are processed.
    - Changed rows are deleted from target by composite unique_key, 
      then re-inserted with fresh values.
    - RESERVATION_RECORD_TYPE_DC - has been added to Unique key to reprocess/Delete the outdated/expired/deleted values from the Target table
    - full_refresh = false prevents accidental full rebuilds.
      To force a full rebuild, use: 
        dbt run -s pb_reservation --full-refresh --vars '{"force_full_refresh": true}'
  
  */


-- lookback window
{%- set lookback_days = var('pb_reservation_lookback_days', 1) -%}

---- SRC LAYER ----
WITH

SRC_lsat_reservation AS (
    SELECT
        LNK_DEPENDENCY_RESERVATION_HK,
        BDMNG,
        ENMNG,
        ENWRT,
        ERFMG,
        FPREIS,
        GPREIS,
        PEINH,
        POSTP,
        PSA_DELETE_IND,
        LOAD_DTS
    FROM {{ ref('lsat_reservation_line_detail__winn_sap') }} AS SRC
    {% if is_incremental() %}
    WHERE SRC.LOAD_DTS >= DATEADD(DAY, -{{ lookback_days }},(SELECT COALESCE(MAX(PB_LOAD_DTS), '1900-01-01')::Date FROM {{ this }})  )
    {% endif %}
    QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY RSNUM, RSPOS, RSART ORDER BY LOAD_DTS DESC)
),

{#-
  Pre-filter: On incremental runs, use EXISTS to restrict the link scan to
  only rows whose satellite has changed. EXISTS is preferred over INNER JOIN
  here because:
    1. It avoids materializing the full join result (short-circuits on first match)
    2. The satellite measures are NOT needed at this stage — they come in via
       the INNER JOIN in JOIN_RESULT below
    3. On full loads, the EXISTS block is skipped entirely (is_incremental() = false)
-#}
SRC_lnk AS (
    SELECT
        LNK.LNK_DEPENDENCY_RESERVATION_HK,
        LNK.RESERVATION_HK,
        LNK.RESERVATION_LINE_HK,
        LNK.PLANT_HK,
        LNK.ITEM_HK,
        LNK.ITEM_ASSEMBLY_HK,
        LNK.PLANNED_ORDER_HK,
        LNK.PURCHASE_REQUISITION_HK,
        LNK.PURCHASE_REQUISITION_ITEM_HK,
        LNK.PO_HEADER_HK,
        LNK.PO_ITEM_HK,
        LNK.PO_LINE_HK,
        LNK.ROUTING_HK,
        LNK.CHANGE_MASTER_HK,
        LNK.GOODS_STORAGE_LOCATION_HK,
        LNK.PRODUCTION_ORDER_HK,
        LNK.STORAGE_BIN_HK,
        LNK.BOM_HK,
        LNK.UOM_HK,
        LNK.ORDER_HEADER_HK,
        LNK.ORDER_LINE_HK,
        LNK.GL_ACCOUNT_NUMBER_HK,
        LNK.RESERVATION_RECORD_TYPE_DC,
        LNK.REC_SRC
    FROM {{ ref('lnk_reservation_line_detail') }} AS LNK
    {% if is_incremental() %}
    WHERE EXISTS (
        SELECT 1
        FROM SRC_lsat_reservation AS DELTA
        WHERE LNK.LNK_DEPENDENCY_RESERVATION_HK = DELTA.LNK_DEPENDENCY_RESERVATION_HK
    )
    {% endif %}
),

---- HUB LOOKUPS ----

SRC_hub_reservation AS (
    SELECT RESERVATION_BK, RESERVATION_HK, BKCC
    FROM {{ ref('hub_reservation') }}
),

SRC_hub_reservation_line AS (
    SELECT RESERVATION_LINE_BK, RESERVATION_LINE_HK
    FROM {{ ref('hub_reservation_line') }}
),

SRC_hub_plant_v1 AS (
    SELECT PLANT_BK, PLANT_HK
    FROM {{ ref('hub_plant_v1') }}
),

SRC_hub_item_v1 AS (
    SELECT ITEM_BK, ITEM_HK
    FROM {{ ref('hub_item_v1') }}
),

SRC_hub_planned_order AS (
    SELECT PLANNED_ORDER_BK, PLANNED_ORDER_HK
    FROM {{ ref('hub_planned_order') }}
),

SRC_hub_purchase_requisition AS (
    SELECT PURCHASE_REQUISITION_BK, PURCHASE_REQUISITION_HK
    FROM {{ ref('hub_purchase_requisition') }}
),

SRC_hub_purchase_requisition_item AS (
    SELECT PURCHASE_REQUISITION_ITEM_BK, PURCHASE_REQUISITION_ITEM_HK
    FROM {{ ref('hub_purchase_requisition_item') }}
),

SRC_hub_po_header AS (
    SELECT PO_HEADER_BK, PO_HEADER_HK
    FROM {{ ref('hub_po_header') }}
),

SRC_hub_po_item AS (
    SELECT
        PO_ITEM_HK,
        IFF(
            NULLIF(TRIM(PO_HEADER_ID), '') IS NOT NULL OR NULLIF(TRIM(PO_LINE_NUMBER), '') IS NOT NULL,
            UPPER(CONCAT(PO_HEADER_ID, '||', PO_LINE_NUMBER)),
            '-1'
        ) AS PO_ITEM_BK
    FROM {{ ref('hub_po_item') }}
),

SRC_hub_po_line_v1 AS (
    SELECT PO_LINE_BK, PO_LINE_HK
    FROM {{ ref('hub_po_line_v1') }}
),

SRC_hub_routing AS (
    SELECT ROUTING_BK, ROUTING_HK
    FROM {{ ref('hub_routing') }}
),

SRC_hub_change_master AS (
    SELECT CHANGE_MASTER_BK, CHANGE_MASTER_HK
    FROM {{ ref('hub_change_master') }}
),

SRC_hub_storage_location AS (
    SELECT GOODS_STORAGE_LOCATION_BK, GOODS_STORAGE_LOCATION_HK
    FROM {{ ref('hub_storage_location') }}
),

SRC_hub_production_order AS (
    SELECT PRODUCTION_ORDER_BK, PRODUCTION_ORDER_HK
    FROM {{ ref('hub_production_order') }}
),

SRC_hub_storage_bin AS (
    SELECT STORAGE_BIN_BK, STORAGE_BIN_HK
    FROM {{ ref('hub_storage_bin') }}
),

SRC_hub_bom AS (
    SELECT BOM_BK, BOM_HK
    FROM {{ ref('hub_bom') }}
),

SRC_hub_uom AS (
    SELECT UOM_BK, UOM_HK
    FROM {{ ref('hub_uom') }}
),

SRC_hub_order_header AS (
    SELECT ORDER_HEADER_BK, ORDER_HEADER_HK
    FROM {{ ref('hub_order_header') }}
),

SRC_hub_order_line AS (
    SELECT ORDER_LINE_BK, ORDER_LINE_HK
    FROM {{ ref('hub_order_line') }}
),

SRC_hub_gl_account_number AS (
    SELECT GL_ACCOUNT_NUMBER_BK, GL_ACCOUNT_NUMBER_HK
    FROM {{ ref('hub_gl_account_number') }}
),

---- LOGIC LAYER (lsat transformations) ----

LOGIC_lsat_reservation AS (
    SELECT
        LNK_DEPENDENCY_RESERVATION_HK   AS lsat_lnk_dependency_reservation_hk,
        BDMNG                            AS REQUIRED_QTY,
        ERFMG                            AS ENTERED_QTY,
        ENWRT                            AS VALUE_WITHDRAWN,
        ENMNG                            AS WITHDRAWN_QTY,
        BDMNG - ENMNG                    AS OPEN_QTY,
        GPREIS                           AS LOT_UNIT_PRICE,
        FPREIS                           AS FIXED_FOREIGN_PRICE,
        PEINH                            AS LOT_SIZE,
        POSTP                            AS STOCK_CATEGORY,
        PSA_DELETE_IND                   AS SAT_WINN_PSA_DELETE_IND
    FROM SRC_lsat_reservation
),

---- JOIN LAYER ----
/*
  The INNER JOIN on lsat serves two purposes:
    * Full load path:  Filters to only link records that have satellite data
    * Incremental path: Brings in the satellite measure columns
                        (SRC_lnk is already pre-filtered via EXISTS above,
                         so this join is 1:1 on the delta set — no extra scan)
*/

JOIN_RESULT AS (
    SELECT
        'PB_RESERVATION'                                    AS PB_REC_SRC,
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())        AS PB_LOAD_DTS,
        CURRENT_DATE                                        AS SNAPSHOTDATE,

        -- Link keys
        LNK.LNK_DEPENDENCY_RESERVATION_HK,
        LNK.REC_SRC,

        -- Reservation
        LNK.RESERVATION_HK,
        hub_res.RESERVATION_BK,
        hub_res.BKCC,

        -- Reservation Line
        LNK.RESERVATION_LINE_HK,
        hub_res_line.RESERVATION_LINE_BK,
        LNK.RESERVATION_RECORD_TYPE_DC,

        -- Plant
        LNK.PLANT_HK,
        hub_plant.PLANT_BK,

        -- Item
        LNK.ITEM_HK,
        hub_item.ITEM_BK,

        -- Item Assembly
        LNK.ITEM_ASSEMBLY_HK,
        hub_item_assy.ITEM_BK              AS ITEM_ASSEMBLY_BK,

        -- Planned Order
        LNK.PLANNED_ORDER_HK,
        hub_po_plan.PLANNED_ORDER_BK,

        -- Purchase Requisition
        LNK.PURCHASE_REQUISITION_HK,
        hub_pr.PURCHASE_REQUISITION_BK,

        -- Purchase Requisition Item
        LNK.PURCHASE_REQUISITION_ITEM_HK,
        hub_pr_item.PURCHASE_REQUISITION_ITEM_BK,

        -- PO Header
        LNK.PO_HEADER_HK,
        hub_po_hdr.PO_HEADER_BK,

        -- PO Item
        LNK.PO_ITEM_HK,
        hub_po_itm.PO_ITEM_BK,

        -- PO Line
        LNK.PO_LINE_HK,
        hub_po_line.PO_LINE_BK,

        -- Routing
        LNK.ROUTING_HK,
        hub_routing.ROUTING_BK,

        -- Change Master
        LNK.CHANGE_MASTER_HK,
        hub_chg.CHANGE_MASTER_BK,

        -- Storage Location
        LNK.GOODS_STORAGE_LOCATION_HK,
        hub_sloc.GOODS_STORAGE_LOCATION_BK,

        -- Production Order
        LNK.PRODUCTION_ORDER_HK,
        hub_prod_ord.PRODUCTION_ORDER_BK,

        -- Storage Bin
        LNK.STORAGE_BIN_HK,
        hub_sbin.STORAGE_BIN_BK,

        -- BOM
        LNK.BOM_HK,
        hub_bom.BOM_BK,

        -- UOM
        LNK.UOM_HK,
        hub_uom.UOM_BK,

        -- Order Header
        LNK.ORDER_HEADER_HK,
        hub_ord_hdr.ORDER_HEADER_BK,

        -- Order Line
        LNK.ORDER_LINE_HK,
        hub_ord_line.ORDER_LINE_BK,

        -- GL Account
        LNK.GL_ACCOUNT_NUMBER_HK,
        hub_gl.GL_ACCOUNT_NUMBER_BK,

        -- Satellite measures
        lsat.REQUIRED_QTY,
        lsat.ENTERED_QTY,
        lsat.VALUE_WITHDRAWN,
        lsat.WITHDRAWN_QTY,
        lsat.OPEN_QTY,
        lsat.LOT_UNIT_PRICE,
        lsat.FIXED_FOREIGN_PRICE,
        lsat.LOT_SIZE,
        lsat.STOCK_CATEGORY,
        lsat.SAT_WINN_PSA_DELETE_IND

    FROM SRC_lnk AS LNK
    INNER JOIN LOGIC_lsat_reservation       AS lsat          ON LNK.LNK_DEPENDENCY_RESERVATION_HK = lsat.lsat_lnk_dependency_reservation_hk
    -- Hub lookups
    LEFT JOIN SRC_hub_reservation           AS hub_res       ON LNK.RESERVATION_HK                = hub_res.RESERVATION_HK
    LEFT JOIN SRC_hub_reservation_line      AS hub_res_line  ON LNK.RESERVATION_LINE_HK           = hub_res_line.RESERVATION_LINE_HK
    LEFT JOIN SRC_hub_plant_v1              AS hub_plant     ON LNK.PLANT_HK                      = hub_plant.PLANT_HK
    LEFT JOIN SRC_hub_item_v1               AS hub_item      ON LNK.ITEM_HK                       = hub_item.ITEM_HK
    LEFT JOIN SRC_hub_item_v1               AS hub_item_assy ON LNK.ITEM_ASSEMBLY_HK              = hub_item_assy.ITEM_HK
    LEFT JOIN SRC_hub_planned_order         AS hub_po_plan   ON LNK.PLANNED_ORDER_HK              = hub_po_plan.PLANNED_ORDER_HK
    LEFT JOIN SRC_hub_purchase_requisition  AS hub_pr        ON LNK.PURCHASE_REQUISITION_HK       = hub_pr.PURCHASE_REQUISITION_HK
    LEFT JOIN SRC_hub_purchase_requisition_item AS hub_pr_item ON LNK.PURCHASE_REQUISITION_ITEM_HK = hub_pr_item.PURCHASE_REQUISITION_ITEM_HK
    LEFT JOIN SRC_hub_po_header             AS hub_po_hdr    ON LNK.PO_HEADER_HK                  = hub_po_hdr.PO_HEADER_HK
    LEFT JOIN SRC_hub_po_item               AS hub_po_itm    ON LNK.PO_ITEM_HK                    = hub_po_itm.PO_ITEM_HK
    LEFT JOIN SRC_hub_po_line_v1            AS hub_po_line   ON LNK.PO_LINE_HK                    = hub_po_line.PO_LINE_HK
    LEFT JOIN SRC_hub_routing               AS hub_routing   ON LNK.ROUTING_HK                    = hub_routing.ROUTING_HK
    LEFT JOIN SRC_hub_change_master         AS hub_chg       ON LNK.CHANGE_MASTER_HK              = hub_chg.CHANGE_MASTER_HK
    LEFT JOIN SRC_hub_storage_location      AS hub_sloc      ON LNK.GOODS_STORAGE_LOCATION_HK     = hub_sloc.GOODS_STORAGE_LOCATION_HK
    LEFT JOIN SRC_hub_production_order      AS hub_prod_ord  ON LNK.PRODUCTION_ORDER_HK           = hub_prod_ord.PRODUCTION_ORDER_HK
    LEFT JOIN SRC_hub_storage_bin           AS hub_sbin      ON LNK.STORAGE_BIN_HK                = hub_sbin.STORAGE_BIN_HK
    LEFT JOIN SRC_hub_bom                   AS hub_bom       ON LNK.BOM_HK                        = hub_bom.BOM_HK
    LEFT JOIN SRC_hub_uom                   AS hub_uom       ON LNK.UOM_HK                        = hub_uom.UOM_HK
    LEFT JOIN SRC_hub_order_header          AS hub_ord_hdr   ON LNK.ORDER_HEADER_HK               = hub_ord_hdr.ORDER_HEADER_HK
    LEFT JOIN SRC_hub_order_line            AS hub_ord_line  ON LNK.ORDER_LINE_HK                  = hub_ord_line.ORDER_LINE_HK
    LEFT JOIN SRC_hub_gl_account_number     AS hub_gl        ON LNK.GL_ACCOUNT_NUMBER_HK          = hub_gl.GL_ACCOUNT_NUMBER_HK
)

---- FINAL LAYER ----
SELECT
    SEQ8()                                                AS SEQ_ID,
    PB_REC_SRC,
    PB_LOAD_DTS,
    SNAPSHOTDATE,
    LNK_DEPENDENCY_RESERVATION_HK,
    RESERVATION_HK,
    RESERVATION_BK,
    BKCC,
    REC_SRC,
    RESERVATION_LINE_HK,
    RESERVATION_LINE_BK,
    PLANT_HK,
    PLANT_BK,
    ITEM_HK,
    ITEM_BK,
    ITEM_ASSEMBLY_HK,
    ITEM_ASSEMBLY_BK,
    PLANNED_ORDER_HK,
    PLANNED_ORDER_BK,
    PURCHASE_REQUISITION_HK,
    PURCHASE_REQUISITION_BK,
    PURCHASE_REQUISITION_ITEM_HK,
    PURCHASE_REQUISITION_ITEM_BK,
    PO_HEADER_HK,
    PO_HEADER_BK,
    PO_ITEM_HK,
    PO_ITEM_BK,
    PO_LINE_HK,
    PO_LINE_BK,
    ROUTING_HK,
    ROUTING_BK,
    CHANGE_MASTER_HK,
    CHANGE_MASTER_BK,
    GOODS_STORAGE_LOCATION_HK,
    GOODS_STORAGE_LOCATION_BK,
    PRODUCTION_ORDER_HK,
    PRODUCTION_ORDER_BK,
    STORAGE_BIN_HK,
    STORAGE_BIN_BK,
    BOM_HK,
    BOM_BK,
    UOM_HK,
    UOM_BK,
    ORDER_HEADER_HK,
    ORDER_HEADER_BK,
    ORDER_LINE_HK,
    ORDER_LINE_BK,
    GL_ACCOUNT_NUMBER_HK,
    GL_ACCOUNT_NUMBER_BK,
    REQUIRED_QTY,
    ENTERED_QTY,
    VALUE_WITHDRAWN,
    WITHDRAWN_QTY,
    OPEN_QTY,
    LOT_UNIT_PRICE,
    FIXED_FOREIGN_PRICE,
    LOT_SIZE,
    STOCK_CATEGORY,
    IFF(BKCC = 'Hiding_Tiger', SAT_WINN_PSA_DELETE_IND, NULL) AS IS_DELETED,
    RESERVATION_RECORD_TYPE_DC
FROM JOIN_RESULT
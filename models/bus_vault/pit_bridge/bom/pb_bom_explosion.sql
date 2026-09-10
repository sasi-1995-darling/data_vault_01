{{
  config(
    materialized = 'incremental',
    unique_key= 'root_bom_key',
    incremental_strategy= 'delete+insert',
    full_refresh = var('force_full_refresh', false)
  )
}}

---Identify all changed records in the source 'pb_bom_hierarchy'
with 
{% if is_incremental() %}

    -- Calculates the most recent CDC date for each 'bkcc' key.
    max_cdc_dates as (SELECT
            bkcc,
            MAX(drvd_bom_explosion_cdc_dt) AS max_dt
        FROM {{ this }}
        GROUP BY bkcc
    ),

    -- Get all records from the source that are new or updated
    changed_records AS (
        SELECT
            DISTINCT t1.assembly_item_hk,
            t1.bkcc,
            t1.drvd_bom_explosion_cdc_dt
        FROM {{ ref('pb_bom_hierarchy') }} AS t1
        LEFT JOIN max_cdc_dates AS m
            ON t1.bkcc = m.bkcc
        WHERE t1.bkcc IN ('Crouching_Dragon', 'Hiding_Tiger')
        -- Include both Oracle EBS (Crouching_Dragon) and SAP (Hiding_Tiger). Updated: 2026-06-08
        AND t1.drvd_bom_explosion_cdc_dt >= COALESCE(m.max_dt, '1900-01-01'::timestamp_ntz(9))
    ),

    affected_and_new_roots AS (
        -- Find roots where the changed item is a component
        SELECT
            existing.assembly_item_key AS root_item_key,
            existing.bkcc
        FROM {{ this }} AS existing
        JOIN changed_records AS changed
            on (changed.assembly_item_hk = existing.assembly_item_key
            or changed.assembly_item_hk = existing.component_item_key)
            AND existing.bkcc = changed.bkcc

        UNION -- UNION handles distinct 

        -- Add the changed/new assemblies themselves (which are roots)
        SELECT
            changed.assembly_item_hk AS root_item_key,
            changed.bkcc
        FROM changed_records AS changed
    ),
{% endif %}

--Run the full explosion logic for ONLY the identified roots
/* 
-- It is currently commented out as we are only processing SAP data ('Hiding_Tiger'). Updated: 2025-12-16
-- Now including both SAP and Oracle EBS. Bizniz using ML data for "Tariff; Planned For Every Part" PFEP. Updated:2026-06-08
*/
tmlc_pre_filter as (
    select
        t1.*
    from {{ ref('pb_bom_hierarchy') }} t1
    where t1.bkcc = 'Crouching_Dragon'

    {% if not is_incremental() %}
        and coalesce(t1.component_effective_to, current_date) >= current_date
    {% endif %}
),

tmlc_bom_explosion as (
    select
        t1.assembly_item_hk AS root_item_hk,
        t1.assembly_item_bk AS root_item_bk,
        t1.assembly_item_id AS root_item_id,
        t1.assembly_bom_hk AS root_bom_hk,
        t1.assembly_bom_bk AS root_bom_bk,
        t1.assembly_bom_id AS root_bom_id,
        t1.assembly_plant_hk AS root_plant_hk,
        t1.assembly_plant_bk AS root_plant_bk,
        t1.assembly_plant_id AS root_plant_id,
        t1.assembly_bom_category AS root_bom_category,
        t1.assembly_bom_usage AS root_bom_usage,
        t1.assembly_alt_bom AS root_alt_bom,
        t1.assembly_item_hk,
        t1.assembly_item_bk,
        t1.assembly_item_id,
        t1.assembly_plant_hk,
        t1.assembly_plant_bk,
        t1.assembly_plant_id,
        t1.assembly_bom_hk,
        t1.assembly_bom_bk,
        t1.assembly_bom_id,
        t1.assembly_bom_category,
        t1.assembly_bom_usage,
        t1.assembly_alt_bom,
        t1.bom_is_preferred,
        t1.bom_implementation_date,
        t1.bom_change_notice,
        t1.component_item_hk,
        t1.component_item_bk,
        t1.component_item_id,
        t1.component_quantity,
        t1.component_uom,
        t1.component_item_num,
        t1.component_operation_sequence_num,
        t1.component_sequence_id,
        t1.component_item_node_num,
        t1.component_bom_item_type,
        t1.component_supply_subinventory,
        t1.component_wip_supply_type,
        t1.component_mutually_exclusive_options,
        t1.component_optional,
        t1.include_component_in_cost_rollup,
        t1.component_change_notice,
        t1.component_effective_from,
        t1.component_effective_to,
        1 AS level,
        ',' || assembly_item_bk || ',' || component_item_bk as bom_path,   -- swapped assembly_item_id for assembly_item_bk to keep bom path consistent in terms of business keys AC 10-24-2025
        NULL AS special_procurement_type,
        NULL AS wrk02_transfer_plant,
        t1.bkcc,
        t1.rec_src,
        t1.drvd_bom_explosion_cdc_dt,
        NULL AS drvd_assembly_plant_id
    from tmlc_pre_filter as t1
    {% if is_incremental() %}
    JOIN affected_and_new_roots AS roots
        ON  t1.assembly_item_hk = roots.root_item_key
        AND t1.bkcc = roots.bkcc
    {% endif %}
    union all
    select
        bh.root_item_hk
        , bh.root_item_bk
        , bh.root_item_id
        , bh.root_bom_hk
        , bh.root_bom_bk
        , bh.root_bom_id
        , bh.root_plant_hk
        , bh.root_plant_bk
        , bh.root_plant_id
        , bh.root_bom_category
        , bh.root_bom_usage
        , bh.root_alt_bom
        , b.assembly_item_hk
        , b.assembly_item_bk
        , b.assembly_item_id
        , b.assembly_plant_hk
        , b.assembly_plant_bk
        , b.assembly_plant_id
        , b.assembly_bom_hk
        , b.assembly_bom_bk
        , b.assembly_bom_id
        , b.assembly_bom_category
        , b.assembly_bom_usage
        , b.assembly_alt_bom
        , b.bom_is_preferred
        , b.bom_implementation_date
        , b.bom_change_notice
        , b.component_item_hk
        , b.component_item_bk
        , b.component_item_id
        , b.component_quantity
        , b.component_uom
        , b.component_item_num
        , b.component_operation_sequence_num
        , b.component_sequence_id
        , b.component_item_node_num
        , b.component_bom_item_type
        , b.component_supply_subinventory
        , b.component_wip_supply_type
        , b.component_mutually_exclusive_options
        , b.component_optional
        , b.include_component_in_cost_rollup
        , b.component_change_notice
        , b.component_effective_from
        , b.component_effective_to
        , bh.level + 1 as level
        , bh.bom_path || ',' || b.component_item_bk as bom_path
        , null as special_procurement_type
        , null as wrk02_transfer_plant
        , b.bkcc
        , b.rec_src
        , b.drvd_bom_explosion_cdc_dt        
        , null as drvd_assembly_plant_id
    from tmlc_bom_explosion as bh
        inner join tmlc_pre_filter as b
            on  bh.component_item_hk = b.assembly_item_hk
            and bh.assembly_alt_bom = b.assembly_alt_bom
            and bh.bkcc = b.bkcc                
    where bh.level < 20
      and bh.bom_path NOT LIKE '%,' || b.component_item_bk::varchar || ',%'    -- swapped component_item_id for component_item_bk to keep bom path consistent in terms of business keys AC 10-24-2025
),

winnsap_pre_filter as(
    select
        t1.*,
        coalesce(nullif(wrk02_transfer_plant, ''), assembly_plant_id) drvd_assembly_plant_id
    from {{ ref('pb_bom_hierarchy') }} t1
    where t1.bkcc = 'Hiding_Tiger'
),

winnsap_bom_explosion as (
    select
        assembly_item_hk as root_item_hk
        , assembly_item_bk as root_item_bk
        , assembly_item_id as root_item_id
        , assembly_bom_hk as root_bom_hk
        , assembly_bom_bk as root_bom_bk
        , assembly_bom_id as root_bom_id
        , assembly_plant_hk as root_plant_hk
        , assembly_plant_bk as root_plant_bk
        , assembly_plant_id as root_plant_id
        , assembly_bom_category as root_bom_category
        , assembly_bom_usage as root_bom_usage
        , assembly_alt_bom as root_alt_bom
        , assembly_item_hk
        , assembly_item_bk
        , assembly_item_id
        , assembly_plant_hk
        , assembly_plant_bk
        , assembly_plant_id
        , assembly_bom_hk
        , assembly_bom_bk
        , assembly_bom_id
        , assembly_bom_category
        , assembly_bom_usage
        , assembly_alt_bom
        , bom_is_preferred
        , bom_implementation_date
        , bom_change_notice
        , component_item_hk
        , component_item_bk
        , component_item_id
        , component_quantity
        , component_uom
        , component_item_num
        , component_operation_sequence_num
        , component_sequence_id
        , component_item_node_num
        , component_bom_item_type
        , component_supply_subinventory
        , component_wip_supply_type
        , component_mutually_exclusive_options
        , component_optional
        , include_component_in_cost_rollup
        , component_change_notice
        , component_effective_from
        , component_effective_to
        , 1 as level
        ,  ',' || assembly_item_id || ',' || component_item_bk as bom_path 
        , special_procurement_type
        , wrk02_transfer_plant
        , bkcc
        , rec_src
        , drvd_bom_explosion_cdc_dt        
        , drvd_assembly_plant_id
    from winnsap_pre_filter
    where assembly_bom_usage = '1' -- production  
    {% if is_incremental() %}
    and assembly_item_hk in (select root_item_key from affected_and_new_roots where bkcc = 'Hiding_Tiger')  
    {% endif %}
    union all
    select
        bh.root_item_hk
        , bh.root_item_bk
        , bh.root_item_id
        , bh.root_bom_hk
        , bh.root_bom_bk
        , bh.root_bom_id
        , bh.root_plant_hk
        , bh.root_plant_bk
        , bh.root_plant_id
        , bh.root_bom_category
        , bh.root_bom_usage
        , bh.root_alt_bom
        , b.assembly_item_hk
        , b.assembly_item_bk
        , b.assembly_item_id
        , b.assembly_plant_hk
        , b.assembly_plant_bk
        , b.assembly_plant_id
        , b.assembly_bom_hk
        , b.assembly_bom_bk
        , b.assembly_bom_id
        , b.assembly_bom_category
        , b.assembly_bom_usage
        , b.assembly_alt_bom
        , b.bom_is_preferred
        , b.bom_implementation_date
        , b.bom_change_notice
        , b.component_item_hk
        , b.component_item_bk
        , b.component_item_id
        , b.component_quantity
        , b.component_uom
        , b.component_item_num
        , b.component_operation_sequence_num
        , b.component_sequence_id
        , b.component_item_node_num
        , b.component_bom_item_type
        , b.component_supply_subinventory
        , b.component_wip_supply_type
        , b.component_mutually_exclusive_options
        , b.component_optional
        , b.include_component_in_cost_rollup
        , b.component_change_notice
        , b.component_effective_from
        , b.component_effective_to
        , bh.level + 1 as level
        , bh.bom_path || ',' || b.component_item_bk   as bom_path
        , b.special_procurement_type
        , b.wrk02_transfer_plant
        , b.bkcc
        , b.rec_src
        , b.drvd_bom_explosion_cdc_dt        
        , b.drvd_assembly_plant_id
    from winnsap_bom_explosion as bh
        inner join winnsap_pre_filter as b
            on bh.component_item_hk = b.assembly_item_hk
                and bh.drvd_assembly_plant_id = b.assembly_plant_id
                -- removing: B = "Commodity Formulations" 9 = "Product Engineering BOM"
                and b.assembly_bom_usage not in ('B', '9', 'R')
    where bh.level < 15
      and bh.bom_path NOT LIKE '%,' || b.component_item_id::varchar || ',%'  
),

---- JOIN LAYER ----
join_result as (
    /* Updated: 2026-06-08 — union Oracle EBS (tmlc / Crouching_Dragon) and SAP (winnsap / Hiding_Tiger) BOM explosions for PFEP use cases. */

    select * from tmlc_bom_explosion 
    union all
    select * from winnsap_bom_explosion
)

select
distinct
    current_timestamp as snapshot_dts
    , root_item_hk as root_item_key
    , root_item_bk as root_item_number
    , root_item_id
    , root_bom_hk as root_bom_key
    , root_bom_bk as root_bom_number
    , root_bom_id
    , root_plant_hk as root_plant_key
    , root_plant_bk as root_plant
    , root_plant_id
    , root_bom_category
    , root_bom_usage
    , root_alt_bom
    , assembly_item_hk as assembly_item_key
    , assembly_item_bk as assembly_item_number
    , assembly_item_id
    , assembly_plant_hk as assembly_plant_key
    , assembly_plant_bk as assembly_plant
    , assembly_plant_id
    , assembly_bom_hk as assembly_bom_key
    , assembly_bom_bk as assembly_bom_number
    , assembly_bom_id
    , assembly_bom_category
    , assembly_bom_usage
    , assembly_alt_bom
    , bom_is_preferred
    , cast(to_varchar(date(bom_implementation_date), 'YYYYMMDD') as integer) as bom_implementation_date__yyyymmdd
    , bom_change_notice
    , component_item_hk as component_item_key
    , component_item_bk as component_item_number
    , component_item_id
    , component_quantity
    , component_uom
    , component_item_num
    , component_operation_sequence_num
    , component_sequence_id
    , component_item_node_num
    , component_bom_item_type
    , component_supply_subinventory
    , component_wip_supply_type
    , component_mutually_exclusive_options
    , component_optional
    , include_component_in_cost_rollup
    , component_change_notice
    , cast(to_varchar(date(component_effective_from), 'YYYYMMDD') as integer) as component_effective_from_date__yyyymmdd
    , cast(to_varchar(date(component_effective_to), 'YYYYMMDD') as integer) as component_effective_to_date__yyyymmdd
    , level
    , bom_path
    , special_procurement_type
    , wrk02_transfer_plant
    , bkcc
    , rec_src
    -- These are fields required to define the incremental predicates
    , drvd_bom_explosion_cdc_dt
    , max(drvd_bom_explosion_cdc_dt) over(partition by root_bom_key ) as drvd_bom_explosion_cdc_max_dt
    , drvd_assembly_plant_id
from join_result
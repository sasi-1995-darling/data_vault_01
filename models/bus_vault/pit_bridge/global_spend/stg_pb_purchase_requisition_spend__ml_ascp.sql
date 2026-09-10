{{
    config(
        materialized='ephemeral'
    )
}}

with
l as (
    select * from {{ ref('lnk_purchase_requisition') }}
    /* This filter is necessary to ensure only one record is kept per Purchase Req level.
     However, the link's granularity is designed to track changes related to Item, Plant,Supplier etc.,*/
    qualify MAX(load_dts) over (partition by purchase_requisition_hk) = load_dts
)

, hub_purchase_requisition as (
    select * from {{ ref('hub_purchase_requisition') }}
)

, sat_purchase_requisition as (
    select * from {{ ref('sat_purchase_requisition__ml_ascp') }}
       qualify MAX(load_dts) over (partition by purchase_requisition_hk) = load_dts
)

/*  Fetch Latest PLAN Creation Date record */
, sat_purchase_requisition_latest_date as (
    select * from sat_purchase_requisition
    qualify max(creation_date) over (order by creation_date desc) = creation_date
)

, hub_supplier as (
    select * from {{ ref('hub_supplier_v2') }} where bkcc = 'Crouching_Dragon'
)

, sat_supplier_tmlc as (
    select
        *
    from {{ ref('sat_supplier__ml_ebs') }}
    qualify MAX(load_dts) over (partition by supplier_hk) = load_dts
)

, hub_item as (
    select * from  {{ ref('hub_item_v1') }} where bkcc = 'Crouching_Dragon')

, sat_item_tmlc as (
    select * ,
         sr_inventory_item_id::TEXT as drvd_sr_inv_item_id
    from {{ ref('sat_item_base_plan__ml_ascp') }}
    qualify 1 = row_number() over (partition by item_hk, organization_id order by load_dts desc)
)


, ref_ctg_src_tmlc as (
    select * from {{ ref('ref_item_sourcing_category_v2') }}
    where business_unit = 'SECURITY'
)

, ref_ctg_set as (
    select * from {{ ref('ref_item_categories__ml_ebs') }}
    where category_set_name = 'Country of Origin'
)

---

, join_layer as (
select
              
          s_pr.order_number as purchase_requisition_number 
        , s_pr.purch_line_num as purchase_requisition_item_number
        , s_pr.new_schedule_date as item_delivery_date            
        , sat_item_tmlc.uom_code as uom         
        , s_pr.new_order_quantity as quantity_po_unit       
        , sat_item_tmlc.standard_cost as net_price
        , s_pr.new_order_quantity * sat_item_tmlc.standard_cost as spend
        , CONCAT_WS('|', ref_ctg_src_tmlc.op_co, sat_item_tmlc.item_name) as opco_item
        , sat_supplier_tmlc.segment1 as supplier_number_parent
        , sat_supplier_tmlc.vendor_name as supplier_name_parent
        , sat_supplier_tmlc.segment1 as supplier_number_child
        , sat_supplier_tmlc.vendor_name as supplier_name_child
        , ref.category_value1 as country_of_origin
        , COALESCE(ref_ctg_src_tmlc.op_co, 'MASTER LOCK') as opco_category
        , COALESCE(ref_ctg_src_tmlc.director_name, 'REVIEW') as director_name
        , COALESCE(ref_ctg_src_tmlc.category_leader_name, 'REVIEW') as category_leader_name
        , COALESCE(ref_ctg_src_tmlc.fbin_category_i, 'REVIEW') as fbin_category_i
        , COALESCE(ref_ctg_src_tmlc.fbin_category_ii, 'REVIEW') as fbin_category_ii
        , COALESCE(ref_ctg_src_tmlc.fbin_category_iii, 'REVIEW') as fbin_category_iii
        , COALESCE(ref_ctg_src_tmlc.business_unit, 'SECURITY') as business_unit
        -- Payment Terms TBD
        , null as document_type -- TBD
        -- BK        
        , sat_item_tmlc.item_name as item_bk
        , SPLIT_PART(sat_item_tmlc.organization_code, ':', 2) as plant_bk
        , TO_CHAR(s_pr.new_schedule_date, 'YYYYMMDD') as item_delivery_date_bk
        --HK
        , l.purchase_requisition_hk
        , l.supplier_hk
        , l.item_hk
        , l.plant_hk
        , l.purchasing_org_hk 
        , l.purchasing_record_hk 
        --System fields
        , l.rec_src
        , h.bkcc
        , s_pr.psa_delete_ind

from l
    inner join hub_purchase_requisition h on l.purchase_requisition_hk = h.purchase_requisition_hk
    inner join sat_purchase_requisition_latest_date s_pr on h.purchase_requisition_hk = s_pr.purchase_requisition_hk
    left join hub_supplier on l.supplier_hk = hub_supplier.supplier_hk
    left join sat_supplier_tmlc on hub_supplier.supplier_hk = sat_supplier_tmlc.supplier_hk
    left join hub_item on l.item_hk = hub_item.item_hk
    left join sat_item_tmlc
        on hub_item.item_hk = sat_item_tmlc.item_hk and s_pr.organization_id = sat_item_tmlc.organization_id
    left join ref_ctg_src_tmlc on sat_item_tmlc.item_name = ref_ctg_src_tmlc.item
    left join ref_ctg_set as ref on sat_item_tmlc.sr_inventory_item_id = ref.inventory_item_id
where s_pr.order_type = 2
    and hub_supplier.supplier_bk <> '-2' 
    and sat_item_tmlc.organization_code in ('FOS:NG2', 'FOS:KY', 'FOS:ARZ', 'FOS:HO', 'FOS:NG')
)

--Final Layer
select
      purchase_requisition_hk
    , purchase_requisition_number
    , purchase_requisition_item_number
    , item_delivery_date      
    , uom   
    , quantity_po_unit
    , net_price    
    , spend   
    , opco_item
    , supplier_number_parent
    , supplier_name_parent
    , supplier_number_child
    , supplier_name_child
    , country_of_origin
    , opco_category
    , category_leader_name
    , director_name
    , fbin_category_i
    , fbin_category_ii
    , fbin_category_iii
    , business_unit
    , document_type
    , item_bk
    , plant_bk  
    , item_delivery_date_bk
    , supplier_hk
    , item_hk
    , plant_hk
    , purchasing_org_hk
    , purchasing_record_hk
    , rec_src
    , BKCC
    , 'TMLC-Forecast Purchase Requisition' as source   
from join_layer